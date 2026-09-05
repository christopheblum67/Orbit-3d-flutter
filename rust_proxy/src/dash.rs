//! Réécriture minimale de manifests DASH (MPD).
//!
//! Gère `<BaseURL>`, `media=`, `initialization=` et `sourceURL=` : toutes les
//! URLs de medias deviennent des URLs de proxy `/hls/<hash>/<fichier>`.
//! Les placeholders DASH (`$Number$`, `$Time$`, `$RepresentationID$`, ...) sont
//! conservés : le player les substitue dans l'URL proxy, le proxy les traduit
//! en retour (voir `resolve_upstream_url`).

use anyhow::{Context, Result};
use url::Url;

use crate::hls::{UrlRegistry, build_proxy_url};

#[derive(Clone)]
pub struct DashRewriter {
    proxy_base: String,
}

impl DashRewriter {
    pub fn new(proxy_base: String) -> Self {
        Self { proxy_base }
    }

    /// Détection heuristique d'un manifest MPD.
    pub fn looks_like_mpd(content: &str) -> bool {
        content.contains("<MPD")
            || (content.trim_start().starts_with("<?xml") && content.contains("BaseURL"))
    }

    /// Réécrit toutes les URLs de medias du MPD pour passer par le proxy.
    ///
    /// La base « effective » est chaînée : chaque `<BaseURL>` rencontré devient
    /// la base de résolution des attributs suivants (cas courant des MPD à une
    /// base globale + templates relatifs).
    pub fn rewrite(&self, content: &str, base_url: &str, registry: &UrlRegistry) -> Result<String> {
        let base = Url::parse(base_url).context("Invalid DASH base URL")?;
        let mut effective_base = base.clone();
        let mut out = String::with_capacity(content.len() + 256);
        let mut rest = content;

        loop {
            if rest.is_empty() {
                break;
            }

            let base_pos = rest.find("<BaseURL");
            let media_pos = find_attr(rest, "media");
            let init_pos = find_attr(rest, "initialization");
            let src_pos = find_attr(rest, "sourceURL");

            if base_pos.is_none() && media_pos.is_none() && init_pos.is_none() && src_pos.is_none() {
                out.push_str(rest);
                break;
            }

            let i = [base_pos, media_pos, init_pos, src_pos]
                .into_iter()
                .filter_map(|p| p)
                .min()
                .unwrap();

            out.push_str(&rest[..i]);
            rest = &rest[i..];

            if base_pos == Some(i) {
                self.consume_base_url(&mut rest, &mut out, &mut effective_base, registry);
            } else if media_pos == Some(i) {
                self.consume_attr(&mut rest, "media", &mut out, &effective_base, registry);
            } else if init_pos == Some(i) {
                self.consume_attr(&mut rest, "initialization", &mut out, &effective_base, registry);
            } else if src_pos == Some(i) {
                self.consume_attr(&mut rest, "sourceURL", &mut out, &effective_base, registry);
            }
        }

        Ok(out)
    }

    /// Consomme un élément `<BaseURL>...</BaseURL>` (ou auto-fermant).
    fn consume_base_url(
        &self,
        rest: &mut &str,
        out: &mut String,
        effective_base: &mut Url,
        registry: &UrlRegistry,
    ) {
        let s = *rest;
        let marker = "<BaseURL";
        let after_open = &s[marker.len()..];

        let Some(gt) = after_open.find('>') else {
            // Tag mal formé : on laisse tel quel.
            out.push_str(s);
            *rest = "";
            return;
        };

        let open_tag = &after_open[..=gt];
        if open_tag.ends_with("/>") {
            // Auto-fermant : pas de contenu à réécrire.
            let consumed = marker.len() + gt + 1;
            out.push_str(&s[..consumed]);
            *rest = &s[consumed..];
            return;
        }

        let close_marker = "</BaseURL>";
        let inner_start = gt + 1;
        let Some(rel_close) = after_open[inner_start..].find(close_marker) else {
            out.push_str(s);
            *rest = "";
            return;
        };

        let inner = &after_open[inner_start..inner_start + rel_close];
        let consumed = marker.len() + inner_start + rel_close + close_marker.len();

        let trimmed = inner.trim();
        if trimmed.is_empty() {
            out.push_str(&s[..consumed]);
            *rest = &s[consumed..];
            return;
        }

        match effective_base.join(trimmed) {
            Ok(next_base) => {
                let proxy = build_proxy_url(&self.proxy_base, next_base.as_str(), registry);
                out.push_str("<BaseURL>");
                out.push_str(&proxy);
                out.push_str("</BaseURL>");
                *effective_base = next_base;
            }
            Err(_) => {
                // URL irrésoluble : on garde le texte original pour ne pas casser le MPD.
                out.push_str(&s[..consumed]);
            }
        }
        *rest = &s[consumed..];
    }

    /// Consomme un attribut `attr="valeur"` (espacements autorisés) et réécrit la valeur.
    fn consume_attr(
        &self,
        rest: &mut &str,
        attr: &str,
        out: &mut String,
        effective_base: &Url,
        registry: &UrlRegistry,
    ) {
        let s = *rest;

        let mut i = attr.len();
        while i < s.len() && s.as_bytes()[i].is_ascii_whitespace() {
            i += 1;
        }
        if i >= s.len() || s.as_bytes()[i] != b'=' {
            // Pas un attribut valide (equal manquant) : on recopie le nom seul.
            out.push_str(&s[..attr.len()]);
            *rest = &s[attr.len()..];
            return;
        }
        i += 1;
        while i < s.len() && s.as_bytes()[i].is_ascii_whitespace() {
            i += 1;
        }
        if i >= s.len() || (s.as_bytes()[i] != b'"' && s.as_bytes()[i] != b'\'') {
            out.push_str(&s[..attr.len()]);
            *rest = &s[attr.len()..];
            return;
        }

        let quote = s.as_bytes()[i];
        i += 1;
        let value_start = i;
        while i < s.len() && s.as_bytes()[i] != quote {
            i += 1;
        }
        if i >= s.len() {
            // Guillemet fermant absent : valeur mal formée, on laisse tel quel.
            out.push_str(&s[..attr.len()]);
            *rest = &s[attr.len()..];
            return;
        }

        let value = &s[value_start..i];
        let consumed = i + 1;

        let trimmed = value.trim();
        if trimmed.is_empty() {
            // Valeur vide : on conserve l'attribut original.
            out.push_str(&s[..consumed]);
            *rest = &s[consumed..];
            return;
        }

        match effective_base.join(trimmed) {
            Ok(abs) => {
                let proxy = build_proxy_url(&self.proxy_base, abs.as_str(), registry);
                out.push_str(attr);
                out.push_str("=\"");
                out.push_str(&proxy);
                out.push_str("\"");
            }
            Err(_) => {
                out.push_str(&s[..consumed]);
            }
        }
        *rest = &s[consumed..];
    }
}

/// Cherche `attr` suivi d'espaces puis d'un '=' (positions d'attribut XML).
fn find_attr(rest: &str, attr: &str) -> Option<usize> {
    let mut search_from = 0usize;
    while let Some(i) = rest[search_from..].find(attr) {
        let abs = search_from + i;
        let before_ok = match rest[..abs].chars().next_back() {
            None => true,
            Some(c) => !(c.is_alphanumeric() || c == '_' || c == '-'),
        };
        let after = &rest[abs + attr.len()..];
        let after_ok = after.chars().next().map_or(true, |c| c.is_whitespace() || c == '=');
        if before_ok && after_ok {
            return Some(abs);
        }
        search_from = abs + attr.len();
    }
    None
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::hls::UrlRegistry;

    #[test]
    fn test_rewrite_base_url_and_templates() {
        let registry = UrlRegistry::new();
        let rewriter = DashRewriter::new("http://127.0.0.1:8080".to_string());
        let mpd = r#"<?xml version="1.0"?>
<MPD>
 <BaseURL>https://cdn.example.com/video/</BaseURL>
 <Period>
  <AdaptationSet>
   <SegmentTemplate media="seg_$Number$.m4s" initialization="init.mp4"/>
  </AdaptationSet>
 </Period>
</MPD>"#;

        let out = rewriter.rewrite(mpd, "https://cdn.example.com/video/", &registry).unwrap();
        assert!(out.starts_with("<?xml"));
        assert!(out.contains("/hls/"));
        assert!(out.contains("seg_$Number$.m4s"));
        assert!(out.contains("init.mp4"));
        assert!(registry.len() >= 3);
    }

    #[test]
    fn test_rewrite_absolute_media_with_spaces() {
        let registry = UrlRegistry::new();
        let rewriter = DashRewriter::new("http://127.0.0.1:8080".to_string());
        let mpd = r#"<MPD><SegmentTemplate media = "https://cdn.example.com/s/1.m4s" /></MPD>"#;

        let out = rewriter.rewrite(mpd, "https://cdn.example.com/", &registry).unwrap();
        assert!(out.contains("/hls/"));
        assert!(out.contains("1.m4s"));
    }

    #[test]
    fn test_looks_like_mpd() {
        assert!(DashRewriter::looks_like_mpd("<?xml version=\"1.0\"?><MPD><BaseURL>x</BaseURL></MPD>"));
        assert!(!DashRewriter::looks_like_mpd("#EXTM3U\n#EXTINF:1,\na.ts"));
    }
}