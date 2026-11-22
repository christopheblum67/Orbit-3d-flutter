# Replay / Catch-up — Architecture et pipeline

> Compte-rendu technique et architectural du pipeline Replay / Catch-up d’Orbit 3D.
> Vue ingénierie : modélisation → récupération réseau → résolution d’URL → état/cache → UI.
>
> 📎 Le **code source complet** (extraction fidèle, commentaires compris) est dans
> [`replay-catchup-reference.md`](./replay-catchup-reference.md).

---

## 1. Modélisation et normalisation des données (`/models`)

**`Channel`** extrait et normalise les attributs critiques du panel Xtream
(`tv_archive`, `radio_tv=dvr`, `tv_archive_duration`, `catchup-days`, `catchup`,
`catchup-source`). Pour pallier les incohérences des panels, le mapping gère des
**identifiants EPG multiples** (`stream_id` et `{num}:{stream_id}`, séparés par une
virgule, exposés par `epgChannelIds`) afin d’assurer la jointure avec le dump XMLTV.

La fenêtre d’archive (`archiveDays`) **priorise la déclaration du panel**
(`tv_archive_duration`, sinon `catchup-days`) tout en conservant le garde-fou de
rétroactivité côté service (§6).

**`ReplayItem` & `EPGProgram`** représentent respectivement un slot de replay
instancié et un événement du guide. `ReplayItem` porte les horaires machine
(`startAt`/`endAt`) pour le tri et le regroupement par jour, et un `description`/`host`.
L’intégration de `PanelText.decode` permet d’intercepter et de décoder de manière
défensive les flux de titres/synopsis **encodés en Base64** par certains panels,
évitant ainsi les artefacts visuels.

---

## 2. Stratégie de fetching et résilience réseau (`ApiService`)

Le pipeline résout le problème critique de la **limitation des panels Xtream**
(où `get_short_epg` se limite par défaut à quelques entrées futures) grâce à une
stratégie hybride à trois sources :

- **Source autoritaire — EPG global / XMLTV** : croisement direct du catalogue live
  avec l’EPG global (`buildReplaysFromGlobalEpg`), filtré sur les chaînes
  `supportsReplay` et les programmes **terminés**. C’est la source multi-jours réelle.
- **Sonde asynchrone en tâche de fond** (`replaysProbeProvider`) : jeu de sondes
  **stratifié par catégorie** (`replayProbeSet`), plafonné à un **budget strict**
  (40 chaînes, 3 par groupe, concurrence de 2 workers) pour éviter l’effet de seuil
  (429 Too Many Requests et bannissement anti-leech IP). Résultat fusionné avec
  l’EPG global via `mergeReplays`.
- **Lazy loading par chaîne** (`channelReplaysProvider`) : chaque détail de chaîne est
  fetché **à la demande** (`get_simple_data_table`, avec **repli** sur
  `get_short_epg`), évitant de saturer le serveur au démarrage.

---

## 3. Moteur de résolution d’URL (`CatchupUrl` & fallback)

- **Approche template-first** (`CatchupUrl.resolve`) : le système analyse en priorité
  le template `catchup-source` déclaré par le fournisseur. Il gère dynamiquement la
  substitution des variables d’horodatage (`{utc}`, `{start}`, `{lutc}`, `{now}`,
  `{duration}`, `{offset}`, composantes ISO `{Y}{m}{d}{H}{M}{S}`) et interprète les
  modes spécifiques (`append`, chemins relatifs Flussonic, etc.).
- **Repli Xtream** (`buildXtreamTimeshiftUrl`) : en l’absence de template, bascule sur
  la convention standard de l’API Xtream Codes
  (`/timeshift/user/pass/duration/stamp/id.ext` — durée en **minutes**, date
  `YYYY-MM-DD:HH-mm`).

---

## 4. Gestion d’état et caching (`/providers`)

- **`ReplaysCache` (TTL 5 min)** : cache mémoire partagé avec mécanisme de
  **déduplication en vol** (`_inFlight`) pour éviter les requêtes redondantes lors de
  la navigation.
- **`_ChannelReplaysCache` (TTL 10 min)** : cache fin par identifiant de chaîne pour
  les requêtes de niveau 2.
- **Fournisseurs Riverpod asynchrones** :
  - `replaysProvider` : fournisseur **rapide non bloquant**, s’appuie sur le cache de
    sonde et l’EPG global ;
  - `replaysProbeProvider` : sonde de fond qui alimente le cache ;
  - `channelReplaysProvider` : détail d’une chaîne (`autoDispose.family`) ;
  - `channelCatchUpProvider` : filtrage strict des programmes **passés**
    (`_pastPrograms`) pour l’accès depuis la grille EPG. Source = **EPG complet
    de la chaîne** (`get_simple_data_table`, repli `get_short_epg`) avec une
    **fenêtre = durée de l’abonnement** (7/14 j). Cache **dédié**
    (`catchUpEpgCacheProvider`) pour ne pas se faire servir l’aperçu court écrit
    par la barre du lecteur.

---

## 5. Ergonomie et UI (`ReplayScreen` & `CatchUpScreen`)

**Navigation à deux niveaux (`ReplayScreen`)** :

- **Niveau 1** : grille de chaînes filtrée sur `supportsReplay`, couplée à un rail de
  catégories et aux tris Favoris / Récents. Aucun appel réseau (catalogue déjà chargé).
- **Niveau 2** : vue détaillée par chaîne avec **sélecteur de jours chronologique** et
  liste verticale de slots (horaires au format **local**).

**Point d’entrée EPG (`CatchUpScreen`)** : accessible par **appui long sur une
*chaîne*** de la grille EPG (`onChannelLongPress`), et uniquement si
`channel.supportsReplay`. Il utilise désormais le **même résolveur de flux**
(`replayStreamUrl`) que l’écran Replay principal, garantissant un comportement
identique.

---

## 6. Garde-fous et points de vigilance

- **Fenêtre d’archive honorée, pas plafonnée à 48 h.** `archiveWindow(channel)`
  renvoie **la déclaration du panel** (`tv_archive_duration` / `catchup-days` → 7 j,
  14 j…) et ne retombe sur **48 h qu’en repli** quand rien n’est déclaré. Un 48 h
  codé en dur filtrait à tort les replays d’un compte annonçant 7 jours. Côté EPG,
  `channelCatchUpProvider` applique la même logique avec un repli à **7 jours**
  (`archiveDays > 0 ? archiveDays : 7`).
  **Diagnostic décisif** : le puits réel n’était pas la fenêtre mais la **source**
  — `channelCatchUpProvider` interrogeait `get_short_epg` (4 entrées, quasi toutes
  futures), qui ne peut pas porter d’historique. Le passage à
  `get_simple_data_table` (via `fetchChannelCatchUpPrograms`) est ce qui débloque
  le rattrapage > 48 h — et c’est la source qu’emploie XCIPTV.
- **Anti-429 / anti-leech.** La sonde est plafonnée (budget, par-groupe, concurrence)
  car sonder tout le catalogue déclenche l’anti-leech et vide EPG/Films/Live au passage.
- **Décodage Base64.** Les titres et synopsis passent par `PanelText.decode` sur les
  deux appels d’EPG (`get_short_epg` **et** `get_simple_data_table`), sinon des titres
  lisibles côtoient des chaînes Base64 brutes dans une même liste.
- **Intégrité de l’i18n.** Correction de l’encodage des fichiers de localisation
  (`.arb` en UTF-8 natif **sans BOM**) pour éradiquer les corruptions de caractères
  sur les composants textuels et les carrousels UI. Diagnostic : les `.arb` et les
  fichiers générés étaient **double-encodés** (CP1252 puis CP850 selon les commits) ;
  correction = restauration des ARB propres + repair ciblé + `flutter gen-l10n`
  (0 `U+FFFD`, 0 caractère de boîte résiduel dans les 7 fichiers générés).

---

## Annexe — trajet en une phrase

```
XMLTV global ─┐
              ├─► buildReplaysFromGlobalEpg ─┐
get_live_streams ┘                            ├─► mergeReplays ─► replaysProvider ─► ReplayScreen (niveau 1)
get_short_epg ─► _fetchChannelReplayPrograms ─┘
                                              └─► channelReplaysProvider ─► ReplayScreen (niveau 2)
get_simple_data_table ─► _fetchChannelFullEpg ─┘        (tap programme)
                                                        └─► replayStreamUrl ─► /player

get_simple_data_table ─► fetchChannelCatchUpPrograms ─► channelCatchUpProvider ─► CatchUpScreen
                        (EPG complet, passé compris)                                (appui long chaîne)
```
