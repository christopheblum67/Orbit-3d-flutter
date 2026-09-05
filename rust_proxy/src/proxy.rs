use axum::{
    body::Body,
    extract::{Path, Query, State},
    http::{HeaderMap, HeaderValue, StatusCode},
    http::response::Builder as ResponseBuilder,
    response::{IntoResponse, Response},
    Json,
};
use bytes::Bytes;
use futures_util::StreamExt;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use std::time::Instant;
use tracing::{debug, error, info, warn};
use url::Url;

use crate::cache::CachedSegment;
use crate::config::ProxyConfig;
use crate::dash::DashRewriter;
use crate::hls::{HlsRewriter, UrlRegistry};

#[derive(Clone)]
pub struct ProxyState {
    pub client: Arc<reqwest::Client>,
}

impl ProxyState {
    pub fn new(client: reqwest::Client) -> Self {
        Self { client: Arc::new(client) }
    }
}

#[derive(Debug, Deserialize)]
pub struct StreamProxyQuery {
    pub url: String,
    #[serde(default)]
    pub headers: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct HlsProxyQuery {
    pub url: String,
}

#[derive(Debug, Deserialize)]
pub struct SegmentProxyQuery {
    pub url: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct ConfigureRequest {
    pub port: Option<u16>,
    pub request_timeout_secs: Option<u64>,
    pub connect_timeout_secs: Option<u64>,
    pub read_timeout_secs: Option<u64>,
    pub hls_rewrite_base: Option<String>,
    pub max_redirects: Option<usize>,
    pub user_agent: Option<String>,
    pub log_level: Option<String>,
    pub enable_metrics: Option<bool>,
    pub health_check_interval_secs: Option<u64>,
}

#[derive(Debug, Serialize)]
pub struct ConfigureResponse {
    pub success: bool,
    pub message: String,
    pub config: Option<ProxyConfig>,
}

#[derive(Debug, Serialize)]
pub struct PurgeResponse {
    pub success: bool,
    pub cleared_entries: usize,
    pub freed_bytes: usize,
    pub hit_ratio: f64,
    pub hits_before_clear: u64,
    pub misses_before_clear: u64,
    pub registry_entries_cleared: usize,
}

const FORWARDED_HEADERS: &[&str] = &[
    "range",
    "accept",
    "accept-language",
    "accept-encoding",
    "cache-control",
    "if-modified-since",
    "if-none-match",
    "origin",
    "referer",
    "user-agent",
    "sec-fetch-dest",
    "sec-fetch-mode",
    "sec-fetch-site",
    "sec-ch-ua",
    "sec-ch-ua-mobile",
    "sec-ch-ua-platform",
];

const RESPONSE_HEADERS_TO_FORWARD: &[&str] = &[
    "content-type",
    "content-length",
    "content-range",
    "accept-ranges",
    "cache-control",
    "etag",
    "last-modified",
    "content-encoding",
    "transfer-encoding",
    "content-disposition",
];

/// En-têtes upstream conservés sur les réponses de segments.
const UPSTREAM_HEADERS_TO_FORWARD: &[&str] = &[
    "content-range",
    "accept-ranges",
    "etag",
    "last-modified",
    "cache-control",
    "content-disposition",
    "content-type",
];

/// Corps upstream complet (mis en mémoire) + méta-données utiles.
struct UpstreamBody {
    status: StatusCode,
    content_type: Option<String>,
    headers: Vec<(String, String)>,
    bytes: Bytes,
    /// Empreinte TLS utilisée (ex: "chrome-120" / "chrome-131").
    mode: String,
}

/// Récupère une ressource via le client impersonant ; si le WAF répond 403/406,
/// on retente une fois avec l'empreinte de secours puis on propage une erreur claire.
async fn fetch_upstream_bytes(
    state: &crate::AppState,
    url: &str,
    range: Option<&str>,
) -> Result<UpstreamBody, (StatusCode, String)> {
    let mut attempts: Vec<(Arc<reqwest_impersonate::async_impl::client::Client>, String)> =
        vec![(state.impersonated_client.clone(), "chrome-120".to_string())];
    if let Some(fallback) = state.fallback_impersonated_client.clone() {
        attempts.push((fallback, state.config.fallback_browser.clone()));
    }

    let partial = matches!(range, Some(r) if !r.trim().is_empty() && r.trim() != "bytes=0-");
    let mut last_blocked: Option<(StatusCode, String)> = None;

    for (idx, (client, mode)) in attempts.iter().enumerate() {
        let mut request = client.get(url);
        if partial {
            if let Some(r) = range {
                request = request.header("range", r.trim());
            }
        }

        let response = match request.send().await {
            Ok(resp) => resp,
            Err(e) => {
                return Err((StatusCode::BAD_GATEWAY, format!("Upstream error: {}", e)));
            }
        };

        let status = response.status();

        if (status == StatusCode::FORBIDDEN || status == StatusCode::NOT_ACCEPTABLE)
            && idx + 1 < attempts.len()
        {
            // Bloqué par le WAF : on réessaie avec l'autre empreinte TLS.
            state.metrics.increment_upstream_fallback_retries();
            warn!(
                "WAF blocked {} with {} ({}) — retry with {}",
                url,
                status,
                mode,
                attempts[(idx + 1) % attempts.len()].1
            );
            last_blocked = Some((
                status,
                format!("Upstream blocked by WAF ({} {})", status.as_u16(), mode),
            ));
            continue;
        }

        if !status.is_success() && status != StatusCode::PARTIAL_CONTENT {
            state.metrics.increment_errors_total("upstream", "upstream_status");
            return Err((status, format!("Upstream returned {}", status)));
        }

        let mut headers = Vec::new();
        for name in UPSTREAM_HEADERS_TO_FORWARD {
            if let Some(value) = response.headers().get(*name) {
                if let Ok(s) = value.to_str() {
                    headers.push((name.to_string(), s.to_string()));
                }
            }
        }
        let content_type = headers
            .iter()
            .find(|(n, _)| n == "content-type")
            .map(|(_, v)| v.clone());

        let bytes = response.bytes().await.map_err(|e| {
            (StatusCode::BAD_GATEWAY, format!("Failed to read upstream body: {}", e))
        })?;

        debug!("Fetched {} via {} ({} bytes)", url, mode, bytes.len());
        return Ok(UpstreamBody {
            status,
            content_type,
            headers,
            bytes,
            mode: mode.clone(),
        });
    }

    Err(last_blocked.unwrap_or_else(|| (StatusCode::BAD_GATEWAY, "Upstream blocked".to_string())))
}

/// Réponse d'erreur avec en-tête `X-Proxy-Error` (message clair pour le client).
fn error_response(status: StatusCode, message: String) -> Response {
    let mut builder = Response::builder().status(status);
    if let Ok(value) = HeaderValue::from_str(&message) {
        builder = builder.header("x-proxy-error", value);
    }
    match builder.body(Body::from(message)) {
        Ok(response) => response,
        Err(_) => (StatusCode::INTERNAL_SERVER_ERROR, "internal error").into_response(),
    }
}

/// Conclut un `ResponseBuilder` sans paniquer (fallback 500 en cas d'échec).
fn finish_response(builder: ResponseBuilder, body: Body) -> Response {
    match builder.body(body) {
        Ok(response) => response,
        Err(_) => error_response(StatusCode::INTERNAL_SERVER_ERROR, "Failed to build response".to_string()),
    }
}

fn report(state: &crate::AppState, endpoint: &str, start: Instant, status: StatusCode) {
    state.metrics.record_request_duration(endpoint, start.elapsed());
    state.metrics.increment_requests_by_status(endpoint, status.as_u16());
}

fn guess_content_type(name: &str) -> String {
    let lower = name.to_ascii_lowercase();
    if lower.ends_with(".ts") {
        "video/mp2t".to_string()
    } else if lower.ends_with(".m4s") || lower.ends_with(".mp4") {
        "video/mp4".to_string()
    } else if lower.ends_with(".aac") {
        "audio/aac".to_string()
    } else if lower.ends_with(".mp3") {
        "audio/mpeg".to_string()
    } else if lower.ends_with(".vtt") || lower.ends_with(".webvtt") {
        "text/vtt".to_string()
    } else {
        "application/octet-stream".to_string()
    }
}

/// Reconstruit l'URL upstream réelle à partir de l'URL enregistrée et du nom de
/// fichier demandé par le player. Gère la substitution des placeholders DASH du
/// dernier segment (`seg_$Number$.m4s` -> `seg_5.m4s`).
fn resolve_upstream_url(registered: &str, requested_name: &str) -> Result<String, String> {
    let mut url = Url::parse(registered)
        .map_err(|e| format!("Invalid registered URL '{}': {}", registered, e))?;

    let trimmed = url.path().trim_end_matches('/').to_string();
    if trimmed.is_empty() {
        return Ok(url.to_string());
    }

    let last = trimmed.rsplit('/').next().unwrap_or("");
    if last == requested_name || last.is_empty() {
        return Ok(url.to_string());
    }

    // Placeholder DASH présent dans le dernier segment enregistré.
    if let Some(open) = last.find('$') {
        let prefix = &last[..open];
        let suffix_start = last[open + 1..]
            .find('$')
            .map(|i| open + 1 + i + 1)
            .unwrap_or(last.len());
        let suffix = &last[suffix_start.min(last.len())..];
        if requested_name.starts_with(prefix) && requested_name.ends_with(suffix) {
            let mut segments: Vec<&str> = trimmed.split('/').collect();
            if let Some(seg) = segments.last_mut() {
                *seg = requested_name;
            }
            url.set_path(&segments.join("/"));
        }
    }
    Ok(url.to_string())
}

fn cached_segment_response(entry: &CachedSegment, requested_name: &str) -> Response {
    let content_type = if entry.content_type.is_empty() {
        guess_content_type(requested_name)
    } else {
        entry.content_type.clone()
    };

    let builder = Response::builder()
        .status(StatusCode::OK)
        .header("content-type", content_type)
        .header("content-length", entry.data.len().to_string())
        .header("accept-ranges", "bytes")
        .header("x-proxy-cache", "HIT");
    finish_response(builder, Body::from(entry.data.clone()))
}

fn segment_response(body: UpstreamBody, requested_name: &str) -> Response {
    let content_type = body
        .content_type
        .clone()
        .filter(|ct| !ct.is_empty())
        .unwrap_or_else(|| guess_content_type(requested_name));

    let mut builder = Response::builder().status(body.status);
    for (name, value) in &body.headers {
        if *name == "content-length" {
            continue;
        }
        if let Ok(v) = HeaderValue::from_str(value) {
            builder = builder.header(name.as_str(), v);
        }
    }
    builder = builder
        .header("content-type", content_type)
        .header("content-length", body.bytes.len().to_string())
        .header("x-proxy-cache", "MISS")
        .header("x-proxy-upstream-mode", body.mode.clone());
    finish_response(builder, Body::from(body.bytes))
}

// ---------------------------------------------------------------------------
// Handlers
// ---------------------------------------------------------------------------

pub async fn stream_proxy(
    State(state): State<crate::AppState>,
    Query(query): Query<StreamProxyQuery>,
) -> Response {
    let start = Instant::now();
    let target_url = query.url;

    state.metrics.increment_requests_total("stream_proxy");

    debug!("Stream proxy request for: {}", target_url);

    let _parsed_url = match Url::parse(&target_url) {
        Ok(url) => url,
        Err(e) => {
            state.metrics.increment_errors_total("stream_proxy", "invalid_url");
            return error_response(StatusCode::BAD_REQUEST, format!("Invalid URL: {}", e));
        }
    };

    let mut request = state.impersonated_client.get(target_url.clone());

    if let Some(headers_str) = query.headers {
        if let Ok(headers_map) = serde_json::from_str::<HashMap<String, String>>(&headers_str) {
            for (key, value) in headers_map {
                if FORWARDED_HEADERS.contains(&key.to_lowercase().as_str()) {
                    request = request.header(&key, &value);
                }
            }
        }
    }

    let response = match request.send().await {
        Ok(resp) => resp,
        Err(e) => {
            state.metrics.increment_errors_total("stream_proxy", "upstream_error");
            error!("Upstream error for {}: {}", target_url, e);
            return error_response(StatusCode::BAD_GATEWAY, format!("Upstream error: {}", e));
        }
    };

    let status = response.status();
    let mut response_builder = Response::builder().status(status);

    for (name, value) in response.headers() {
        let name_str = name.as_str().to_lowercase();
        if RESPONSE_HEADERS_TO_FORWARD.contains(&name_str.as_str()) {
            if let Ok(val) = HeaderValue::from_bytes(value.as_bytes()) {
                response_builder = response_builder.header(name, val);
            }
        }
    }

    response_builder = response_builder.header("x-proxy-upstream-status", status.as_str());
    response_builder = response_builder.header("x-proxy-upstream-url", target_url);

    let body = response.bytes_stream()
        .map(|chunk| chunk.map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e)))
        .boxed();

    let stream_body = Body::from_stream(body);

    report(&state, "stream_proxy", start, status);

    if status.is_success() {
        state.metrics.increment_bytes_transferred(start.elapsed().as_secs_f64() * 1024.0);
    }

    finish_response(response_builder, stream_body)
}

pub async fn hls_proxy(
    State(state): State<crate::AppState>,
    Path(_path): Path<String>,
    Query(query): Query<HlsProxyQuery>,
) -> Response {
    let start = Instant::now();
    let target_url = query.url;

    state.metrics.increment_requests_total("hls_proxy");

    debug!("HLS proxy request for: {} (path: {})", target_url, _path);

    let _parsed_url = match Url::parse(&target_url) {
        Ok(url) => url,
        Err(e) => {
            state.metrics.increment_errors_total("hls_proxy", "invalid_url");
            return error_response(StatusCode::BAD_REQUEST, format!("Invalid URL: {}", e));
        }
    };

    let body = match fetch_upstream_bytes(&state, &target_url, None).await {
        Ok(b) => b,
        Err((status, msg)) => {
            state.metrics.increment_errors_total("hls_proxy", "upstream_manifest");
            return error_response(status, msg);
        }
    };

    let content_type = body.content_type.clone().unwrap_or_default();

    let content_str = match String::from_utf8(body.bytes.to_vec()) {
        Ok(s) => s,
        Err(e) => {
            state.metrics.increment_errors_total("hls_proxy", "utf8_error");
            return error_response(StatusCode::BAD_GATEWAY, format!("Invalid UTF-8: {}", e));
        }
    };

    let is_dash = !content_type.to_lowercase().contains("mpegurl") && DashRewriter::looks_like_mpd(&content_str);
    let is_master = if is_dash {
        false
    } else {
        HlsRewriter::is_master_playlist(&content_str)
    };

    let base_url = match HlsRewriter::extract_base_url(&content_str, &target_url) {
        Ok(b) => b,
        Err(e) => {
            error!("Failed to extract base URL: {}", e);
            target_url.clone()
        }
    };

    let rewritten = if is_dash {
        state.dash_rewriter.rewrite(&content_str, &base_url, &state.url_registry)
    } else {
        state.hls_rewriter.rewrite(&content_str, &base_url, is_master, &state.url_registry)
    };

    let rewritten = match rewritten {
        Ok(r) => r,
        Err(e) => {
            state.metrics.increment_hls_rewrite_errors_total();
            error!("Failed to rewrite HLS: {}", e);
            return error_response(StatusCode::INTERNAL_SERVER_ERROR, format!("Rewrite error: {}", e));
        }
    };
    state.metrics.increment_hls_rewrites_total();

    let mut response_builder = Response::builder().status(StatusCode::OK);
    if is_dash {
        response_builder = response_builder.header("content-type", "application/dash+xml");
    } else {
        response_builder = response_builder.header("content-type", "application/vnd.apple.mpegurl");
    }
    response_builder = response_builder.header("cache-control", "no-cache, no-store, must-revalidate");
    response_builder = response_builder.header("x-proxy-upstream-url", target_url);
    response_builder = response_builder.header("x-proxy-rewritten", "true");
    response_builder = response_builder.header("x-proxy-is-master", is_master.to_string());
    response_builder = response_builder.header("x-proxy-upstream-mode", body.mode.clone());

    report(&state, "hls_proxy", start, StatusCode::OK);
    finish_response(response_builder, Body::from(rewritten))
}

pub async fn segment_proxy(
    State(state): State<crate::AppState>,
    Query(query): Query<SegmentProxyQuery>,
    headers: HeaderMap,
) -> Response {
    let start = Instant::now();
    let target_url = query.url;

    state.metrics.increment_requests_total("segment_proxy");

    debug!("Segment proxy request for: {}", target_url);

    let _parsed_url = match Url::parse(&target_url) {
        Ok(url) => url,
        Err(e) => {
            state.metrics.increment_errors_total("segment_proxy", "invalid_url");
            return error_response(StatusCode::BAD_REQUEST, format!("Invalid URL: {}", e));
        }
    };

    let range = headers.get("range").and_then(|v| v.to_str().ok()).map(|s| s.to_string());
    let partial = matches!(range.as_deref(), Some(r) if r != "bytes=0-");
    let requested_name = UrlRegistry::filename(&target_url).unwrap_or_else(|| "segment".to_string());

    let cache_key = target_url.clone();
    if !partial {
        if let Some(entry) = state.segment_cache.get(&cache_key) {
            state.metrics.increment_cache_hits();
            report(&state, "segment_proxy", start, StatusCode::OK);
            return cached_segment_response(&entry, &requested_name);
        }
        state.metrics.increment_cache_misses();
    }

    let body = match fetch_upstream_bytes(&state, &target_url, range.as_deref()).await {
        Ok(b) => b,
        Err((status, msg)) => {
            state.metrics.increment_errors_total("segment_proxy", "upstream_segment");
            return error_response(status, msg);
        }
    };

    if !partial && body.status == StatusCode::OK && !body.bytes.is_empty() {
        let entry = CachedSegment {
            data: body.bytes.clone(),
            content_type: body.content_type.clone().unwrap_or_default(),
        };
        state.segment_cache.insert(cache_key, entry);
    }

    report(&state, "segment_proxy", start, body.status);
    segment_response(body, &requested_name)
}

/// Point d'entrée des URLs réécrites `/hls/<hash>/<fichier>` : manifest HLS/DASH
/// (réécriture) ou segment (cache + relais).
pub async fn hls_entrypoint(
    State(state): State<crate::AppState>,
    Path((hash, file)): Path<(String, String)>,
    headers: HeaderMap,
) -> Response {
    let start = Instant::now();
    state.metrics.increment_requests_total("hls_entrypoint");

    let requested_name = file.rsplit('/').next().unwrap_or(&file).to_string();

    let registered = match state.url_registry.resolve(&hash) {
        Some(u) => u,
        None => {
            state.metrics.increment_errors_total("hls_entrypoint", "unknown_hash");
            return error_response(
                StatusCode::NOT_FOUND,
                format!("Unknown entrypoint '{}' (cache purgé ?)", hash),
            );
        }
    };

    let upstream_url = match resolve_upstream_url(&registered, &requested_name) {
        Ok(u) => u,
        Err(e) => {
            state.metrics.increment_errors_total("hls_entrypoint", "unresolvable");
            return error_response(StatusCode::BAD_REQUEST, e);
        }
    };

    let lower = requested_name.to_ascii_lowercase();
    let is_hls_manifest = lower.ends_with(".m3u8") || lower.ends_with(".m3u");
    let is_dash_manifest = lower.ends_with(".mpd") || lower.ends_with(".xml");

    if is_hls_manifest || is_dash_manifest {
        // --- Manifest : fetch + réécriture -----------------------------------
        let body = match fetch_upstream_bytes(&state, &upstream_url, None).await {
            Ok(b) => b,
            Err((status, msg)) => {
                state.metrics.increment_errors_total("hls_entrypoint", "upstream_manifest");
                return error_response(status, msg);
            }
        };

        let content = match String::from_utf8(body.bytes.to_vec()) {
            Ok(c) => c,
            Err(e) => {
                state.metrics.increment_errors_total("hls_entrypoint", "non_utf8_manifest");
                return error_response(StatusCode::BAD_GATEWAY, format!("Manifest is not UTF-8: {}", e));
            }
        };

        let base_url = HlsRewriter::extract_base_url(&content, &upstream_url)
            .unwrap_or_else(|_| upstream_url.clone());
        let mode = body.mode.clone();

        let (rewritten, content_type, is_master) = if is_hls_manifest {
            let master = HlsRewriter::is_master_playlist(&content);
            match state.hls_rewriter.rewrite(&content, &base_url, master, &state.url_registry) {
                Ok(r) => (r, "application/vnd.apple.mpegurl".to_string(), Some(master)),
                Err(e) => {
                    state.metrics.increment_hls_rewrite_errors_total();
                    return error_response(StatusCode::INTERNAL_SERVER_ERROR, format!("HLS rewrite error: {}", e));
                }
            }
        } else {
            match state.dash_rewriter.rewrite(&content, &base_url, &state.url_registry) {
                Ok(r) => (r, "application/dash+xml".to_string(), None),
                Err(e) => {
                    state.metrics.increment_hls_rewrite_errors_total();
                    return error_response(StatusCode::INTERNAL_SERVER_ERROR, format!("DASH rewrite error: {}", e));
                }
            }
        };
        state.metrics.increment_hls_rewrites_total();

        let mut builder = Response::builder()
            .status(StatusCode::OK)
            .header("content-type", content_type)
            .header("cache-control", "no-cache, no-store, must-revalidate")
            .header("x-proxy-upstream-url", upstream_url)
            .header("x-proxy-rewritten", "true")
            .header("x-proxy-upstream-mode", mode);
        if let Some(master) = is_master {
            builder = builder.header("x-proxy-is-master", master.to_string());
        }

        report(&state, "hls_entrypoint", start, StatusCode::OK);
        return finish_response(builder, Body::from(rewritten));
    }

    // --- Segment : cache LRU puis relais ------------------------------------
    let range = headers.get("range").and_then(|v| v.to_str().ok()).map(|s| s.to_string());
    let partial = matches!(range.as_deref(), Some(r) if r != "bytes=0-");

    let cache_key = upstream_url.clone();
    if !partial {
        if let Some(entry) = state.segment_cache.get(&cache_key) {
            state.metrics.increment_cache_hits();
            report(&state, "hls_entrypoint", start, StatusCode::OK);
            return cached_segment_response(&entry, &requested_name);
        }
        state.metrics.increment_cache_misses();
    }

    let body = match fetch_upstream_bytes(&state, &upstream_url, range.as_deref()).await {
        Ok(b) => b,
        Err((status, msg)) => {
            state.metrics.increment_errors_total("hls_entrypoint", "upstream_segment");
            return error_response(status, msg);
        }
    };

    if !partial && body.status == StatusCode::OK && !body.bytes.is_empty() {
        let entry = CachedSegment {
            data: body.bytes.clone(),
            content_type: body.content_type.clone().unwrap_or_default(),
        };
        state.segment_cache.insert(cache_key, entry);
    }

    report(&state, "hls_entrypoint", start, body.status);
    segment_response(body, &requested_name)
}

/// Purge du cache segments + registre d'URL. Loggue le hit ratio avant vidage.
pub async fn purge_cache(State(state): State<crate::AppState>) -> Response {
    state.metrics.increment_requests_total("purge_cache");

    let cleared = state.segment_cache.clear();
    let registry_entries_cleared = state.url_registry.clear();

    info!(
        "Cache purgé : {} entrées, {} octets libérés, hit ratio {:.2}% ({} hits / {} misses)",
        cleared.cleared_entries,
        cleared.freed_bytes,
        cleared.hit_ratio * 100.0,
        cleared.hits_before_clear,
        cleared.misses_before_clear,
    );

    let response = PurgeResponse {
        success: true,
        cleared_entries: cleared.cleared_entries,
        freed_bytes: cleared.freed_bytes,
        hit_ratio: cleared.hit_ratio,
        hits_before_clear: cleared.hits_before_clear,
        misses_before_clear: cleared.misses_before_clear,
        registry_entries_cleared,
    };

    (StatusCode::OK, Json(response)).into_response()
}

pub async fn configure_proxy(
    State(state): State<crate::AppState>,
    axum::Json(payload): axum::Json<ConfigureRequest>,
) -> Response {
    state.metrics.increment_requests_total("configure_proxy");

    info!("Runtime config update requested: {:?}", payload);

    let mut current_config = (*state.config).clone();
    let mut changed = false;

    if let Some(port) = payload.port {
        current_config.port = port;
        changed = true;
    }
    if let Some(timeout) = payload.request_timeout_secs {
        current_config.request_timeout_secs = timeout;
        changed = true;
    }
    if let Some(timeout) = payload.connect_timeout_secs {
        current_config.connect_timeout_secs = timeout;
        changed = true;
    }
    if let Some(timeout) = payload.read_timeout_secs {
        current_config.read_timeout_secs = timeout;
        changed = true;
    }
    if let Some(base) = payload.hls_rewrite_base {
        current_config.hls_rewrite_base = base;
        state.hls_rewriter = Arc::new(HlsRewriter::new(current_config.hls_rewrite_base.clone()));
        state.dash_rewriter = Arc::new(DashRewriter::new(current_config.hls_rewrite_base.clone()));
        changed = true;
    }
    if let Some(redirects) = payload.max_redirects {
        current_config.max_redirects = redirects;
        changed = true;
    }
    if let Some(ua) = payload.user_agent {
        current_config.user_agent = ua;
        changed = true;
    }
    if let Some(level) = payload.log_level {
        current_config.log_level = level;
        changed = true;
    }
    if let Some(metrics) = payload.enable_metrics {
        current_config.enable_metrics = metrics;
        changed = true;
    }
    if let Some(interval) = payload.health_check_interval_secs {
        current_config.health_check_interval_secs = interval;
        changed = true;
    }

    let response = if changed {
        ConfigureResponse {
            success: true,
            message: "Configuration updated successfully (restart required for port changes)".to_string(),
            config: Some(current_config),
        }
    } else {
        ConfigureResponse {
            success: true,
            message: "No changes provided".to_string(),
            config: None,
        }
    };

    (StatusCode::OK, axum::Json(response)).into_response()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_configure_request_deserialize() {
        let json = r#"{"port": 9090, "request_timeout_secs": 60}"#;
        let req: ConfigureRequest = serde_json::from_str(json).unwrap();
        assert_eq!(req.port, Some(9090));
        assert_eq!(req.request_timeout_secs, Some(60));
        assert_eq!(req.hls_rewrite_base, None);
    }

    #[test]
    fn test_stream_proxy_query() {
        let query = StreamProxyQuery {
            url: "https://example.com/video.mp4".to_string(),
            headers: Some(r#"{"range": "bytes=0-1023"}"#.to_string()),
        };
        assert_eq!(query.url, "https://example.com/video.mp4");
        assert!(query.headers.is_some());
    }

    #[test]
    fn test_segment_proxy_query() {
        let query = SegmentProxyQuery {
            url: "https://example.com/segment.ts".to_string(),
        };
        assert_eq!(query.url, "https://example.com/segment.ts");
    }

    #[test]
    fn test_resolve_upstream_url_identical() {
        let resolved = resolve_upstream_url(
            "https://cdn.example.com/video/segment1.ts",
            "segment1.ts",
        )
        .unwrap();
        assert_eq!(resolved, "https://cdn.example.com/video/segment1.ts");
    }

    #[test]
    fn test_resolve_upstream_url_dash_placeholder() {
        let resolved = resolve_upstream_url(
            "https://cdn.example.com/video/seg_$Number$.m4s",
            "seg_42.m4s",
        )
        .unwrap();
        assert_eq!(resolved, "https://cdn.example.com/video/seg_42.m4s");
    }

    #[test]
    fn test_guess_content_type() {
        assert_eq!(guess_content_type("seg.ts"), "video/mp2t");
        assert_eq!(guess_content_type("init.mp4"), "video/mp4");
        assert_eq!(guess_content_type("subs.vtt"), "text/vtt");
    }
}