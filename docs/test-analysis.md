---
title: "Audit des tests — paliers P1/P2/P3 + documentation"
labels: ["qa", "tests", "ci"]
---

# Audit des tests — Orbit3D

Rapport établi par 3 agents d'analyse parallèles (inventaire, écarts critiques,
CI/documentation), mis à jour après la session N1 (Séries/VOD/Live).

## État actuel

- **5 fichiers, 22 tests unitaires** : `api_service_test` (7), `stream_helpers_test` (5),
  `app_constants_test` (4), `user_profile_test` (1), + rajoutés récemment
  `series_model_test` (4) et `series_info_parse_test` (1).
- **0 widget test** : l'UI (navigation, formulaires, player, contrôle parental) n'est pas couverte.
- Aucun setup Hive/SharedPreferences dans la suite (tests « unitaires purs »).
- Commandes vérifiées : `flutter analyze` → 0 erreur, `flutter test` → 22 tests verts.

## P1 — Critique

- **CI `dart.yml` ne lance ni `flutter test` ni `flutter analyze`** : la CI n'empêche
  aucune régression. Ex. les bugs `rating` en String (écran Séries en panne) et
  l'interpolation `$objet.champ` en Dart n'ont été attrapés que par les nouveaux tests.
- **Secret réel en clair dans `.github/workflows/publish-beta.yml`** (identifiants
  Xtream/M3U du serveur beta). À passer en secrets GitHub Actions / variables d'env
  du runner + gitignore.
- Chemins métier critiques non couverts : **migration Preferences → Hive**,
  **`SubscriptionProvider.testConnection`** (le 404 du serveur renvoyé sur mauvais
  identifiants), **endpoints de streaming** (construction d'URL + mapping).

## P2 — Correctifs

- **`stream_helpers_test` non déterministe** : `.toLocal()` sur les dates XMLTV dépend
  du fuseau horaire de la machine. Rendre le fuseau explicite.
- Renforcer les tests de modèles avec les **fixtures réelles du serveur**
  (déjà amorcé : `test/fixtures/series2.json`, série « The Rain ») — c'est ce qui a
  permis de détecter 2 bugs de parsing en session.
- Couvrir `fetchSeriesInfo` / `fetchLiveChannels` / `fetchMovies` (URL + mapping).

## P3 — Nice-to-have

- **Contrôle parental jamais appliqué** : la restriction d'âge est stockée mais aucun
  écran/filtre ne l'applique au contenu (manque test + feature — à cadrer produit).
- Reads sont non tracés : à la fois un manque de test et un manque de feature.
- README insuffisant : pas de section build/test ni doc `.env`/scripts.
- `install-ollama-service.bat` présent mais non suivi par git.

## Recommandation immédiate

Ajouter dans `dart.yml` :

```yaml
flutter analyze
flutter test
```

Aucun autre changement de code nécessaire pour que la CI devienne utile.