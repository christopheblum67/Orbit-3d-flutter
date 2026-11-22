# EPG — grille : index

> Fiches générées par `tool/gen_epg_grid_doc.dart` (extraction fidèle du code, commentaires compris). Découpage : un fichier par couche, borné à 400 lignes de code, puis chaque bloc borné à 200 lignes — un copier-coller ne dépasse jamais cette taille.

## Pipeline de la grille EPG

```text
DONNÉES (panneau)              CODE                                      AFFICHAGE
───────────────────────────────────────────────────────────────────────────────────
xmltv.php (dump ~94k) ─► fetchEpg ─► EpgStreamParser.parse (isolate)
                                      │
                                      ▼
                                EPGDataCache.loadFull ─┐
                                                        ▼
get_short_epg ─► fetchChannelEpgPrograms ─► shortEpg  _resolveChannelEpg
                                          Cache       (cache court → XMLTV
                                                       → repli réseau borné)
                                                          │
        ┌─────────────────────────────────────────────────┼──────────────────┐
        ▼                        ▼                                 ▼
 channelEpgWindowProvider   channelEpgProvider            EPGProgramsNotifier
  (GRILLE, passé compris,    (barre lecteur :              (dump global partagé)
   AUCUN réseau)              « en cours + à venir »)
        │
        ▼
 EpgGrid2dView ◄─ EpgTimeline (heures) ◄─ EpgHeadbar / EpgScrollGesture
        ├─ EpgMiniProgramBar / EpgPreviewHeader
        └─ appui long sur une CHAÎNE ─► CatchUpScreen
             └─ channelCatchUpProvider ─► fetchChannelCatchUpPrograms
                                          (get_simple_data_table)
```

## Fiches

| # | Couche | Fichiers |
|---|--------|----------|
| 1 | 1. modèles et utilitaires purs | 01-modeles.md |
| 2 | 2. cache et providers Riverpod | 02-cache-providers-part1.md … 02-cache-providers-part2.md |
| 3 | 3. récupération (ApiService) et parseurs | 03-api-epg-part1.md … 03-api-epg-part3.md |
| 4 | 4. la grille 2D | 04-grille-2d-part1.md … 04-grille-2d-part5.md |
| 5 | 5. timeline, gestes et en-têtes | 05-timeline-headers-part1.md … 05-timeline-headers-part4.md |
| 6 | 6. l’écran EPG | 06-ecran-epg-part1.md … 06-ecran-epg-part3.md |
| 7 | 7. rattrapage et recherche | 07-rattrapage-recherche-part1.md … 07-rattrapage-recherche-part3.md |
| 8 | 8. annexe — orbite 3D | 08-orbite-3d-annexe-part1.md … 08-orbite-3d-annexe-part5.md |

## Note de découpage

- Les fiches `…-partN.md` sont des **morceaux du même module** : à lire/coller dans l’ordre.
- Les numéros de ligne sont ceux du dépôt au moment de la génération ; relancer le générateur après une modification du code.
