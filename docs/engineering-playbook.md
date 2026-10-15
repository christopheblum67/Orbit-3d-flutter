# Orbit IPTV — Playbook Ingénieurs (Amélioration continue)

> **Règle d'or :** chaque équipe lit ce playbook AVANT de commencer un nouveau chantier, et propose à la FIN de chaque sprint 1 nouvelle règle à ajouter (ce qu'elle a appris). Le playbook s'enrichit à chaque itération → chaque nouvel ingénieur démarre plus fort que le précédent.

## Règles non négociables
1. `provider` package **banni** : riverpod uniquement (`ref.read`/`ref.watch`, jamais `context.read<T>()`).
2. PowerShell : jamais `&&`, jamais `grep`/`sed`/`head` → `Select-String`, `Get-Content`.
3. Dépendances : vérifier `pubspec.yaml` avant tout nouvel import (pas de surprise).
4. Après toute série de modifications : `dart format <fichiers>` puis `flutter analyze` puis `flutter test` (50 tests).
5. Toute modification de widget garde un chemin de retour (`context.canPop() ? pop() : go('/home')`).
6. **Gestion d'erreurs robuste et détaillée — jamais d'écran muet.** Tout échec (flux, API, EPG, réseau) affiche une erreur HUMaine : cause, code HTTP/code interne, étape, action de remédiation (« Vérifiez votre abonnement, puis Réessayer »). Les `debugPrint` portent systématiquement `[feature] étape → cause` pour que le logcat soit exploitable en 5 min.
7. **Cas limites traités EXPLICITEMENT** (pas « ça ne devrait pas arriver ») : abonnement absent/expiré, URL de flux vide, hôte offline (socket timeout), 403/404/406, manifest HLS/DASH vide, chaîne retirée, données partiellement chargées → chaque cas a une branche de code et un état UI dédié.
8. **Présence continue d'un ingénieur du début à la fin** : l'agent qui lance un chantier le MÈNE À TERME (implémentation + tests + analyze + build + leçon écrite). Interdit de « compiler et passer à autre chose » : un chantier n'est clos que DoD respecté, vérifié par le coordinateur.
9. **Gain d'expérience x10** : chaque chantier dépose au moins 1 leçon réutilisable ; les leçons L1..L13 sont relues AVANT chaque nouveau chantier ; toute découverte (bug, contournement Cloudflare, spécificité panneau Xtream) alimente directement le playbook plutôt que la mémoire volatile d'un agent.

## Pièges connus (lecons apprises — LIRE AVANT LE CODE)
### L1. Parenthèses/accollades en cascade (cause n°1 des erreurs AI)
- Une parenthèse fermante manquante fait croire au parseur que les paramètres nommés suivants appartiennent au widget **du dessus** (ex: `body:` englobé dans `AppBar` → « The named parameter 'body' isn't defined »).
- **Corriger toujours en suivant l'ordre de fermeture LIFO**, enfants → parent, et vérifier `dart format` (échoue si déséquilibré) puis les erreurs d'analyzer.
- Ne jamais ajouter de fermetures « au pif » : compter les constructions ouvertes (parens, brackets, accolades) dans l'ordre.
### L2. Widgets imbriqués profonds
- Structurer d'abord l'arborescence sur papier (racine → children), fermer dans l'ordre exact inverse.
- Les listes `children: [` se ferment par `],` AVANT le `)` du widget parent.
### L3. Types `Map<dynamic, dynamic>`
- Après `is Map`, convertir explicitement : `Map<String, dynamic>.from(x)` sinon le type inféré (dynamic) casse les signatures.
### L4. Exports/imports relatifs
- Les erreurs « Target of URI doesn't exist » = export relatif (`export 'cast.dart'`) au lieu du package-path (`package:orbit_3d_flutter/models/cast.dart`). Toujours utiliser package-path.
### L5. Chaque fichier de feature qui importe un modèle/utilitaire doit déclarer son propre import (pas de transitif).
### L6. Vérifier sur le S20 après tout build (PB combiné: un écran ne se voit qu'au runtime).
### L7. Duplicate case en `switch` (ex: 'editing') = erreur compile. Centraliser les maps label/icône.

## Vérification type d'un sprint
1. `dart format lib/...` (0 fichier non formatable)
2. `flutter analyze` → 0 erreur
3. `flutter test` → 50/50
4. `flutter build apk --release` OK
5. Install S20 (si branché) + `git add -A; git commit; git push`

## Nouvelles lecons du sprint courant (à fusionner au prochain)
### L8. Animation d'entrée dans une carte qui change d'état (focus)
- `TweenAnimationBuilder` redémarre son animation si le widget est re-construit avec un nouvel objet `Tween` (comparaison par identité). Or une carte focusable re-build à chaque gain/perte de focus (`setState`).
- **Correct** : lancer l'animation UNE fois via un `AnimationController` créé dans `initState` + `Future.delayed(index * 60ms)` pour le stagger, piloté par `FadeTransition`/`ScaleTransition`. Les effets de focus passent par `AnimatedScale`/`AnimatedContainer` (indépendants de l'entrée).
- **Correct** : toujours vérifier par `grep` qu'un écran remplacé n'est importé par aucun autre fichier (ex: `profile_selection_screen` compilé mais orphelin = doublon de classe si réimporté).
### L9. Écran TV à nombreuses touches (numpad) : ne pas ré-implanter la navigation par flèches
- La traversée de focus par défaut (`FocusTraversalGroup`) gère déjà les flèches dans le sens de lecture ; on n'intercepte manuellement que `select`/`enter` (+ `backspace` pour effacer), et on soigne le retour haptique (`selectionClick` sur focus, `heavyImpact` sur activation).
- Toujours passer le contexte (mode `set`/`verify` + profil cible) par `extra` de route et ne faire `pop` qu'avec un résultat typé (**String** pour un PIN posé, **bool** pour une vérification) : le caller interprète le résultat et reset l'état (ex: `currentProfile = null`, `clear()` du notifier) en cas d'échec au lieu de le faire dans le pavé.
### L10. Proxy local : l'entrée ≠ l'URL réécrite (l'autorité, c'est le serveur)
- Un proxy ne connaît une URL que s'il l'a déjà obtenue puis enregistrée. La 1ʳᵉ requête depuis l'app ne peut PAS être `/hls/<hash>/...` (404) : le premier appel doit passer par l'**entrée** (`/proxy/hls?url=<manifest>` qui réécrit le manifest, enregistre les segments enfants, puis permet les réécrires), jamais par une URL réécrite « à froid ».
- Le hash calculé côté client (`buildProxyUrl`, miroir documentaire) sert à éviter de recalculer à chaque affichage, mais ce n'est **pas** l'autorité serveur : devant une incohérence hash/réécriture, c'est le registre du proxy qui prime.
- Code ajouté « en miroir » (Rust ↔ Dart) = contrat fragile : garder les deux côtés alignés, et n'autoriser le relais que vers l'hôte ciblé (liste blanche) pour ne jamais re-doubler un 127.0.0.1 déja relayé.
### L11. Le Cargo.toml ment : vérifier les deps croisées AVANT de déclarer "cohérent"
- Une dépendance non déclarée = échec `cargo check` (ex: `use url::Url;` dans 5 fichiers sans `url = "..."`). Après avoir écrit du Rust : **grep** des crates utilisés, croisement avec le Cargo.toml, vérifier qu'aucune target `[lib]` n'est déclarée sans `src/lib.rs`, et supprimer les deps mortes (ex: `bcrypt` dans un proxy) qui ajoutent du temps de build et de la confusion.
- Sans Cargo installé, la seule garantie est ce croisement statique. Ne jamais écrire « vérifié cohérent » quand on n'a pas pu compiler : dire « relecture statique faite, build à valider ».

## DEFINITION OF DONE (Obligatoire avant de déclarer un sprint "done")
- [ ] RUST : crates utilisés (grep `use crate_name`) croisés avec Cargo.toml ; aucune target `[lib]` sans fichier source ; deps mortes retirées ; mention explicite « build non exécutable ici » si pas de Cargo.
- [ ] DART : `dart format` sur les fichiers modifiés (échoue = parse error → PAS done).
- [ ] `flutter analyze` : 0 erreur introduite (diff avant/après, pas un simple "0 erreur" global).
- [ ] `flutter test` : le COUNT est annoncé AVANT et APRÈS (ex: 50 → 71) pour détecter les suites perdues/ajoutées.
- [ ] 1 leçon écrite EFFECTIVEMENT dans ce playbook (le fichier doit avoir été modifié).
- [ ] Vérification runtime sur écran réel quand applicable (pas seulement compile).

## SYSTEME DE NIVEAU (levelling des équipes — "Pokémon Lvl 1 → 99")
Le coordinateur calcule après chaque sprint, et affiche le niveau dans `docs/sprints-status.md` :
- **+XP** : sprint livré sans bug rattrapé au review (+40) · DoD intégral respecté (+20) · leçon qui évite une régression mesurable (+10) · test/bug capté avant le push (+10).
- **-XP** : bug qu'un check du DoD aurait attrapé (-15) · affirmation « vérifié » fausse (-25 : la confiance est la ressource la plus chère) · rework visible (-10).
- **Niveaux** : 1-9 Apprenti · 10-19 Confirmé · 20-29 Expert · 30+ Architecte.
- **Règle** : un agent ne démarre un chantier qu'après avoir lu ce playbook ; les leçons L1..L12 sont les « moves » qu'il MAÎTRISE — le coordinateur vérifie qu'aucune n'est violée avant d'accepter le chantier.

## Nouvelles lecons du sprint courant (à fusionner au prochain)
- _(à remplir par chaque équipe en fin de chantier)_
### L12. Contenus par âge : réglages explicites > masquage heuristique (abandon S5)
- **Décision produit (Sprint 5) : l'abandon du masquage automatique 18+/violence.** On garde le concept de profils Adulte/Enfant/Expert + PIN pour les réglages par âge, mais **plus aucun contenu n'est masqué automatiquement**. Les booléens `hideAdultContent`/`hideViolentContent` restent dans le modèle (compat données) mais ne sont **plus édités par l'UI**, et aucune grille n'applique plus `contentFilterProvider.visibleList(...)`.
- **Reverter proprement = ne rien casser au passage** : avant de supprimer le filtrage d'un écran, `grep` des consommateurs du provider (ici `content_filter_provider.dart`) ; retirer les imports devenus orphelins pour garder un `flutter analyze` **sans `unused_import`** sur les fichiers touchés (le count global se compare sur l'arbre identique, diff ligne par ligne).
- **Un utilitaire conservé doit être documenté comme tel** : `ContentFilter`/`contentFilterProvider` sont gardés (réutilisables pour les badges « âge » et les recommandations par âge) avec un en-tête « inactif dans l'UI courante » — sans changer leur comportement : les tests unitaires dédiés restent la garantie de non-régression.
- **UI = source unique de la décision** : retirer TOUTE la surface d'édition des booléens (édition de profil ET onglet Réglages), pas seulement les grilles ; un toggle restant qui éditait le masquage serait une UI morte qui ment à l'utilisateur.
- **Leçon préservée du S4** : filtrer à la couche d'affichage (widget) plutôt que dans les providers exposés — les listes brutes (`moviesProvider`, etc.) servent aussi à la recherche, l'EPG et le matchmaking.
### L13. Standards full-stack : erreurs détaillées + cas limites (flux hors ligne)
- **Un échec de lecture doit dire POURQUOI** : distinguer `URL vide/malformée` (StreamUrlEmptyException), `réseau/socket` (offline), `HTTP 403/404/406` (WAF/CDN/abonnement), `décodage errata` (манifest JSON invalide), `chaîne retirée` (404 panel). Le player expose `erreur codée` + `étape` + `remédiation`, jamais un `ErrorWidget` brut en production.
- **Toujours brancher les états hors-ligne** : avant d'essayer 3 User-Agents sur un flux, tester la connectivité (`InternetAddress.lookup` borné, ~1.5s) et afficher « Hors ligne » sinon — économise des erreurs factices et un spinner infini.
- **La robustesse se vérifie par l'énumération des états** : lister les combinaisons (données OK/partielles/vides × réseau OK/absent × HTTP codes) et s'assurer qu'aucune ne produit ni crash ni blocage sans message.
- **Gain x10** : toute constatation (ex: draap.online 406 vs HEAD 200, cf_clearance lié à IP+UA) quitte le commissaire et entre ICI, pour que l'ingénieur suivant parte de cette connaissance.
### L14. « Aucun » de piste = désactiver le TYPE, pas baisser le volume
- **Un « Aucun » audio réel s'obtient au niveau du sélecteur, pas du volume.** `setTrackTypeDisabled(C.TRACK_TYPE_AUDIO, true)` sur le `DefaultTrackSelector` coupe la sortie ET laisse une trace lisible : plus aucune piste n'a `isSelected == true` dans `getAudioTracks()`. Un simple `setVolume(0)` aurait produit un état que le natif ne peut pas distinguer de « piste en cours, son coupé » — impossible d'afficher la coche « Aucun » après réouverture du panneau.
- **La réactivation est gratuite si elle réutilise le chemin existant** : `applyTrackSelection` (sélection d'une piste) appelle déjà `setTrackTypeDisabled(type, false)`. Le « Aucun » n'a donc besoin que de sa moitié « couper » ; sélectionner n'importe quelle piste rallume le type. Ne pas écrire de « réactiver » séparé.
- **Oublier la préférence persistée quand on coupe.** Couper l'audio sans `remove()` de `PlayerTrackPrefs` fait rejouer la piste mémorisée à la prochaine lecture : l'utilisateur retrouve le son qu'il venait de couper, et conclut que « Aucun » ne marche pas. Même règle pour un futur « Aucun » sous-titres s'il devenait persistant.
- **Désactivations SÉPARÉES audio / sous-titres** : ce sont deux `setTrackTypeDisabled` indépendants (AUDIO vs TEXT). Ne pas les fusionner sous un « tout couper » — le produit veut deux entrées distinctes, chacune avec sa propre coche.
- **Mesurer « 0 erreur introduite » par fichier, pas globalement.** Ici `flutter analyze` rend 12 erreurs PRÉEXISTANTES dans un fichier **orphelin** (`lib/core/services/connectivity_service.dart`, jamais importé : `Connectivity`/`InternetAddress` sans import). Un fichier non atteint depuis `main.dart` ne casse pas `flutter build apk`, mais pollue le DoD. La preuve à produire est `flutter analyze <fichiers touchés>` → « No issues found », et signaler l'orphelin séparément au lieu de le réparer à l'aveugle.

### L15. Un `ChangeNotifier` exposé par un simple `Provider` a des `ref.watch` MORTS
- **Symptôme trompeur : tout est vert en amont, et rien à l'écran.** Ici `TextRenderer` publiait bien ses cues (`onCues n=1`), `getCurrentCues()` les renvoyait **textuelles** (`raw=1 text=1`) et le contrôleur Dart les recevait (`1re cue reçue`). Le sous-titre n'apparaissait pas pour autant. On a cherché le défaut côté décodage/extracteur pendant des heures alors qu'il était dans le **câblage réactif**.
- **La règle** : `ref.watch(provider)` ne s'abonne à `notifyListeners()` que si le provider enveloppe un `Listenable`. Un `Provider<SubtitleController>((ref) => SubtitleController())` renvoie bien l'instance, mais **ne réveille jamais ses dépendants** : le `notifyListeners()` du contrôleur tombe dans le vide. Il faut `ChangeNotifierProvider<T>` — que Riverpod 3 sort de l'export principal (`import 'package:flutter_riverpod/legacy.dart';`).
- **Pourquoi ça survit au premier test** : tout widget qui fait un `setState` après une action (feuille, dialogue, bouton) se rafraîchit de lui-même et paraît correct. Seul un consommateur **purement passif** — un overlay qui se contente de rendre un état — révèle le défaut. Un bug d'affichage isolé sur un seul widget est donc un signal de *câblage*, pas de rendu.
- **Ne pas doubler le `dispose`** : `ChangeNotifierProvider` (`disposeNotifier = true` par défaut) dispose lui-même le notifier. Retirer tout `ref.onDispose(controller.dispose)` manuel, sinon double `dispose()` → assertion.
- **Ne pas contourner en local.** Coller un `setState`/`ValueListenableBuilder` dans l'overlay aurait « marché » en laissant le contrat cassé pour les autres `ref.watch` du même provider. Ici une seule ligne de déclaration répare l'overlay, la feuille « Détails du flux » et le panneau sous-titres.
- **Diagnostiquer par étage, pas à l'intuition** : trois sondes indépendantes ont localisé la panne en un aller-retour — natif (`onCues n=` : le renderer émet-il ?), pont (`getCurrentCues raw=/text=` : cue textuelle ou bitmap PGS ?), Dart (`1re cue reçue` : le contrôleur reçoit-il ?). **Quand les trois sont vertes, le bug est APRÈS le dernier point de mesure.**

### L16. Deux repères de coordonnées dans un painter virtualisé (absolu vs écran)
- **Symptôme : des blocs de programme VISIBLES mais VIDES.** Dans la grille EPG, une ligne = un `CustomPaint` de la largeur du viewport, mais les programmes portent une abscisse **absolue depuis minuit** (0 → 5760 px). Le fond du bloc était dessiné à `left + shift`, le titre et le badge « REPLAY » restaient à `rp.left` (absolu) : à minuit pile le texte s'affichait, partout ailleurs il partait jusqu'à plusieurs milliers de pixels hors du canvas (clippé par le `ListView`). Comme le bloc, lui, restait peint, l'utilisateur voyait des rectangles sombres et concluait « aucun programme dans la grille ».
- **Règle** : dès qu'un painter applique une translation manuelle (plutôt qu'un `canvas.translate`), **toute** primitive doit passer par la même conversion. On l'extrait en UNE fonction pure (`screenXFor(absolutePx, offset)`), appelée par le fond, le texte ET le badge — source unique, donc plus de divergence possible.
- **Même piège pour le toucher/survol** : `PointerEvent.localPosition` est **local au canvas**, alors que la géométrie est absolue. La conversion inverse (`absolute = localDx + offset`) est obligatoire, sinon le tap/hover tombe sur le programme situé à la même abscisse près de minuit. Vérifier les DEUX sens : « absolu → écran » pour peindre, « écran → absolu » pour toucher.
- **Test de visibilité = test PIXEL, pas test d'assertion.** Un test qui vérifie une fonction pure ne prouve rien sur ce qui est réellement peint. On photographie la ligne (`RenderRepaintBoundary.toImage`) et on compte les pixels clairs dans la zone du bloc : 0 = texte hors canvas. **Piège d'exécution** : `toImage()` et `toByteData()` doivent tourner dans `tester.runAsync(...)` — les `await` hors `runAsync` ne se complètent jamais (timeout 10 min du test, pas un échec franc). Les glyphes de test (police Ahem) étant des rectangles pleins, le seuil sur R/G/B > 130 distingue le texte (blanc 70 %) du fond (#1C1F26), de la bordure (blanc 10 %) et de la ligne « maintenant » (rouge : vert/bleu bas).
- **Gain x10** : « ronde de pixels invisible à l'œil » ≠ « correctif inutile ». Un correctif géométrique dont l'effet est de quelques pixels ne se vérifie pas à l'œil sur un écran de box — il se vérifie au test pixel. Ne pas conclure « pas de changement » faute de preuve visuelle : instrumenter d'abord.
