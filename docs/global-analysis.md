# Analyse globale — « Orbit 3D » (application IPTV Flutter)

**Périmètre** : audit statique du dépôt complet (`lib/`, `test/`, `android/`, `.github/`, `docs/`), exécution de `flutter analyze`, exploration de `git log`. Aucun fichier n'a été modifié. Les faits sont marqués « ✅ Vérifié » (lecture directe du code, de l'historique git ou de la sortie d'outils) ; le reste est signalé comme hypothèse.

## 1 - Verdict d'ensemble

Application de type Xtream/M3U/Radio fonctionnelle, architecture Riverpod + go_router correctement structurée (**~8 800 LOC** dans **73 fichiers Dart**, `lib/`). Aucune erreur ni warning d'analyse statique. En revanche :

- **Fuite active d'identifiants de serveur** dans le code suivi par git : `test/unit/series_info_parse_test.dart:34` (`https://draap.online/169503400638842/1593574628/$id`) ;
- **Fuites historiques** non purgées dans `.github/workflows/publish-beta.yml` (commits `f0f80a1`, `eeb5d69`) ;
- **Clé Admin Firebase présente sur disque** (racine du dépôt, gitignorée mais réelle) ;
- **Cache EPG jamais invalidé** lors d'un changement de serveur (`subscriptions_screen.dart:73-77`) ;
- **Images jamais mises en cache** (`Image.network` × 4) alors que `cached_network_image` est déclaré et inutilisé ;
- **275 infos `flutter analyze`** : 178 `always_use_package_imports`, 47 `require_trailing_commas`, 46 `deprecated_member_use` (`withOpacity`), 4 divers (**0 erreur, 0 warning**).

## 2 - Architecture

- **Bootstrap séquentiel** : `lib/main.dart:40-89` — chargement `.env`, `Hive.initFlutter`, enregistrement d'adaptateurs (49-51), `initializeDateFormatting('fr_FR')` (52-53), puis une suite d'`await` qui bloquent le rendu avant `runApp` : boîtes Hive, `FavoritesService`, `HistoryService`, `NotificationService` (FCM + Firebase), migration depuis SharedPreferences, restauration du profil. ✅
- **Navigation** : `go_router` 15.1.2, `GoRouter` construit en `main.dart:103-179` ; `ShellRoute` → `HomeShell` (`lib/features/home_shell.dart:152`) ; les paramètres de lecture sont transmis par `state.extra` `PlayerRouteData` (route `/player`, `main.dart:123-136`).
- **Couches** : `lib/features/` (un dossier par écran), `lib/core/` (theme, constantes, widgets, utils), `lib/models/`, `lib/providers/`, `lib/services/`, `lib/player/`, `lib/database/`.
- **État, Riverpod pur** (2.6.1) :
  - `FutureProvider` simples : `liveChannelsProvider` (`providers.dart:38-41`), `moviesProvider` (43-46), `seriesProvider` (48-51), `radioChannelsProvider` (58-61), `replaysProvider` (63-66) ;
  - `FutureProvider.family` : `seriesInfoProvider` (53-56), `channelEpgProvider` (109-122), `aiRecommendationsProvider` (149-160) ;
  - `AsyncNotifierProvider` : `epgProgramsProvider` (68-71) + notifier `EPGProgramsNotifier` (124-147) ;
  - `StateNotifierProvider` : `SubscriptionsNotifier` (`subscription_provider.dart`), `PreferencesNotifier` (`preferences_provider.dart:6`) ;
  - `StateProvider` : `currentProfileProvider` (`providers.dart:31`).
- **Double source de vérité** sur les services : fournis par `providers.dart:21-29` **et** instanciés en dur ailleurs (`ApiService()` dans `subscription_provider.dart:94`, `SubscriptionManager()` dans `api_service.dart:30` et `home_shell.dart:11`). ✅
- `sourceTypeProvider` est défini **dans un fichier d'écran** (`home_shell.dart:10-13`), pas dans `lib/providers/`.

## 3 - Structure & cohérence du code

- **Fichiers fantômes** (1 ligne de commentaire, rien n'y est importé) : `lib/services/services.dart:1`, `lib/player/player.dart:1`, `lib/database/database.dart:1`. `ARCHITECTURE.md` (2 lignes) promet encore un couplage « Flutter + Rust FFI » alors que le code Rust a été archivé dans `archive/` (commit `3ec2c5b`).
- **Provider dupliqué** : `aiServiceProvider` déclaré 2 fois — `providers.dart:23` **et** `lib/providers/ai_provider.dart:4` (jamais importé → mort). ✅
- **Symboles morts** (Vérifié par `git grep`) :
  - `subscriptionsStreamProvider` (`subscription_provider.dart:155-159`) jamais écouté ;
  - classe `TestResult` (`subscription.dart:200-216`) jamais instanciée — `testConnection` n'écrit qu'un enum `TestResultStatus` (`subscription_provider.dart:111-123`) ;
  - `FavoritesService.addFavorite/removeFavorite/isFavorite` (`favorites_service.dart:10-23`) jamais appelés : l'écran Favoris est un simple affichage, rien ne peut y être ajouté ;
  - `HistoryService.addEntry` (`history_service.dart:10-14`) jamais appelée → historique vide par construction ;
  - token FCM débuggé mais **jamais stocké nulle part** (`notification_service.dart:33,39`, `_storeToken` vide).
- **Logique dupliquée** : `buildXtreamTestUrl` (`subscription_provider.dart:130-138`) reproduit `_playerApiUrl` (`api_service.dart:338-342`) ; `_refererFor` dupliqué (`live_tv_screen.dart:16-19` / `player_screen.dart:96-99`) ; listes de User-Agent dupliquées (`live_tv_screen.dart:21-29`, `player_screen.dart:16-24` puis 50-54, 163-166, 341-344).
- **Encodage corrompu** : caractères U+FFFD réels dans plusieurs fichiers sources : `main.dart:42,46`, `subscriptions_screen.dart:71,116,367-369,445-446,482`, `player_screen.dart:57`, `api_service.dart:143`. ✅
- **Nommage** : `lib/features/` comme « couche » ; `data_providers.dart` n'est qu'un re-export hérité (seul `search_screen.dart:3` l'importe).

## 4 - Dépendances

Résolues dans `pubspec.lock` : dio 5.11.0, hive 2.2.3, hive_flutter 1.1.0, flutter_riverpod 2.6.1, go_router 15.1.2, video_player 2.9.5, just_audio 0.9.44, intl 0.20.2, uuid 4.6.0, xml 6.5.0, flutter_local_notifications 19.5.0, firebase_core 3.15.2, firebase_messaging 15.2.10. ✅

**Déclarées mais 0 import dans `lib/`** (Vérifié par grep) :
- `provider` 6.1.5+1 et `logger` 2.7.0 (remplacés par Riverpod et `LoggerService` maison dans `core/utils/error_handler.dart`) ;
- `package_info_plus`, `cupertino_icons` ;
- `cached_network_image` 3.4.0 — **le plus dommageable** : les images sont chargées en `Image.network` brut dans `media_card.dart:44`, `channel_tile.dart:108`, `profile_avatar.dart:90`, `series_detail_screen.dart:112`.

**Incohérence d'environnement** : `.fvmrc` épingle Flutter **3.24.5** tandis que la CI installe **3.47.2** (`dart.yml:26`) ; `flutter_lints` reste en `^3.0.1` (v6 disponible). ✅

## 5 - Dette technique & fragilités

- **Erreurs hétérogènes** : `StreamNetworkException` (`api_service.dart:11-20`), `StreamUrlEmptyException` (`stream_helpers.dart:1-8`), `Exception` nues (« Aucun abonnement configuré », `api_service.dart:143`), `UnimplementedError` pour les modes M3U (`api_service.dart:168,186,192,270,304`), `StreamAiException` (`providers.dart:162-169`). L'UI aplatit tout en un message générique via `userFriendlyError` (`user_friendly_error.dart:4-9`).
- **Retries/timeouts éparpillés** : options dio (`api_service.dart:23-29`), `retryStream` (`stream_helpers.dart:34-54`), rebouclage EPG (`providers.dart:129-132`), boucle propre dans `ai_service.dart`, rotation User-Agent du player (`player_screen.dart`).
- **Hive peu typé** : profils/préférences/favoris/historique stockés en `Map`/`String` (`storage_service.dart:13-17`, `whereType<Map>()` 26-29) alors qu'un adapter généré existe pour `Subscription` (`subscription.g.dart`, typeId 3, enregistré `main.dart:49-51`). PIN parental stocké en clair (`storage_service.dart:54-67`).
- **EPG** : pull XMLTV complet + cache 30 min en mémoire (`EPGDataCache`, `providers.dart:75-102`) ; `channelEpgProvider` re-filtre toute la liste par chaîne (117-120). **Bogue confirmé** : `subscriptions_screen.dart:73-77` invalide les providers de données mais **ni `epgProgramsProvider` (68-71) ni `epgDataCacheProvider` (104)** → guide périmé après changement de compte pendant toute la TTL. `home_screen.dart` `_refreshAll` (133-148) invalide le provider mais pas le cache → le « rafraîchissement » ne rafraîchit pas l'EPG. ✅
- **Contrôle parental** : `ageRestriction`/PEGI est stocké (`models/user_profile.dart`) mais **jamais appliqué** à la lecture des contenus (l'écran `parental_control_screen.dart` ne fait que sauvegarder).

## 6 - Performance & UX

- **Démarrage à froid** : séquence d'`await` séquentielle bloquante dont `NotificationService.init` (Firebase.initializeApp + `getToken` réseau, `notification_service.dart:33`) — le réseau est sur le chemin critique avant le premier frame.
- **Listes** : `LiveTvScreen` utilise `ListView.builder` (`live_tv_screen.dart:48`), VOD/séries des `GridView.builder`/`SliverGrid.builder` — **rendu virtualisé ✅** mais la liste complète (~13 000 chaînes, estimation fournie) est matérialisée et regroupée/triée en mémoire à chaque (re)build (`channel_groups.dart:21-33`, `buildLiveChannelGroups` = O(n·log n)).
- **Images** : aucun cache (voir § 4) → sur 13 000 logos, chaque scroll ou ré-ouverture re-fetch réseau.
- **EPG** : guide complet en RAM + filtrage par chaîne à chaque lecture.
- **Prewarm** (bonne pratique, à conserver) : pool de 2 `VideoPlayerController` (`stream_prewarm_service.dart:14`) + pré-chargement de la chaîne voisine (`player_screen.dart`).
- **Home** : `PageView` animé avec `Transform`/`Matrix4` par page (`home_screen.dart:167-195`) — risque de micro-jank sur TV bas de gamme (hypothèse, non mesuré).

## 7 - Sécurité

- **Fuite active (P0)** : `test/unit/series_info_parse_test.dart:34` contient des identifiants réels du compte `draap.online` (`169503400638842` / `1593574628`). Fichier **suivi par git** → exposé publiquement dès le push. ✅
- **Fuites dans l'historique git** : `.github/workflows/publish-beta.yml` commit `f0f80a1` (`http://sofia.rabaden.eu:80/get.php?username=LzoLGMw2GkPxzN&password=S8TbVmPyUB3sjx&type=m3u_plus...`) et commit `eeb5d69` (`https://draap.online/get.php?username=169503400638842&password=1593574628...`). Le HEAD (`f1f791f`) utilise désormais `secrets.BETA_*` + inputs ✅ — mais l'historique n'est pas purgé et les comptes n'ont pas été révoqués. ✅
- **Clé Admin Firebase** : `orbit-3d-8264d-firebase-adminsdk-fbsvc-a83639078a.json` présente à la racine du dépôt ; gitignorée (`gitignore:29`, jamais suivie — Vérifié `git ls-files` et `git log`) mais il s'agit d'une **clé de service administrateur active sur le disque**.
- `android/app/google-services.json` est **suivi** (projet `orbit-3d-8264d`, API key `AIzaSyDqPeWznoX2ITnTrHcBmnWhmAB3tNGnwts`).
- `android/app/src/main/AndroidManifest.xml:9` : `android:usesCleartextTraffic="true"` (HTTP autorisé — souvent nécessaire pour les fournisseurs TPV/Xtream, mais à documenter).
- **Données au repos** : mots de passe Xtream en clair dans Hive (`subscription.dart`, champ `@HiveField(5)`), PIN parental en clair, profils (naissance, genres) non chiffrés. Pas de `flutter_secure_storage`.

## 8 - Tests & CI

- **8 fichiers de tests, 31 tests unitaires** (comptés sur `test\()`) : API/URL Xtream ×9 (`api_service_test.dart`), dates XMLTV ×5, migration SharedPreferences→Hive ×4, modèle Series ×4, connexion abonnement ×3, constantes ×4, profil ×1, parse `series_info` ×1. `docs/test-analysis.md` annonce **22** → document périmé, à régénérer. ✅
- **0 test widget**, et aucune couverture pour : lecture, écran/anneau EPG (`_OrbitPainter`), grilles, navigation, verrou parental, prewarm.
- **Fiabilité** : `stream_helpers_test` dépend de `toLocal()` → non déterministe selon la timezone de la machine ; la fixture `test/fixtures/series2.json` est une réponse réelle.
- **CI** : `dart.yml` (analyze `--no-fatal-infos` + unit tests + `build apk` sur Flutter 3.47.2), `publish-beta.yml` (secrets), `phase-tracking.yml`, `setup-labels.yml`, `triage.yaml`. Aucun gate ne bloque les 275 infos.

## 9 - Plan d'action priorisé

**P0 — Sécurité & intégrité des données (immédiat)**
1. **`test/unit/series_info_parse_test.dart:34`** : remplacer l'URL par un placeholder et **révoquer le compte `draap.online`**. Bénéfice : fin de la fuite active du dépôt.
2. **Purger l'historique git** (`git filter-repo`) des commits `f0f80a1`/`eeb5d69` **et** invalider les deux fournisseurs Xtream (sofia.rabaden.eu, draap.online) + rotation des credentials. Bénéfice : expositions historiques éliminées.
3. **Supprimer la clé Admin Firebase** du disque (ou la déplacer hors du dépôt, ex. dossier secret CI). Bénéfice : réduction du rayon d'explosion.
4. **Corriger l'invalidation EPG** : dans `subscriptions_screen.dart:73-77` et `home_screen.dart:133-148`, ajouter `ref.invalidate(epgDataCacheProvider); ref.invalidate(epgProgramsProvider);`. Bénéfice : le guide reflète le serveur actif.

**P1 — Court terme (dette & confort)**
5. **Activer `cached_network_image`** sur les 4 `Image.network` (`media_card.dart:44`, `channel_tile.dart:108`, `profile_avatar.dart:90`, `series_detail_screen.dart:112`). Bénéfice : scroll fluide sur ~13 000 logos, zéro re-téléchargement.
6. **Nettoyer l'analyzer** (275 → 0 infos : imports paquet, trailing commas, `withOpacity` → `withValues`) et activer `--fatal-infos` en CI. Bénéfice : garde-fous automatiques.
7. **Supprimer fichiers fantômes et symboles morts** (`services.dart`, `player.dart`, `database.dart`, `ai_provider.dart`, `subscriptionsStreamProvider`, `TestResult`, dépendances inutilisées `provider`/`logger`/`package_info_plus`/`cupertino_icons`). Bénéfice : −kLOC de lecteurs trompeurs.
8. **Ré-encoder en UTF-8** les fichiers corrompus (`main.dart`, `subscriptions_screen.dart`, `player_screen.dart`, `api_service.dart:143`). Bénéfice : fin des caractères parasites.
9. **Sortir FCM du chemin critique** : `NotificationService.init` post-premier-frame ou lazy + non-dégradant si échec. Bénéfice : démarrage plus rapide.
10. **Brancher ou retirer Favoris/Historique** (appeler `addFavorite`/`addEntry` depuis l'UI). Bénéfice : pas d'écrans factices.

**P2 — Structure**
11. **Centraliser les providers** (`sourceTypeProvider` → `providers/`, un seul `aiServiceProvider`) et router toutes les instanciations par l'« injecteur » Riverpod (fini `new ApiService()`/`new SubscriptionManager()`/`new StorageService()` : `api_service.dart:30`, `subscription_manager.dart:22-23,42-43,60-61,70-71`, `home_shell.dart:11`). Bénéfice : testabilité, source unique de vérité.
12. **Factoriser la connectique streaming** (`_playerApiUrl`, `buildXtreamTestUrl`, `_refererFor`, User-Agents) dans `stream_helpers.dart` testé. Bénéfice : moins de copier-coller.
13. **Fractionner l'EPG** (endpoint par chaîne ou index lazy au lieu du pull XMLTV complet en RAM). Bénéfice : mémoire maîtrisée sur grand guide.
14. **Uniformiser les erreurs** (type canonic + mapping UI unique ; supprimer `Exception` nue et les `UnimplementedError` M3U). Bénéfice : messages utilisateur cohérents, navigation M3U non trompeuse.
15. **Verrou parental effectif** (gate de lecture exploitant le PEGI stocké) + PIN protégé (`flutter_secure_storage`). Bénéfice : contrôle parental réel.
16. **Aligner `.fvmrc` ↔ CI** (3.47.2), monter `flutter_lints` ^6, régénérer `docs/test-analysis.md` (31 tests).

## 10 - Chiffres clés

| Indicateur | Valeur |
|---|---|
| LOC `lib/` / fichiers Dart | ~8 800 / 73 |
| Analyse statique | 0 erreur, 0 warning, 275 infos (178 + 47 + 46 + 4) |
| Tests unitaires / widget | 31 (8 fichiers) / 0 |
| Dépendances mortes | 5 (`provider`, `logger`, `package_info_plus`, `cupertino_icons`, `cached_network_image`) |
| Symboles/fichiers morts | ≥ 7 (3 stubs, `ai_provider.dart`, `subscriptionsStreamProvider`, `TestResult`, token FCM non stocké) |
| Identifiants exposés | 2 comptes Xtream (1 actif en test, 1 dans l'historique git), 1 clé Admin Firebase sur disque, 1 API key `google-services.json` suivie |