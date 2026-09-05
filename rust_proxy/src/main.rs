//! Orbit Rust Proxy - Local TLS-impersonating proxy for Cloudflare bypass
//! 
//! This binary runs a local HTTP proxy that impersonates Chrome 120 TLS fingerprint
//! (avec retry via empreinte de secours) to bypass Cloudflare WAF protection on
//! streaming endpoints.

use std::sync::Arc;

use anyhow::{Context, Result};
use axum::{
    body::Body,
    extract::{Query, Path, FromRef, State},
    http::{HeaderMap, HeaderValue, Method, StatusCode, Uri, header},
    response::{IntoResponse, Response},
    routing::{get, post, any},
    Router,
};
use bytes::Bytes;
use http_body_util::{BodyExt, StreamBody};
use hyper::body::Incoming;
use hyper_util::client::legacy::Client;
use hyper_util::rt::TokioExecutor;
use hyper_rustls::HttpsConnectorBuilder;
use reqwest_impersonate::async_impl::client::Client as ImpersonatedClient;
use reqwest;
use serde::{Deserialize, Serialize};
use tokio::net::TcpListener;
use tokio::signal;
use tracing::{error, info, warn, debug, instrument};
use tracing_subscriber::{EnvFilter, fmt::format::FmtSpan};

mod config;
mod proxy;
mod hls;
mod dash;
mod cache;
mod client_factory;
mod health;
mod metrics;
mod status;

use config::ProxyConfig;
use proxy::ProxyState;
use hls::{HlsRewriter, UrlRegistry};
use dash::DashRewriter;
use cache::SegmentCache;
use client_factory::ClientFactory;
use health::HealthState;
use metrics::MetricsCollector;

#[derive(Clone)]
struct AppState {
    config: Arc<ProxyConfig>,
    proxy: Arc<ProxyState>,
    hls_rewriter: Arc<HlsRewriter>,
    dash_rewriter: Arc<DashRewriter>,
    health: Arc<HealthState>,
    metrics: Arc<MetricsCollector>,
    impersonated_client: Arc<ImpersonatedClient>,
    /// Empreinte TLS de secours (None si non disponible/échouée au démarrage).
    fallback_impersonated_client: Option<Arc<ImpersonatedClient>>,
    url_registry: Arc<UrlRegistry>,
    segment_cache: Arc<SegmentCache>,
}

// Pont FromRef : permet aux handlers /health et /metrics (State<Arc<...>>)
// d'extraire leur état depuis l'AppState du router principal.
impl FromRef<AppState> for Arc<MetricsCollector> {
    fn from_ref(state: &AppState) -> Self {
        state.metrics.clone()
    }
}

impl FromRef<AppState> for Arc<HealthState> {
    fn from_ref(state: &AppState) -> Self {
        state.health.clone()
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env()
            .add_directive("orbit_rust_proxy=debug".parse()?)
            .add_directive("hyper=info".parse()?)
            .add_directive("rustls=info".parse()?))
        .with_span_events(FmtSpan::CLOSE)
        .init();

    info!("🚀 Starting Orbit Rust Proxy v0.1.0");

    // Load configuration
    let config = Arc::new(ProxyConfig::load().context("Failed to load config")?);
    info!("📋 Config loaded: {:?}", config);

    let client_factory = ClientFactory::new(config.clone());

    // Initialize impersonated client (Chrome 120)
    let impersonated_client = client_factory
        .create_impersonated_client()
        .context("Failed to build impersonated client")?;
    info!("🕵️ Impersonated client ready (Chrome 120)");

    // Initialize fallback impersonated client (empreinte de secours, ex: Chrome 131)
    let fallback_impersonated_client = client_factory
        .create_fallback_impersonated_client()
        .map(Arc::new);
    if fallback_impersonated_client.is_some() {
        info!("🕵️ Fallback impersonated client ready ({})", config.fallback_browser);
    }

    // Initialize standard reqwest client for ProxyState
    let reqwest_client = reqwest::Client::builder()
        .timeout(config.request_timeout())
        .connect_timeout(config.connect_timeout())
        .read_timeout(config.read_timeout())
        .build()
        .context("Failed to build reqwest client")?;

    // Initialize hyper client for proxying (uses hyper-rustls for TLS)
    let https_connector = HttpsConnectorBuilder::new()
        .with_native_roots()
        .unwrap()
        .https_or_http()
        .enable_http1()
        .enable_http2()
        .build();
    
    let hyper_client = Client::builder(TokioExecutor::new())
        .pool_max_idle_per_host(10)
        .build(https_connector);

    // Initialize state
    let proxy_state = Arc::new(ProxyState::new(reqwest_client));
    let hls_rewriter = Arc::new(HlsRewriter::new(config.hls_rewrite_base.clone()));
    let dash_rewriter = Arc::new(DashRewriter::new(config.hls_rewrite_base.clone()));
    let health_state = Arc::new(HealthState::new());
    let metrics = Arc::new(MetricsCollector::new());
    let url_registry = Arc::new(UrlRegistry::new());
    let segment_cache = Arc::new(SegmentCache::new(config.cache_max_bytes));

    info!("🗄️  Segment cache ready ({} octets)", config.cache_max_bytes);

    let app_state = AppState {
        config: config.clone(),
        proxy: proxy_state,
        hls_rewriter,
        dash_rewriter,
        health: health_state,
        metrics,
        impersonated_client,
        fallback_impersonated_client,
        url_registry,
        segment_cache,
    };

    // Build router
    let app = build_router(app_state);

    // Start server
    // Bind sur listen_addr (défaut 127.0.0.1:8787) : évite les conflits de
    // ports et garde le proxy local uniquement (jamais exposé sur le LAN).
    let addr = config.bind_addr();
    let listener = TcpListener::bind(addr).await
        .context("Failed to bind to address")?;
    
    info!("🌐 Proxy server listening on http://{}", addr);
    info!("📋 Endpoints:");
    info!("   GET  /health          - Health check");
    info!("   GET  /api/proxy-status- État du proxy (JSON pour l'app Flutter)");
    info!("   GET  /metrics         - Prometheus metrics");
    info!("   GET  /proxy/stream    - Stream proxy (url=...)");
    info!("   GET  /proxy/hls/*     - HLS manifest/segment proxy");
    info!("   GET  /proxy/segment   - Segment proxy (url=...)");
    info!("   GET  /hls/{hash}/{*file} - Manifest/segment reécrit par le proxy");
    info!("   DELETE /cache          - Purge du cache segments");
    info!("   POST /proxy/configure - Runtime config update");

    // Graceful shutdown
    let server = axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal());

    if let Err(e) = server.await {
        error!("Server error: {}", e);
        return Err(e.into());
    }

    info!("👋 Proxy server stopped gracefully");
    Ok(())
}

fn build_router(state: AppState) -> Router {
    Router::new()
        .route("/health", get(health::health_check))
        .route("/api/proxy-status", get(status::proxy_status_handler))
        .route("/metrics", get(metrics::metrics_handler))
        .route("/proxy/stream", get(proxy::stream_proxy))
        .route("/proxy/hls/{*path}", get(proxy::hls_proxy))
        .route("/proxy/segment", get(proxy::segment_proxy))
        .route("/proxy/configure", post(proxy::configure_proxy))
        .route("/hls/{hash}/{*file}", get(proxy::hls_entrypoint))
        .route("/cache", axum::routing::delete(proxy::purge_cache))
        .with_state(state)
}

async fn shutdown_signal() {
    let ctrl_c = async {
        signal::ctrl_c()
            .await
            .expect("Failed to install Ctrl+C handler");
    };

    #[cfg(unix)]
    let terminate = async {
        signal::unix::signal(signal::unix::SignalKind::terminate())
            .expect("Failed to install signal handler")
            .recv()
            .await;
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        _ = ctrl_c => info!("Received Ctrl+C, shutting down..."),
        _ = terminate => info!("Received SIGTERM, shutting down..."),
    }
}

// Re-export modules
pub use config::ProxyConfig;
pub use proxy::{ProxyState, StreamProxyQuery, HlsProxyQuery};
pub use hls::HlsRewriter;
pub use health::HealthState;
pub use metrics::MetricsCollector;