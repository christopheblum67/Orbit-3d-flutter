//! Réécriture des manifests HLS (master + media).
//!
//! Toutes les URLs relatives (segments .ts/.m4s, playlists enfants, clés, maps)
//! sont converties en URLs absolues pointant vers le proxy local lui-même
//! (`http://127.0.0.1:PORT/hls/<hash>/<fichier>`) : le player refait alors
//! chaque requête via le proxy, qui re-signe l'empreinte TLS à chaque fetch.

use anyhow::{Context, Result};
use m3u8_rs::{parse_master_playlist, parse_media_playlist};
use std::collections::HashMap;
use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};
use std::sync::{Arc, Mutex};
use url::Url;

/// Registre `hash -> URL originale` permettant de retrouver l'URL réelle à
/// re-fetcher à partir de l'URL de proxy `/hls/<hash>/<fichier>`.
#[derive(Clone, Default)]
pub struct UrlRegistry {
    inner: Arc<Mutex<HashMap<String, String>>>,
}

impl UrlRegistry {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn register(&self, hash: &str, url: &str) {
        if let Ok(mut inner) = self.inner.lock() {
            inner.insert(hash.to_string(), url.to_string());
        }
    }

    pub fn resolve(&self, hash: &str) -> Option<String> {
        self.inner.lock().ok().and_then(|m| m.get(hash).cloned())
    }

    /// Vide le registre ; retourne le nombre d'entrées supprimées.
    pub fn clear(&self) -> usize {
        self.inner
            .lock()
            .ok()
            .map(|mut m| {
                let n = m.len();
                m.clear();
                n
            })
            .unwrap_or(0)
    }

    pub fn len(&self) -> usize {
        self.inner.lock().map(|m| m.len()).unwrap_or(0)
    }

    pub fn is_empty(&self) -> bool {
        self.len() == 0
    }

    /// Hash déterministe (DefaultHasher, clés fixes) d'une URL — clé du registre.
    pub fn hash_url(url: &str) -> String {
        let mut hasher = DefaultHasher::new();
        url.hash(&mut hasher);
        format!("{:016x}", hasher.finish())
    }

    /// Dernier segment du chemin d'une URL (nom de fichier affiché dans l'URL proxy).
    pub fn filename(url: &str) -> Option<String> {
        let parsed = Url::parse(url).ok()?;
        let last = parsed.path().trim_end_matches('/').rsplit('/').next().unwrap_or("");
        if last.is_empty() {
            None
        } else {
            Some(last.to_string())
        }
    }
}

/// Construit l'URL de proxy pour une URL absolue et mémorise hash -> URL.
pub fn build_proxy_url(proxy_base: &str, absolute_url: &str, registry: &UrlRegistry) -> String {
    let hash = UrlRegistry::hash_url(absolute_url);
    registry.register(&hash, absolute_url);
    let filename = UrlRegistry::filename(absolute_url).unwrap_or_else(|| "segment".to_string());
    format!("{}/hls/{}/{}", proxy_base.trim_end_matches('/'), hash, filename)
}

#[derive(Clone)]
pub struct HlsRewriter {
    proxy_base: String,
}

impl HlsRewriter {
    pub fn new(proxy_base: String) -> Self {
        Self { proxy_base }
    }

    pub fn rewrite_master_playlist(&self, content: &str, base_url: &str, registry: &UrlRegistry) -> Result<String> {
        let (_, mut playlist) = parse_master_playlist(content)
            .context("Failed to parse master playlist")?;

        let base = Url::parse(base_url).context("Invalid base URL")?;

        for variant in &mut playlist.variants {
            if let Some(uri) = &variant.uri {
                let absolute = base.join(uri).context("Failed to join variant URI")?;
                variant.uri = Some(self.proxy_url(&absolute.to_string(), registry));
            }
        }

        for session_data in &mut playlist.session_data {
            if let Some(uri) = &session_data.uri {
                let absolute = base.join(uri).context("Failed to join session data URI")?;
                session_data.uri = Some(self.proxy_url(&absolute.to_string(), registry));
            }
        }

        for session_key in &mut playlist.session_keys {
            if let Some(uri) = &session_key.uri {
                let absolute = base.join(uri).context("Failed to join session key URI")?;
                session_key.uri = Some(self.proxy_url(&absolute.to_string(), registry));
            }
        }

        let mut output = Vec::new();
        playlist.write_to(&mut output).context("Failed to write master playlist")?;
        String::from_utf8(output).context("Failed to convert playlist to string")
    }

    pub fn rewrite_media_playlist(&self, content: &str, base_url: &str, registry: &UrlRegistry) -> Result<String> {
        let (_, mut playlist) = parse_media_playlist(content)
            .context("Failed to parse media playlist")?;

        let base = Url::parse(base_url).context("Invalid base URL")?;

        if let Some(key) = &mut playlist.key {
            if let Some(uri) = &key.uri {
                let absolute = base.join(uri).context("Failed to join key URI")?;
                key.uri = Some(self.proxy_url(&absolute.to_string(), registry));
            }
        }

        for segment in &mut playlist.segments {
            segment.uri = self.proxy_url(
                &base.join(&segment.uri).context("Failed to join segment URI")?.to_string(),
                registry,
            );

            if let Some(map) = &mut segment.map {
                map.uri = self.proxy_url(
                    &base.join(&map.uri).context("Failed to join map URI")?.to_string(),
                    registry,
                );
            }

            for key in &mut segment.keys {
                if let Some(uri) = &key.uri {
                    let absolute = base.join(uri).context("Failed to join segment key URI")?;
                    key.uri = Some(self.proxy_url(&absolute.to_string(), registry));
                }
            }
        }

        let mut output = Vec::new();
        playlist.write_to(&mut output).context("Failed to write media playlist")?;
        String::from_utf8(output).context("Failed to convert playlist to string")
    }

    pub fn rewrite(&self, content: &str, base_url: &str, is_master: bool, registry: &UrlRegistry) -> Result<String> {
        if is_master {
            self.rewrite_master_playlist(content, base_url, registry)
        } else {
            self.rewrite_media_playlist(content, base_url, registry)
        }
    }

    fn proxy_url(&self, original_url: &str, registry: &UrlRegistry) -> String {
        build_proxy_url(&self.proxy_base, original_url, registry)
    }

    pub fn is_master_playlist(content: &str) -> bool {
        content.contains("#EXT-X-STREAM-INF:") || content.contains("#EXT-X-MEDIA:")
    }

    /// Base de résolution RFC 3986 : le répertoire du manifest, finissant par '/'.
    pub fn extract_base_url(_content: &str, original_url: &str) -> Result<String> {
        let parsed = Url::parse(original_url).context("Invalid original URL")?;
        let mut base = parsed.clone();
        base.set_query(None);
        base.set_fragment(None);

        let path = base.path().to_string();
        let trimmed = path.trim_end_matches('/').to_string();
        match trimmed.rfind('/') {
            Some(i) => base.set_path(&trimmed[..=i]),
            None => base.set_path("/"),
        }
        Ok(base.to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_is_master_playlist() {
        let master = "#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=1000\nvideo.m3u8";
        let media = "#EXTM3U\n#EXTINF:10,\nsegment.ts";

        assert!(HlsRewriter::is_master_playlist(master));
        assert!(!HlsRewriter::is_master_playlist(media));
    }

    #[test]
    fn test_hash_deterministic() {
        assert_eq!(UrlRegistry::hash_url("https://a.example/x.ts"), UrlRegistry::hash_url("https://a.example/x.ts"));
        assert_ne!(UrlRegistry::hash_url("https://a.example/x.ts"), UrlRegistry::hash_url("https://a.example/y.ts"));
    }

    #[test]
    fn test_build_proxy_url_registers() {
        let registry = UrlRegistry::new();
        let original = "https://example.com/video/segment1.ts";
        let url = build_proxy_url("http://127.0.0.1:8080", original, &registry);

        let hash = UrlRegistry::hash_url(original);
        assert!(url.starts_with(&format!("http://127.0.0.1:8080/hls/{}/segment1.ts", hash)));
        assert_eq!(registry.resolve(&hash).as_deref(), Some(original));
    }

    #[test]
    fn test_extract_base_url() {
        let base = HlsRewriter::extract_base_url("", "https://example.com/path/to/playlist.m3u8").unwrap();
        assert_eq!(base, "https://example.com/path/to/");
    }

    #[test]
    fn test_rewrite_media_playlist() {
        let rewriter = HlsRewriter::new("http://127.0.0.1:8080".to_string());
        let registry = UrlRegistry::new();
        let content = r#"#EXTM3U
#EXT-X-VERSION:3
#EXTINF:10.0,
segment1.ts
#EXTINF:10.0,
segment2.ts
#EXT-X-ENDLIST"#;

        let result = rewriter.rewrite_media_playlist(content, "https://example.com/video/", &registry).unwrap();
        assert!(result.contains("/hls/"));
        assert!(result.contains("segment1.ts"));
        assert!(result.contains("segment2.ts"));
        assert!(registry.len() >= 2);
    }

    #[test]
    fn test_rewrite_master_playlist() {
        let rewriter = HlsRewriter::new("http://127.0.0.1:8080".to_string());
        let registry = UrlRegistry::new();
        let content = r#"#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=1000000
playlist_720p.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=2000000
playlist_1080p.m3u8"#;

        let result = rewriter.rewrite_master_playlist(content, "https://example.com/video/", &registry).unwrap();
        assert!(result.contains("/hls/"));
        assert!(result.contains("playlist_720p.m3u8"));
        assert!(result.contains("playlist_1080p.m3u8"));
        assert!(registry.len() >= 2);
    }
}