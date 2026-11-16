# Mises à jour Android

Dans **Réglages → Avancé → Mises à jour**, la recherche est manuelle. Seules les releases GitHub stables et publiées sont proposées ; les préreleases bêta ne le sont pas. Aucune installation n'est automatique : Android demande une confirmation et, si nécessaire, l'autorisation d'installer des applications inconnues.

Pour publier une mise à jour compatible :

1. Augmenter la version `major.minor.patch` et le `versionCode` Android (`version: x.y.z+n` dans `pubspec.yaml`). La release doit porter le tag `vx.y.z` ou `vx.y.z+n`, correspondant à l'APK.
2. Construire un APK universel incluant les architectures prises en charge, avec le même identifiant d'application et la même clé de signature que la version installée.
3. Créer une release stable publique dans ce dépôt et y joindre exactement un fichier nommé `orbit-3d-universal.apk`. GitHub doit fournir son empreinte SHA-256 dans les métadonnées de l'asset.

L'application vérifie la taille et l'empreinte publiées, puis refuse les APK d'un autre paquet, d'une autre signature, dont la version ne correspond pas au tag ou dont le `versionCode` n'est pas supérieur. Android vérifie lui aussi le paquet avant installation. Les APK bêta existants, les fichiers de nom différent et les releases sans empreinte ne sont pas installés automatiquement. Un échec de réseau, de publication ou de vérification est affiché séparément d'une application déjà à jour.

Ce mécanisme concerne les installations directes d'APK ; une distribution sur Google Play doit respecter les règles du Play Store relatives à l'installation de paquets et aux mises à jour.
