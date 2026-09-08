# Audit — Gestion du bouton retour (Back Handling) — App IPTV « Orbit »

> **Équipe Terre** (EPG/Données, Lvl 4 Apprenti) — **Audit rapport uniquement**.
> Aucun fichier de code n'a été modifié.

- **Date** : 2026-09-08
- **Périmètre** : toutes les routes GoRouter de `lib/main.dart` (1 shell + 28 routes),
  croisement avec `WithBackHandling`, `ConfirmExitApp`, et les écrans de `lib/features/`.
- **Mécanismes en jeu** :
  - `ConfirmExitApp` (`lib/core/widgets/confirm_exit_app.dart`) : `PopScope(canPop:false)` + dialog « Quitter Orbit IPTV ? » → `SystemNavigator.pop()`.
  - `WithBackHandling` (`lib/core/navigation/with_back_handling.dart`) : `PopScope(canPop:false)` + `RestorationScope`, piloté par `RouteMeta` (pop / popOrFallback / custom).
  - `PopScope` racine dans `OrbitApp.build` (`MaterialApp.router` → `builder`) : `canPop:false` + même dialog.

---

## 1. Tableau des routes

Légende : **Pb** = none / mineur / bloquant. « Retour attendu » = comportement souhaitable produit.

| # | Route | Type | Retour attendu | Implémentation actuelle | Problème | Correction proposée |
|---|-------|------|----------------|--------------------------|----------|---------------------|
| 1 | `/onboarding` | builder (pushReplacement) | quitter (écran d'accueil initial) | aucun PopScope → pop par défaut du Navigator | mineur — sortie directe sans confirmation | envelopper dans `ConfirmExitApp` ou un `PopScope` dédié |
| 2 | `/profiles` | builder (racine, in-shell initial) | dialog de sortie | `ConfirmExitApp` interne (PopScope canPop:false + dialog) | none | — |
| 3 | `/profile/create` | builder (push) | revenir à `/profiles` (avec garde si formulaire modifié) | aucun PopScope → pop Navigator. Écran = `features/profile/profile_edit_screen.dart` **sans garde « modifications non sauvegardées »** et **sans FormBackHandler** | **mineur → bloquant potentiel** — perte silencieuse de saisie | envelopper avec `FormBackHandlerScope` / réutiliser `FormBackHandler` (existe déjà dans `features/auth/profile_edit_screen.dart`) |
| 4 | `/profile/edit/:id` | builder (push) | revenir à `/profiles` (garde si modifié) | idem route 3 : pas de garde dans `features/profile/profile_edit_screen.dart` | mineur (perte possible) | garde « quitter sans sauvegarder » |
| 5 | `/profile/pin` | builder (push) | revenir à l'appelant (annuler) | `PinPadScreen` : AppBar leading `context.pop()`, aucun PopScope | none | — |
| 6 | `/profile/preferences` | builder (push) | revenir à l'appelant | `ProfilePreferencesScreen` (`features/auth/`) : `PopScope(canPop:true)` + `onPopInvoked` → `router.pop()` | **mineur** — `canPop:true` + handler redondant (re-pop) ; si route ouverte en plein écran → risque de double pop | simplifier (PopScope canPop:false + `RouteMeta.pop`) |
| 7 | `/parental` | builder (push) | revenir à l'appelant | aucun PopScope → pop Navigator par défaut | none | — |
| 8 | `/matchmaking` | builder (push) | revenir | AppBar leading `context.pop()`, aucun PopScope | none | — |
| 9 | `/player` | pageBuilder + `WithBackHandling` **custom** (restorationId `player`) | arrière → `cleanup()` contrôleurs puis pop / `go('/home')` | handler custom : `playerState.cleanup()` (dispose vidéo) + `router.canPop() ? pop : go('/home')` | none (mise en œuvre correcte du dispose) | — |
| 10 | `/multivideo` | pageBuilder + `WithBackHandling` **custom** (restorationId `multivideo`) | arrière → dispose vidéo puis pop | handler custom : `state.disposeAllControllers()` + `canPop ? pop` | **mineur** — si `canPop` faux, rien ne se passe (pas de fallback) ; AppBar sans leading retour (multi-vue plein écran) | ajouter fallback `go('/home')` |
| 11 | `/vod/detail` | pageBuilder + `WithBackHandling` **pop** (restorationId `vod_detail`) | revenir à la liste VOD | `RouteMeta.pop` ; AppBar auto-back (auto leading) intercepté par le PopScope | none | — |
| 12 | `/series/detail` | pageBuilder + `WithBackHandling` **pop** | revenir à la liste séries | idem | none | — |
| 13 | `/episode/detail` | pageBuilder + `WithBackHandling` **pop** | revenir au détail série | idem | none | — |
| 14 | `/favorites` | pageBuilder + `WithBackHandling` **pop** (restorationId `favorites`) | revenir | idem | none | — |
| 15 | `/history` | pageBuilder + `WithBackHandling` **pop** (restorationId `history`) | revenir | idem | none | — |
| 16 | `/startup` | builder (pushReplacement) | passer à `/profiles` (temporaire) | aucun PopScope | mineur — aucun contrôle sur la sortie pendant le splash | sans objet (route transitoire) |
| 17 | `/home` | **ShellRoute** pageBuilder + `ConfirmExitApp` (restorationId `home`) | dialog de sortie | `ConfirmExitApp` (PopScope canPop:false + dialog) | none | — |
| 18 | `/live` | ShellRoute + `WithBackHandling` **pop** (restorationId `live`) | revenir à l'onglet `/home` | `RouteMeta.pop` → `router.pop()` | **mineur/bloquant** — au sein du shell, `go()` ne cumule pas d'historique : `router.pop()` peut soit rien faire (pas de fallback), soit quitter le shell vers `/profiles` | utiliser `popOrFallback('/home')` pour les onglets shell |
| 19 | `/series` | ShellRoute + `WithBackHandling` **pop** | revenir à `/home` | idem route 18 | **mineur/bloquant** — même problème | `popOrFallback('/home')` |
| 20 | `/vod` | ShellRoute + `WithBackHandling` **pop** | revenir à `/home` | idem | **mineur/bloquant** — idem | `popOrFallback('/home')` |
| 21 | `/radio` | ShellRoute + `WithBackHandling` **custom** (restorationId `radio`) | arrière → `radioService.stop()` puis revenir à `/home` | handler custom : `radioService.stop()` + `canPop ? pop` | **mineur** — pas de fallback si `canPop` faux ; pas de dispose dans l'écran (OK, géré par la route) | ajouter `else go('/home')` |
| 22 | `/replay` | ShellRoute + `WithBackHandling` **pop** | revenir à `/home` | idem route 18 | **mineur/bloquant** | `popOrFallback('/home')` |
| 23 | `/epg` | ShellRoute + `WithBackHandling` **pop** | revenir à `/home` | idem | **mineur/bloquant** | `popOrFallback('/home')` |
| 24 | `/search` | ShellRoute + `WithBackHandling` **pop** (restorationId `search`) | revenir à `/home` | idem ; `SearchScreen` a un leading retour (ligne 175-179) | **mineur/bloquant** | `popOrFallback('/home')` |
| 25 | `/ai` | ShellRoute + `WithBackHandling` **pop** | revenir à `/home` | idem | **mineur/bloquant** | `popOrFallback('/home')` |
| 26 | `/settings` | ShellRoute + `WithBackHandling` **custom** (restorationId `settings`) | revenir à `/home` | handler custom : `canPop ? pop` → **pas de fallback** | **mineur/bloquant** — `go('/settings')` depuis l'accueil : `canPop` faux → retour muet | `popOrFallback('/home')` ou fallback explicite |
| 27 | `/settings/advanced` | ShellRoute + `WithBackHandling` **pop** (restorationId `settings_advanced`) | revenir aux réglages | `RouteMeta.pop` (mais ouvert via `go`, non `push`) | **bloquant** — atteint via `context.go('/settings/advanced')` depuis `settings_screen.dart:48` ; le `pop` ne revient pas au shell comme attendu | ouvrir en `push` modale ou utiliser `popOrFallback('/settings')` |
| 28 | `/subscriptions` | ShellRoute + `WithBackHandling` **pop** | revenir à l'accueil | idem route 18 (or `go('/subscriptions')` depuis l'accueil) | **mineur/bloquant** | `popOrFallback('/home')` |

> **Total** : **28 routes** (1 shell interne + 6 routes modales push + 16 pageBuilder détail/média + 13 shell interne avec WithBackHandling dont `/home` ConfirmExitApp).
> Routage utilisé : `pageBuilder` (restorationId) pour les écrans média/détail et les onglets shell ; `builder` (sans restorationId) pour profiles/onboarding/startup/matchmaking/parental.

---

## 2. Conflits PopScope imbriqués

**Règle Flutter** : en cas de PopScope imbriqués `canPop:false`, **le plus INTERNE gagne** ; seuls les `canPop:false` les plus profonds sont notifiés via `onPopInvoked(didPop:false)`.

### Embarquement observé
1. **`PopScope` racine** (`OrbitApp.build`, `MaterialApp.router → builder`), `canPop:false`.
   → ⚠️ Placé **au-dessus du Navigator** (`child` = Navigator) : n'est rattaché à aucune `ModalRoute`. En pratique **inactif** pour la touche retour système (code mort). La « vraie » protection est assurée par `ConfirmExitApp` posé *par route* (`/home`, `/profiles`).
2. **Route Shell** (`/home`) : `ConfirmExitApp` → `PopScope(canPop:false)` (interne, gagne) → dialog de sortie.
3. **Route Shell non-home** (`/live`, `/vod`, …) : `WithBackHandling` → `PopScope(canPop:false)` (interne, gagne).
4. **Modales** (`/profile/create`, `/profile/pin`, …) : pas de PopScope dans l'écran → seul le PopScope racine (inactif) existe ⇒ **le retour système fait un pop Navigator standard**.

### Conflits détectés
- **Racine vs route** : le PopScope racine `canPop:false` serait *censé* englober toutes les routes ; étant inactif (non rattaché à une `ModalRoute`), il ne fournit **aucune** confirmation de sortie sur les routes sans `ConfirmExitApp`/`WithBackHandling`. Les routes modales poussées (`/profile/create`, etc.) sortent donc sans garde ni confirmation.
- **`/home` double PopScope** : `ConfirmExitApp` (interne, `canPop:false`) + racine (externe). Le plus interne gagne → dialog correct. **Non-bloquant**, mais la redondance avec le PopScope racine est trompeuse.
- **`WithBackHandling._hasModalRoute` peu fiable** (`with_back_handling.dart:39-74`) : il retourne `navigator.canPop()` (quasi toujours `true` sur une route poussée). Donc, en présence d'un vrai dialog/bottom-sheet, la branche « laisser le modal gérer » peut ne **pas** se déclencher correctement, et le `router.pop()` peut fermer la mauvaise couche.

---

## 3. Écrans avec état non sauvegardé (formulaires)

| Écran | Fichier | État | Garde retour ? |
|-------|---------|------|----------------|
| Création / édition profil | `features/profile/profile_edit_screen.dart` (utilisé par les routes 3-4) | `_nameController`, `_type`, `_gender`, genres, `_pinHash`, avatar | **NON** — `context.pop()` direct, aucune garde. ⚠️ |
| Édition profil (variante) | `features/auth/profile_edit_screen.dart` (dupliqué, `with FormBackHandler`, PopScope canPop:false + dirty-check) | idem | OUI (via `FormBackHandler`) — mais **non branché aux routes** | 
| Préférences profil | `features/auth/profile_preferences_screen.dart` | toggles persistés immédiatement (Riverpod) | N/A (persistance immédiate, pas d'état perdu) |
| Paramètres | `features/settings/settings_screen.dart` | réglages persistés (tabular) | N/A (persistance via provider) |
| Paramètres avancés | `features/settings/advanced_settings_screen.dart` | options persistées | N/A |
| Contrôle parental | `features/auth/parental_control_screen.dart` | PIN + préférences persistées | N/A |

**Problème principal** : `/profile/create` et `/profile/edit/:id` utilisent `features/profile/profile_edit_screen.dart` qui **ne protège pas** un formulaire modifié (perte de saisie au retour). Le mécanisme de garde existe déjà (`core/navigation/form_back_handler.dart` + `FormBackHandlerScope` + variante `features/auth/profile_edit_screen.dart`) mais **n'est pas utilisé par la route active**.

---

## 4. Dispose / lifetime des contrôleurs

| Ressource | Écran | Libre correctement ? |
|-----------|-------|----------------------|
| Vidéo (player) | `features/player/player_screen.dart:148` | OUI — `dispose()` → `_disposeActive/_disposeCachedNext/_disposeCachedPrev`, plus `cleanup()` public appelé par la route custom `/player` (l.933-948) |
| Video (multivideo) | `features/multivideo/multivideo_screen.dart:174` (tile) + `disposeAllControllers()` l.22 | OUI — controller disposes + `removeListener` avant dispose |
| Radio just_audio | `features/radio/radio_screen.dart` (pas de `dispose` propre) | OUI via la route custom `/radio` → `radioService.stop()` (l.416-426 de main.dart). ⚠️ pas de fallback si `canPop` faux. |
| TabController settings | `settings_screen.dart:34`, `advanced_settings_screen.dart:32` | OUI |
| PageController home | `home_screen.dart:41` | OUI |
| Search/vod/series controllers | `search_screen.dart:113`, `vod_screen.dart:31`, `series_screen.dart:31` | OUI |
| Start-up splash | `startup_splash_screen.dart:64` | OUI (timer) |

**Bilan** : les ressources lourdes (vidéo, radio) sont libérées correctement *au retour* via les handlers custom. Points restants : `multivideo` et `radio` ne gèrent pas le cas `canPop == false` (retour muet possible), et le player/radio ne sont pas libérés s'ils sont remplacés par une autre navigation non-« back » (dépend du handler de route, OK ici).

---

## 5. Recommandations (actions par priorité)

### P0 — Comportement de retour incorrect (bloquant)
1. **Remplacer `RouteMeta.pop` par `RouteMeta.popOrFallback('/home')` sur les onglets Shell** (`/live`, `/series`, `/vod`, `/replay`, `/epg`, `/search`, `/ai`, `/subscriptions`, `/settings`) : le `go()` interne ne cumulant pas d'historique, `pop` est incohérent (retour muet ou sortie du shell vers `/profiles`).
2. **`/settings/advanced`** : passer en `push` modal (comme `/vod/detail`) ou `popOrFallback('/settings')` — actuellement ouvert via `go()`, le retour `pop` n'est pas fiable.

### P1 — Perte de données / états non sauvegardés
3. **Brancher la garde de formulaire sur `/profile/create` et `/profile/edit/:id`** (réutiliser `FormBackHandlerScope`/`FormBackHandler` déjà présents) pour prévenir la perte de saisie.

### P2 — Architecture & robustesse
4. **Supprimer ou corriger le `PopScope` racine** (`OrbitApp.build`) : non rattaché à une `ModalRoute`, il est inopérant et trompeur. Le déplacer à l'intérieur du Navigator (ex. autour de chaque `MaterialPage` via `ConfirmExitApp`) s'il doit être global.
5. **Corriger `WithBackHandling._hasModalRoute`** : remplacer le simple `navigator.canPop()` par une détection réelle de modal (`ModalRoute.of(context)!.isCurrent` + type route), sinon gestion fausse des dialogs/bottom-sheets.
6. **Consolider les duplications** `features/auth/profile_edit_screen.dart` / `features/profile/profile_edit_screen.dart` et `features/auth/profile_selection_screen.dart` / `features/profile/profile_selection_screen.dart` (deux familles de fichiers quasi identiques, seule `features/profile/` est routée).
7. **Ajouter un fallback** à `multivideo` et `radio` quand `canPop == false` (`go('/home')`).

---

## 6. Risques résiduels

- **Sortie non confirmée** sur `/onboarding`, `/startup` et tout écran non protégé par `ConfirmExitApp`/`WithBackHandling` (le PopScope racine ne couvre pas réellement).
- **Retour muet possible** sur les onglets Shell (pas de fallback) jusqu'à application de la P0.
- **Double-class code** entre `auth/` et `profile/` : risque de corriger la mauvaise copie (la route utilise `features/profile/`).
- **Gestion des modales** (`search` bottom-sheets, dialogs PIN/parental) reposant sur une heuristique fragile (`_hasModalRoute`).
- La restauration d'état (`restorationId`) n'est définie que sur les routes `pageBuilder` ; les routes `builder` (profiles, onboarding, startup, matchmaking) perdent leur position après kill du process.
- **Non testé** : comportement précis de `router.pop()` sur une route Shell en fonction de l'historique réel (selon qu'on vient de `/home` via `pushReplacement` ou d'un `push` modal) — à valider par un scénario manuel avant correction.

---

## Résumé exécutif

- **Routes auditées** : **28** (1 shell + 6 modales push + 16 détail/média + 13 inner-shell avec back handling dont `/home` ConfirmExitApp).
- **Problèmes signalés** :
  - **P0 (bloquant)** : 2 groupes — (a) retour incohérent sur les onglets Shell (pas de `popOrFallback`), (b) `/settings/advanced` ouvert via `go()` avec retour `pop` non fiable.
  - **P1 (mineur/bloquant)** : perte de saisie sur `/profile/create` & `/profile/edit/:id` (aucune garde de formulaire).
  - **P2 (arme/robustesse)** : `PopScope` racine inactif, `_hasModalRoute` fragile, duplication `auth/`↔`profile/`, fallbacks manquants (`multivideo`, `radio`), restauration absente sur les routes `builder`.
- **Recommandations clés** : utiliser `popOrFallback('/home')` pour les onglets Shell (P0), brancher `FormBackHandler` sur l'édition de profil (P1), corriger le PopScope racine et la détection de modale (P2).
