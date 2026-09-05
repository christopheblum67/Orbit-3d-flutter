# Orbit IPTV — Playbook Ingénieurs (Amélioration continue)

> **Règle d'or :** chaque équipe lit ce playbook AVANT de commencer un nouveau chantier, et propose à la FIN de chaque sprint 1 nouvelle règle à ajouter (ce qu'elle a appris). Le playbook s'enrichit à chaque itération → chaque nouvel ingénieur démarre plus fort que le précédent.

## Règles non négociables
1. `provider` package **banni** : riverpod uniquement (`ref.read`/`ref.watch`, jamais `context.read<T>()`).
2. PowerShell : jamais `&&`, jamais `grep`/`sed`/`head` → `Select-String`, `Get-Content`.
3. Dépendances : vérifier `pubspec.yaml` avant tout nouvel import (pas de surprise).
4. Après toute série de modifications : `dart format <fichiers>` puis `flutter analyze` puis `flutter test` (50 tests).
5. Toute modification de widget garde un chemin de retour (`context.canPop() ? pop() : go('/home')`).

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