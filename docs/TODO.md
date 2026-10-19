# Orbit 3D â€” Liste de tÃ¢ches (todolist)

> Fichier unique de suivi. Une ligne = une tÃ¢che vÃ©rifiable.
> Statuts : `[ ]` Ã  faire Â· `[~]` en cours Â· `[x]` fait (Ã  valider) Â· `[X]` validÃ© sur appareil.
> DerniÃ¨re mise Ã  jour : 2026-10-17.

---

## 0. Bugs signalÃ©s (prioritÃ© utilisateur)

- [x] **IcÃ´ne Â« hamburger Â» non cliquable** â€” `Scaffold.of(context)` Ã©tait appelÃ© depuis le contexte du widget qui *crÃ©e* le `Scaffold` (donc au-dessus), ce qui lÃ¨ve une `FlutterError` et rend le tap muet. CorrigÃ© via `DrawerMenuButton` (avec `Builder`) dans `HomeShell` et `DuoProfileSelectionScreen`. Test de non-rÃ©gression : `test/widget/drawer_menu_button_test.dart` (2 verts). **InstallÃ© sur le S20 â€” reste la validation visuelle par l'utilisateur (accueil + Ã©cran profils Duo).**
- [x] **Sous-titres OpenSubtitles qui Â« ne se lisaient plus Â»** (les intÃ©grÃ©s fonctionnaient) â€” *Cause racine* : media3 auto-sÃ©lectionne sa piste texte **quelques secondes aprÃ¨s** le dÃ©but de la lecture, pas au premier sondage. Un sous-titre OpenSubtitles choisi dans cette fenÃªtre Ã©tait adoptÃ© alors que `_activeEmbeddedTrackId == null` : `_cancelEmbeddedForExternal` sortait donc sans couper le type Â« texte Â» cÃ´tÃ© natif, et dÃ¨s que media3 sÃ©lectionnait sa piste (souvent la Â« forced Â») **et** que la liste s'enrichissait, `setEmbeddedContext` rÃ©-adoptait la piste intÃ©grÃ©e â†’ l'overlay intÃ©grÃ© masquait le sous-titre externe.
      *Correctif* (`lib/services/subtitle_controller.dart`) : â‘  `_cancelEmbeddedForExternal` coupe dÃ©sormais **toujours** le type texte natif quand un pont existe ; â‘¡ garde d'exclusivitÃ© `_externalPlayerId` â€” la dÃ©couverte intÃ©grÃ©e n'adopte plus la sÃ©lection automatique de media3 tant que l'utilisateur a choisi une piste externe **pour ce lecteur** (le changement de contenu libÃ¨re la garde tout seul). Tests : `test/unit/embedded_subtitle_controller_test.dart` (2 nouveaux, Ã©chouaient avant le correctif). **Reste : validation utilisateur sur le S20.**

## 1. Tri des listes â€” refonte demandÃ©e

- [x] **Menu de tri sans doublons asc/desc** : un seul item par critÃ¨re, tout critÃ¨re **inversible** (paires `recentlyAddedâ†”recentlyAddedAsc`, `ratingDescâ†”ratingAsc`, `yearDescâ†”yearAsc`, `durationShortâ†”durationLong`, `affinityâ†”affinityAsc`, `nameAscâ†”nameDesc`) ; Â« Ã€ reprendre Â» sans inverse (bouton dÃ©sactivÃ©) â€” Ã©crans **Films / SÃ©ries / Parcourir**.
- [x] **2 boutons icÃ´ne** Ã  cÃ´tÃ© de l'option de tri : â‘  ascendant / descendant, â‘¡ alphabÃ©tique (Aâ†’Z / Zâ†’A, hors menu).
- [x] Conserver le sens affinitÃ© croissant/dÃ©croissant dÃ©jÃ  ajoutÃ© (`SortMode.affinityAsc`), avec les mÃªmes % que les badges.
- [x] Tests (17 nouveaux : `media_library_sort_test`, `sort_toolbar_buttons_test`, `sort_options_dialog_test`) + `dart analyze` 0 + suite complÃ¨te verte (853 verts aprÃ¨s le tri).
      **Reste : validation visuelle sur le S20** (build cumulÃ© installÃ© le 13/10).

## 2. Nouveaux chantiers (demandÃ©s le 13/10)

- [x] **Correction grille EPG** â€” *DÃ©faut rapportÃ© (13/10)* : Â« les programmes ne sont affichÃ©s que pour les premiÃ¨res heures aprÃ¨s minuit ; tout le reste disparaÃ®t Â».
      â†’ *Cause racine trouvÃ©e* : le **tampon EPG local** (`lib/services/epg_buffer_store.dart`) est ancrÃ© sur la **journÃ©e de l'Ã©criture** (`project(windowStart = minuit du jour, horizon = Ã©criture + 30 h)`), et `read()` ne le rejetait que sur une pÃ©remption de 12 h. Ã‰crit la veille au soir, il couvre Â« hier 00:00 â†’ aujourd'hui ~05:00 Â» ; relu le lendemain matin (moins de 12 h plus tard, donc Â« frais Â»), il ne reste que les **premiÃ¨res heures aprÃ¨s minuit** â€” le reste est comblÃ© par des blocs Â« Aucune donnÃ©e de programme Â» quasi invisibles, d'oÃ¹ Â« tout disparaÃ®t Â».
      *Correctif* : â‘  `EpgBufferStore.read` refuse un tampon Ã©crit un **autre jour civil** (horloge injectable pour le test) ; â‘¡ `EPGDataCache.isFresh` rejette aussi les donnÃ©es en mÃ©moire chargÃ©es la veille (application restÃ©e ouverte Ã  cheval sur minuit). Tests : `test/unit/epg_buffer_store_test.dart` (2 nouveaux, dont un Ã©chouait avant le correctif).
      **Reste : confirmation visuelle sur le S20** â€” le diagnostic est une hypothÃ¨se forte appuyÃ©e par un dÃ©faut prouvÃ©, pas une mesure faite sur l'appareil.
- [x] **AmÃ©liorations Replay â€” durÃ©e rÃ©elle de l'abonnement** â€” *Demande (13/10)* : Â« avoir le replay rÃ©el que chaque abonnement propose en durÃ©e de jours Â».
      â†’ La fenÃªtre de replay doit reflÃ©ter la rÃ©troactivitÃ© **rÃ©ellement annoncÃ©e par l'abonnement/le panel**, par chaÃ®ne et par compte, au lieu d'une constante globale.
      Aujourd'hui : `kCatchUpWindow = 14 jours` en dur (`lib/providers/providers.dart:1091`) + `Channel.archiveDays` (`tv_archive_duration`, `models/channel.dart`) et logique dans `api_service.dart` (~1820, ~1983).
      **FAIT** : fenÃªtre unifiÃ©e via `ApiService.fallbackArchiveDays = 14` (remplace 48 h / 7 j divergents) ; `effectiveArchiveDays` source unique pour Replay + rattrapage EPG ; `_replayLimit = 400`. ValidÃ© S20 : 517 replays FRANCE 2 (archiveDays=0 â†’ repli 14 j). Tests : `replay_archive_window_test` mis Ã  jour.

## 2 bis. Chantiers du 13/10 â€” demande utilisateur (ordre 1â†’4, tous livrÃ©s)

- [x] **â‘  Suppression recherche vocale & notifications** â€” `speech_to_text` retirÃ© (bouton micro, prÃ©chauffage, permission `RECORD_AUDIO`) et notifications retirÃ©es (`firebase_messaging`, `flutter_local_notifications`, tuile Â« test notification Â», `notification_service.dart`, `third_party/speech_to_text`). ConsÃ©quence **acceptÃ©e** : plus de notification de lecture en arriÃ¨re-plan, la lecture continue de fonctionner. Firebase (analytics/crashlytics/auth/firestore) et la FGS `MediaPlaybackService` sont conservÃ©s (une FGS est exemptÃ©e de `POST_NOTIFICATIONS`). Garde-fou : `test/unit/removed_features_guard_test.dart` (10 tests).
- [x] **â‘¡ Sous-titres forcÃ©s par sÃ©rie** â€” mÃªme principe que l'audio forcÃ© : `PlayerTrackPrefs` gagne `seriesSubtitleLanguageFor` / `setSeriesSubtitleLanguage` / `isSeriesSubtitleForced` / `setSeriesSubtitleForced` / `clearSeriesSubtitlePreference` ; `StreamSubtitleTracksService` dÃ©couvre les pistes texte **intÃ©grÃ©es** (sondage bornÃ©, media3 les publiant par vagues) ; `_SeriesSubtitleLanguageSelector` dans l'Ã©cran sÃ©rie ; le lecteur applique la langue **une fois par contenu** (`_applySeriesSubtitlePreference`), via `pickEmbeddedSubtitleTrackForLanguage` qui **prÃ©fÃ¨re une piste non-forcÃ©e** Ã  sa variante Â« forced Â». Tests : `embedded_subtitle_pick_test` (6) + `player_track_prefs_test` (+6).
- [x] **â‘¢ Ã‰cran de dÃ©marrage / rafraÃ®chissement** â€” carrousel Â« Pour vous Â» retirÃ© de l'Ã©cran de **rechargement des catÃ©gories d'abonnement** (chaÃ®nes TV / films / sÃ©ries) ; `RefreshProgressView` rÃ©Ã©crit : Â« Orbit IPTV Â» en haut, texte Â« Mise Ã  jour du contenu multimÃ©dia en coursâ€¦ Â», 4 sections (ChaÃ®nes TV / Films & VOD / SÃ©ries / EPG), **adaptatif portrait ET paysage** (cÃ´te Ã  cÃ´te en paysage, empilÃ© en portrait, scrollable pour ne jamais dÃ©border). ClÃ© l10n `updatingMediaContent` (6 locales). Tests : `refresh_progress_view_test` (6). *(L'onglet Matchmaking Â« Pour vous Â» n'est pas touchÃ©.)*
- [x] **â‘£ Multi-Ã©cran** â€” `multiViewGridDimensions` fait **remplir tout l'Ã©cran** Ã  la grille (1Ã—1, 2Ã—1 en paysage / 1Ã—2 en portrait, 2Ã—2), lÃ  oÃ¹ le `GridView` Ã  `childAspectRatio: 1.5` fixe laissait une bande vide ; **le son ne sort que de la tuile active** â€” toutes les tuiles continuent de jouer (`setVolume(0)` sur les autres, l'image n'est pas coupÃ©e) ; sÃ©lection par **feuille de recherche** cochable (remplace la barre de `FilterChip` de 120 px) ; badge son, bouton retirer et titre par tuile ; Â« Ajouter Â» / Â« Tout retirer Â» dans l'AppBar. ClÃ©s l10n `addChannel` / `noChannelSelected` / `removeChannel` / `activeAudio` (6 locales). Tests : `multivideo_grid_test` (6).

Ã‰tat : `flutter analyze lib test` â†’ 0 problÃ¨me (hors 4 avertissements prÃ©existants dans `test/`), `dart run tool/check_i18n_sync.dart` â†’ 421 messages / 6 locales, **suite complÃ¨te 895 verts**.

## 2 ter. Chantiers du 14/10 â€” sous-titres intÃ©grÃ©s & entrÃ©e Â« Aucun Â»

- [x] **â‘  Sous-titres intÃ©grÃ©s INVISIBLES malgrÃ© une dÃ©tection correcte** â€” *DÃ©faut rapportÃ© (14/10)* : les pistes intÃ©grÃ©es sont listÃ©es et sÃ©lectionnables, mais **aucun sous-titre ne s'affiche jamais**.
      â†’ *Cause racine trouvÃ©e* : `subtitleControllerProvider` Ã©tait dÃ©clarÃ© en **`Provider<SubtitleController>` nu** (`lib/providers/providers.dart:105`). Or `SubtitleController` est un `ChangeNotifier` dont l'Ã©tat change **en cours de lecture** (`_pollLiveEmbedded` â†’ `notifyListeners`, toutes les 300 ms). `ref.watch` ne s'abonne Ã  `notifyListeners` que si le provider enveloppe un `Listenable` : **les `ref.watch` Ã©taient donc morts**. L'overlay du lecteur â€” seul consommateur **sans `setState`**, il se contente de rendre `liveEmbeddedCues` â€” ne se reconstruisait jamais pendant la lecture.
      *Preuve par Ã©tage* : natif `onCues n=1` (le `TextRenderer` Ã©met bien), pont `getCurrentCues raw=1 text=1` (cue **textuelle**, pas bitmap PGS), Dart `1re cue reÃ§ue (1) â€” [grincement lÃ©ger]` (le contrÃ´leur reÃ§oit bien). La chaÃ®ne s'arrÃªtait au `notifyListeners`, **sans abonnÃ©**.
      *Correctif* : `ChangeNotifierProvider<SubtitleController>` (Riverpod 3 l'exporte via `package:flutter_riverpod/legacy.dart`), sans `ref.onDispose(controller.dispose)` â€” le provider dispose lui-mÃªme le notifier. Un seul changement rÃ©pare aussi les autres `ref.watch` du mÃªme provider (feuille Â« DÃ©tails du flux Â», panneau sous-titres). Sondes temporaires natif + Dart retirÃ©es aprÃ¨s validation. LeÃ§on : playbook **L15**.
      **ValidÃ© sur le S20 (14/10)** : les sous-titres s'affichent Ã  l'Ã©cran.
- [x] **â‘¡ EntrÃ©e Â« Aucun Â» audio ET sous-titres, dÃ©sactivations SÃ‰PARÃ‰ES** â€” *Demande (14/10)* : Â« un entÃªte aucun dans les 2 dÃ©tails de flux, un pour l'audio, et un pour les sous-titres, dÃ©sactivation sÃ©parÃ©e Â».
      â†’ Â« Aucun Â» **audio** = vraie dÃ©sactivation du **type** au niveau du sÃ©lecteur (`clearAudioTracks` â†’ `setTrackTypeDisabled(C.TRACK_TYPE_AUDIO, true)`) et oubli de la prÃ©fÃ©rence persistÃ©e (`PlayerTrackPrefs.clearAudioTrack`) ; Â« Aucun Â» **sous-titres** = `SubtitleController.disable()` (coupe intÃ©grÃ©s ET externes, `clearSubtitleTracks` natif). Chaque section a **son** Â« Aucun Â» ; celui des sous-titres est rendu en **1re ligne de la sous-section Â« Sous-titres intÃ©grÃ©s Â»** (repli en tÃªte de la liste gÃ©nÃ©rale quand le flux n'a aucune piste intÃ©grÃ©e). ClÃ© l10n `noneOption` (6 locales). Tests : `player_track_prefs_test` (+3), `embedded_subtitle_controller_test` (+3).
- [x] **â‘¢ Menu sÃ©rie Â« Langue des sous-titres par dÃ©faut Â» : une entrÃ©e PAR PISTE** â€” *Demande (14/10)* : le menu n'offrait que 2 langues lÃ  oÃ¹ le lecteur en proposait 5.
      â†’ `StreamSubtitleTracksService._toLanguages` **dÃ©dupliquait par code langue** et collait au survivant le libellÃ© de la **derniÃ¨re** piste (`FranÃ§ais (SDH)`, `English [Original] (SDH)`) : l'utilisateur lisait Â« 3 options Â» face aux 6 du lecteur. RemplacÃ© par `_toTrackChoices` (**une entrÃ©e par piste**, valeur = libellÃ©, `Map` pour dÃ©dupliquer sans violer l'assertion `DropdownButton` sur valeurs dupliquÃ©es) ; nouveau `pickEmbeddedSubtitleTrackForPreference` (libellÃ© exact â†’ nom de langue traduit â†’ code langue, pour les prÃ©fÃ©rences enregistrÃ©es avant ce changement) ; items du menu complÃ©tÃ©s par la prÃ©fÃ©rence mÃ©morisÃ©e quand la sonde courante ne la contient pas (sinon assertion â†’ crash de l'Ã©cran sÃ©rie). Tests : `embedded_subtitle_pick_test` (+5).

Ã‰tat : `flutter analyze <fichiers touchÃ©s>` â†’ Â« No issues found! Â», **suite complÃ¨te 915 verts**, build release installÃ© et validÃ© sur le S20.

## 2 quater. Chantiers du 15/10 â€” artefacts d'encodage, lecture locale, aperÃ§u live

- [x] **AperÃ§u live â€” Ã©tendre l'EPG Ã  4-5 programmes** â€” *Demande (15/10)* : Â« Ã©tendre le programme EPG Ã  4-5 programmes dans l'aperÃ§u live Â».
      Aujourd'hui `_EpgList` (`lib/features/live_tv/widgets/channel_browse_view.dart`) est **bornÃ© Ã  `_maxPrograms = 2`** (programme en cours + suivant), Ã  cause d'une hauteur contrainte dans la maquette Ã  deux zones (voir commentaire l. 174-177 : Â« les deux programmes EPG passaient sous le bord de l'Ã©cran Â»).
      **FAIT** : `_maxPrograms = 5` + padding vertical densifiÃ© (dense: 7â†’5, normal: 10â†’7). ValidÃ© S20.
- [x] **Signature APK en schÃ©ma v3** â€” *Demande (15/10)* : Â« faire passer la signature en v3 pour le keystore Â».
      â†’ *Constat mesurÃ©* : l'APK release est signÃ© **v2 uniquement**. `apksigner verify --verbose` (build-tools 36.0.0, AGP 9.0.1) renvoie `v1: false`, `v2: true`, `v3: false`, `v3.1: false`, `v4: false`. Signature `CN=Orbit3D, OU=Mobile, O=Orbit, C=FR`, SHA-256 `856837ba79570f2bc2658766880e8fceb112439418b9c96554abe2428446fb2a`.
      **FAIT** : `signingConfigs.release { enableV3Signing = true }` â†’ `apksigner verify --verbose` â†’ `v3: true`. ClÃ©/certificat inchangÃ©s â†’ mises Ã  jour `adb install -r` conservent abonnement/profil.

## 2 quinquies. TV Support (Android TV / Fire TV / TV Boxes) â€” 2026-10-15

### PrioritÃ© 1 : Manifest & Assets (CRITICAL â€” bloquant pour TV Launcher)
- [x] **AndroidManifest.xml** : `android:software.leanback required="true"`, `<category android:name="android.intent.category.LEANBACK_LAUNCHER"/>`, `android:largeHeap="true"`, `android:banner="@drawable/tv_banner"` sur `<application>`
- [x] **TV Banner (320Ã—180)** : `android/app/src/main/res/drawable/tv_banner.xml` (vector drawable scalable)

### PrioritÃ© 2 : Safe Area / Overscan (CRITICAL â€” contenu coupÃ© aux bords)
- [x] **TvSafeArea widget** (`lib/core/widgets/tv_safe_area.dart`) : minimum `EdgeInsets.symmetric(horizontal: 48, vertical: 27)` pour overscan 5-10%
- [x] **AppliquÃ© aux Ã©crans principaux** : Home, Live TV, VOD, SÃ©ries, Replay, EPG, Search, Settings, Advanced Settings

### PrioritÃ© 3 : Navigation D-pad / Focus System (HIGH)
- [x] **TvFocus** existant : glow + scale + border + haptique + clÃ©s OK/Enter/Space/GamepadA
- [x] **CategoriesRail** : `_FocusableCategoryTile` avec `Focus` + `onKeyEvent` (Enter = select)
- [x] **ProfileEditScreen** : chips focales (`_ProfileChoiceChip`), SegmentedButton, "Suivant" button accessible D-pad
- [x] **PlayerScreen** : `_onKeyEvent` gÃ¨re flÃ¨ches (zapping), Space (play/pause), Escape (footer)
- [~] **EPG Grid** : CustomPainter sans FocusNode par cellule â€” **nÃ©cessite refactor majeur** pour D-pad left/right entre programmes
- [~] **SearchScreen** : SearchAnchor/TextField pas TV-ready â€” IME options, conditional keyboard, SearchManager manquant
- [~] **UnifiedSettingsScreen** : TabBar, DropdownButton, ListTile pas focus-wrappÃ©s â€” navigation D-pad limitÃ©e

### PrioritÃ© 4 : Audio Focus / MediaSession (MEDIUM)
- [ ] **MediaSessionCompat + MediaButtonReceiver** Android natif pour contrÃ´les tÃ©lÃ©commande (play/pause/next/prev)
- [ ] **AudioAttributes** explicites (USAGE_MEDIA, CONTENT_TYPE_MOVIE)
- [ ] Bridge Flutter â†” MediaSession via platform channel

### PrioritÃ© 5 : Tests TV (LOW)
- [ ] `integration_test/tv_navigation_test.dart` : scÃ©narios navigation complÃ¨te, lecture, zapping, recherche, profil

### Ã‰tat actuel
- `flutter analyze lib` â†’ 0 erreur, 0 warning (hors infos prÃ©existantes EPG)
- `flutter test` â†’ **966 tests passed**
- `dart run tool/check_i18n_sync.dart` â†’ 428 messages, 0 problÃ¨me sur 6 locales
- Build release installÃ© sur S20 (mode TV forcÃ© via rÃ©glages avancÃ©s)

**Prochaines Ã©tapes prioritaires** : EPG Grid D-pad refactor + SearchScreen TV delegate + MediaSession bridge.

---

## 2 sexies. Chantiers du 17/10 â€” synopsis, aperÃ§u EPG, menus RÃ©glages

- [x] **Synopsis traduit affichÃ© en ROUGE (film ET sÃ©rie)** â€” *Demande (17/10)* : Â« pour le synopsis, si traduction, affichage du texte en rouge Â», Â« valable pour film et sÃ©rie Ã©videmment Â».
      `TranslatedSynopsisView` (partagÃ© par `movie_detail_screen` et `series_detail_screen`) colorait le texte en `onSurfaceVariant` quelle que soit la source. Le texte passe dÃ©sormais en `Colors.redAccent` dÃ¨s que `resolved.isTranslated` (synopsis TMDB fr **ou** traduction automatique Google) ; la source du traducteur reste affichÃ©e sous le texte. Couleur exposÃ©e en `TranslatedSynopsisView.translatedTextColor`. Tests : `test/widget/translated_synopsis_view_test.dart` (3, dont 2 Ã©chouaient sans le rouge).
- [x] **AperÃ§u Live TV â€” 7 programmes EPG au lieu de 5** â€” *Demande (17/10)* : Â« augmenter le nombre de programmes valides en validant 2 lignes de plus Â».
      `_EpgList._maxPrograms` (5) remplacÃ© par l'appel Ã  `epgPreviewPrograms(programs, now)` (`lib/core/utils/epg_lookup.dart`) avec `kEpgPreviewMaxPrograms = 7`. La sÃ©lection quitte le widget pour devenir testable. Tests : `test/unit/epg_preview_programs_test.dart` (6, dont 1 Ã©chouait avec l'ancienne limite de 5).
- [x] **RÃ©glages â€” fusion des menus (RÃ©seau + SÃ©curitÃ© / Lecteur + Audio)** â€” *Demande (17/10)* : Â« fusionner les menus RÃ©seau + SÃ©curitÃ© / Lecteur vidÃ©o + Audio, avec un sÃ©parateur en sous-titre distinctif pour bien diffÃ©rencier les 2 Â».
      Barre d'onglets ramenÃ©e de 6 Ã  4 : **Compte Â· Â« RÃ©seau & SÃ©curitÃ© Â» Â· Â« Lecteur & Audio Â» Â· AvancÃ©**. Nouveau widget `SettingsGroupDivider` (`lib/features/settings/widgets/settings_widgets.dart`) : libellÃ© cyan (`tertiary`) en majuscules espacÃ©es, encadrÃ© de deux traits, qui marque la frontiÃ¨re entre les deux anciens menus dans chaque onglet fusionnÃ©. Les noms d'onglets sont la concatÃ©nation des libellÃ©s existants â†’ correct dans les 6 langues sans nouvelle clÃ© l10n. VÃ©rif : suite complÃ¨te **966 verts**, `flutter analyze` sans erreur.
- [~] **Bug d'affichage Â« Moteurs de lecture Â» (Ã©cran gris)** â€” *investigation* en cours (agent externe, lecture seule). Le fix FocusNode du 16/10 (`6c6a923`) couvre le double usage du `FocusNode` ; la cause exacte de l'Ã©cran gris reste Ã  confirmer, faute de device connectÃ©.

---

## 2 ter. Garde-fou TV et grilles portrait (17/10)

- [x] **DÃ©tection TV multi-mÃ©thodes** (`lib/core/utils/device_info.dart`) â€” `DeviceInfoUtils.detectDeviceType()` combine : â‘  feature `android.software.leanback` (packaging), â‘¡ taille d'Ã©cran (`shortestSide >= 720dp`), â‘¢ UI mode. Retourne `DeviceDetectionResult` avec `isTv`, `confidence` (0-1) et `details`. Fallback synchrone `isTvFromContext()` pour le `build()`.
- [x] **Provider centralisÃ© `TvModeController`** (`lib/providers/tv_mode_provider.dart`) â€” `ChangeNotifier` unique avec `enabled`, `autoDetected`, `detectionResult`. `enable()`/`disable()`/`setEnabled()` pour activation manuelle (premiÃ¨re pression D-pad). `updateFromDetection()` pour auto-dÃ©tection au dÃ©marrage. `tvModeControllerProvider` + `tvModeProvider` (boolÃ©en).
- [x] **Adaptation `TvFocus`/`TvSafeArea`** (`lib/core/widgets/tv_focus.dart`, `tv_safe_area.dart`) â€” `TvModeNotifier` wrapper rÃ©trocompatible dÃ©lÃ¨gue au controller centralisÃ©. `TvFocus` et `TvSafeArea` lisent `tvModeNotifierProvider` (qui watch le controller). Aucun changement d'API.
- [x] **IntÃ©gration dÃ©tection auto au dÃ©marrage** â€” `main.dart` appelle `DeviceInfoUtils.detectDeviceType()` et `controller.updateFromDetection()` avant `runApp()`. Le mode TV s'active automatiquement si leanback dÃ©tectÃ©.
- [x] **Adaptation `SearchScreen`** (`lib/features/search/search_screen.dart`) â€” Utilise `tvModeControllerProvider` au lieu de l'ancien `tvModeNotifierProvider`. `initState` lit le controller, `dispose` nettoie correctement.
- [x] **Tests TvSafeArea/TvFocus** â€” `test/widget/tv_safe_area_test.dart` et `test/widget/tv_focus_test.dart` ajoutÃ©s par l'agent.
- [x] **Grilles films/sÃ©ries 2 colonnes en portrait** (`vod_screen.dart`, `series_screen.dart`) â€” `maxCrossAxisExtent: 200` â†’ `140`, `childAspectRatio: 0.55/0.62` â†’ `0.65`. En portrait (~360dp), 2 colonnes au lieu de 1. Commit `8308a23`.
- [x] **Nettoyage imports inutiles** (`providers.dart`) â€” Suppression de `tv_mode_provider.dart` et `device_info.dart` (inutiles dans ce fichier). Commit `14c9bcc`.

---

## 3. Chantiers en cours (issus du plan prÃ©cÃ©dent)

- [x] **P1 â€” RafraÃ®chissement Ã  la demande** (`RefreshStepsController` / `RefreshProgressView` / `showRefreshProgress`) : implÃ©mentÃ© â€” **reste Ã  valider sur device** (dÃ©marrage pÃ©rimÃ© + changement d'abonnement).
- [x] **P3 â€” Sous-titres intÃ©grÃ©s** : cause racine confirmÃ©e â€” `subtitleControllerProvider` Ã©tait **non autoDispose** â‡’ contrÃ´leur app-scoped, `_activeTrack` contaminait le contenu suivant. Restreint (dÃ©cision utilisateur) Ã  la **rÃ©initialisation de `_activeTrack` entre deux contenus** : `SubtitleController.resetForNewContent()` appelÃ© Ã  l'init de la `PlayerScreen` et dans `_switchTo` (zapping). Test fails-first dans `embedded_subtitle_controller_test.dart` (16 verts).
- ~~[ ] **P4b â€” RÃ©serve de cache froid**~~ â€” **AbandonnÃ© (dÃ©cision utilisateur, 13/10)** : jamais dÃ©fini nulle part (pas de cahier des charges), aucun livrable attendu.
- [x] **P6 â€” Hive `json_retyping`** : dÃ©faut de retypage des maps relues aprÃ¨s `Hive.close()` + rÃ©ouverture. `deepRetypeMap` appliquÃ© aux lectures de `StorageService` (`getProfiles`/`getPreferences`) et au cache OMDB. Test fails-first : `storage_service_retyping_test.dart` (round-trip Hive close/rÃ©ouverture, 11 verts).

## 4. ReportÃ© (audit `docs/audit-complet-2026-10-12.md`)

- [x] **S1** â€” Migration `flutter_secure_storage` â€” **COMPLÃˆTE (dÃ©cision utilisateur : tout migrer)** : abstraction `SecretStore` (Keystore RSA OAEP + AES-GCM, `InMemorySecretStore` pour tests injectÃ© via `test/flutter_test_config.dart`). Cinq familles migrÃ©es : â‘  PIN parental (Hive â†’ coffre, `_migrateLegacySecrets`), â‘¡ mot de passe OpenSubtitles (prefs â†’ coffre, l'identifiant â€” non sensible â€” reste en prefs), â‘¢ clÃ© API OpenSubtitles (prefs â†’ coffre, sanitise conservÃ©), â‘£ override clÃ© API TMDB (prefs â†’ coffre), â‘¤ **mot de passe Xtream des abonnements (Hive â†’ coffre, keyÃ© par id)** : cache mÃ©moire pour les lecteurs synchrones (`getActiveSubscriptionSync`), hydratation aux lectures, nettoyage Ã  la suppression, migration au premier `init()`. Tests : `parental_pin_migration_test`, `subscription_password_migration_test`, stores adaptÃ©s + tests de migration legacy. Suite complÃ¨te : **861 verts**, `dart analyze` 0.
- [x] **S2** â€” Signature release + `proguard-rules.pro` (+ rÃ¨gles R8 si sÃ©rialisation impactÃ©e) : keystore neuf PKCS12 `upload-keystore.jks` + `key.properties` gitignorÃ©s, `signingConfigs.release`, rÃ¨gles keep media3/videoplayer, `minifyEnabled`/`shrinkResources` actifs. **Build release validÃ© (13/10)** : `âˆš Built build\app\outputs\flutter-apk\app-release.apk (71,4 Mo)`, installÃ© sur le S20 sans crash R8.
- [x] **armeabi-v7a** â€” **DÃ©cision prise (13/10)** : conserver tel quel (arm64-v8a + x86_64).

## 5. HygiÃ¨ne dÃ©pÃ´t

- [x] **Commits** : 19 commits atomiques rÃ©alisÃ©s le 14/10, couvrant tout le reliquat (config, docs, l10n, sÃ©curitÃ©/SecretStore, stockage Hive, OpenSubtitles, sous-titres + fork media3, tri/affinitÃ©, EPG, replay `archiveDays`, dÃ©marrage/rafraÃ®chissement, connectivitÃ©, synopsis, mÃ©tadonnÃ©es, matchmaking, bouton hamburger, avatars, UI, style). Arbre de travail propre ; suite complÃ¨te verte (906 tests) et build release installÃ© sur le S20.
[~] Sous-titre désactivé non acquis   TranslatedSynopsisView s'affiche indépendamment de subtitleController.disable()   fix suggéré : coupler avec subtitleControllerProvider ou cacher dans player_screen quand sous-titre off

