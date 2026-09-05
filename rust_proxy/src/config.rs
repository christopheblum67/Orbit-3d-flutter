use anyhow::{Context, Result};
use config::{Config, File, FileFormat};
use serde::{Deserialize, Serialize};
use std::net::SocketAddr;
use std::path::PathBuf;
use std::time::Duration;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProxyConfig {
    pub port: u16,
    /// Adresse d'écoute complète (`host:port`) : déportée sur 127.0.0.1:8787
    /// (au lieu de 8080) pour éviter les conflits de ports avec les autres
    /// services locaux. Le champ `port` reste la source de vérité pour le
    /// JSON `/api/proxy-status` et l'URL de réécriture HLS.
    #[serde(default = "default_listen_addr")]
    pub listen_addr: String,
    pub request_timeout_secs: u64,
    pub connect_timeout_secs: u64,
    pub read_timeout_secs: u64,
    pub hls_rewrite_base: String,
    pub max_redirects: usize,
    pub user_agent: String,
    pub log_level: String,
    pub enable_metrics: bool,
    pub health_check_interval_secs: u64,
    #[serde(default = "default_cache_max_bytes")]
    pub cache_max_bytes: usize,
    #[serde(default = "default_fallback_browser")]
    pub fallback_browser: String,
}

/// Quota par défaut du cache segments : 256 Mo.
fn default_cache_max_bytes() -> usize {
    256 * 1024 * 1024
}

/// Empreinte TLS de secours (utilisée si le WAF répond 403/406 avec Chrome 120).
fn default_fallback_browser() -> String {
    "chrome-131".to_string()
}

/// Adresse d'écoute par défaut : 8787 (hors de la zone 8080/3000 des devs).
fn default_listen_addr() -> String {
    "127.0.0.1:8787".to_string()
}

impl Default for ProxyConfig {
    fn default() -> Self {
        Self {
            port: 8787,
            listen_addr: default_listen_addr(),
            request_timeout_secs: 30,
            connect_timeout_secs: 10,
            read_timeout_secs: 30,
            // Base « origine » du proxy local : les URLs réécrites pointent vers /hls/<hash>/<fichier>.
            hls_rewrite_base: "http://127.0.0.1:8787".to_string(),
            max_redirects: 10,
            user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36".to_string(),
            log_level: "info".to_string(),
            enable_metrics: true,
            health_check_interval_secs: 30,
            cache_max_bytes: default_cache_max_bytes(),
            fallback_browser: default_fallback_browser(),
        }
    }
}

impl ProxyConfig {
    pub fn load() -> Result<Self> {
        let config_path = Self::config_path()?;
        
        let mut builder = Config::builder();
        
        if config_path.exists() {
            builder = builder.add_source(File::from(config_path.clone()).format(FileFormat::Toml));
            log::info!("Loading config from {:?}", config_path);
        } else {
            log::warn!("Config file not found at {:?}, using defaults", config_path);
        }
        
        builder = builder.add_source(config::Environment::with_prefix("ORBIT_PROXY"));
        
        let config: ProxyConfig = builder
            .build()
            .context("Failed to build config")?
            .try_deserialize()
            .context("Failed to deserialize config")?;
        
        Ok(config)
    }
    
    fn config_path() -> Result<PathBuf> {
        if let Ok(path) = std::env::var("ORBIT_PROXY_CONFIG") {
            return Ok(PathBuf::from(path));
        }
        
        let mut path = dirs::config_dir()
            .context("Could not find config directory")?;
        path.push("orbit_rust_proxy");
        path.push("config.toml");
        Ok(path)
    }
    
    pub fn request_timeout(&self) -> Duration {
        Duration::from_secs(self.request_timeout_secs)
    }
    
    pub fn connect_timeout(&self) -> Duration {
        Duration::from_secs(self.connect_timeout_secs)
    }
    
    pub fn read_timeout(&self) -> Duration {
        Duration::from_secs(self.read_timeout_secs)
    }
    
    pub fn health_check_interval(&self) -> Duration {
        Duration::from_secs(self.health_check_interval_secs)
    }

    /// Adresse de bind : `listen_addr` (ex: "127.0.0.1:8787") prime ; on retombe
    /// sur `127.0.0.1:{port}` pour les anciens fichiers de config sans le champ.
    /// Si `listen_addr` ne porte pas de port, le port de `port` est substitué.
    pub fn bind_addr(&self) -> SocketAddr {
        let parsed: SocketAddr = match self.listen_addr.trim().parse() {
            Ok(addr) => addr,
            Err(_) => SocketAddr::from(([127, 0, 0, 1], self.port)),
        };
        if parsed.port() == 0 {
            SocketAddr::from((parsed.ip(), self.port))
        } else {
            parsed
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;
    use tempfile::NamedTempFile;
    
    #[test]
    fn test_default_config() {
        let config = ProxyConfig::default();
        assert_eq!(config.port, 8787);
        assert_eq!(config.request_timeout_secs, 30);
        assert_eq!(config.listen_addr, "127.0.0.1:8787");
        assert_eq!(config.bind_addr().to_string(), "127.0.0.1:8787");
    }

    #[test]
    fn test_config_from_toml() {
        let toml_content = r#"
            port = 9090
            request_timeout_secs = 60
            hls_rewrite_base = "http://localhost:9090/proxy"
        "#;
        
        let mut file = NamedTempFile::new().unwrap();
        file.write_all(toml_content.as_bytes()).unwrap();
        
        let mut builder = Config::builder();
        builder = builder.add_source(File::from(file.path()).format(FileFormat::Toml));
        
        let config: ProxyConfig = builder.build().unwrap().try_deserialize().unwrap();
        assert_eq!(config.port, 9090);
        assert_eq!(config.request_timeout_secs, 60);
        assert_eq!(config.hls_rewrite_base, "http://localhost:9090/proxy");
        // Le champ listen_addr absent du TOML retombe sur la valeur par défaut.
        assert_eq!(config.listen_addr, "127.0.0.1:8787");
    }

    #[test]
    fn test_bind_addr_falls_back_to_port_when_invalid() {
        let mut config = ProxyConfig::default();
        config.listen_addr = "not-an-addr".to_string();
        assert_eq!(config.bind_addr().to_string(), "127.0.0.1:8787");

        config.listen_addr = "0.0.0.0:0".to_string();
        assert_eq!(config.bind_addr().to_string(), "0.0.0.0:8787");
    }
}