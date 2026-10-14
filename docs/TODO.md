# Orbit 3D — Liste de tâches (todolist)

> Fichier unique de suivi. Une ligne = une tâche vérifiable.
> Statuts : `[ ]` à faire · `[~]` en cours · `[x]` fait (à valider) · `[X]` validé sur appareil.
> Dernière mise à jour : 2026-10-13.

---

## 0. Bugs signalés (priorité utilisateur)

- [x] **Icône « hamburger » non cliquable** — `Scaffold.of(context)` était appelé depuis le contexte du widget qui *crée* le `Scaffold` (donc au-dessus), ce qui lève une `FlutterError` et rend le tap muet. Corrigé via `DrawerMenuButton` (avec `Builder`) dans `HomeShell` et `DuoProfileSelectionScreen`. Test de non-régression : `test/widget/drawer_menu_button_test.dart` (2 verts). **Installé sur le S20 — reste la validation visuelle par l'utilisateur (accueil + écran profils Duo).**
- [x] **Sous-titres OpenSubtitles qui « ne se lisaient plus »** (les intégrés fonctionnaient) — *Cause racine* : media3 auto-sélectionne sa piste texte **quelques secondes après** le début de la lecture, pas au premier sondage. Un sous-titre OpenSubtitles choisi dans cette fenêtre était adopté alors que `_activeEmbeddedTrackId == null` : `_cancelEmbeddedForExternal` sortait donc sans couper le type « texte » côté natif, et dès que media3 sélectionnait sa piste (souvent la « forced ») **et** que la liste s'enrichissait, `setEmbeddedContext` ré-adoptait la piste intégrée → l'overlay intégré masquait le sous-titre externe.
      *Correctif* (`lib/services/subtitle_controller.dart`) : ① `_cancelEmbeddedForExternal` coupe désormais **toujours** le type texte natif quand un pont existe ; ② garde d'exclusivité `_externalPlayerId` — la découverte intégrée n'adopte plus la sélection automatique de media3 tant que l'utilisateur a choisi une piste externe **pour ce lecteur** (le changement de contenu libère la garde tout seul). Tests : `test/unit/embedded_subtitle_controller_test.dart` (2 nouveaux, échouaient avant le correctif). **Reste : validation utilisateur sur le S20.**

## 1. Tri des listes — refonte demandée

- [x] **Menu de tri sans doublons asc/desc** : un seul item par critère, tout critère **inversible** (paires `recentlyAdded↔recentlyAddedAsc`, `ratingDesc↔ratingAsc`, `yearDesc↔yearAsc`, `durationShort↔durationLong`, `affinity↔affinityAsc`, `nameAsc↔nameDesc`) ; « À reprendre » sans inverse (bouton désactivé) — écrans **Films / Séries / Parcourir**.
- [x] **2 boutons icône** à côté de l'option de tri : ① ascendant / descendant, ② alphabétique (A→Z / Z→A, hors menu).
- [x] Conserver le sens affinité croissant/décroissant déjà ajouté (`SortMode.affinityAsc`), avec les mêmes % que les badges.
- [x] Tests (17 nouveaux : `media_library_sort_test`, `sort_toolbar_buttons_test`, `sort_options_dialog_test`) + `dart analyze` 0 + suite complète verte (853 verts après le tri).
      **Reste : validation visuelle sur le S20** (build cumulé installé le 13/10).

## 2. Nouveaux chantiers (demandés le 13/10)

- [x] **Correction grille EPG** — *Défaut rapporté (13/10)* : « les programmes ne sont affichés que pour les premières heures après minuit ; tout le reste disparaît ».
      → *Cause racine trouvée* : le **tampon EPG local** (`lib/services/epg_buffer_store.dart`) est ancré sur la **journée de l'écriture** (`project(windowStart = minuit du jour, horizon = écriture + 30 h)`), et `read()` ne le rejetait que sur une péremption de 12 h. Écrit la veille au soir, il couvre « hier 00:00 → aujourd'hui ~05:00 » ; relu le lendemain matin (moins de 12 h plus tard, donc « frais »), il ne reste que les **premières heures après minuit** — le reste est comblé par des blocs « Aucune donnée de programme » quasi invisibles, d'où « tout disparaît ».
      *Correctif* : ① `EpgBufferStore.read` refuse un tampon écrit un **autre jour civil** (horloge injectable pour le test) ; ② `EPGDataCache.isFresh` rejette aussi les données en mémoire chargées la veille (application restée ouverte à cheval sur minuit). Tests : `test/unit/epg_buffer_store_test.dart` (2 nouveaux, dont un échouait avant le correctif).
      **Reste : confirmation visuelle sur le S20** — le diagnostic est une hypothèse forte appuyée par un défaut prouvé, pas une mesure faite sur l'appareil.
- [ ] **Améliorations Replay — durée réelle de l'abonnement** — *Demande (13/10)* : « avoir le replay réel que chaque abonnement propose en durée de jours ».
      → La fenêtre de replay doit refléter la rétroactivité **réellement annoncée par l'abonnement/le panel**, par chaîne et par compte, au lieu d'une constante globale.
      Aujourd'hui : `kCatchUpWindow = 14 jours` en dur (`lib/providers/providers.dart:1091`) + `Channel.archiveDays` (`tv_archive_duration`, `models/channel.dart`) et logique dans `api_service.dart` (~1820, ~1983).
      Attendu : bornage par la durée réelle (catchup-days / tv_archive_duration), par chaîne, et non systématiquement 14 j.

## 2 bis. Chantiers du 13/10 — demande utilisateur (ordre 1→4, tous livrés)

- [x] **① Suppression recherche vocale & notifications** — `speech_to_text` retiré (bouton micro, préchauffage, permission `RECORD_AUDIO`) et notifications retirées (`firebase_messaging`, `flutter_local_notifications`, tuile « test notification », `notification_service.dart`, `third_party/speech_to_text`). Conséquence **acceptée** : plus de notification de lecture en arrière-plan, la lecture continue de fonctionner. Firebase (analytics/crashlytics/auth/firestore) et la FGS `MediaPlaybackService` sont conservés (une FGS est exemptée de `POST_NOTIFICATIONS`). Garde-fou : `test/unit/removed_features_guard_test.dart` (10 tests).
- [x] **② Sous-titres forcés par série** — même principe que l'audio forcé : `PlayerTrackPrefs` gagne `seriesSubtitleLanguageFor` / `setSeriesSubtitleLanguage` / `isSeriesSubtitleForced` / `setSeriesSubtitleForced` / `clearSeriesSubtitlePreference` ; `StreamSubtitleTracksService` découvre les pistes texte **intégrées** (sondage borné, media3 les publiant par vagues) ; `_SeriesSubtitleLanguageSelector` dans l'écran série ; le lecteur applique la langue **une fois par contenu** (`_applySeriesSubtitlePreference`), via `pickEmbeddedSubtitleTrackForLanguage` qui **préfère une piste non-forcée** à sa variante « forced ». Tests : `embedded_subtitle_pick_test` (6) + `player_track_prefs_test` (+6).
- [x] **③ Écran de démarrage / rafraîchissement** — carrousel « Pour vous » retiré de l'écran de **rechargement des catégories d'abonnement** (chaînes TV / films / séries) ; `RefreshProgressView` réécrit : « Orbit IPTV » en haut, texte « Mise à jour du contenu multimédia en cours… », 4 sections (Chaînes TV / Films & VOD / Séries / EPG), **adaptatif portrait ET paysage** (côte à côte en paysage, empilé en portrait, scrollable pour ne jamais déborder). Clé l10n `updatingMediaContent` (6 locales). Tests : `refresh_progress_view_test` (6). *(L'onglet Matchmaking « Pour vous » n'est pas touché.)*
- [x] **④ Multi-écran** — `multiViewGridDimensions` fait **remplir tout l'écran** à la grille (1×1, 2×1 en paysage / 1×2 en portrait, 2×2), là où le `GridView` à `childAspectRatio: 1.5` fixe laissait une bande vide ; **le son ne sort que de la tuile active** — toutes les tuiles continuent de jouer (`setVolume(0)` sur les autres, l'image n'est pas coupée) ; sélection par **feuille de recherche** cochable (remplace la barre de `FilterChip` de 120 px) ; badge son, bouton retirer et titre par tuile ; « Ajouter » / « Tout retirer » dans l'AppBar. Clés l10n `addChannel` / `noChannelSelected` / `removeChannel` / `activeAudio` (6 locales). Tests : `multivideo_grid_test` (6).

État : `flutter analyze lib test` → 0 problème (hors 4 avertissements préexistants dans `test/`), `dart run tool/check_i18n_sync.dart` → 421 messages / 6 locales, **suite complète 895 verts**.

## 3. Chantiers en cours (issus du plan précédent)

- [x] **P1 — Rafraîchissement à la demande** (`RefreshStepsController` / `RefreshProgressView` / `showRefreshProgress`) : implémenté — **reste à valider sur device** (démarrage périmé + changement d'abonnement).
- [x] **P3 — Sous-titres intégrés** : cause racine confirmée — `subtitleControllerProvider` était **non autoDispose** ⇒ contrôleur app-scoped, `_activeTrack` contaminait le contenu suivant. Restreint (décision utilisateur) à la **réinitialisation de `_activeTrack` entre deux contenus** : `SubtitleController.resetForNewContent()` appelé à l'init de la `PlayerScreen` et dans `_switchTo` (zapping). Test fails-first dans `embedded_subtitle_controller_test.dart` (16 verts).
- ~~[ ] **P4b — Réserve de cache froid**~~ — **Abandonné (décision utilisateur, 13/10)** : jamais défini nulle part (pas de cahier des charges), aucun livrable attendu.
- [x] **P6 — Hive `json_retyping`** : défaut de retypage des maps relues après `Hive.close()` + réouverture. `deepRetypeMap` appliqué aux lectures de `StorageService` (`getProfiles`/`getPreferences`) et au cache OMDB. Test fails-first : `storage_service_retyping_test.dart` (round-trip Hive close/réouverture, 11 verts).

## 4. Reporté (audit `docs/audit-complet-2026-10-12.md`)

- [x] **S1** — Migration `flutter_secure_storage` — **COMPLÈTE (décision utilisateur : tout migrer)** : abstraction `SecretStore` (Keystore RSA OAEP + AES-GCM, `InMemorySecretStore` pour tests injecté via `test/flutter_test_config.dart`). Cinq familles migrées : ① PIN parental (Hive → coffre, `_migrateLegacySecrets`), ② mot de passe OpenSubtitles (prefs → coffre, l'identifiant — non sensible — reste en prefs), ③ clé API OpenSubtitles (prefs → coffre, sanitise conservé), ④ override clé API TMDB (prefs → coffre), ⑤ **mot de passe Xtream des abonnements (Hive → coffre, keyé par id)** : cache mémoire pour les lecteurs synchrones (`getActiveSubscriptionSync`), hydratation aux lectures, nettoyage à la suppression, migration au premier `init()`. Tests : `parental_pin_migration_test`, `subscription_password_migration_test`, stores adaptés + tests de migration legacy. Suite complète : **861 verts**, `dart analyze` 0.
- [x] **S2** — Signature release + `proguard-rules.pro` (+ règles R8 si sérialisation impactée) : keystore neuf PKCS12 `upload-keystore.jks` + `key.properties` gitignorés, `signingConfigs.release`, règles keep media3/videoplayer, `minifyEnabled`/`shrinkResources` actifs. **Build release validé (13/10)** : `√ Built build\app\outputs\flutter-apk\app-release.apk (71,4 Mo)`, installé sur le S20 sans crash R8.
- [x] **armeabi-v7a** — **Décision prise (13/10)** : conserver tel quel (arm64-v8a + x86_64).

## 5. Hygiène dépôt

- [ ] **Commits** : rien n'est commité depuis `49bf129` — gros volume de travail non suivi (fork media3 modifié + fichiers natifs non suivis : `SubtitleDetector.java`, `SubtitleDetectorTest.java`, `VideoPlayerSubtitleTest.java`, `test/resources/`). Prévoir des commits atomiques.
