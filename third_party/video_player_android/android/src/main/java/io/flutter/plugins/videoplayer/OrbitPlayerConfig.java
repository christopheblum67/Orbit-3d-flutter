package io.flutter.plugins.videoplayer;

/**
 * Paramètres de lecture injectés dans la construction de l'ExoPlayer
 * (DefaultLoadControl + limite de hauteur de piste vidéo).
 *
 * Les champs sont peuplés depuis Dart via le canal « orbit/player_config »
 * (PlayerConfigChannel) AVANT la création d'un VideoPlayerController.
 * 0 = non renseigné, comportement ExoPlayer par défaut préservé.
 */
public final class OrbitPlayerConfig {
  public static int minBufferMs = 0;
  public static int maxBufferMs = 0;
  public static int bufferForPlaybackMs = 0;
  public static int bufferForPlaybackAfterRebufferMs = 0;
  public static int maxVideoWidth = 0;
  public static int maxVideoHeight = 0;

  private OrbitPlayerConfig() {}
}