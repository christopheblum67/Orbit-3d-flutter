# Orbit IPTV — Suivi des projets (Sprints)

> Mis à jour à chaque sprint. Progression = travail réellement livré et vérifié.

## Légende
- 🔴 Bloqué | 🟡 En cours | 🟢 Done | ◻️ À faire
- **Durée estimée** = temps restant (heures dev, 1 ingénieur).

---

## Équipes & Niveaux (XP)
Paliers : 1–9 Apprenti · 10–19 Confirmé · 20–29 Expert · 30+ Architecte.\
XP : sprint propre +40 · DoD +20 · leçon +10 · bug capté avant push +10 · hors DoD −15 · bug production −25 · scope creep −10.

| Équipe | Secteur | Niveau | Rôle |
|---|---|---|---|
| **Terre** | EPG / Données | **Lvl 4** Apprenti | EPG, grille, cache |
| **Soleil** | Player / Streaming | **Lvl 12** Confirmé | Zapping, players |
| **Lune** | IA / Data | **Lvl 7** Apprenti | IA zapping |
| **Mars** | UX / Favoris | **Lvl 10** Confirmé | Favoris, navigation |
| **Alpha** | QA / Livraison | **Lvl 14** Confirmé | Tests, commit, release |
| **Polaris** | Documentation / Recherche | **Lvl 1** Apprenti | Veille : si une équipe bloque trop longtemps, recherche sur le web (docs, widgets, API, patterns) pour débloquer et fiabiliser le processus |

---

## 1. STREAM DRAAP — Lecture Live sur S20 (objectif prioritaire)
**Preuve (capture PCAP XCIPTV, 06/09)** : le flux est SAIN — XCIPTV lit `/live/{u}/{p}/{id}.ts` → 302 Cloudflare → CDN `79.143.17.130` → MPEG TS. Le blocage est côté ExoPlayer/notre stack, pas côté réseau.

| Élément | Statut | Détail |
|---|---|---|
| Crash `The source buffer is this buffer` | 🟢 | **Cause = notre `NightFocusAudioProcessor.queueInput`** (in-place media3). Corrigé : by-pass sans copie + boucle in-place. Son audible après fix. |
| Anti-leech panneau (~90 s / IP) | 🟡 | **En test utilisateur sur TV (07/09)** : zapping fluide ; cooldown/circuit breaker côté app à ajouter si nécessaire selon retour. |
| Vidéo confirmée S20 | 🟢 | **Validée par l'utilisateur (07/09)** : rendu vidéo OK de bout en bout ; sera testée de façon fluide sur TV |
| media3 | 🟢 | Repointé 1.9.3 (1.12.0 inexistante au dépôt Google). |

**Progression : ~85% — Vidéo OK ; anti-leech en validation manuelle TV (retour utilisateur attendu).**

---

## 2. RUST PROXY — Contourner Cloudflare 406 (flux video)
**Objectif** : proxy local `reqwest-impersonate` (Chrome 120) + axum pour masquer l'empreinte TLS des flux `draap.online`.

| Sprint | Contenu | Statut | Reste |
|---|---|---|---|
| S1 | Squelette: config.rs, client_factory.rs, hls.rs, proxy.rs, health.rs, metrics.rs | 🟢 | — |
| S2 | HLS/DASH rewriter (URLs → proxy), cache LRU 256Mo, purge /cache, retry browser fallback | 🟢* | *unit test only — jamais exécuté |
| S3 | Bridge Flutter: RustProxyManager (ProcessManager + ping) + stream_relay (rebase via /proxy/hls?url=) | 🟢* | *unit test only — jamais exécuté |
| S4 | Fallback auto (proxy → direct), logs/diagnostics UI, binaire Android | ◻️ | 3h |
| ⚠️ | **HYPOTHÈSE À FALSIFIER** (machine avec Cargo) : `cargo run --example smoke -- "<URL_FLUX_406>"` → voir « Instructions cargo » ci-dessous | 🔴 | 0.2h |

**Progression réelle : ~15% livré (65% écrit)** — **Reste : ~3h + preuve d'exécution.**

### Instructions cargo (à exécuter côté équipe — machine avec Cargo)
Dans `rust_proxy/` — la falsification `smoke` n'utilise AUCUN code du proxy (seulement `reqwest-impersonate`) :

```powershell
cd rust_proxy
cargo fmt --check             # style
cargo check                   # compilation (deps + code)
cargo clippy --all-targets     # lints
cargo test                    # tests unitaires (S2 : HLS/DASH, cache ; S3 : bridge à re-falsifier en conditions réelles)
cargo build --release         # binaire + cibles Android (cf. Cargo.toml)
```

Falsification TLS (point décisif, ~0.2h) :

```powershell
cargo run --example smoke -- "<URL_FLUX_406_reel>"
```

* ⚠️ Lancer depuis un **poste sur le MÊME réseau que le téléphone** (réseau qui subit le 406).
* 🔴 `200` = **HYPOTHÈSE CONFIRMÉE** : l'empreinte Chrome 120/131 suffit → le proxy a un sens.
* 🔴 `403/406` même avec Chrome 120/131 = **HYPOTHÈSE FALSIFIÉE** : le blocage n'est pas (que) le fingerprint TLS → pivoter (pistes listées dans `examples/smoke.rs`).
* 🟢 Commits déjà poussés : `fa8dc48` (pooling strict + WAF 403/406/429/503 + renewal session + status étendu).

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
| S2 | Badge « Nouveau », High Contrast, Export/Import réglages | 🟢 | — |

**Progression : 100% — ✅ Quick Wins S2 LIVRÉ & VALIDÉ (DoD).**

---

## 5. UX — Navigation & expérience
| Chantier | Contenu | Statut | Reste |
|---|---|---|---|
| Back Handling | Spike `RouteMeta` + `WithBackHandling` committé `894a377` ; audit complet `docs/back_handling_audit.md` (09/09, 28 routes, P0/P1/P2) **entièrement implémenté** (onder `popOrFallback('/home')` partout, `/settings/advanced`, garde formulaire profils `FormBackHandlerScope` + `confirmLeave`, fallbacks `/player`/`/multivideo`/`/radio`) | 🟢 | — |
| Buffering/hardware | Indicateur buffering + contrôles (replay10/play/ff30) dans footerbar (BU : ✅ _ReadyPlayer → footerbar VOD) | 🟢 | — |
| EPG Timeline | Frise horaire EPG continue | 🟢 | Frise continue partagée grille/en-tête, nav -1h/Maintenant/+1h, mini-lecteur, sync scroll↔timeline, ligne "maintenant" temps réel |

**Progression : 100% — EPG Timeline LIVRÉ & VALIDÉ (DoD).**
| Nebula Search | Recherche "nébuleuse" fine + VoiceInput | 🟢 | **Livré 09/09 : SearchService unifié (fuzzy+historique+ranking), VoiceInput fr-FR, suggestions temps réel, 12 tests** |

**Progression : ~90% — Reste : ~4h (EPG Timeline)**

---

## 5b. MONITORING RÉSEAU & STALL PLAYER (Soleil) — 09/09
**Objectif** : détecter coupure réseau et flux "stall" (image figée/son muet) en cours de lecture, afficher overlay informatif, auto-retry intelligent.

| Chantier | Contenu | Statut | Reste |
|---|---|---|---|
| Connectivity Monitor | `ConnectivityMonitor` singleton + provider (`connectivity_plus` stream temps réel) | 🟢 | `lib/services/connectivity_monitor.dart` |
| Stall Detector | Heartbeat 5s sur `controller.value.position` → stall > 15s déclenche `_handleActiveError()` | 🟢 | `lib/services/stall_detector.dart` |
| Host Circuit Breaker | Cooldown 90s par hôte après 2 échecs (401/Source error), enregistre succès/échecs | 🟢 | `lib/services/host_circuit_breaker.dart` |
| UI Overlay unifié | Overlay non-intrusif : "Réseau coupé" (bouton retry), "Connexion instable…", "Serveur protégé (anti-leech) Xs" | 🟢 | `player_monitoring_overlay.dart` dans `_ReadyPlayer` |
| Intégration Player | Démarrage/arrêt timers dans `initState`/`dispose`, check cooldown avant `_tryPlay()` | 🟢 | `player_screen.dart` modifié |
| Tests | 19 nouveaux tests (circuit breaker, stall, connectivity, overlay widget) | 🟢 | **130/130 tests** ; analyze 0 erreur |

**Progression : 100% — Monitoring réseau/stall livré & testé.**

---

## 6. DETAIL — Fiche film style Allociné
| Chantier | Contenu | Statut | Reste |
|---|---|---|---|
| Cast/Crew | models + api fetchMovieCredits + CastGrid + CrewSection | 🟢 | — |
| Matchmaking Films | Section « Films » (genre enrichi via catégorie VOD) | 🟢 | — |
| Filtres genres | Filtres par genres favoris du profil dans matchmaking | 🟢 | OR logic, session-only, chips horizontales dans tuile matchmaking, par abonnement actif, invalide auto |
| **Enrichissement TMDB/TVmaze/OMDB/IA (09/09)** | **Film : TMDB primaire → OMDB date → TVmaze cast → IA | 🟢 | **Livré : modèles étendus, 4 services, carousel acteurs, guests/saison, 111 tests** |
| | Série : **TVmaze primaire** → TMDB guests/saison → OMDB → IA | | `cast_carousel.dart` réutilisable, cache Hive 24h, rate limits |
| | Carrousel horizontal acteurs (Film + Série guests) | | badge source, hors-ligne gracieux, mapping Xtream→TMDB/TVmaze |

**Progression : ~95% — Enrichissement métadonnées livré.**

---

## 7. VERIFICATION / LIVRAISON
| Chantier | Contenu | Statut |
|---|---|---|
| Tests | 89/89 ✓ (15 fichiers) | 🟢 |
| Analyze | 0 erreur (16 erreurs `integration_test` hors scope) | 🟢 |
| Build debug / release | ✓ / 60,3 MB ✓ | 🟢 |
| S20 | Debug + release installés, logcat opérationnel | 🟢 |
| Dépôt git | Nettoyé : seuls les changements réels sont stageables (anti-bruit CRLF) | 🟢 |

**Progression : ~90%**

---

## 7b. CORRECTIFS URGENTS (09/09, non commités)
| Correctif | Équipe | Détail |
|---|---|---|
| Titre film/série absent | **Mars** | `Movie.fromMap` ne lisait que `map['title']` mais Xtream `get_vod_streams` renvoie `name` → titre vide dans la grille et la fiche détail. Fix : lecture `name` puis `title` (comme `Series`), titre dans l'AppBar détail, + 2 tests unitaires |
| Reprise lecture VOD | **Soleil** | Seek initial bloqué quand durée encore inconnue (0) → seek autorisé, + nouvelle tentative tant que non appliqué |
| Rail catégories | **Mars** | Largeur 140px (compact) + libellés complets (maxLines 3, plus de troncature) |
| Refresh au changement d'abonnement | **Soleil**/Terre | `setActive` invalide désormais live/VOD/séries/replay/radio/EPG/récents (import manquant corrigé) |
| Tests | — | **182/182 verts** ; analyze 0 erreur sur `lib` ; APK debug installé S20 (0 FATAL au lancement) |

---

## ⚠️ Constats critiques (revue 06/09 → nettoyé 09/09)
- ✅ **Réglages avancés factices SUPPRIMÉS** (09/09) : `useCustomDNS`, `enableP2PHybrid`, `enableAiUpscaling`, `localAiSubtitles`, `sportsHighlightsDetection`, `autoFrameRate`, `smartFailover`, `directToLive`, `hideCredentials` + doublon `livePlayer` → retirés du provider, de l'UI (settings + advanced_settings), tests adaptés. **0 phantom switch restant.**
- `vpn_service.dart` : `return null` → détection VPN stub. Écran AI = vraie API OpenAI (pas heuristique).

---

## 8. EPG & ORBITE (Terre) — décision 07/09 : Grille 2D seule
**Décision utilisateur** : l'Orbite 3D est la cause principale présumée de latence/freeze → retirée de l'EPG avec Favoris et Recherche (ils seront repositionnés dans d'autres sections dédiées).

| Élément | Statut | Détail |
|---|---|---|
| EpgScreen = Grille 2D seule (Orbite/Favoris/Recherche retirés) | 🟢 | `epg_screen.dart` réécrit : AppBar + filtre catégories + grille ; classes 3D/speech supprimées |
| Perf grille 2D | 🟢 | `epg_grid_2d_view.dart` : repaints via ValueNotifier, cache sur signature, culling hors viewport, RepaintBoundary |
| Cache EPG unifié | 🟢 | `EPGDataCache` `_inFlight` partagé (1 téléchargement XMLTV) + `epgProgramsProvider` → `cache.loadFull` |
| Charges EPG par lots | 🟢 | `_loadAllEpg` : 1 `setState` / lot de 8 chaînes au lieu de 1 / chaîne |
| **Perf recherche programme (10/09)**  | 🟢 | `epg_lookup.dart` : **recherche dichotomique O(log N)** en cours/suivant (mini-bar + player) ; **index par chaîne** dans `EPGDataCache` (plus de re-parcours global à chaque `channelEpgProvider`) — 196 tests |
| Parsing XMLTV hors thread UI | 🟢 | `fetchEpg` → `compute(parseXmltvIsolate)` — aucun blocage UI, même sur 94 k entrées |
| Crash « déconnexion » S20 | 🟡 | 2 captures logcat sans FATAL : gel Samsung `FreecessController FZ reason: LEV` ; whitelist deviceidle + standby active appliqués — à re-validator sur la durée |
| EpgHeadbar (live + fiches) | 🟢 | `epg_headbar.dart` : **0 erreur analyzer** (corrigé 07/09 : context passé en paramètre, retraits références `posterUrl`/`channelName` inexistantes) ; **intégrée dans la grille 2D 10/09** (`_EpgHeadbarSection` : programme en cours/suivant via dichotomie + actions favori/lecture/info chaîne ciblée) — 200 tests |
| Analyse globale `lib` | 🟢 | `dart analyze lib` : **0 erreur** sur tout le projet |

**Progression : ~60% — Reste : validation S20 longue durée + (S4) Rust EPG streaming quick-xml/SQLite.**

---

## 9. FAVORIS V2 (Mars) — 07/09
**Périmètre validé** : Live + VOD + Séries + Replay ; cœur permanent et visible (pas de long-press obligatoire). Retirés de l'EPG (décision Terre) → doivent vivre dans ces 4 sections + écran dédié.

| Élément | Statut | Détail |
|---|---|---|
| Modèle `FavoriteEntry` + `ContentType` | 🟢 | id/title/poster/subtitle/streamUrl + clé canonique `type:id` + égalité de valeur |
| `FavoritesService` v2 | 🟢 | Hive → JSON d'entrée, loadAll/save/remove ; entrées corrompues ignorées |
| Réactivité `favoritesProvider` | 🟢 | `StateNotifier` (pattern maison) : toggle sync état + persist |
| `FavoriteToggle` permanent | 🟢 | Variantes icône (trailing) + overlay fondu sur poster ; SnackBar |
| Branché Live (ChannelTile) | 🟢 | remplace l'ancien `FavoriteButton` local |
| Branché VOD / Séries (MediaCard overlay) | 🟢 | cœur permanent sur poster + long-press conservé (réactif) |
| Branché Replay (ListTile trailing) | 🟢 | cœur permanent sur chaque ligne |
| Écran Favoris v2 (4 onglets) | 🟢 | Live/VOD/Séries/Replay ; résolution catalogues (repli sur données mémorisées) + lecture directe |
| Tests unitaires | 🟢 | `test/unit/favorites_service_test.dart` 7/7 — dont `forType` récents d'abord + `clearAll` (suite 96/96) |
| Suite — cœurs Player + fiches détail | 🟢 | Cœur AppBar du player (suit le canal en zapping) ; cœurs fiches film/série/épisode ; `PlayerRouteData.favorite` |
| Suite — compteurs onglets + tri récents | 🟢 | Libellés onglets `Live (n)`… ; `forType` renvoie du plus récent au plus ancien |
| Suite — swipe supprimer + tout supprimer | 🟢 | `Dismissible` Live/Replay + action AppBar `delete_sweep` avec confirmation |
| Suite — raccourci Home | 🟢 | Badge compteur réactif sur la tuile Favoris du carrousel |
| **Validation utilisateur (DoD)** | 🟢 | 07/09 : cœur opérationnel (chaîne/film/série) + compteurs + tuile Home OK ; lecture auto & « tout supprimer » testés OK ; replay non testé (non dispo sur l'abonnement) |

**Progression : 100% — ✅ FAVORIS V2 (Mars) LIVRÉ & VALIDÉ (DoD).**

---

## 10. CATÉGORIES « FAVORIS » & « RÉCEMMENT REGARDÉ » — 07/09
**Demande utilisateur** : en tête des catégories des sections Live / Films / Séries **et** de l'EPG, ajouter une catégorie « Favoris » et « Récemment regardé » ; l'EPG doit démarrer sur la 1re catégorie (perf) et **sans** la section « Toutes ». **Ordre retenu (retour utilisateur 07/09)** : 1. Tous, 2. Favoris, 3. Récemment regardé (rails Live/VOD/Séries) ; l'EPG reste sans « Toutes » (remarque ingénierie, charge suivie).

| Élément | Statut | Détail |
|---|---|---|
| Modèle `RecentEntry` (type/id/titre/poster/sous-titre/stream + `watchedAt`) | 🟢 | `lib/models/recent_entry.dart` — réutilise `ContentType` |
| `RecentlyWatchedService` (Hive) | 🟢 | clé `type:id`, remplacement doublon, borne 50, plus récents d'abord |
| `recentlyWatchedProvider` (StateNotifier) | 🟢 | `record()` type/id/titre → tête de liste ; **estampille strictement croissante** (ordre déterministe) ; `forType()` |
| Enregistrement lecture (player) | 🟢 | Live = chaîne courante (suit le zapping) ; VOD/Séries/Replay via `widget.favorite` |
| Live TV / Films / Séries : rail | 🟢 | ordre **Tous → Favoris → Récemment** (corrigé) + messages vides |
| EPG : Favoris + Récemment, sans « Toutes » | 🟢 | chips en tête ; démarre sur la **1re catégorie** ; grille vide gérée |
| Nettoyage réglage mort | 🟢 | Retiré « Guide TV (EPG) / Affichage EPG » + option fantôme « 3D immersive » (`EpgDisplayMode`/`grid3D` supprimés) |
| Tests | 🟢 | `recently_watched_service_test.dart` 3/3 ; **99/99** ; analyze 0 erreur |
| APK | 🟢 | buildé + installé + lancé S20 (topResumed, 0 FATAL) ; validation utilisateur en attente |

---

## 11. PLAYER — FUSION HEADERBAR/FOOTERBAR (Alpha) — 09/09
**Objectif** : une seule footerbar basse translucide en bas (retrait AppBar, FAB, InfoBar top, ZapBar). Auto-masquage 5s. Menu contextuel paramètre. Night Focus direct. Hints télécommande.

| Élément | Statut | Détail |
|---|---|---|
| Footerbar Live | 🟢 | nom + n° chaîne (`Channel.orderNum`) + EPG now/next (`_EpgRow`/`_nowAndNext`) + **barre de progression du programme** + zapping prev/next + volume-zap |
| Footerbar Replay | 🟢 | horaires + seek ±10s + pause/play |
| Footerbar VOD/Séries | 🟢 | titre + ★ note + genre (+ série·épisode) + `VideoProgressIndicator` + replay10/play/ff30 |
| Auto-masquage 5s | 🟢 | `_showFooterBar/_hideFooterBar/_toggleFooter` + timer, couplé system UI immersive ; tap/OK/espace/zapping réaffichent |
| Menu contextuel ⚙️ | 🟢 | Audio & sync (`showAudioControlsSheet`), Night Focus, Qualité/lecteur (`showPlayerEngineConfigSheet`), Réglages → `/settings` |
| Night Focus 🌙 | 🟢 | toggle direct `NightFocusAudioService.push` |
| Retraits | 🟢 | AppBar, FAB pause, `_InfoBar`, `_ZapBar`, contrôles matériels `_ReadyPlayer` (replay10/play/ff30 → footerbar) |
| `PlayerRouteData` étendu | 🟢 | `posterUrl/subtitle/rating/genre/year/seriesName/episodeLabel` + call sites VOD/Séries/Replay/Fav/Search/Matchmaking enrichis |
| Baseline build cassée | 🟢 | Fix 4 fichiers WIP bloquant APK : `form_back_handler` (import RouteMeta), `home_shell` (paren excéd), `main.dart` (context.read→ProviderScope.containerOf, radio stop), `profile_preferences` (brace corrompue) |
| Vérifs | 🟢 | analyze 0 erreur · **142/142 tests** · build APK OK · install S20 topResumed 0 FATAL |

**Progression : 100% — Footerbar unifiée livrée (commit `194e6eb`).**

---

## 12. FLIXPATROL → API TRAKT (Terre/Polaris) — 10/09
**Décision utilisateur** : remplacer le scraping flixpatrol.com (403 Cloudflare) et l'API payante par l'**API publique Trakt** (client_id gratuit, sans OAuth). Sources éliminées avec preuves : flixpatrol.com 403 CF partout + API officielle payante ; mdblist API clé 401 + OAuth requis pour une app distribuée. Attribution exigée et respectée (logo officiel `Powered by Trakt` dark/light embarqué + « Affiches © TMDB »).

| Élément | Statut | Détail |
|---|---|---|
| `TraktRankEntry` (film/série/populaires/tendances) | 🟢 | `lib/models/trakt_rank_entry.dart` : parsing `extended=full` (ids croisés, genres, runtime, certification, tagline, trailer, images, `watchers` trending) |
| `TraktService` | 🟢 | `lib/services/trakt_service.dart` calqué sur TmdbService : headers `trakt-api-key`/`trakt-api-version:2`, cache Hive 24h, rate limit, 4 endpoints `/movies|/shows popular|trending?extended=full&limit=` |
| Providers | 🟢 | `flixPatrol*` → `trakt*` (Popular/Trending × Films/Séries), `traktServiceProvider` |
| Onglet Parcourir | 🟢 | `_FlixPatrolView`/`_RankCard`/`_RankEntrySheet` basculés : fiche détail enrichie (genres, durée, certif, tagline, watchers, bande-annonce), message erreur `TRAKT_CLIENT_ID` |
| Attribution | 🟢 | `_TraktAttributionFooter` (logo + Powered by Trakt + Affiches © TMDB) dans l'onglet et la fiche |
| Env | 🟢 | `TRAKT_CLIENT_ID` ajouté à `.env` (vide) et `.env.example` (création sur trakt.tv/oauth/applications) |
| Tests | 🟢 | `trakt_rank_entry_test.dart` 4/4 ; **200/200** ; analyze 0 erreur `lib` ; APK debug installé S20 |

**Progression : 100% — FLIXPATROL/TRAKT LIVRÉ (commit `76421d4`).** Reste : clé à renseigner par l'utilisateur + validation visuelle S20.

---

## Total backlog restant estimé : ~3h (1 ingénieur) — Rust Proxy uniquement
Prochaines priorités : **Rust Proxy S4** (3h + falsification 0.2h sur machine Cargo) — seul chantier technique restant. Tout le reste (Quick Wins S2, EPG Timeline, Filtres genres matchmaking, Multi-abonnements universelle, Correctifs urgents 09/09, **EPG headbar 10/09, FlixPatrol→Trakt 10/09**) est **✅ LIVRÉ & VALIDÉ**.