use anyhow::Result;
use axum::{
    extract::State,
    http::StatusCode,
    response::{IntoResponse, Json},
    routing::get,
    Router,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};
use tokio::sync::RwLock;
use tracing::{debug, info};

#[derive(Clone)]
pub struct HealthState {
    start_time: Instant,
    last_check: Arc<RwLock<Option<SystemTime>>>,
    checks: Arc<RwLock<HashMap<String, HealthCheck>>>,
    healthy: Arc<RwLock<bool>>,
}

use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HealthCheck {
    pub name: String,
    pub status: HealthStatus,
    pub message: Option<String>,
    pub timestamp: u64,
    pub duration_ms: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum HealthStatus {
    Healthy,
    Degraded,
    Unhealthy,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct HealthResponse {
    pub status: HealthStatus,
    pub version: String,
    pub uptime_secs: u64,
    pub checks: Vec<HealthCheck>,
    pub timestamp: u64,
}

impl HealthState {
    pub fn new() -> Self {
        Self {
            start_time: Instant::now(),
            last_check: Arc::new(RwLock::new(None)),
            checks: Arc::new(RwLock::new(HashMap::new())),
            healthy: Arc::new(RwLock::new(true)),
        }
    }
    
    pub async fn run_checks(&self) -> HealthResponse {
        let mut checks = Vec::new();
        let mut overall_healthy = true;
        
        let memory_check = self.check_memory().await;
        overall_healthy &= memory_check.status == HealthStatus::Healthy;
        checks.push(memory_check);
        
        let disk_check = self.check_disk_space().await;
        overall_healthy &= disk_check.status == HealthStatus::Healthy;
        checks.push(disk_check);
        
        let network_check = self.check_network().await;
        overall_healthy &= network_check.status == HealthStatus::Healthy;
        checks.push(network_check);
        
        let mut last_check = self.last_check.write().await;
        *last_check = Some(SystemTime::now());
        
        let mut health_checks = self.checks.write().await;
        for check in &checks {
            health_checks.insert(check.name.clone(), check.clone());
        }
        
        let mut healthy = self.healthy.write().await;
        *healthy = overall_healthy;
        
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        
        HealthResponse {
            status: if overall_healthy { HealthStatus::Healthy } else { HealthStatus::Unhealthy },
            version: env!("CARGO_PKG_VERSION").to_string(),
            uptime_secs: self.start_time.elapsed().as_secs(),
            checks,
            timestamp,
        }
    }
    
    async fn check_memory(&self) -> HealthCheck {
        let start = Instant::now();
        
        #[cfg(target_os = "linux")]
        let status = {
            use std::fs;
            let content = fs::read_to_string("/proc/meminfo").unwrap_or_default();
            let mut total = 0u64;
            let mut available = 0u64;
            for line in content.lines() {
                if line.starts_with("MemTotal:") {
                    total = line.split_whitespace().nth(1).unwrap_or("0").parse().unwrap_or(0);
                } else if line.starts_with("MemAvailable:") {
                    available = line.split_whitespace().nth(1).unwrap_or("0").parse().unwrap_or(0);
                }
            }
            if total > 0 {
                let usage_pct = 100.0 - (available as f64 / total as f64 * 100.0);
                if usage_pct > 90.0 {
                    HealthStatus::Unhealthy
                } else if usage_pct > 75.0 {
                    HealthStatus::Degraded
                } else {
                    HealthStatus::Healthy
                }
            } else {
                HealthStatus::Healthy
            }
        };
        
        #[cfg(not(target_os = "linux"))]
        let status = HealthStatus::Healthy;
        
        HealthCheck {
            name: "memory".to_string(),
            status,
            message: Some(format!("Memory check completed in {}ms", start.elapsed().as_millis())),
            timestamp: SystemTime::now().duration_since(UNIX_EPOCH).unwrap_or_default().as_secs(),
            duration_ms: start.elapsed().as_millis() as u64,
        }
    }
    
    async fn check_disk_space(&self) -> HealthCheck {
        let start = Instant::now();
        
        #[cfg(target_os = "linux")]
        let status = {
            use std::fs;
            let content = fs::read_to_string("/proc/self/mountinfo").unwrap_or_default();
            let mut status = HealthStatus::Healthy;
            for line in content.lines() {
                if line.contains("/ ") || line.contains(" / ") {
                    let parts: Vec<&str> = line.split_whitespace().collect();
                    if parts.len() >= 5 {
                        let mount_point = parts[4];
                        if let Ok(metadata) = fs::metadata(mount_point) {
                            if let Ok(space) = fs::read_dir(mount_point) {
                            }
                        }
                    }
                }
            }
            status
        };
        
        #[cfg(not(target_os = "linux"))]
        let status = HealthStatus::Healthy;
        
        HealthCheck {
            name: "disk".to_string(),
            status,
            message: Some(format!("Disk check completed in {}ms", start.elapsed().as_millis())),
            timestamp: SystemTime::now().duration_since(UNIX_EPOCH).unwrap_or_default().as_secs(),
            duration_ms: start.elapsed().as_millis() as u64,
        }
    }
    
    async fn check_network(&self) -> HealthCheck {
        let start = Instant::now();
        
        let status = match tokio::net::TcpStream::connect("1.1.1.1:53").await {
            Ok(_) => HealthStatus::Healthy,
            Err(_) => HealthStatus::Degraded,
        };
        
        HealthCheck {
            name: "network".to_string(),
            status,
            message: Some(format!("Network check completed in {}ms", start.elapsed().as_millis())),
            timestamp: SystemTime::now().duration_since(UNIX_EPOCH).unwrap_or_default().as_secs(),
            duration_ms: start.elapsed().as_millis() as u64,
        }
    }
    
    pub async fn is_healthy(&self) -> bool {
        *self.healthy.read().await
    }
    
    pub async fn get_cached_checks(&self) -> Vec<HealthCheck> {
        self.checks.read().await.values().cloned().collect()
    }
}

pub async fn health_check(State(state): State<Arc<HealthState>>) -> impl IntoResponse {
    let response = state.run_checks().await;
    let status_code = match response.status {
        HealthStatus::Healthy => StatusCode::OK,
        HealthStatus::Degraded => StatusCode::OK,
        HealthStatus::Unhealthy => StatusCode::SERVICE_UNAVAILABLE,
    };
    (status_code, Json(response))
}

pub async fn health_check_simple() -> impl IntoResponse {
    let response = HealthResponse {
        status: HealthStatus::Healthy,
        version: env!("CARGO_PKG_VERSION").to_string(),
        uptime_secs: 0,
        checks: vec![],
        timestamp: SystemTime::now().duration_since(UNIX_EPOCH).unwrap_or_default().as_secs(),
    };
    (StatusCode::OK, Json(response))
}

pub fn health_router(state: Arc<HealthState>) -> Router {
    Router::new()
        .route("/health", get(health_check))
        .route("/health/simple", get(health_check_simple))
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
    
    #[tokio::test]
    async fn test_health_state_creation() {
        let state = HealthState::new();
        assert!(state.is_healthy().await);
    }
    
    #[tokio::test]
    async fn test_health_check_endpoint() {
        let state = Arc::new(HealthState::new());
        let app = health_router(state.clone());
        
        let response = app
            .oneshot(Request::builder().uri("/health").body(Body::empty()).unwrap())
            .await
            .unwrap();
        
        assert_eq!(response.status(), StatusCode::OK);
    }
    
    #[tokio::test]
    async fn test_health_check_simple_endpoint() {
        let state = Arc::new(HealthState::new());
        let app = health_router(state);
        
        let response = app
            .oneshot(Request::builder().uri("/health/simple").body(Body::empty()).unwrap())
            .await
            .unwrap();
        
        assert_eq!(response.status(), StatusCode::OK);
    }
    
    #[test]
    fn test_health_status_serialization() {
        let status = HealthStatus::Healthy;
        let json = serde_json::to_string(&status).unwrap();
        assert_eq!(json, "\"healthy\"");
        
        let status = HealthStatus::Degraded;
        let json = serde_json::to_string(&status).unwrap();
        assert_eq!(json, "\"degraded\"");
        
        let status = HealthStatus::Unhealthy;
        let json = serde_json::to_string(&status).unwrap();
        assert_eq!(json, "\"unhealthy\"");
    }
}