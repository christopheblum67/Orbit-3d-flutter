//! Cache mémoire LRU pour les segments HLS/DASH.
//!
//! Quota en octets (défaut 256 Mo). L'ordre LRU est piloté par la crate `lru`
//! (capacité compteur fixée très haut), l'éviction est déclenchée manuellement
//! dès que le quota d'octets est dépassé. Aucune panique : les verrous empoisonnés
//! sont récupérés via `into_inner`.

use std::num::NonZeroUsize;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Mutex, MutexGuard};

use bytes::Bytes;
use lru::LruCache;
use serde::Serialize;
use tracing::{debug, info};

/// Entrée du cache : corps binaire + type MIME à réutiliser sans re-fetch.
#[derive(Clone)]
pub struct CachedSegment {
    pub data: Bytes,
    pub content_type: String,
}

impl CachedSegment {
    pub fn size(&self) -> usize {
        self.data.len()
    }
}

struct CacheInner {
    cache: LruCache<String, CachedSegment>,
    bytes: usize,
}

/// Rapport d'un vidage de cache (pour DELETE /cache).
#[derive(Debug, Clone, Serialize)]
pub struct ClearReport {
    pub cleared_entries: usize,
    pub freed_bytes: usize,
    pub hit_ratio: f64,
    pub hits_before_clear: u64,
    pub misses_before_clear: u64,
    pub remaining_entries: usize,
}

#[derive(Clone)]
pub struct SegmentCache {
    inner: Arc<Mutex<CacheInner>>,
    max_bytes: usize,
    hits: Arc<AtomicU64>,
    misses: Arc<AtomicU64>,
    inserts: Arc<AtomicU64>,
    evictions: Arc<AtomicU64>,
}

impl SegmentCache {
    /// `max_bytes = 0` désactive le cache (aucune insertion).
    pub fn new(max_bytes: usize) -> Self {
        // Capacité compteur très grande : seule l'éviction manuelle par
        // quota d'octets s'applique (voir `insert`).
        let capacity = NonZeroUsize::new(10_000_000).unwrap_or(NonZeroUsize::MIN);
        Self {
            inner: Arc::new(Mutex::new(CacheInner {
                cache: LruCache::new(capacity),
                bytes: 0,
            })),
            max_bytes,
            hits: Arc::new(AtomicU64::new(0)),
            misses: Arc::new(AtomicU64::new(0)),
            inserts: Arc::new(AtomicU64::new(0)),
            evictions: Arc::new(AtomicU64::new(0)),
        }
    }

    /// Accès au verrou interne, tolérant à l'empoisonnement (jamais de panique).
    fn guard(&self) -> MutexGuard<'_, CacheInner> {
        self.inner
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner())
    }

    /// Retourne une copie de l'entrée si présente (et met à jour l'ordre LRU).
    pub fn get(&self, key: &str) -> Option<CachedSegment> {
        let mut g = self.guard();
        if let Some(entry) = g.cache.get(key) {
            self.hits.fetch_add(1, Ordering::Relaxed);
            Some(entry.clone())
        } else {
            self.misses.fetch_add(1, Ordering::Relaxed);
            None
        }
    }

    /// Insère un segment ; évince les entrées les moins récentes si le quota est dépassé.
    pub fn insert(&self, key: String, segment: CachedSegment) {
        let size = segment.size();
        if self.max_bytes == 0 || size == 0 {
            return;
        }
        if size > self.max_bytes {
            debug!("segment de {} octets trop gros pour le cache (quota {})", size, self.max_bytes);
            return;
        }

        let mut g = self.guard();
        if let Some(old) = g.cache.put(key, segment) {
            g.bytes = g.bytes.saturating_sub(old.size());
        }
        g.bytes += size;
        self.inserts.fetch_add(1, Ordering::Relaxed);

        while g.bytes > self.max_bytes {
            match g.cache.pop_lru() {
                Some((_k, v)) => {
                    g.bytes = g.bytes.saturating_sub(v.size());
                    self.evictions.fetch_add(1, Ordering::Relaxed);
                }
                None => break,
            }
        }
    }

    pub fn hits_misses(&self) -> (u64, u64) {
        (self.hits.load(Ordering::Relaxed), self.misses.load(Ordering::Relaxed))
    }

    pub fn hit_ratio(&self) -> f64 {
        let (hits, misses) = self.hits_misses();
        ratio(hits, misses)
    }

    pub fn len(&self) -> usize {
        self.guard().cache.len()
    }

    pub fn bytes_used(&self) -> usize {
        self.guard().bytes
    }

    /// Vide le cache, loggue le hit ratio, remet les compteurs à zéro.
    pub fn clear(&self) -> ClearReport {
        let (hits, misses) = self.hits_misses();
        let ratio = ratio(hits, misses);

        let mut g = self.guard();
        let cleared_entries = g.cache.len();
        let freed_bytes = g.bytes;
        g.cache.clear();
        g.bytes = 0;
        drop(g);

        self.hits.store(0, Ordering::Relaxed);
        self.misses.store(0, Ordering::Relaxed);
        self.inserts.store(0, Ordering::Relaxed);
        self.evictions.store(0, Ordering::Relaxed);

        info!(
            "Cache segments purgé : {} entrées, {} octets libérés, hit ratio {:.2}% ({} hits / {} misses)",
            cleared_entries,
            freed_bytes,
            ratio * 100.0,
            hits,
            misses
        );

        ClearReport {
            cleared_entries,
            freed_bytes,
            hit_ratio: ratio,
            hits_before_clear: hits,
            misses_before_clear: misses,
            remaining_entries: 0,
        }
    }
}

fn ratio(hits: u64, misses: u64) -> f64 {
    let total = hits + misses;
    if total == 0 {
        0.0
    } else {
        hits as f64 / total as f64
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use bytes::Bytes;

    fn entry(n: usize) -> CachedSegment {
        CachedSegment {
            data: Bytes::from(vec![0u8; n]),
            content_type: "video/mp2t".to_string(),
        }
    }

    #[test]
    fn test_cache_hit_miss() {
        let cache = SegmentCache::new(1024 * 1024);
        assert!(cache.get("a").is_none());
        cache.insert("a".to_string(), entry(100));
        assert!(cache.get("a").is_some());
        let (hits, misses) = cache.hits_misses();
        assert_eq!(hits, 1);
        assert_eq!(misses, 1);
    }

    #[test]
    fn test_cache_eviction_by_bytes() {
        let cache = SegmentCache::new(150);
        cache.insert("a".to_string(), entry(100));
        cache.insert("b".to_string(), entry(100));
        // Quota 150 dépassé après 'b' -> 'a' (la moins récente) évincée.
        assert!(cache.get("a").is_none());
        assert!(cache.get("b").is_some());
        assert!(cache.bytes_used() <= 150);
    }

    #[test]
    fn test_cache_clear_report() {
        let cache = SegmentCache::new(1024 * 1024);
        cache.insert("a".to_string(), entry(50));
        assert!(cache.get("a").is_some());
        assert!(cache.get("b").is_none());
        let report = cache.clear();
        assert_eq!(report.cleared_entries, 1);
        assert_eq!(report.freed_bytes, 50);
        assert!(report.hit_ratio > 0.0);
        assert!(cache.get("a").is_none());
    }
}