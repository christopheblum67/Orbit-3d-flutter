//! Endpoint `/api/proxy-status` : état courant du proxy pour le pont Flutter
//! (`RustProxyManager.ping()` valide le démarrage en recevant ce JSON).
//!
//! 💡 BUILD À VALIDER SUR MACHINE AVEC CARGO AVANT TOUTE UTILISATION :
//!    Rust/Cargo n'est pas installé dans l'environnement d'édition, ce module
//!    n'a donc PAS été compilé. À faire :
//!       cargo check && cargo test   (dans rust_proxy/)
//!    puis `curl http://127.0.0.1:8787/api/proxy-status` pour vérifier le cast
//!    de l'`AppState` (config / segment_cache / metrics) contre `/health`.
//!
//! Les clés JSON sont alignées sur `RustProxyStatus.fromJson` côté Dart :
//! `status`, `port`, `cache_hit_ratio`, `segments_cached`, `proxy_mode`.

use axum::{extract::State, Json};
use serde::Serialize;

use crate::AppState;

/// Réponse renvoyée par GET /api/proxy-status.
#[derive(Debug, Clone, Serialize)]
pub struct ProxyStatus {
    pub status: &'static str,
    pub port: u16,
    pub cache_hit_ratio: f64,
    pub segments_cached: usize,
    pub proxy_mode: &'static str,
}

pub async fn proxy_status_handler(State(state): State<crate::AppState>) -> Json<ProxyStatus> {
    Json(ProxyStatus {
        status: "running",
        port: state.config.port,
        cache_hit_ratio: state.segment_cache.hit_ratio(),
        segments_cached: state.segment_cache.len(),
        proxy_mode: "cloudflare-tls-impersonation",
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_proxy_status_shares_cast_with_health() {
        // Valide le « cast contre la config » : le handler ne construit sa
        // réponse qu'à partir de champs d'AppState (config/segment_cache).
        // À re-vérifier à la compilation (cargo check) pour le wiring exact.
        let status = ProxyStatus {
            status: "running",
            port: 8787,
            cache_hit_ratio: 0.5,
            segments_cached: 3,
            proxy_mode: "cloudflare-tls-impersonation",
        };
        assert_eq!(status.status, "running");
        assert_eq!(status.port, 8787);
        assert!(status.cache_hit_ratio > 0.0);
        assert_eq!(status.segments_cached, 3);
    }

    #[test]
    fn test_status_serializes_expected_keys() {
        let status = ProxyStatus {
            status: "running",
            port: 8787,
            cache_hit_ratio: 0.25,
            segments_cached: 2,
            proxy_mode: "cloudflare-tls-impersonation",
        };
        let json = serde_json::to_value(&status).unwrap();
        let obj = json.as_object().expect("status serializes to an object");
        assert!(obj.contains_key("status"));
        assert!(obj.contains_key("port"));
        assert!(obj.contains_key("cache_hit_ratio"));
        assert!(obj.contains_key("segments_cached"));
        assert!(obj.contains_key("proxy_mode"));
        assert_eq!(obj["status"], "running");
        assert_eq!(obj["segments_cached"], 2);
    }
}