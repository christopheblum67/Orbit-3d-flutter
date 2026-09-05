# Orbit IPTV — Suivi des projets (Sprints)

> Mis à jour automatiquement à chaque sprint. Progression = travail réellement livré et vérifié.

## Légende
- 🔴 Bloqué | 🟡 En cours | 🟢 Done | ◻️ À faire
- **Durée estimée** = temps restant (heures dev, 1 ingénieur).

---

## 1. RUST PROXY — Contourner Cloudflare 406 (flux video)
**Objectif** : proxy local `reqwest-impersonate` (Chrome 120) + axum pour masquer l'empreinte TLS des flux `draap.online`.

| Sprint | Contenu | Statut | Reste |
|---|---|---|---|
| S1 | Squelette: config.rs, client_factory.rs, hls.rs, proxy.rs, health.rs, metrics.rs | 🟢 | — |
| S2 | HLS/DASH rewriter (URLs → proxy), cache LRU 256Mo, purge /cache, retry browser fallback | 🟢 | — |
| S3 | Bridge Flutter: RustProxyManager (ProcessManager + ping) + stream_relay (rebase via /proxy/hls?url=) + 21 tests | 🟢 | — |
| S4 | Fallback auto (proxy → direct), logs/diagnostics UI, binaire Android | ◻️ | 3h |
| ⚠️ | **HYPOTHÈSE À FALSIFIER** : `cargo run --example smoke -- "<URL>"` sur une machine avec Cargo (superviseur). 200 = proxy validé ; 403/406 = hypothèse TLS fausse → pivoter | 🔴 | 0.2h |

**Progression globale : ~65%** — **Durée restante estimée : ~3h** (hors pivot possible)

---

## 2. PROFIL & CONTRÔLE PARENTAL (PINS)
**Décision produit :** filtrage auto abandonné (PEGI non fiable/absent, surtout chaînes TV). Profils Adulte/Enfant/Expert + PIN conservés pour les réglages par âge (futur).

| Sprint | Contenu | Statut | Reste |
|---|---|---|---|
| S1 | UserProfile enrichi + ProfileTypeProvider (PIN, isChild, maxProfiles) | 🟢 | — |
| S2 | Écran Sélection de profil (cartes animées, d-pad, avatar orbital, route /profiles) | 🟢 | — |
| S3 | Création/édition (`profile_edit_screen`), numpad PIN (`pin_pad_screen`, 3 essais) | 🟢 | — |
| S4 | ~~Masquage 18+/violence~~ → **reverté** (aucun masquage appliqué), ContentFilter = utilitaire dormant, toggles retirés de l'UI | 🟢 | — |
| S5 | Réglages par âge (badges âge, recos, UI simplifiée enfant) — QUAND vous voudrez | ◻️ | 3-4h |

**Progression : ~80% (bloc profils) — filtrage : annulé.** Tests 71 → 88

---

## 3. QUICK WINS (correctifs rapides Home)
| Sprint | Contenu | Statut | Reste |
|---|---|---|---|
| S1 | Haptic, raccourcis 1-9, auto-resume | 🟢 | — |
| S2 | Badge « Nouveau », High Contrast, Export/Import réglages | ◻️ | 3h |

**Progression : ~50%** — **Durée restante : ~3h**

---

## 4. UX — Navigation & expérience
| Chantier | Contenu | Statut | Reste |
|---|---|---|---|
| Solar System | Navigation solaire 3D accueil | 🟢 | — |
| Bouton retour | Player OK (AppBar). Audit complet: chaque écran doit pouvoir revenir en arrière | 🟡 | 2h |
| Buffering/hardware | Indicateur buffering + contrôles (replay10/play/ff30) dans _ReadyPlayer | 🟡 | 1h (test téléphone) |
| EPG Timeline | Frise horaire EPG continue | ◻️ | 4h |
| Nebula Search | Recherche "nébuleuse" fine + VoiceInput | ◻️ | 3h |

**Progression : ~40%** — **Durée restante : ~10h**

---

## 5. DETAIL — Fiche film style Allociné
| Chantier | Contenu | Statut | Reste |
|---|---|---|---|
| Cast/Crew | models + api fetchMovieCredits + CastGrid + CrewSection | 🟢 | — |
| Corrige compile | parsers/files (erreurs syntaxe player/cast/crew) | 🟢 | — |
| Matchmaking Films | Section « Films » ne s'affiche pas (investigation données) | 🔴 | 2h |
| Filtres genres | Filtres par genres favoris du profil dans matchmaking | ◻️ | 2h |

**Progression : ~55%** — **Durée restante : ~4h**

---

## 6. VERIFICATION / LIVRAISON
| Chantier | Contenu | Statut | Reste |
|---|---|---|---|
| Tests | 50/50 ✓ | 🟢 | — |
| Analyze | 0 erreur (102 warnings) | 🟢 | — |
| Build release | 60.6 MB ✓ | 🟢 | — |
| Install S20 | APK pret — téléphone non branché | 🟡 | 0.1h |
| Commit/Push | État brut à nettoyer | ◻️ | 0.3h |

**Progression : ~80%** — **Durée restante : ~0.5h**

---

## Total backlog restant estimé : ~35h (1 ingénieur)
Répartissable sur 5 équipes = **~7h de travail parallèle** possible.