---
title: "[BUG] - Moyen : Absence de gestion d'état réseau (connexion perdue / serveur injoignable)"
labels: ["bug", "triage-required", "criticality:moyen", "module:donnees"]
---

## Version de l'application
Bêta Xtream / M3U.

## Appareil / Modèle
Samsung Galaxy S20 5G (SM-G988B), Android 13.

## Version Android
13 (API 33).

## Criticité
- [x] 🟡 Moyen (gêne non bloquante : messages réseau peu clairs)

## Module concerné
- [x] 💾 Données / Base
- [x] ⚙️ Paramètres

## Description du problème
Lorsque le réseau est coupé ou le serveur injoignable, les erreurs réseau ne sont pas toujours présentées clairement à l'utilisateur (temps d'attente, messages techniques vagues).

## Comportement attendu
En cas de perte de connexion, l'app devrait afficher un message clair et rapide (ex. "Connexion impossible, vérifie ton réseau") sans blocage prolongé.

## Étapes pour reproduire
1. Couper la connexion réseau du téléphone.
2. Charger un écran qui appelle l'API (Live TV / VOD / EPG).
3. Constater le comportement (temps de blocage et/ou message imprécis).

## Journal / Logs
Sur des serveurs non joignables (ex. `sofia.rabaden.eu` depuis un poste de dev) : connexion interrompue (`La connexion sous-jacente a été fermée`, HTTP 000 via curl), ce qui peut laisser l'UI en attente sans retour rapide.

## Diagnostic / Analyse
- Un timeout réseau global a été ajouté dans `ApiService` (connect 15s, receive 30s) et des exceptions typées (`StreamNetworkException`) introduites dans cette itération.
- **Point restant** : diffuser l'état réseau à l'UI (message utilisateur clair et immédiat dans les différents écrans) et optionnellement afficher un état hors-ligne / bouton "Réessayer" au niveau écran. Vérifier que toutes les routes (Live, VOD, EPG, Séries, Replay) gèrent l'exception et ne propagent pas de blocage.

## Informations complémentaires
- Amélioration partielle livrée dans le commit `5309d4e` (timeout + retry + exceptions typées côté `ApiService` / `stream_helpers.dart`). À parfaire côté UI écrans.
