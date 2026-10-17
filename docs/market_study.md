# Orbit IPTV — Étude Marketing & Stratégie (17/10/2026)

## 1. Profil Application
- **Nom** : Orbit IPTV
- **Plateforme** : Android (arm64 + x86_64), API 33+
- **Usage** : Télévision (D-pad, télécommande Android, mode TV forcé)
- **Design** : 3D/Spatial (EPG grille 2D, constellation, planète orbitale, focus lumineux)
- **Contenu** : Live TV, VOD, Séries, Replay, EPG, Sous-titres (OpenSubtitles), Replay, Matchmaking Duo

## 2. Analyse par Dimension

### Design
- **Force** : Palette cyan/indigo/rose, arrondis généreux, typographie dynamique, effets 3D uniques
- **Faiblesse** : Encadré portrait (corrigé : `maxCrossAxisExtent: 140`), trop dense sur téléphone

### Juridique
- **Clés API** : `SecretStore` (Keystore RSA OAEP + AES-GCM) — sécurité haute
- **Sous-titres** : Intégrés + OpenSubtitles — risque de blocage API
- **Manques** : Pas de consentement RGPD visible, pas de conditions d'utilisation dans le code

### Ergonomie
- **TV Navigation** : Complète (`TvFocus`, `TvSafeArea`, `EpgGrid2DView` avec `_onGridKey`)
- **Zapping** : Présent mais signalé compromis (agent C en cours)
- **Recherche** : Adaptée TV (`SearchScreen` + `tvModeControllerProvider`) — delegate incomplet

### Futuriste
- **Détection TV auto** : Multi-méthodes (`leanback`, taille, UI mode)
- **MediaSession native** : `BackgroundPlaybackService` (foreground service + notification)
- **Matchmaking Duo** : Original (`duo_profile_selection_screen.dart`)

### Concurrence
- **Tivimate / IPTV Smarters / StbEmu / OTT Navigator / Perfect Player**
- **Avantage** : Design 3D + détection TV + MediaSession complète + matchmaking

## 3. Options de Monétisation

| Option | Prix | Sources | Risque / Recommandation |
|--------|------|---------|------------------------|
| **Gratuite** | 0€ | Pub in-app limitée | Dégradation TV ; éviter |
| **Payante** | 4,99€/mo | Abonnement direct | Bon pour usage sérieux |
| **Hybride (recommandé)** | 0€ / 4,99€ | Gratuit + Premium (replay 30j, multi-profil, pas de pub) | Meilleur modèle ; test 7j |

## 4. Améliorations Prioritaires

### Immédiates (faites)
- Grilles 2 colonnes portrait (`8308a23`)
- Synopsis rouge (`7103fd6`)
- Fusion menus (`de561d7`)

### Court terme (3-6 mois)
- SearchScreen TV delegate complet
- MediaSession bridge validation S20
- Mode cinéma automatique

### Long terme (6-12 mois)
- Reconnaissance vocale
- Matchmaking social (chat sync)
- Statistiques écoute (Wrapped-style)

## 5. Qualité du Projet
- **Tests** : 986 verts
- **Analyse** : 0 erreur (modifiés)
- **Commits** : 13 terminés + fichi TODO `b8e722d`
- **APK** : 37 Mo (`Orbit-IPTV.apk` sur Bureau / S20)
- **Device** : S20 connecté (R5CN21FYWWT), installé
- **Agents** : A/B/C relancés (ollama `deepseek-coder:6.7b` en pull)

---
*Document généré lors des chantiers LOW du 17/10/2026. Toutes les preuves (tests, commits, APK) sont dans le dépôt et le Bureau.*
