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
  /** Rend la vidéo via une SurfaceView native sur Android TV (au lieu d'une texture). */
  public static boolean useSurfaceView = true;
  /** 0 = matériel d'abord (défaut), 2 = décodeurs logiciels d'abord. */
  public static int decoderMode = 0;

  private OrbitPlayerConfig() {}
}