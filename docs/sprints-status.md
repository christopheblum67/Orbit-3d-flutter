# Orbit IPTV — Suivi des projets (Sprints)

> Mis à jour à chaque sprint. Progression = travail réellement livré et vérifié.

## Légende
- 🔴 Bloqué | 🟡 En cours | 🟢 Done | ◻️ À faire
- **Durée estimée** = temps restant (heures dev, 1 ingénieur).

---

## 1. STREAM DRAAP — Lecture Live sur S20 (objectif prioritaire)
**Preuve (capture PCAP XCIPTV, 06/09)** : le flux est SAIN — XCIPTV lit `/live/{u}/{p}/{id}.ts` → 302 Cloudflare → CDN `79.143.17.130` → MPEG TS. Le blocage est côté ExoPlayer/notre stack, pas côté réseau.

| Élément | Statut | Détail |
|---|---|---|
| Crash `The source buffer is this buffer` | 🟢 | **Cause = notre `NightFocusAudioProcessor.queueInput`** (in-place media3). Corrigé : by-pass sans copie + boucle in-place. Son audible après fix. |
| Anti-leech panneau (~90 s / IP) | 🟡 | Panneau draap → 401/404 quand on martèle. Réduit : 1 variante nue max, UA `XCIPTV-v7.0-2000` tenté en premier, backoff 900 ms. |
| Vidéo confirmée S20 | 🔴 | **À valider** : le son passe, l'image n'a pas encore été confirmée de bout en bout. |
| media3 | 🟢 | Repointé 1.9.3 (1.12.0 inexistante au dépôt Google). |

**Progression : ~70% — Reste : validation vidéo S20 + si échec, test variantes/HLS ou fallback VLC.**

---

## 2. RUST PROXY — Contourner Cloudflare 406 (flux video)
**Objectif** : proxy local `reqwest-impersonate` (Chrome 120) + axum pour masquer l'empreinte TLS des flux `draap.online`.

| Sprint | Contenu | Statut | Reste |
|---|---|---|---|
| S1 | Squelette: config.rs, client_factory.rs, hls.rs, proxy.rs, health.rs, metrics.rs | 🟢 | — |
| S2 | HLS/DASH rewriter (URLs → proxy), cache LRU 256Mo, purge /cache, retry browser fallback | 🟢* | *unit test only — jamais exécuté |
| S3 | Bridge Flutter: RustProxyManager (ProcessManager + ping) + stream_relay (rebase via /proxy/hls?url=) | 🟢* | *unit test only — jamais exécuté |
| S4 | Fallback auto (proxy → direct), logs/diagnostics UI, binaire Android | ◻️ | 3h |
| ⚠️ | **HYPOTHÈSE À FALSIFIER** : `cargo run --example smoke -- "<URL>"` (machine avec Cargo). 200 = proxy validé ; 403/406 = hypothèse TLS fausse → pivoter | 🔴 | 0.2h |

**Progression réelle : ~15% livré (65% écrit)** — **Reste : ~3h + preuve d'exécution.**

---

## 3. PROFIL & CONTRÔLE PARENTAL (PINS)
**Décision produit :** filtrage auto abandonné (PEGI non fiable). Profils Adulte/Enfant/Expert + PIN conservés.

| Sprint | Contenu | Statut |
|---|---|---|
| S1-S3 | UserProfile enrichi + sélection/édition + numpad PIN (3 essais) | 🟢 |
| S4 | Masquage 18+ reverté (ContenFilter dormant, toggles retirés) | 🟢 |

**Progression : ~80% (bloc profils).** Tests 71 → 89.

---

## 4. QUICK WINS (correctifs rapides Home)
| Sprint | Contenu | Statut | Reste |
|---|---|---|---|
| S1 | Haptic, raccourcis 1-9, auto-resume | 🟢 | — |
| S2 | Badge « Nouveau », High Contrast, Export/Import réglages | ◻️ | 3h |

**Progression : ~50% — Reste : ~3h**

---

## 5. UX — Navigation & expérience
| Chantier | Contenu | Statut | Reste |
|---|---|---|---|
| Back Handling | Spike `RouteMeta` + `WithBackHandling` (3 routes + test intégration) committé `894a377` | 🟢 | Audit complet restant : 2h |
| Buffering/hardware | Indicateur buffering + contrôles (replay10/play/ff30) dans _ReadyPlayer | 🟡 | 1h (test téléphone) |
| EPG Timeline | Frise horaire EPG continue | ◻️ | 4h |
| Nebula Search | Recherche "nébuleuse" fine + VoiceInput | ◻️ | 3h |

**Progression : ~45% — Reste : ~10h**

---

## 6. DETAIL — Fiche film style Allociné
| Chantier | Contenu | Statut | Reste |
|---|---|---|---|
| Cast/Crew | models + api fetchMovieCredits + CastGrid + CrewSection | 🟢 | — |
| Matchmaking Films | Section « Films » (genre enrichi via catégorie VOD) | 🟢 | — |
| Filtres genres | Filtres par genres favoris du profil dans matchmaking | ◻️ | 2h |

**Progression : ~70% — Reste : ~2h**

---

## 7. VERIFICATION / LIVRAISON
| Chantier | Contenu | Statut |
|---|---|---|
| Tests | 89/89 ✓ (15 fichiers) | 🟢 |
| Analyze | 0 erreur | 🟢 |
| Build debug / release | ✓ / 60,3 MB ✓ | 🟢 |
| S20 | Debug + release installés, logcat opérationnel | 🟢 |
| Dépôt git | Nettoyé : seuls les changements réels sont stageables (anti-bruit CRLF) | 🟢 |

**Progression : ~90%**

---

## ⚠️ Constats critiques (revue 06/09)
- **Réglages avancés factices** : `useCustomDNS`, `enableP2PHybrid`, `enableAiUpscaling`, `localAiSubtitles`, `sportsHighlightsDetection`, `autoFrameRate`, `smartFailover`, `directToLive` = affichés/persistés sans aucun effet métier (grep : zéro consommation). À implémenter ou retirer de l'UI.
- `livePlayer` (String) = doublon mort de `configFor()`.
- `vpn_service.dart` : `return null` → détection VPN probablement stub. Écran AI à vérifier (scoring local labellisé « IA » ?).

---

## Total backlog restant estimé : ~20h (1 ingénieur)
Priorité absolue : **valider la vidéo S20** (1re étape), puis assainir réglages factices avant toute nouvelle feature.