//! Test de FALSIFICATION — vérifie l'hypothèse centrale du proxy.
//!
//! Hypothèse à tester : « le 406 draap.online vient du fingerprint TLS (JA3/JA4)
//! bloqué par le WAF, donc une empreinte Chrome réelle via reqwest-impersonate
//! suffit à obtenir 200. »
//!
//! Ce binaire ne dépend d'AUCUN code du proxy : il isole uniquement l'empreinte
//! TLS. S'il retourne encore 406/403 → l'hypothèse est FAUSSE (le blocage ne vient
//! pas du TLS) et tout le projet proxy devient inutile → pivoter.
//!
//! Usage (machine AVEC Cargo/rustc, ex: chez le superviseur) :
//!   cargo run --example smoke -- "http://draap.online:25461/live/USER/PASS/12345.ts"
//!   (utiliser la vraie URL d'un flux qui renvoie 406 depuis le réseau concerné)

use std::time::Duration;

const USER_AGENTS: &[(&str, &str)] = &[
    ("chrome-120", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"),
    ("chrome-131", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"),
];

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let url = std::env::args()
        .nth(1)
        .ok_or_else(|| anyhow::anyhow!("Usage: cargo run --example smoke -- \"<URL_FLUX>\""))?;

    println!("== SMOKE TEST TLS-impersonation contre: {}", url);
    println!("== Attention: la machine qui exécute ce test doit être sur le MÊME réseau/IP");
    println!("== que le téléphone (ou au moins un réseau qui subit le 406).\n");

    let mut any_success = false;
    for &(name, ua) in USER_AGENTS {
        let version = match name {
            "chrome-120" => reqwest_impersonate::browser::BrowserVersion::Chrome120,
            _ => reqwest_impersonate::browser::BrowserVersion::Chrome131,
        };
        let client = match reqwest_impersonate::Client::builder()
            .impersonate(version)
            .user_agent(ua)
            .timeout(Duration::from_secs(15))
            .build()
        {
            Ok(c) => c,
            Err(e) => {
                println!("[{}] ECHEC construction client: {}", name, e);
                continue;
            }
        };

        // GET avec l'empreinte Chrome réelle (JA3/JA4 complet, pas juste UA).
        match client.get(url.clone()).send().await {
            Ok(resp) => {
                let status = resp.status();
                let ct = resp
                    .headers()
                    .get(reqwest::header::CONTENT_TYPE)
                    .and_then(|v| v.to_str().ok())
                    .unwrap_or("?")
                    .to_string();
                let body = resp.text().await.unwrap_or_default();
                let preview: String = body.chars().take(120).collect();
                println!(
                    "[{}] STATUS = {} | content-type = {} | len = {} | début: {:?}",
                    name,
                    status,
                    ct,
                    body.len(),
                    preview
                );
                if status.is_success() {
                    any_success = true;
                }
            }
            Err(e) => println!("[{}] ERREUR HTTP: {}", name, e),
        }
    }

    println!("\n== VERDICT ==");
    if any_success {
        println!("HYPOTHESE CONFIRMEE : le TLS impersonation suffit (200). Le proxy a un sens.");
    } else {
        println!(
            "HYPOTHESE FALSIFIEE : toujours 403/406 même avec empreinte Chrome réelle.\n\
             => Le blocage n'est PAS (seulement) le fingerprint TLS. \n\
             Pistes à explorer avant d'investir davantage :\n\
              * Accept-Encoding / sec-fetch-* / Referer ou Origin attendus par l'origine\n\
              * cookie/Session (cf_clearance) requis AVANT le GET média\n\
              * règle sur le chemin (/live,/movie,/series) vs resources statiques\n\
              * sécurité \"routeur FTP/media\" côté panneau (hotlink/media protection)\n\
              * IP du serveur origine perdante (nécessite un relais distant, pas local)"
        );
    }
    Ok(())
}