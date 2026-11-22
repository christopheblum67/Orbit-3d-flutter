# Règles ProGuard/R8 pour le build release d'Orbit3D.
#
# Les règles de base du SDK Android sont fournies par
# `proguard-android-optimize.txt` ; celles des dépendances AAR (media3,
# firebase…) sont appliquées automatiquement par Gradle via leurs
# `consumer-rules.pro` respectives. Ce fichier ne garde que ce que les AARs ne
# couvrent pas : notre fork natif et les points de réflexion connus.

# ---- Fork natif video_player_android -------------------------------------
# Les classes du plugin sont référencées statiquement par
# `GeneratedPluginRegistrant`, donc gardées. On garde quand même les callbacks
# ExoPlayer/Media3 passés par interface : R8 supprime parfois les méthodes
# d'interface « jamais appelées » dans le graphe, ce qui casse la sélection des
# pistes texte/audio (appels JNI vers les méthodes du pont natif).
-keep class io.flutter.plugins.videoplayer.** { *; }

# ---- Réflexion media3 (client hérité hors consumer rules du fork) ----------
# Le fork video_player_android dépend d'androidx.media3:media3-exoplayer:1.9.3
# mais n'expose pas de consumer-rules.pro. Les factories/renderers instanciés
# par réflexion (DefaultRenderersFactory, DrmSessionManager) doivent être gardés
# pour ne pas casser le décodage.
-keep class androidx.media3.exoplayer.** { *; }
-keep class androidx.media3.datasource.** { *; }
-keep class androidx.media3.drm.** { *; }

# ---- Plugins sans réflexion connue (garde défensive légère) ----------------
# Supprimé : -keep class com.example.orbit_3d_flutter.** { *; }
# Aucune réflexion détectée dans le code natif ; les classes de l'app sont
# atteintes statiquement par le graphe R8.

# ---- Java 8+ APIs (génériques, streams) ---------------------------------
# Pas de sérialisation custom : rien à garder de plus.

# Désactivation des avertissements de classes manquantes connues (firebase,
# analytics) : on ne les transforme pas en erreurs de build.
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**