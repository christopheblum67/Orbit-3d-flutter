# Orbit 3D — Liste de tâches (todolist)

> Fichier unique de suivi. Une ligne = une tâche vérifiable.
> Statuts : `[ ]` à faire · `[~]` en cours · `[x]` fait (à valider) · `[X]` validé sur appareil.
> Dernière mise à jour : 2026-10-17.

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
- [x] **Améliorations Replay — durée réelle de l'abonnement** — *Demande (13/10)* : « avoir le replay réel que chaque abonnement propose en durée de jours ».
      → La fenêtre de replay doit refléter la rétroactivité **réellement annoncée par l'abonnement/le panel**, par chaîne et par compte, au lieu d'une constante globale.
      Aujourd'hui : `kCatchUpWindow = 14 jours` en dur (`lib/providers/providers.dart:1091`) + `Channel.archiveDays` (`tv_archive_duration`, `models/channel.dart`) et logique dans `api_service.dart` (~1820, ~1983).
      **FAIT** : fenêtre unifiée via `ApiService.fallbackArchiveDays = 14` (remplace 48 h / 7 j divergents) ; `effectiveArchiveDays` source unique pour Replay + rattrapage EPG ; `_replayLimit = 400`. Validé S20 : 517 replays FRANCE 2 (archiveDays=0 → repli 14 j). Tests : `replay_archive_window_test` mis à jour.

## 2 bis. Chantiers du 13/10 — demande utilisateur (ordre 1→4, tous livrés)

- [x] **① Suppression recherche vocale & notifications** — `speech_to_text` retiré (bouton micro, préchauffage, permission `RECORD_AUDIO`) et notifications retirées (`firebase_messaging`, `flutter_local_notifications`, tuile « test notification », `notification_service.dart`, `third_party/speech_to_text`). Conséquence **acceptée** : plus de notification de lecture en arrière-plan, la lecture continue de fonctionner. Firebase (analytics/crashlytics/auth/firestore) et la FGS `MediaPlaybackService` sont conservés (une FGS est exemptée de `POST_NOTIFICATIONS`). Garde-fou : `test/unit/removed_features_guard_test.dart` (10 tests).
- [x] **② Sous-titres forcés par série** — même principe que l'audio forcé : `PlayerTrackPrefs` gagne `seriesSubtitleLanguageFor` / `setSeriesSubtitleLanguage` / `isSeriesSubtitleForced` / `setSeriesSubtitleForced` / `clearSeriesSubtitlePreference` ; `StreamSubtitleTracksService` découvre les pistes texte **intégrées** (sondage borné, media3 les publiant par vagues) ; `_SeriesSubtitleLanguageSelector` dans l'écran série ; le lecteur applique la langue **une fois par contenu** (`_applySeriesSubtitlePreference`), via `pickEmbeddedSubtitleTrackForLanguage` qui **préfère une piste non-forcée** à sa variante « forced ». Tests : `embedded_subtitle_pick_test` (6) + `player_track_prefs_test` (+6).
- [x] **③ Écran de démarrage / rafraîchissement** — carrousel « Pour vous » retiré de l'écran de **rechargement des catégories d'abonnement** (chaînes TV / films / séries) ; `RefreshProgressView` réécrit : « Orbit IPTV » en haut, texte « Mise à jour du contenu multimédia en cours… », 4 sections (Chaînes TV / Films & VOD / Séries / EPG), **adaptatif portrait ET paysage** (côte à côte en paysage, empilé en portrait, scrollable pour ne jamais déborder). Clé l10n `updatingMediaContent` (6 locales). Tests : `refresh_progress_view_test` (6). *(L'onglet Matchmaking « Pour vous » n'est pas touché.)*
- [x] **④ Multi-écran** — `multiViewGridDimensions` fait **remplir tout l'écran** à la grille (1×1, 2×1 en paysage / 1×2 en portrait, 2×2), là où le `GridView` à `childAspectRatio: 1.5` fixe laissait une bande vide ; **le son ne sort que de la tuile active** — toutes les tuiles continuent de jouer (`setVolume(0)` sur les autres, l'image n'est pas coupée) ; sélection par **feuille de recherche** cochable (remplace la barre de `FilterChip` de 120 px) ; badge son, bouton retirer et titre par tuile ; « Ajouter » / « Tout retirer » dans l'AppBar. Clés l10n `addChannel` / `noChannelSelected` / `removeChannel` / `activeAudio` (6 locales). Tests : `multivideo_grid_test` (6).

État : `flutter analyze lib test` → 0 problème (hors 4 avertissements préexistants dans `test/`), `dart run tool/check_i18n_sync.dart` → 421 messages / 6 locales, **suite complète 895 verts**.

## 2 ter. Chantiers du 14/10 — sous-titres intégrés & entrée « Aucun »

- [x] **① Sous-titres intégrés INVISIBLES malgré une détection correcte** — *Défaut rapporté (14/10)* : les pistes intégrées sont listées et sélectionnables, mais **aucun sous-titre ne s'affiche jamais**.
      → *Cause racine trouvée* : `subtitleControllerProvider` était déclaré en **`Provider<SubtitleController>` nu** (`lib/providers/providers.dart:105`). Or `SubtitleController` est un `ChangeNotifier` dont l'état change **en cours de lecture** (`_pollLiveEmbedded` → `notifyListeners`, toutes les 300 ms). `ref.watch` ne s'abonne à `notifyListeners` que si le provider enveloppe un `Listenable` : **les `ref.watch` étaient donc morts**. L'overlay du lecteur — seul consommateur **sans `setState`**, il se contente de rendre `liveEmbeddedCues` — ne se reconstruisait jamais pendant la lecture.
      *Preuve par étage* : natif `onCues n=1` (le `TextRenderer` émet bien), pont `getCurrentCues raw=1 text=1` (cue **textuelle**, pas bitmap PGS), Dart `1re cue reçue (1) — [grincement léger]` (le contrôleur reçoit bien). La chaîne s'arrêtait au `notifyListeners`, **sans abonné**.
      *Correctif* : `ChangeNotifierProvider<SubtitleController>` (Riverpod 3 l'exporte via `package:flutter_riverpod/legacy.dart`), sans `ref.onDispose(controller.dispose)` — le provider dispose lui-même le notifier. Un seul changement répare aussi les autres `ref.watch` du même provider (feuille « Détails du flux », panneau sous-titres). Sondes temporaires natif + Dart retirées après validation. Leçon : playbook **L15**.
      **Validé sur le S20 (14/10)** : les sous-titres s'affichent à l'écran.
- [x] **② Entrée « Aucun » audio ET sous-titres, désactivations SÉPARÉES** — *Demande (14/10)* : « un entête aucun dans les 2 détails de flux, un pour l'audio, et un pour les sous-titres, désactivation séparée ».
      → « Aucun » **audio** = vraie désactivation du **type** au niveau du sélecteur (`clearAudioTracks` → `setTrackTypeDisabled(C.TRACK_TYPE_AUDIO, true)`) et oubli de la préférence persistée (`PlayerTrackPrefs.clearAudioTrack`) ; « Aucun » **sous-titres** = `SubtitleController.disable()` (coupe intégrés ET externes, `clearSubtitleTracks` natif). Chaque section a **son** « Aucun » ; celui des sous-titres est rendu en **1re ligne de la sous-section « Sous-titres intégrés »** (repli en tête de la liste générale quand le flux n'a aucune piste intégrée). Clé l10n `noneOption` (6 locales). Tests : `player_track_prefs_test` (+3), `embedded_subtitle_controller_test` (+3).
- [x] **③ Menu série « Langue des sous-titres par défaut » : une entrée PAR PISTE** — *Demande (14/10)* : le menu n'offrait que 2 langues là où le lecteur en proposait 5.
      → `StreamSubtitleTracksService._toLanguages` **dédupliquait par code langue** et collait au survivant le libellé de la **dernière** piste (`Français (SDH)`, `English [Original] (SDH)`) : l'utilisateur lisait « 3 options » face aux 6 du lecteur. Remplacé par `_toTrackChoices` (**une entrée par piste**, valeur = libellé, `Map` pour dédupliquer sans violer l'assertion `DropdownButton` sur valeurs dupliquées) ; nouveau `pickEmbeddedSubtitleTrackForPreference` (libellé exact → nom de langue traduit → code langue, pour les préférences enregistrées avant ce changement) ; items du menu complétés par la préférence mémorisée quand la sonde courante ne la contient pas (sinon assertion → crash de l'écran série). Tests : `embedded_subtitle_pick_test` (+5).

État : `flutter analyze <fichiers touchés>` → « No issues found! », **suite complète 915 verts**, build release installé et validé sur le S20.

## 2 quater. Chantiers du 15/10 — artefacts d'encodage, lecture locale, aperçu live

- [x] **Aperçu live — étendre l'EPG à 4-5 programmes** — *Demande (15/10)* : « étendre le programme EPG à 4-5 programmes dans l'aperçu live ».
      Aujourd'hui `_EpgList` (`lib/features/live_tv/widgets/channel_browse_view.dart`) est **borné à `_maxPrograms = 2`** (programme en cours + suivant), à cause d'une hauteur contrainte dans la maquette à deux zones (voir commentaire l. 174-177 : « les deux programmes EPG passaient sous le bord de l'écran »).
      **FAIT** : `_maxPrograms = 5` + padding vertical densifié (dense: 7→5, normal: 10→7). Validé S20.
- [x] **Signature APK en schéma v3** — *Demande (15/10)* : « faire passer la signature en v3 pour le keystore ».
      → *Constat mesuré* : l'APK release est signé **v2 uniquement**. `apksigner verify --verbose` (build-tools 36.0.0, AGP 9.0.1) renvoie `v1: false`, `v2: true`, `v3: false`, `v3.1: false`, `v4: false`. Signature `CN=Orbit3D, OU=Mobile, O=Orbit, C=FR`, SHA-256 `856837ba79570f2bc2658766880e8fceb112439418b9c96554abe2428446fb2a`.
      **FAIT** : `signingConfigs.release { enableV3Signing = true }` → `apksigner verify --verbose` → `v3: true`. Clé/certificat inchangés → mises à jour `adb install -r` conservent abonnement/profil.

## 2 quinquies. TV Support (Android TV / Fire TV / TV Boxes) — 2026-10-15

### Priorité 1 : Manifest & Assets (CRITICAL — bloquant pour TV Launcher)
- [x] **AndroidManifest.xml** : `android:software.leanback required="true"`, `<category android:name="android.intent.category.LEANBACK_LAUNCHER"/>`, `android:largeHeap="true"`, `android:banner="@drawable/tv_banner"` sur `<application>`
- [x] **TV Banner (320×180)** : `android/app/src/main/res/drawable/tv_banner.xml` (vector drawable scalable)

### Priorité 2 : Safe Area / Overscan (CRITICAL — contenu coupé aux bords)
- [x] **TvSafeArea widget** (`lib/core/widgets/tv_safe_area.dart`) : minimum `EdgeInsets.symmetric(horizontal: 48, vertical: 27)` pour overscan 5-10%
- [x] **Appliqué aux écrans principaux** : Home, Live TV, VOD, Séries, Replay, EPG, Search, Settings, Advanced Settings

### Priorité 3 : Navigation D-pad / Focus System (HIGH)
- [x] **TvFocus** existant : glow + scale + border + haptique + clés OK/Enter/Space/GamepadA
- [x] **CategoriesRail** : `_FocusableCategoryTile` avec `Focus` + `onKeyEvent` (Enter = select)
- [x] **ProfileEditScreen** : chips focales (`_ProfileChoiceChip`), SegmentedButton, "Suivant" button accessible D-pad
- [x] **PlayerScreen** : `_onKeyEvent` gère flèches (zapping), Space (play/pause), Escape (footer)
- [~] **EPG Grid** : CustomPainter sans FocusNode par cellule — **nécessite refactor majeur** pour D-pad left/right entre programmes
- [~] **SearchScreen** : SearchAnchor/TextField pas TV-ready — IME options, conditional keyboard, SearchManager manquant
- [~] **UnifiedSettingsScreen** : TabBar, DropdownButton, ListTile pas focus-wrappés — navigation D-pad limitée

### Priorité 4 : Audio Focus / MediaSession (MEDIUM)
- [ ] **MediaSessionCompat + MediaButtonReceiver** Android natif pour contrôles télécommande (play/pause/next/prev)
- [ ] **AudioAttributes** explicites (USAGE_MEDIA, CONTENT_TYPE_MOVIE)
- [ ] Bridge Flutter ↔ MediaSession via platform channel

### Priorité 5 : Tests TV (LOW)
- [ ] `integration_test/tv_navigation_test.dart` : scénarios navigation complète, lecture, zapping, recherche, profil

### État actuel
- `flutter analyze lib` → 0 erreur, 0 warning (hors infos préexistantes EPG)
- `flutter test` → **966 tests passed**
- `dart run tool/check_i18n_sync.dart` → 428 messages, 0 problème sur 6 locales
- Build release installé sur S20 (mode TV forcé via réglages avancés)

**Prochaines étapes prioritaires** : EPG Grid D-pad refactor + SearchScreen TV delegate + MediaSession bridge.

---

## 2 sexies. Chantiers du 17/10 — synopsis, aperçu EPG, menus Réglages

- [x] **Synopsis traduit affiché en ROUGE (film ET série)** — *Demande (17/10)* : « pour le synopsis, si traduction, affichage du texte en rouge », « valable pour film et série évidemment ».
      `TranslatedSynopsisView` (partagé par `movie_detail_screen` et `series_detail_screen`) colorait le texte en `onSurfaceVariant` quelle que soit la source. Le texte passe désormais en `Colors.redAccent` dès que `resolved.isTranslated` (synopsis TMDB fr **ou** traduction automatique Google) ; la source du traducteur reste affichée sous le texte. Couleur exposée en `TranslatedSynopsisView.translatedTextColor`. Tests : `test/widget/translated_synopsis_view_test.dart` (3, dont 2 échouaient sans le rouge).
- [x] **Aperçu Live TV — 7 programmes EPG au lieu de 5** — *Demande (17/10)* : « augmenter le nombre de programmes valides en validant 2 lignes de plus ».
      `_EpgList._maxPrograms` (5) remplacé par l'appel à `epgPreviewPrograms(programs, now)` (`lib/core/utils/epg_lookup.dart`) avec `kEpgPreviewMaxPrograms = 7`. La sélection quitte le widget pour devenir testable. Tests : `test/unit/epg_preview_programs_test.dart` (6, dont 1 échouait avec l'ancienne limite de 5).
- [x] **Réglages — fusion des menus (Réseau + Sécurité / Lecteur + Audio)** — *Demande (17/10)* : « fusionner les menus Réseau + Sécurité / Lecteur vidéo + Audio, avec un séparateur en sous-titre distinctif pour bien différencier les 2 ».
      Barre d'onglets ramenée de 6 à 4 : **Compte · « Réseau & Sécurité » · « Lecteur & Audio » · Avancé**. Nouveau widget `SettingsGroupDivider` (`lib/features/settings/widgets/settings_widgets.dart`) : libellé cyan (`tertiary`) en majuscules espacées, encadré de deux traits, qui marque la frontière entre les deux anciens menus dans chaque onglet fusionné. Les noms d'onglets sont la concaténation des libellés existants → correct dans les 6 langues sans nouvelle clé l10n. Vérif : suite complète **966 verts**, `flutter analyze` sans erreur.
- [~] **Bug d'affichage « Moteurs de lecture » (écran gris)** — *investigation* en cours (agent externe, lecture seule). Le fix FocusNode du 16/10 (`6c6a923`) couvre le double usage du `FocusNode` ; la cause exacte de l'écran gris reste à confirmer, faute de device connecté.

---

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

- [x] **Commits** : 19 commits atomiques réalisés le 14/10, couvrant tout le reliquat (config, docs, l10n, sécurité/SecretStore, stockage Hive, OpenSubtitles, sous-titres + fork media3, tri/affinité, EPG, replay `archiveDays`, démarrage/rafraîchissement, connectivité, synopsis, métadonnées, matchmaking, bouton hamburger, avatars, UI, style). Arbre de travail propre ; suite complète verte (906 tests) et build release installé sur le S20.
