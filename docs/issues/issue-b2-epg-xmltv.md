---
title: "[BUG] - Élevé : EPG (guide TV) impossible à charger (parseXmltv / XMLTV)"
labels: ["bug", "triage-required", "criticality:eleve", "module:epg"]
---

## Version de l'application
Bêta Xtream (lot Xtream).

## Appareil / Modèle
Samsung Galaxy S20 5G (SM-G988B), Android 13.

## Version Android
13 (API 33).

## Criticité
- [x] 🟠 Élevé (fonction majeure en panne : guide TV inutilisable)

## Module concerné
- [x] 📡 EPG (Guide TV)

## Description du problème
La récupération de l'EPG (programme TV) échoue. Le parseur XMLTV ne gère pas le format de date utilisé par les serveurs Xtream.

## Comportement attendu
Le guide TV devrait afficher les programmes des chaînes (titre, horaire, description).

## Étapes pour reproduire
1. Ouvrir l'app sur un profil Xtream.
2. Accéder au guide/EPG d'une chaîne (module EPG).
3. Constater l'échec de chargement.

## Journal / Logs
Format de date XMLTV non supporté par `DateTime.parse` :
```
start="20260830090000 +0200"   <- format XMLTV (YYYYMMDDHHMMSS + offset)
```
Ce format provoque une `FormatException` dans `DateTime.parse`, rendant l'écran EPG inutilisable.

## Diagnostic / Analyse
- Dans `lib/services/api_service.dart`, `parseXmltv` appelle `DateTime.parse(prog.getAttribute('start'))`.
- Le format XMLTV standard est `YYYYMMDDHHMMSS +ZZZZ` (ex. `20260830090000 +0200`), qui n'est **pas** parsable directement par `DateTime.parse` (attendu `YYYY-MM-DD HH:MM:SS`).
- **Fix attendu** : parser manuellement le format XMLTV (sous-chaîne date + heure, appliquer l'offset) ou convertir en format ISO avant `DateTime.parse`. À confirmer aussi pour l'attribut `stop`.

## Informations complémentaires
- Hors périmètre des équipes senior/junior de cette itération (Bug B2 identifié en audit et non encore corrigé).
