# Orbit 3D — Roadmap nouveautés (ciblée, 3 axes prioritaires)

Suite à l'audit concurrentiel 2026, la roadmap générale a été réduite aux **3 axes retenus** par le propriétaire : **portage Tizen/WebOS**, **badges qualité 4K/HDR/ABR**, **profils parentaux 2.0**. Le reste (IA conversationnelle, watch party, résumés IA, session cross-device…) est reporté.

## Axe 1 — Portage Smart TV (Tizen / webOS)

**Objectif** : rendre Orbit 3D disponible nativement sur les TV Samsung (Tizen) et LG (webOS), sans box, comme IBO Player Pro/MyIPTV Player (seul concurrent dominant sur ce terrain — et sans IA ni UX moderne).

**Contexte** : Flutter ne supporte officiellement ni Tizen ni webOS à l'état stable. Options à étudier :
- **En-Tizen / en-webOS (partenaires Flutter)** : SDK embarqués pour Tizen (Samsung Support Center) et webOS (LG). Risque : mises à jour aléatoires.
- **Le portage par « TL` interactive » web (HbbTV)** : une coquille web HbbTV sur la TV redirigeant vers un lecteur web optimisé (hls.js/video.js) — moins performant que natif mais un seul code.
- **Refactor exploit「 cross-platform du player** : isoler la couche vidéo (video_player → interface) pour réutiliser le même code métier (Riverpod/go_router) sur les 3 cibles.

**Livrables** : étude de faisabilité + preuve de concept sur une TV Samsung/LG réelle, puis distribution (APK → TPK/IPK, signatures Samsung/LG).

**Effort : XL — Phases LATER**.

## Axe 2 — Badges qualité 4K / HDR / ABR

**Objectif** : transparence de la qualité : badges **2160p / 4K / HDR10 / HDR10+ / Dolby Vision / HEVC** sur les cartes VOD, séries et listes Live ; **sélecteur de qualité adaptatif** (Auto/manuel) dans le lecteur ; overlay « infos flux » (résolution, codec, bitrate) au zapping.

**Contexte technique Android** :
- Utiliser `MediaQualityManager` (Android 16 / API 36) pour la sélection de profils image.
- Les métadonnées qualité sont déductibles : manifestes M3U8 (bandwidth/resolution), champs Xtream (`container_extension`, streams), ou fournisseurs de méta (TMDB) pour VOD.
- Le lecteur `media3` (video_player) permet de rapporter la résolution réelle via `VideoPlayerController.value.size`.

**Livrables** :
1. `QualityBadge` widget + mapping `resolution/bitrate → label`.
2. Sur la grille Live & VOD : badge visible.
3. Dans le player : sélecteur ABR (Auto/manuel) — via ré-écriture de l'URL HLS (ou media3 TrackSelectionParameters si migration).
4. Overlay info flux dans la barre d'info P4.

**Effort : S–M — Phases NOW/NEXT**. Première étape : badges + overlay (faible risque), sélecteur ABR ensuite.

## Axe 3 — Profils parentaux 2.0

**Objectif** : transformer le contrôle parental (actuellement PIN sauvegardé mais **jamais appliqué** à la lecture) en **vraie expiration par foyer** : profils enfants verrouillés, restriction par catégorie/chaîne, classement « qui regarde quoi ».

**Constats code** :
- `ageRestriction`/PEGI est stocké dans `models/user_profile.dart` mais **jamais appliqué** à la lecture (`parental_control_screen.dart` ne fait que sauvegarder).
- PIN parental stocké en clair dans Hive (`storage_service.dart:54-67`).

**Livrables** :
1. Gate de lecture effective : avant `context.go('/player')`, vérifier `profile.ageRestriction` vs PEGI/age du contenu (live – catégorie adulte ; VOD – `pegiLabel` ; séries). Blocage + demande PIN si dépassé.
2. Profils enfants : thème dédié, contenu filtré par défaut, mot de passe/verrou de profil.
3. PIN protégé via `flutter_secure_storage` (au lieu de clair Hive).
4. « Qui regarde quoi » : stats minimales par profil (top catégories, temps) — optionnel, en NEXT.

**Effort : M — Phases NOW (gate + PIN chiffré) / NEXT (profils enfants, stats)**.

## Priorités immédiates (ordre proposé)
1. **Parental 2.0 — gate de lecture + PIN chiffré** (sécurité utilisateur, code existant, faible risque). *(NOW)*
2. **Badges 4K/HDR + overlay info flux** sur l'existant P4. *(NOW)*
3. **Étude/faisabilité Tizen·webOS** (une équipe dédiée, proof of concept). *(LATER)*

## Sources clés consultées
- Tizen : Samsung Developer / en-Tizen/WebOS. webOS : LG Developer / en-webos.
- Android 16 : `developer.android.com` — `MediaQualityManager` (transfert d'images).
- IBO Player Pro / MyIPTV Player : comparatifs 2026 (portages natifs Tizen/webOS).
- Xtream : contexte `container_extension`/résolution des listes VOD/Live.