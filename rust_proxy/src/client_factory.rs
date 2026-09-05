use anyhow::{Context, Result};
use reqwest::cookie::Jar;
use reqwest::redirect::Policy;
use reqwest_impersonate::async_impl::client::Client as ImpersonatedClient;
use reqwest_impersonate::browser::BrowserVersion;
use std::sync::Arc;
use std::time::Duration;
use url::Url;

use crate::config::ProxyConfig;

pub struct ClientFactory {
    config: Arc<ProxyConfig>,
}

impl ClientFactory {
    pub fn new(config: Arc<ProxyConfig>) -> Self {
        Self { config }
    }
    
    /// Client impersonant Chrome 120 (empreinte principale).
    pub fn create_impersonated_client(&self) -> Result<Arc<ImpersonatedClient>> {
        self.create_impersonated_client_for(BrowserVersion::Chrome120)
    }
    
    /// Client impersonant une version de Chrome donnée.
    pub fn create_impersonated_client_for(&self, version: BrowserVersion) -> Result<Arc<ImpersonatedClient>> {
        let cookie_jar = Arc::new(Jar::default());
        
        let client = ImpersonatedClient::builder()
            .impersonate(version)
            .cookie_store(true)
            .cookie_provider(cookie_jar.clone())
            .redirect(Policy::limited(self.config.max_redirects))
            .timeout(self.config.request_timeout())
            .connect_timeout(self.config.connect_timeout())
            .read_timeout(self.config.read_timeout())
            .user_agent(&self.config.user_agent)
            .build()
            .context("Failed to build impersonated client")?;
        
        Ok(Arc::new(client))
    }
    
    /// Client de secours (ex: Chrome 131) utilisé quand le WAF renvoie 403/406.
    /// Retourne None si le nom configuré est inconnu ou si la construction échoue
    /// (dégradation non bloquante : on reste sur l'empreinte principale).
    pub fn create_fallback_impersonated_client(&self) -> Option<Arc<ImpersonatedClient>> {
        if self.config.fallback_browser.trim().is_empty() {
            return None;
        }
        let version = match browser_version_from_name(&self.config.fallback_browser) {
            Ok(v) => v,
            Err(e) => {
                log::warn!("Invalid fallback_browser '{}': {} — fallback désactivé", self.config.fallback_browser, e);
                return None;
            }
        };
        match self.create_impersonated_client_for(version) {
            Ok(c) => Some(c),
            Err(e) => {
                log::warn!("Failed to build fallback impersonated client: {:?} — fallback désactivé", e);
                None
            }
        }
    }
    
    pub fn create_reqwest_client(&self) -> Result<reqwest::Client> {
        let cookie_jar = Arc::new(Jar::default());
        
        let client = reqwest::Client::builder()
            .cookie_store(true)
            .cookie_provider(cookie_jar)
            .redirect(Policy::limited(self.config.max_redirects))
            .timeout(self.config.request_timeout())
            .connect_timeout(self.config.connect_timeout())
            .read_timeout(self.config.read_timeout())
            .user_agent(&self.config.user_agent)
            .gzip(true)
            .brotli(true)
            .deflate(true)
            .build()
            .context("Failed to build reqwest client")?;
        
        Ok(client)
    }
    
    pub fn create_client_for_url(&self, target_url: &str) -> Result<reqwest::Client> {
        let parsed = Url::parse(target_url).context("Invalid target URL")?;
        
        let mut builder = reqwest::Client::builder()
            .cookie_store(true)
            .redirect(Policy::limited(self.config.max_redirects))
            .timeout(self.config.request_timeout())
            .connect_timeout(self.config.connect_timeout())
            .read_timeout(self.config.read_timeout())
            .user_agent(&self.config.user_agent)
            .gzip(true)
            .brotli(true)
            .deflate(true);
        
        if parsed.scheme() == "https" {
            builder = builder.use_rustls_tls();
        }
        
        let client = builder.build().context("Failed to build client for URL")?;
        Ok(client)
    }
}

impl Default for ClientFactory {
    fn default() -> Self {
        Self::new(Arc::new(ProxyConfig::default()))
    }
}

/// Mappe un nom lisible ("chrome-131", "chrome120") vers le variant BrowserVersion.
pub fn browser_version_from_name(name: &str) -> Result<BrowserVersion, String> {
    match name.trim().to_ascii_lowercase().as_str() {
        "chrome-120" | "chrome120" | "chrome_120" | "120" => Ok(BrowserVersion::Chrome120),
        "chrome-131" | "chrome131" | "chrome_131" | "131" => Ok(BrowserVersion::Chrome131),
        other => Err(format!("unsupported browser version '{}'", other)),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::Arc;
    
    #[test]
    fn test_factory_creation() {
        let config = Arc::new(ProxyConfig::default());
        let factory = ClientFactory::new(config);
        assert!(factory.create_impersonated_client().is_ok());
    }
    
    #[test]
    fn test_reqwest_client_creation() {
        let config = Arc::new(ProxyConfig::default());
        let factory = ClientFactory::new(config);
        assert!(factory.create_reqwest_client().is_ok());
    }
    
    #[test]
    fn test_browser_version_from_name() {
        assert!(browser_version_from_name("chrome-120").is_ok());
        assert!(browser_version_from_name("chrome131").is_ok());
        assert!(browser_version_from_name("firefox").is_err());
    }
}