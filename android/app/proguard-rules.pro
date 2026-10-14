# Règles ProGuard/R8 pour le build release d'Orbit3D.
#
# Les règles de base du SDK Android sont fournies par
# `proguard-android-optimize.txt` ; celles des dépendances AAR (ExoPlayer,
# media3, firebase…) sont appliquées automatiquement par Gradle via leurs
# `consumer-rules.pro` respectives. Ce fichier ne garde que ce que les AARs ne
# couvrent pas : notre fork natif et les points de réflexion connus.

# ---- Fork natif video_player_android -------------------------------------
# Les classes du plugin sont référencées statiquement par
# `GeneratedPluginRegistrant`, donc gardées. On garde quand même les callbacks
# ExoPlayer/Media3 passés par interface : R8 supprime parfois les méthodes
# d'interface « jamais appelées » dans le graphe, ce qui casse la sélection des
# pistes texte/audio (appels JNI vers les méthodes du pont natif).
-keep class io.flutter.plugins.videoplayer.** { *; }

# ---- Réflexion ExoPlayer/media3 (client hérité hors consumer rules) ------
# ExoPlayer instancie par réflexion les `DefaultRenderersFactory` /
# `DrmSessionManager` de certains chemins de lecture. On garde les classes
# renderer référencées par le fork pour ne pas casser le décodage.
-keep class com.google.android.exoplayer2.** { *; }
-keep class androidx.media3.** { *; }

# ---- Divers plugins (aucune réflexion connue, garde défensive légère) ----
-keep class com.example.orbit_3d_flutter.** { *; }

# ---- Java 8+ APIs (génériques, streams) ---------------------------------
# Pas de sérialisation custom : rien à garder de plus.

# Désactivation des avertissements de classes manquantes connues (firebase,
# analytics) : on ne les transforme pas en erreurs de build.
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**