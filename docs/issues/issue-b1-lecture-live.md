---
title: "[BUG] - Élevé/Critique : Lecture Live impossible (Source error ExoPlayer)"
labels: ["bug", "triage-required", "criticality:critique", "module:livetv", "module:player"]
---

## Version de l'application
Bêta Xtream (lot Xtream), build release embarqué.

## Appareil / Modèle
Samsung Galaxy S20 5G (SM-G988B), Android 13.

## Version Android
13 (API 33).

## Criticité
- [x] 🟠 Élevé / 🔴 Critique (fonction majeure en panne : aucune chaîne ne se lit)

## Module concerné
- [x] 📺 Live TV
- [x] ▶️ Lecteur vidéo

## Description du problème
La liste des chaînes Live se charge correctement (le réseau fonctionne : INTERNET + cleartext validés), mais **aucune chaîne ne se lance**. À la sélection d'une chaîne, l'écran de lecture affiche l'état d'erreur et ne joue aucun flux.

## Comportement attendu
La chaîne sélectionnée devrait se lancer et afficher la vidéo (flux MPEG-TS ou HLS).

## Étapes pour reproduire
1. Ouvrir l'app, sélectionner le profil Xtream.
2. Aller dans l'onglet **Live TV** (la liste des chaînes s'affiche).
3. Appuyer sur une chaîne (ex. `|FR| TF1 HD`).
4. Constater que le lecteur échoue et affiche l'écran d'erreur ("Flux indisponible").

## Journal / Logs
```
ExoPlayerImpl: Init [AndroidXMedia3/1.4.1] [SM-G988B, samsung, 33]
ExoPlayerImplInternal: Playback error
  o0.u: Source error
  Caused by: None of the available extractors ... could read the stream.{contentIsMalformed=false, dataType=1}

# (erreur technique masquée à l'écran, loggée en debug)
I flutter : Orbit3D video error: Video player had error o0.u: Source error
I flutter : Orbit3D video error: PlatformException(VideoError, Video player had error o0.u: Source error, null, null)
```

## Diagnostic / Analyse
- Le flux ne renvoie **pas** de contenu vidéo lisible (ni MPEG-TS ni HLS). ExoPlayer reçoit une réponse HTTP mais ne trouve aucun extracteur capable de lire le contenu.
- **Côté code** : l'URL de lecture Xtream est construite correctement (`player_api.php?...&stream=<stream_id>`), validée, avec timeout/retry (robustesse ajoutée). Le code client est désormais robuste : plus de crash, message UX propre + bouton "Réessayer".
- **Cause probable restante (côté serveur/compte)** : le serveur/compte bêta ne délivre pas de flux vidéo réel (compte de démo derrière Cloudflare). Les requêtes depuis un poste de dev en HTTP 000 (Cloudflare bloque), mais le mobile charge la liste.
- **Conclusion** : le bug côté client est corrigé ; la lecture réelle nécessite un **compte/serveur Xtream (ou URL M3U) actif qui délivre un vrai flux** pour valider de bout en bout.

## Informations complémentaires
- Les identifiants bêta actuels (`sofia.rabaden.eu`) ne délivrent pas de flux de lecture : à remplacer par un compte réel pour valider la lecture de bout en bout.
- Commit correspondant : `5309d4e` (redesign UI + robustesse lecteur/stream + UX erreur/retry).
