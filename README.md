# 🪐 ORBIT 3D

https://github.com/christopheblum67/orbit-3d

Application de streaming IP-TV 3D (Flutter).

---

## 🧪 Phase de test bêta — Guide pour les testeurs

Merci de faire partie du programme de test ! Votre retour est essentiel pour améliorer Orbit 3D.

### 📥 Installer l'application

1. Ouvrez l'onglet **Releases** de ce dépôt (https://github.com/christopheblum67/Orbit-3d-flutter/releases)
2. Téléchargez la dernière version **bêta** (fichier `.apk`)
3. Sur votre appareil Android, autorisez l'installation de sources inconnues (Paramètres > Sécurité) si demandé
4. Installez le fichier `.apk` et lancez l'application

### 🐞 Signaler un bug

Utilisez le modèle de rapport fourni dans l'onglet **Issues** → **New issue** → **Bug Report**.

Renseignez notamment :
- La **criticité** (🔴 Critique / 🟠 Élevé / 🟡 Moyen / 🟢 Faible)
- Le **module** concerné
- Les **étapes pour reproduire** le bug
- Le **modèle d'appareil** et la **version Android**
- Les **logs** si disponibles

Chaque bug est automatiquement classé par criticité puis rattaché à une **phase de correctif**.

### 📅 Cycle de correction par phase

| Phase | Bugs traités |
|-------|---------------|
| Phase 1 | 🔴 Critiques + 🟠 Élevés |
| Phase 2 | 🟡 Moyens |
| Phase 3 | 🟢 Faibles + retours |

Une fois corrigés, les correctifs sont publiés en nouvelle version bêta, puis les bugs sont fermés après validation.

### 🔑 Modes Test Panels
* Pro : TEST-PANEL-PRO-2026
* Free : TEST-PANEL-FREE-2026

---
## 🛠️ Pour les développeurs

### Pipeline CI/CD
- `.github/workflows/dart.yml` — Build APK + analyse + tests sur chaque push `main`
- `.github/workflows/publish-beta.yml` — Publie une version bêta en GitHub Release (déclenchement manuel)
- `.github/workflows/triage.yaml` — Triage automatique des bugs par criticité
- `.github/workflows/phase-tracking.yml` — Suivi des phases de correction

### Créer les labels (une fois par dépôt)
```bash
# Depuis la racine, avec gh CLI authentifié
gh label create --force 2>/dev/null; 
# ou utilisez une application comme "Label 3" / importez `.github/labels.yml`
```

### Publier une version bêta pour les testeurs
1. Allez dans l'onglet **Actions** → **Publish Beta (100 testeurs)**
2. Cliquez **Run workflow**
3. (Optionnel) renseignez un tag de version et des notes de release
4. Le workflow construit l'APK et publie une nouvelle Release
5. Partagez le lien de la Release aux 100 testeurs
