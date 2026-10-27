# Correction plugin Kotlin — dépôt christopheblum67/Orbit-3d-flutter

## Cause
Flutter 3.x + Kotlin 2.2.20/2.3.20 = erreur "Built-in Kotlin" (Gradle task assembleRelease failed).
Le dépôt doit migrer vers le Kotlin intégré (Built-in Kotlin) de Flutter.

## Fichiers à modifier (depuis le dépôt)

### 1. android/settings.gradle
Supprimer ou commenter :
  id "org.jetbrains.kotlin.android" version "2.3.20" apply false
Le plugin Kotlin est désormais intégré par Flutter Gradle Plugin.

### 2. android/app/build.gradle
Supprimer le bloc (déjà fait dans le code local) :
  kotlin {
      compilerOptions { ... }
  }
Conserver uniquement :
  compileOptions {
      sourceCompatibility = JavaVersion.VERSION_17
      targetCompatibility = JavaVersion.VERSION_17
  }

### 3. pubspec.yaml
Vérifier que `uses-material-design: true` est présent dans `flutter:`.

## Modifications Orbit IPTV (notre travail, à conserver)
- lib/features/startup/startup_splash_screen.dart : _showBranding (première frame allégée) + cf_clearance + UA
- lib/features/home/home_screen.dart : barre d'en-tête nettoyée, boutons dans le bas
- android/app/build.gradle : Kotlin block supprimé
- android/settings.gradle : version Kotlin ajustée

## Étapes de validation
1. Appliquer le patch Kotlin ci-dessus sur le dépôt GitHub
2. Pushover sur main
3. Relancer flutter build apk --release
4. Installer APK sur S20 via adb install -r
