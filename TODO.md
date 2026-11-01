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

## À vérifier / à faire (non validé à l'exécution)
- [ ] Saisons déplacées sous les onglets Audio/Sous-titres (UI non vérifiée sur device).
- [ ] Carrousel multi-acteurs (cast) : affichage réel non vérifié.
- [ ] Mots-clés (keywords) : affichage réel non vérifié.
- [ ] Masquage du mot de passe dans le formulaire d'abonnement : non vérifié visuellement.
- [ ] D-pad dans le dialogue d'abonnement : navigation par flèches entre champs (haut/bas) non testée sur device (seule l'activation Entrée/DPAD_CENTER a été vérifiée).
- [ ] Abonnements M3U : `fetchM3uParseResult()` utilise `sub['m3uUrl']!` — non validé sur un abonnement M3U réel (l'utilisateur est en Xtream).
- [ ] `flutter analyze` : 27 issues préexistantes (warnings `unused_element`, `require_trailing_commas`, `prefer_const_constructors`, `deprecated_member_use` dans `test/unit/*`, `test/widget/*`, `test/widgets/tv_focus_test.dart`) — hors périmètre, à nettoyer.
- [ ] Tests `test/tv_focus_chaining_test.dart` : le test "le bouton interne focalisé s'active aussi" est à revoir (Tab ne tombe pas sur le bouton interne dans la composition testée).
- [ ] Nettoyer les logs de build temporaires (déjà supprimés du dépôt).
- [ ] Vérifier le carrousel de films similaires (`localSimilarMoviesProvider`) sur device.
- [ ] Vérifier la migration des données après `adb install -r` (pas de régression).
- [ ] **NOUVEAU** Focus carrousel home : seuls "Chaînes" et "Films" atteignables — corrigé (TvFocus unique + flèches gauche/droite). À valider sur device.
- [ ] **NOUVEAU** Grille programmes : halo se multiplie + ouverture poster agrandi au focus — à investiguer (écran précis ? EPG ? VOD ? Séries ?).
- [ ] **NOUVEAU** Auto-détection taille écran pour adapter l'affichage général (responsive TV) — à étudier.
- [ ] **NOUVEAU** D-pad section hamburger/menu gauche (settings) ne fonctionne pas correctement — à investiguer.

## Décisions / points d'attention
- Toujours installer via `adb install -r` (préserver les données) ; uninstall uniquement sur demande explicite.
- Flutter à utiliser : FVM 3.47.2 (`$env:USERPROFILE\fvm\versions\3.47.2\bin\flutter.bat`) ; le Flutter global 3.50.0-0.2.pre (beta) casse le build.
- Diagnostic autonome : `logcat -c` → `am force-stop orbit.app` → `am start -n …` → `Start-Sleep` → `logcat -d > fichier` (le streaming `logcat` bloque et dépasse le timeout). Les logs applicatifs apparaissent sous `I OrbitDiag:` et `I flutter : Orbit3D [INFO]`.
- Dernier commit avant cette session : `67a4338`.
