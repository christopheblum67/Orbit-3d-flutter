use anyhow::Result;
use axum::{
    extract::State,
    http::StatusCode,
    response::{IntoResponse, Response},
    routing::get,
    Router,
};
use prometheus_client::encoding::text::encode;
use prometheus_client::metrics::counter::Counter;
use prometheus_client::metrics::family::Family;
use prometheus_client::metrics::gauge::Gauge;
use prometheus_client::metrics::histogram::{exponential_buckets, Histogram};
use prometheus_client::registry::Registry;
use std::collections::HashMap;
use std::sync::{Arc, LazyLock, Mutex};
use std::time::{Duration, Instant};
use tracing::{debug, info};

static GLOBAL_METRICS: LazyLock<Arc<MetricsCollector>> = LazyLock::new(|| {
    Arc::new(MetricsCollector::new())
});

pub fn global_metrics() -> Arc<MetricsCollector> {
    GLOBAL_METRICS.clone()
}

#[derive(Clone)]
pub struct MetricsCollector {
    registry: Arc<Mutex<Registry>>,
    
    requests_total: Family<String, Counter>,
    requests_by_status: Family<(String, u16), Counter>,
    request_duration_seconds: Family<String, Histogram>,
    errors_total: Family<(String, String), Counter>,
    bytes_transferred: Counter,
    active_connections: Gauge,
    upstream_requests_total: Family<String, Counter>,
    upstream_request_duration_seconds: Family<String, Histogram>,
    config_updates_total: Counter,
    hls_rewrites_total: Counter,
    hls_rewrite_errors_total: Counter,
    cache_hits_total: Counter,
    cache_misses_total: Counter,
    upstream_fallback_retries_total: Counter,
}

impl MetricsCollector {
    pub fn new() -> Self {
        let mut registry = Registry::default();
        
        let requests_total = Family::default();
        registry.register(
            "proxy_requests_total",
            "Total number of proxy requests",
            requests_total.clone(),
        );
        
        let requests_by_status = Family::default();
        registry.register(
            "proxy_requests_by_status_total",
            "Total number of proxy requests by status code",
            requests_by_status.clone(),
        );
        
        let request_duration_seconds = Family::default();
        registry.register(
            "proxy_request_duration_seconds",
            "Request duration in seconds",
            request_duration_seconds.clone(),
        );
        
        let errors_total = Family::default();
        registry.register(
            "proxy_errors_total",
            "Total number of proxy errors",
            errors_total.clone(),
        );
        
        let bytes_transferred = Counter::default();
        registry.register(
            "proxy_bytes_transferred_total",
            "Total bytes transferred",
            bytes_transferred.clone(),
        );
        
        let active_connections = Gauge::default();
        registry.register(
            "proxy_active_connections",
            "Number of active connections",
            active_connections.clone(),
        );
        
        let upstream_requests_total = Family::default();
        registry.register(
            "proxy_upstream_requests_total",
            "Total number of upstream requests",
            upstream_requests_total.clone(),
        );
        
        let upstream_request_duration_seconds = Family::default();
        registry.register(
            "proxy_upstream_request_duration_seconds",
            "Upstream request duration in seconds",
            upstream_request_duration_seconds.clone(),
        );
        
        let config_updates_total = Counter::default();
        registry.register(
            "proxy_config_updates_total",
            "Total number of configuration updates",
            config_updates_total.clone(),
        );
        
        let hls_rewrites_total = Counter::default();
        registry.register(
            "proxy_hls_rewrites_total",
            "Total number of HLS playlist rewrites",
            hls_rewrites_total.clone(),
        );
        
        let hls_rewrite_errors_total = Counter::default();
        registry.register(
            "proxy_hls_rewrite_errors_total",
            "Total number of HLS rewrite errors",
            hls_rewrite_errors_total.clone(),
        );
        
        let cache_hits_total = Counter::default();
        registry.register(
            "proxy_cache_hits_total",
            "Total number of cache hits for cached segments",
            cache_hits_total.clone(),
        );
        
        let cache_misses_total = Counter::default();
        registry.register(
            "proxy_cache_misses_total",
            "Total number of cache misses for cached segments",
            cache_misses_total.clone(),
        );
        
        let upstream_fallback_retries_total = Counter::default();
        registry.register(
            "proxy_upstream_fallback_retries_total",
            "Total number of upstream retries using the fallback TLS fingerprint",
            upstream_fallback_retries_total.clone(),
        );
        
        Self {
            registry: Arc::new(Mutex::new(registry)),
            requests_total,
            requests_by_status,
            request_duration_seconds,
            errors_total,
            bytes_transferred,
            active_connections,
            upstream_requests_total,
            upstream_request_duration_seconds,
            config_updates_total,
            hls_rewrites_total,
            hls_rewrite_errors_total,
            cache_hits_total,
            cache_misses_total,
            upstream_fallback_retries_total,
        }
    }
    
    pub fn increment_requests_total(&self, endpoint: &str) {
        self.requests_total.get_or_create(&endpoint.to_string()).inc();
    }
    
    pub fn increment_requests_by_status(&self, endpoint: &str, status: u16) {
        self.requests_by_status
            .get_or_create(&(endpoint.to_string(), status))
            .inc();
    }
    
    pub fn record_request_duration(&self, endpoint: &str, duration: Duration) {
        self.request_duration_seconds
            .get_or_create(&endpoint.to_string())
            .observe(duration.as_secs_f64());
    }
    
    pub fn increment_errors_total(&self, endpoint: &str, error_type: &str) {
        self.errors_total
            .get_or_create(&(endpoint.to_string(), error_type.to_string()))
            .inc();
    }
    
    pub fn increment_bytes_transferred(&self, bytes: f64) {
        self.bytes_transferred.inc_by(bytes as u64);
    }
    
    pub fn set_active_connections(&self, count: i64) {
        self.active_connections.set(count);
    }
    
    pub fn increment_active_connections(&self) {
        self.active_connections.inc();
    }
    
    pub fn decrement_active_connections(&self) {
        self.active_connections.dec();
    }
    
    pub fn increment_upstream_requests_total(&self, endpoint: &str) {
        self.upstream_requests_total
            .get_or_create(&endpoint.to_string())
            .inc();
    }
    
    pub fn record_upstream_request_duration(&self, endpoint: &str, duration: Duration) {
        self.upstream_request_duration_seconds
            .get_or_create(&endpoint.to_string())
            .observe(duration.as_secs_f64());
    }
    
    pub fn increment_config_updates_total(&self) {
        self.config_updates_total.inc();
    }
    
    pub fn increment_hls_rewrites_total(&self) {
        self.hls_rewrites_total.inc();
    }
    
    pub fn increment_hls_rewrite_errors_total(&self) {
        self.hls_rewrite_errors_total.inc();
    }
    
    pub fn increment_cache_hits(&self) {
        self.cache_hits_total.inc();
    }
    
    pub fn increment_cache_misses(&self) {
        self.cache_misses_total.inc();
    }
    
    pub fn increment_upstream_fallback_retries(&self) {
        self.upstream_fallback_retries_total.inc();
    }
    
    pub fn gather(&self) -> String {
        let mut buffer = String::new();
        let registry = self.registry.lock().unwrap();
        encode(&mut buffer, &registry).unwrap();
        buffer
    }
    
    pub fn registry(&self) -> Arc<Mutex<Registry>> {
        self.registry.clone()
    }
}

impl Default for MetricsCollector {
    fn default() -> Self {
        Self::new()
    }
}

pub async fn metrics_handler(State(state): State<Arc<MetricsCollector>>) -> impl IntoResponse {
    let metrics = state.gather();
    Response::builder()
        .status(StatusCode::OK)
        .header("content-type", "text/plain; version=0.0.4; charset=utf-8")
        .body(metrics)
        .unwrap()
}

pub fn metrics_router(state: Arc<MetricsCollector>) -> Router {
    Router::new()
        .route("/metrics", get(metrics_handler))
        .with_state(state)
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::{
        body::Body,
        http::{Request, StatusCode},
    };
    use tower::ServiceExt;
    
    #[test]
    fn test_metrics_collector_creation() {
        let collector = MetricsCollector::new();
        collector.increment_requests_total("test");
        collector.increment_requests_by_status("test", 200);
        collector.record_request_duration("test", Duration::from_millis(100));
        collector.increment_errors_total("test", "timeout");
        collector.increment_bytes_transferred(1024.0);
        
        let metrics = collector.gather();
        assert!(metrics.contains("proxy_requests_total"));
        assert!(metrics.contains("proxy_requests_by_status_total"));
        assert!(metrics.contains("proxy_request_duration_seconds"));
        assert!(metrics.contains("proxy_errors_total"));
        assert!(metrics.contains("proxy_bytes_transferred_total"));
    }
    
    #[tokio::test]
    async fn test_metrics_endpoint() {
        let state = Arc::new(MetricsCollector::new());
        state.increment_requests_total("test_endpoint");
        
        let app = metrics_router(state);
        
        let response = app
            .oneshot(Request::builder().uri("/metrics").body(Body::empty()).unwrap())
            .await
            .unwrap();
        
        assert_eq!(response.status(), StatusCode::OK);
        
        let body = axum::body::to_bytes(response.into_body(), usize::MAX).await.unwrap();
        let body_str = String::from_utf8(body.to_vec()).unwrap();
        assert!(body_str.contains("proxy_requests_total"));
    }
    
    #[test]
    fn test_global_metrics() {
        let metrics = global_metrics();
        metrics.increment_requests_total("global_test");
        let gathered = metrics.gather();
        assert!(gathered.contains("global_test"));
    }
    
    #[test]
    fn test_histogram_buckets() {
        let collector = MetricsCollector::new();
        for i in 0..100 {
            collector.record_request_duration("test", Duration::from_millis(i * 10));
        }
        let metrics = collector.gather();
        assert!(metrics.contains("proxy_request_duration_seconds"));
        assert!(metrics.contains("bucket"));
    }
}