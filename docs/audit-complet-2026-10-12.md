# Audit complet — Orbit IPTV (2026-10-12)

**Périmètre** : `lib/` (260 fichiers, 73 374 lignes), `android/`, `pubspec.yaml`, `test/`,
`.gitignore`, `docs/`. Méthode : `dart analyze`, `flutter test`, lecture directe du code et
de la config native. Chaque fait vérifié est marqué ✅ ; le reste est explicitement signalé
comme hypothèse ou comme non vérifié à l'exécution (téléphone déconnecté pendant l'audit).

> Ce document complète (et remplace pour l'état courant) `docs/global-analysis.md`, qui date
> d'une version à ~8 800 lignes / 73 fichiers / 275 infos. Depuis : 260 fichiers, 73 374
> lignes, **0 info d'analyse**, 830 tests.

---

## 1. Métriques actuelles (vérifiées ✅)

| Indicateur | Valeur |
|---|---|
| Analyse statique `dart analyze lib` | **0 erreur, 0 warning, 0 info** (avant nettoyage : 7 warnings + 79 infos) |
| Tests `flutter test` | **830 réussis, 0 échec** |
| Code `lib/` | 260 fichiers Dart, 73 374 lignes |
| Dépendances mortes déclarées | 1 (`flutter_secure_storage`, prévu mais non utilisé) |
| `withOpacity` restants | 0 |
| Secrets en clair dans `lib/` | 0 (aucune clé API codée en dur) |

---

## 2. Sécurité

### 2.1 Points solides ✅
- Aucun identifiant de serveur ni clé API en dur dans `lib/`.
- `crypto`, `flutter_secure_storage`, `dio_cookie_manager` disponibles pour le durcissement.
- `MediaPlaybackService` en `exported="false"` + `foregroundServiceType="mediaPlayback"` (conforme Android 14+).
- Minification R8 (`minifyEnabled`) + `shrinkResources` activés en release.
- Historique git purgé des anciens credentials (vérifié précédemment, cf. `LEGAL_README.md` §4.1bis).

### 2.2 Findings

| # | Sévérité | Constat | Fichier / preuve | Recommandation |
|---|---|---|---|---|
| **S1** | 🔴 Élevé | **Données au repos non chiffrées** : mots de passe Xtream en clair (`Subscription.password`, `@HiveField(5)`), PIN parental en clair. `flutter_secure_storage` est déclaré mais **jamais importé** (0 usage). | `pubspec.yaml:52`, `models/subscription.dart`, `storage_service.dart` | Migrer les secrets (mot de passe Xtream, PIN parental, clés API TMDB/OpenSubtitles) vers `flutter_secure_storage` (Keystore/EncryptedSharedPreferences). Voir §8. |
| **S2** | 🔴 Élevé | **L'APK release est signé avec la clé de debug** (`signingConfigs.debug`). Impossible à publier (Play refuse les APK signés debug) et la clé debug est partagée/publique. | `android/app/build.gradle:38` | Créer un keystore release + `key.properties` (gitignoré) et une `signingConfigs.release`. ⚠️ nécessite tes mots de passe — voir §8. |
| **S3** | 🟠 Moyen | `android:usesCleartextTraffic="true"` global : tout le trafic HTTP est autorisé, sans `networkSecurityConfig`. Souvent nécessaire (panneaux Xtream/TPV en `http://`), mais on ne peut pas distinguer les domaines légitimes. | `AndroidManifest.xml:15` | Si un jour tous les panneaux passent en HTTPS, créer `res/xml/network_security_config.xml` + `cleartextTrafficPermitted="false"` par défaut. **Non modifié** : risque de casser la lecture `http://`. |
| **S4** | 🟠 Moyen | **Clé de compte de service Firebase Admin présente sur le disque** du dépôt (gitignorée mais réelle et active). | racine du dépôt (`*firebase-adminsdk*.json`) | Déplacer hors du dépôt (coffre CI) ou supprimer ; ne jamais committer. Action utilisateur. |
| **S5** | 🟡 Faible | Deux receveurs `android:exported="true"` (`OrbitHomeWidgetProvider`, `HomeWidgetBackgroundReceiver`) : n'importe quelle app peut émettre l'action `…home_widget.action.BACKGROUND`. Standard pour les widgets, surface limitée (mise à jour de widget). | `AndroidManifest.xml:80-98` | Acceptable. Ne pas ajouter de logique sensible dans le receveur. |
| **S6** | 🟡 Faible | `android/app/google-services.json` est suivi : contient une clé API Firebase (publique par nature, mais à restreindre). | `android/app/google-services.json` | Restreindre la clé dans la console Firebase (par package + empreinte SHA-1) + règles Firestore. |
| **S7** | 🔵 Info | Aucun `proguard-rules.pro` explicite ; R8 utilise ses règles par défaut + `consumer-rules` des plugins. Le build et l'app fonctionnent tels quels. | absence de `android/app/proguard-rules.pro` | Ajouter un fichier de keeps **additif** (ne peut que conserver davantage de code, donc ne casse rien) si des libs à réflexion sont ajoutées. Non urgent. |
| **S8** | 🟡 Faible | `android:taskAffinity=""` sur `MainActivity` : l'activité n'appartient pas à la tâche par défaut de l'app — peut surprendre le comportement « Récents »/multitâche. | `AndroidManifest.xml:55` | À confirmer sur device ; ne pas changer sans preuve d'un bug visuel. |

---

## 3. Ergonomie

- ✅ **Clavier / télécommande** : `Focus`/`tv_focus.dart` dédié, `shortcuts`/`FocusTraversal` présents.
- ✅ **PiP** (`supportsPictureInPicture`) + `resizeableActivity` : utile téléphone et TV multi-fenêtre.
- ✅ **Bandeau Leanback** (`android:banner`) + `leanback` non requis : TV supportée sans exclure le téléphone.
- ⚠️ **`EnableImpeller=false`** (`AndroidManifest.xml:49-50`) : l'app force le moteur **Skia**. C'est un choix de stabilité sur GPU TV exotiques ; à ré-évaluer (Impeller est plus fluide sur device récent). Non modifié.
- ⚠️ **Documents d'analyse périmés** : `docs/global-analysis.md`, `docs/test-analysis.md`, `docs/sprints-status.md` décrivent un état ancien (31 tests annoncés vs 830 réels). Risque de tromper le prochain lecteur.
- ⚠️ **5 fichiers** contiennent des caractères de remplacement U+FFFD (encodage cassé) → texte visiblement corrompu à l'écran.

---

## 4. Code & dette technique

- ✅ **0 info d'analyse** après nettoyage (voir §6). `analysis_options.yaml` active déjà `prefer_const_constructors`, `require_trailing_commas`, `sort_child_properties_last`, `use_key_in_widget_constructors`, `avoid_print`, `always_use_package_imports`, `prefer_final_locals`.
- ✅ **Dépendances mortes netttoyées** depuis l'ancienne analyse : `provider`, `logger`, `package_info_plus`, `cupertino_icons` ne sont plus déclarés ni importés. Seul `flutter_secure_storage` reste déclaré sans usage (volontaire — cible S1).
- ✅ `cached_network_image` est maintenant utilisé (3 imports).
- ⚠️ **Contraintes `any`** : `crypto: any`, `meta: any` (ce dernier ajouté par `dart fix` pour résoudre `depend_on_referenced_packages`). `any` évite les conflits mais gèle la traçabilité. Acceptable, à épingler si besoin.
- ⚠️ **`.fvmrc`** épingle Flutter **3.24.5**, tandis que la CI et la machine locale utilisent **3.47.2** : incohérence de reproductibilité.
- ⚠️ **42 marqueurs `TODO/FIXME/HACK`** restants dans `lib/`.
- ⚠️ **`runtime_metrics` / tests** : aucune couverture des écrans (uniquement unit + widget isolé) ; validation device requise pour P1/P2.

---

## 5. Polyvalence Android téléphone & TV

| Point | État | Remarque |
|---|---|---|
| `minSdk` / `targetSdk` | flutter defaults | alignés sur Flutter ; OK téléphone + TV modernes |
| `compileSdk` | **36** ✅ | requis par les AndroidX des plugins natifs |
| ABIs embarqués | **`arm64-v8a`, `x86_64`** | ⚠️ **pas d'`armeabi-v7a`** : les box TV / téléphones 32-bit ARM ne pourront pas installer l'APK. À ajouter si tu cibles du matériel ancien (`abiFilters 'arm64-v8a', 'armeabi-v7a', 'x86_64'`). |
| Java / Kotlin | **17 / JVM 17** ✅ | cohérents ; `coreLibraryDesugaring` 2.1.4 |
| TV | `leanback` + banner + `touchscreen not required` ✅ | navigation D-pad gérée |
| Téléphone | touch, PiP, resizeable ✅ | |
| Moteur | Skia forcé (Impeller off) | voir §3 |

**Conclusion** : polyvalence téléphone/TV correcte, **sauf** l'exclusion des appareils 32-bit ARM (`armeabi-v7a`).

---

## 6. Corrections appliquées sans ton aval (fait)

### 6.1 P1 — Écran de mise à jour à 4 icônes (terminé)
Le rafraîchissement au démarrage périmé (> 30 min) et le bouton « Mettre à jour » passaient
par un rechargement **silencieux**. Ils ouvrent désormais le **même écran plein écran à 4
icônes + avancement** que le démarrage et le changement d'abonnement.
- Nouveau : `lib/core/services/refresh_steps_controller.dart` (base testable, pas de Riverpod/réseau).
- Nouveau : `lib/features/startup/widgets/refresh_progress_view.dart` (vue réutilisable).
- Nouveau : `lib/features/startup/refresh_progress_screen.dart` (écran + `showRefreshProgress`).
- Édité : `startup_splash_screen.dart` (utilise la vue), `home_screen.dart` (`_autoRefreshIfStale`
  et `_refreshAll` ouvrent l'écran ; ancien `_waitDataProviders` supprimé).
- 7 tests unitaires ajoutés (`test/unit/refresh_steps_controller_test.dart`).

### 6.2 Nettoyage statique (`dart fix --apply` + corrections manuelles)
- **86 → 0 problème** dans `lib/` (imports inutiles, `const`, virgules finales, `withOpacity`→`withValues`,
  `cacheExtent`→`scrollCacheExtent`, doc-comments, `old`→`oldWidget`, getter/setter→champ, code mort `_allItems`/`headers`/`_describeCue`).
- 4 blocs de logs **DIAGNOSTIC temporaires** retirés (`matchmaking_provider` AFFGEN/AFFGEN-S,
  `synopsis_translation_provider`, `subscription_provider`, `subtitle_controller`).
- `.gitignore` : ajout de `.opencode/` et des artefacts de build des forks `third_party/*/{android/build,.gradle,build}/`.

---

## 7. Actions nécessitant ton aval

1. **S1** — Migration chiffrement des secrets (`flutter_secure_storage`) : je peux l'implémenter,
   mais elle touche la connexion/abonnement → validation device obligatoire + stratégie de
   migration (les abonnements existants en clair doivent être re-chiffrés au premier lancement).
2. **S2** — Signature release : fournir un keystore + mots de passe (`key.properties`).
3. **S4** — Déplacer/supprimer la clé Admin Firebase du disque.
4. **§5** — Ajouter `armeabi-v7a` (cible matériel 32-bit) ou confirmer qu'on ne le cible pas.
5. **§3** — Ré-encoder les 5 fichiers corrompus (U+FFFD).

---

## 8. Plan priorisé

| Prio | Action | Effort | Risque si fait à l'aveugle |
|---|---|---|---|
| P0 | Signature release (S2) | S | nul (config) |
| P0 | Retirer clé Admin Firebase du disque (S4) | XS | nul |
| P1 | Chiffrement secrets via `flutter_secure_storage` (S1) | L | élevé → test device requis |
| P1 | Ré-encoder 5 fichiers corrompus | S | faible |
| P2 | Ajouter `armeabi-v7a` (S5/§5) | XS | taille APK ↑ |
| P2 | `proguard-rules.pro` additif (S7) | S | nul (additif) |
| P3 | Aligner `.fvmrc` ↔ CI, épingler `crypto`/`meta` | XS | nul |
| P3 | Rafraîchir `docs/global-analysis.md`/`test-analysis.md` | S | nul |
