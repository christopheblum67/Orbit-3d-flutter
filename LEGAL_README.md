# Orbit IPTV - Documentation Juridique & Conformité

> **Version :** 1.0.0  
> **Date :** 2024  
> **Application :** Orbit IPTV (anciennement Orbit 3D)  
> **Plateforme :** Android TV / Fire TV / Android Mobile  

---

## ⚖️ AVERTISSEMENT LÉGAL IMPORTANT

> **CE DOCUMENT NE CONSTITUE PAS UN CONSEIL JURIDIQUE PROFESSIONNEL.**  
> Les informations ci-dessous sont fournies à titre informatif uniquement.  
> **Consultez un avocat spécialisé en droit du numérique / propriété intellectuelle** avant la mise en production commerciale.

---

## 1. QUALIFICATION JURIDIQUE DE L'APPLICATION

### 1.1 Nature du service
Orbit IPTV est une **application lecteur (player) IPTV** qui :
- Affiche des flux vidéo fournis par des **serveurs tiers** (fournisseurs IPTV / M3U / Xtream Codes)
- **N'héberge aucun contenu** vidéo, audio ou sous-titre
- Ne fait qu'**agréger et présenter** des métadonnées (EPG, affiches, synopsis) récupérées via API publiques
- Fonctionne comme un **navigateur spécialisé** pour flux HLS/DASH

### 1.2 Responsabilité éditoriale
L'application **n'est pas un éditeur de contenu** au sens de la loi :
- Aucune sélection éditoriale des chaînes/contenus
- Aucune modification du flux original
- Simple intermédiaire technique (lecteur + interface)

---

## 2. CADRE RÉGLEMENTAIRE EUROPÉEN (RGPD, ePrivacy, DSA)

### 2.1 RGPD (Règlement 2016/679)

| Obligation | Statut | Implémentation |
|------------|--------|----------------|
| **Base légale** | ✅ | Intérêt légitime (fonctionnement) + Consentement (notifications, analytics) |
| **Privacy by Design** | ✅ | Aucune collecte par défaut, opt-in explicite |
| **Droit d'accès** | ⚠️ | À implémenter : export JSON profil/historique |
| **Droit à l'effacement** | ⚠️ | À implémenter : suppression compte + données |
| **Portabilité** | ⚠️ | Export JSON/CSV geplant |
| **DPO** | ❌ | Non requis (< 250 employés, pas traitement sensible) |
| **Registre des traitements** | ✅ | Documenté ci-dessous |

#### Registre des traitements (Art. 30 RGPD)

| Finalité | Base légale | Données | Durée | Destinataires |
|----------|-------------|---------|-------|---------------|
| Authentification profil | Exécution contrat | Prénom, DoB, genre, avatar | Durée vie compte + 3 ans | Stockage local (Hive) |
| Favoris / Historique | Intérêt légitime | IDs contenus, timestamps | 2 ans glissants | Local uniquement |
| Préférences UI | Consentement | Thème, langue, densité | Durée vie compte | Local uniquement |
| Notifications push | Consentement explicite | Token FCM, préférences | Jusqu'à rétractation | Firebase (Google) |
| Crash reports | Intérêt légitime | Stack trace, device info | 90 jours | Sentry / Firebase Crashlytics |
| Analytics anonymes | Consentement | Événements UI anonymes | 13 mois | Firebase Analytics |

### 2.2 Directive ePrivacy (2002/58/CE)

- **Cookies / Stockage local** : Hive (SQLite local) → pas de cookies tiers
- **Notifications push** : Consentement explicite requis (opt-in) avant demande token FCM
- **Communications électroniques** : Aucuns emails/SMS marketing sans consentement

### 2.3 Digital Services Act (DSA - Règlement 2022/2065)

> **S'applique si** : L'application agit comme "plateforme en ligne" (hébergement contenu tiers)

| Critère DSA | Statut Orbit IPTV |
|-------------|-------------------|
| Hébergement contenu utilisateur | ❌ Non (pas d'upload utilisateur) |
| Modération contenu | ❌ Non applicable |
| Transparence algorithmes | ❌ Pas d'algo de recommandation opaque |
| Signalement contenu illicite | ❌ Non applicable |
| **Conclusion** | **Hors champ DSA** (simple player technique) |

---

## 3. PROPRIÉTÉ INTELLECTUELLE & DROITS D'AUTEUR

### 3.1 Contenus diffusés (Flux IPTV)

| Acteur | Responsabilité |
|--------|----------------|
| **Fournisseur IPTV** (votre client) | **Seul responsable** : Licences chaînes, droits de diffusion, géoblocage |
| **Orbit IPTV** (votre app) | **Intermédiaire technique** : Simple affichage flux, pas de stockage |

> ⚠️ **RISQUE MAJEUR** : Si votre client diffuse sans licence → **Contrefaçon** (Art. L.335-2 CPI FR / Dir. 2001/29/CE UE).  
> L'application **doit inclure** une clause contractuelle : *"Le fournisseur garantit détenir tous droits nécessaires."*

### 3.2 Métadonnées (EPG, affiches, synopsis)

| Source | Risque | Mitigation |
|--------|--------|------------|
| API publiques (TMDb, TVDb, IMDb) | Licence CC BY / API Terms | Respecter conditions API (attribution, rate limit) |
| Logos chaînes (logos gratuits) | Copyright / Marques | Utiliser logos officiels fournisseur ou placeholders |
| EPG (XMLTV) | Souvent copyright | Vérifier licence XMLTV provider |

> **Recommandation** : Ne pas scraper. Utiliser APIs officielles avec clé.

### 3.3 Code source & Marque "Orbit IPTV"

- **Code source** : Propriétaire (closed source) ou Open Source (MIT/Apache-2.0 si publié)
- **Marque "Orbit IPTV"** : Déposer à l'INPI (FR) + EUIPO (UE) + WIPO (International)
- **Logo / Design** : Déposer en modèle/dessein (CNRS/INPI)

---

## 4. CONFORMITÉ TECHNIQUE & SÉCURITÉ

### 4.1 Sécurité applicative

| Mesure | Statut |
|--------|--------|
| **Chiffrement stockage** | ✅ Hive chiffré (AES-256) |
| **TLS 1.3** | ✅ ExoPlayer + reqwest-impersonate (Rust proxy) |
| **PIN / Biométrie** | ⚠️ Prévu (ProfileType.child/expert) |
| **Certificate Pinning** | ⚠️ À implémenter (API backend) |
| **Code Obfuscation** | ✅ Flutter release + ProGuard/R8 |

### 4.2 Accessibilité (WCAG 2.1 AA / EN 301 549)

| Critère | Statut | Action |
|---------|--------|--------|
| Contraste (4.5:1) | ✅ | Thème dark par défaut |
| Texte redimensionnable | ✅ | `fontScale` paramétrable |
| Navigation clavier/remote | ✅ | Focus management complet |
| Descriptions audio | ⚠️ | Prévu (ProfilePreferences) |
| Sous-titres | ✅ | ExoPlayer natif |
| Contraste élevé | ✅ | Thème "High Contrast" prévu |

---

## 5. CONFORMITÉ MONDIALE (HORS UE)

| Juridiction | Réglementation clé | Points d'attention |
|-------------|-------------------|-------------------|
| **USA** | DMCA (17 USC 512) | Procédure notice & takedown si contenu US |
| **Canada** | Copyright Act / CASL | Consentement explicite notifications |
| **UK** | UK GDPR / DPA 2018 | Équivalent RGPD post-Brexit |
| **Brésil** | LGPD (Lei 13.709) | DPO requis si traitement brésilien |
| **Australie** | Privacy Act 1988 / APP | Notifiable Data Breaches |
| **Chine** | PIPL / CSL | Stockage local Chine requis si users CN |
| **Inde** | DPDP Act 2023 | Consentement granulaire, DPO |

> **Stratégie** : Déployer par région avec feature flags (Firebase Remote Config)

---

## 6. CONTRACTUEL - RELATIONS TIERS

### 6.1 Contrat Fournisseur IPTV (B2B)

**Clauses indispensables :**
```markdown
1. **Garantie de droits** : Le Fournisseur garantit détenir toutes licences
   nécessaires pour la diffusion des chaînes dans les territoires ciblés.

2. **Indemnisation** : Le Fournisseur indemnise l'Éditeur (Orbit IPTV)
   contre toute action en contrefaçon liée aux flux fournis.

3. **SLA** : Disponibilité 99.9%, support 24/7, géoblocage respecté.

4. **Audit** : Droit d'audit technique (DRM, géoblocage, logs d'accès).

5. **Résiliation** : Résiliation immédiate en cas de contrefaçon avérée.
```

### 6.2 Conditions Générales d'Utilisation (CGU) - Utilisateurs finaux

**Points obligatoires :**
- [ ] Âge minimum (13+ / 16+ selon juridiction)
- [ ] Interdiction contournement géoblocage / DRM
- [ ] Interdiction partage compte (sauf profil famille)
- [ ] Responsabilité utilisateur : usage légal uniquement
- [ ] Limitation responsabilité éditeur (force majeure, coupure flux)
- [ ] Droit de résiliation unilatéral
- [ ] Loi applicable / Juridiction (ex: Tribunal de Paris)

---

## 6. MONÉTISATION & TVA

| Modèle | TVA (UE) | Règles |
|--------|----------|--------|
| **Abonnement** (B2C) | TVA pays client | OSS/IOSS obligatoire >10k€/an |
| **Achat in-app** (Google Play) | Google perçoit | 15-30% commission |
| **B2B** (Revendeurs) | TVA prestataire | Autoliquidation |

> **One-Stop Shop (OSS)** : Obligatoire si CA UE > 10k€/an hors pays d'établissement.

---

## 7. CHECKLIST MISE EN PRODUCTION

### Pré-lancement (T-30j)
- [ ] Contrat fournisseur IPTV signé + audit droits
- [ ] CGU / CGV / Politique confidentialité en ligne (FR/EN)
- [ ] Mentions légales complètes (éditeur, hébergeur, DPO)
- [ ] Déclaration CNIL (si traitement sensible) / DPO nommé
- [ ] Déclaration TVA OSS/IOSS si CA UE prévu
- [ ] Marque "Orbit IPTV" déposée (INPI/EUIPO)
- [ ] Conditions Google Play / Apple TV validées
- [ ] Tests pénétration / Audit sécurité (OWASP MASVS)

### Lancement (T-0)
- [ ] Déploiement progressif (5% → 25% → 100%)
- [ ] Monitoring temps réel (Sentry, Firebase, uptime)
- [ ] Plan de communication crise (modèle communiqué)
- [ ] Procédure retrait contenu illicite (< 24h)

### Post-lancement (T+30j)
- [ ] Audit RGPD (DPIA si profiling)
- [ ] Rapports transparence (DSA si applicable)
- [ ] Renouvellement marques / noms de domaine
- [ ] Revue contrats fournisseurs (annuelle)

---

## 8. MODÈLES DE DOCUMENTS (À CRÉER)

### 8.1 Politique de Confidentialité (FR/EN)
> Basée sur Art. 12-14 RGPD : langage clair, accessible, layers (résumé + détail)

### 8.2 Conditions Générales d'Utilisation (CGU)
> Inclure : clause limite responsabilité, loi applicable, médiation

### 8.3 Politique Cookies / Stockage
> Même si pas de cookies tiers : expliquer Hive local, finalités

### 8.4 Procédure Signalement Contenu Illicite
> Formulaire en ligne + email dédié (abuse@orbit-iptv.com) + délai 24h

### 8.4 Registre des Violations Données (Data Breach Register)
> Template notification CNIL / 72h

---

## 9. CONTACTS & RESSOURCES

| Rôle | Contact | Ressource |
|------|---------|-----------|
| **DPO** (si requis) | dpo@orbit-iptv.com | CNIL guide DPO |
| **Legal** | legal@orbit-iptv.com | Cabinet spécialisé IT/IP |
| **Abuse** | abuse@orbit-iptv.com | Phishing, contrefaçon, CSAM |
| **Security** | security@orbit-iptv.com | Bug bounty (YesWeHack/Intigriti) |
| **Support** | support@orbit-iptv.com | Zendesk / Intercom |

### Ressources officielles
- **CNIL** : https://www.cnil.fr/rgpd-guide
- **EUIPO** : https://euipo.europa.eu (marques)
- **INPI** : https://www.inpi.fr (marques FR)
- **EUIPO DSA** : https://digital-services-act.europa.eu
- **WIPO** : https://www.wipo.int (marques internationales)

---

## 10. HISTORIQUE DES VERSIONS

| Version | Date | Auteur | Changements |
|---------|------|--------|-------------|
| 1.0.0 | 2024 | Équipe Orbit IPTV | Version initiale |

---

## ⚠️ CLAUSE DE NON-RESPONSABILITÉ FINALE

> Ce document est un **guide de conformité** basé sur l'état du droit au 2024.  
> La législation évolue rapidement (DSA, DMA, AI Act, ePrivacy reform).  
> **Aucune responsabilité** ne saurait être engagée par les auteurs pour tout dommage direct ou indirect résultant de l'utilisation de ce document.  
> **Validation juridique impérative** par un avocat qualifié avant toute mise en production.

---

*Document généré pour Orbit IPTV - Confidentiel - Usage interne uniquement*