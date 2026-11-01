# Orbit IPTV — Todo list (01/11/2026)

## Vérifié à l'exécution (OK)
- [x] Films VOD : catalogue chargé (100 109 films, 0 ignoré) — cause racine `Actor.listFromDynamic` retournait une liste non modifiable → `UnsupportedError` sur chaque entrée. Corrigé (`List<Actor>.of(fallback)` + garde `length > 1` sur les tris). Test de régression `test/movie_from_map_test.dart` (4/4 verts).
- [x] Fiche film (`MovieDetail`) : affichage correct après le fix.
- [x] `api_service.dart` : import `StreamUrlEmptyException` ajouté (`show …`), build release OK.
- [x] AppBar "Films VOD" (compteur temporaire retiré).
- [x] D-pad / TvFocus : chaînage `onKeyEvent` → `_handleKeyEvent` → `onActivate` (test `test/tv_focus_chaining_test.dart`, 3/3 verts).
- [x] Abonnements : masquage des identifiants/mot de passe dans les sous-titres (`_redactCredentials`).
- [x] D-pad sur l'écran d'abonnements : Entrée/DPAD_CENTER activent "Annuler"/"Ajouter" (vérifié sur S20 via `adb input keyevent`).
- [x] D-pad sur la sélection de profil : flèche droite → "Créer un nouveau profil", Entrée ouvre le formulaire.
- [x] Build release OK (`flutter build apk --release`, EXIT=0), APK copié sur `E:\OrbitIPTV\app-release.apk`.
- [x] Suite ciblée : `flutter test test/movie_from_map_test.dart test/tv_focus_chaining_test.dart` → 7/7 verts.

## À vérifier / à faire (TV principalement)

### Focus / D-pad (TV)
- [x] Carrousel home : TvFocus unique + flèches gauche/droite + halo sur index focalisé (commit `17f900c`-adjacent).
- [x] Grilles VOD, Séries, Live TV, Browse : `OrderedTraversalPolicy` → `ReadingOrderTraversalPolicy` (évite les halos multiples).
- [x] Hamburger (drawer) + Réglages : `OrderedTraversalPolicy` → `ReadingOrderTraversalPolicy`.
- [ ] Valider sur device : carrousel (toutes les tuiles atteignables), grilles (un seul halo), hamburger (navigation films/séries/etc.).
- [ ] Navigation par flèches entre champs du dialogue d'abonnement (haut/bas) — non testée.
- [ ] Halo / scale : vérifier que le scale 1.20 de TvFocus ne déborde pas de la grille (poster « plus grand »).

### Démarrage / performance (TV)
- [x] Cache-first : skip splash, auto-refresh si stale (>30 min).
- [x] Impeller activé (`EnableImpeller=true`).
- [x] Timeout EPG 30s (évite blocage infini).
- [x] Délai splash 1500→300ms.
- [ ] Baseline Profiles (démarrage jusqu'à -30%) — à générer.
- [ ] 16 KB page sizes (obligatoire août 2026 Play Store).
- [ ] Profiler sur device réel (`flutter run --profile`) pour identifier le goulot.

### Fonctionnel (TV)
- [ ] Auto-détection taille écran pour adapter l'affichage général (responsive TV).
- [ ] Vérifier saisons sous onglets Audio/Sous-titres.
- [ ] Vérifier carrousel cast multi-acteurs + mots-clés.
- [ ] Vérifier masquage mot de passe (formulaire abonnement).
- [ ] Abonnements M3U : `fetchM3uParseResult()` avec `sub['m3uUrl']!` — non validé sur abonnement réel.
- [ ] Carrousel films similaires (`localSimilarMoviesProvider`) sur device.

### Qualité code
- [ ] `flutter analyze` : 27 warnings préexistants à nettoyer.
- [ ] Test "bouton interne focalisé" (`tv_focus_chaining_test.dart`) à revoir.

## Décisions / points d'attention
- Toujours installer via `adb install -r` (préserver les données) ; uninstall uniquement sur demande explicite.
- Flutter à utiliser : FVM 3.47.2 (`$env:USERPROFILE\fvm\versions\3.47.2\bin\flutter.bat`) ; le Flutter global 3.50.0-0.2.pre (beta) casse le build.
- Diagnostic autonome : `logcat -c` → `am force-stop orbit.app` → `am start -n …` → `Start-Sleep` → `logcat -d > fichier` (le streaming `logcat` bloque et dépasse le timeout). Les logs applicatifs apparaissent sous `I OrbitDiag:` et `I flutter : Orbit3D [INFO]`.
- Dernier commit avant cette session : `67a4338`.

## Mise � jour responsive TV (session en cours)
- [x] Grilles responsive : VOD, S�ries, Live TV, Replay, Browse (6 cols TV)
- [x] Padding responsive : VOD, S�ries, Live TV, Browse, Favorites
- [x] Typographie responsive : Home (titre + carrousel)
- [x] 16 KB page sizes (NDK r28 + extractNativeLibs=false)
- [ ] Appliquer screenPadding � Home
- [ ] Appliquer titleMedium/bodyMedium aux titres de section (VOD, S�ries, Live TV, Settings)
- [ ] Int�grer TvKeyHandlerWrapper dans PlayerScreen
- [ ] Baseline Profiles (d�marrage -30%)

## Mise � jour responsive TV (suite)
- [x] Padding responsive : VOD, S�ries, Live TV, Browse, Favorites, Home
- [x] Typographie responsive : Home (titre + carrousel)
- [x] TvKeyHandlerWrapper int�gr� dans Home (play/pause ? item focalis�)
- [x] 16 KB page sizes (NDK r28)
- [ ] Appliquer titleMedium/bodyMedium aux titres de section (VOD, S�ries, Live TV, Settings)
- [ ] Int�grer TvKeyHandlerWrapper dans PlayerScreen (optionnel, player g�re d�j� les touches m�dia)
- [ ] Baseline Profiles (d�marrage -30%) � � g�n�rer
- [ ] V�rifications device (reconnecter S20)
