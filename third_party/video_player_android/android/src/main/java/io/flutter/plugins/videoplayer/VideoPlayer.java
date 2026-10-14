// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.videoplayer;

import static androidx.media3.common.Player.REPEAT_MODE_ALL;
import static androidx.media3.common.Player.REPEAT_MODE_OFF;

import android.content.Context;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.OptIn;
import androidx.annotation.RestrictTo;
import androidx.annotation.VisibleForTesting;
import androidx.media3.common.AudioAttributes;
import androidx.media3.common.C;
import androidx.media3.common.Format;
import androidx.media3.common.MediaItem;
import androidx.media3.common.PlaybackException;
import androidx.media3.common.PlaybackParameters;
import androidx.media3.common.Player;
import androidx.media3.common.TrackSelectionOverride;
import androidx.media3.common.Tracks;
import androidx.media3.common.text.Cue;
import androidx.media3.common.text.CueGroup;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.exoplayer.DefaultLoadControl;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector;
import io.flutter.view.TextureRegistry;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

final class VideoPlayer implements TextureRegistry.SurfaceProducer.Callback {
  @NonNull private final ExoPlayerProvider exoPlayerProvider;
  @NonNull private final MediaItem mediaItem;
  @NonNull private final TextureRegistry.SurfaceProducer surfaceProducer;
  @NonNull private final VideoPlayerCallbacks videoPlayerEvents;
  @NonNull private final VideoPlayerOptions options;
  @NonNull private ExoPlayer exoPlayer;
  @Nullable private ExoPlayerState savedStateDuring;

  /**
   * Creates a video player.
   *
   * @param context application context.
   * @param events event callbacks.
   * @param surfaceProducer produces a texture to render to.
   * @param asset asset to play.
   * @param options options for playback.
   * @return a video player instance.
   */
  @NonNull
  static VideoPlayer create(
      @NonNull Context context,
      @NonNull VideoPlayerCallbacks events,
      @NonNull TextureRegistry.SurfaceProducer surfaceProducer,
      @NonNull VideoAsset asset,
      @NonNull VideoPlayerOptions options) {
    return new VideoPlayer(
        () -> {
          // Pipeline « Night Focus » : la fabrique de renderers injecte un
          // DefaultAudioSink muni du processeur DSP (Dialogue Boost / Bass
          // Killer / gain / décalage). Le processeur reste inactif
          // (isActive == false) tant que le switch Night Focus est OFF, donc
          // le pipeline audio par défaut est préservé.
          ExoPlayer.Builder builder =
              new ExoPlayer.Builder(context)
                  .setRenderersFactory(new NightFocusRenderersFactory(context))
                  .setMediaSourceFactory(asset.getMediaSourceFactory(context));

          // Configuration par profil (Orbit Player Config) : tampon media3 et
          // limite de résolution, peuplés depuis Dart avant la création.
          // 0 = non renseigné -> comportement ExoPlayer par défaut.
          Log.i(
              "OrbitPlayer",
              "config min="
                  + OrbitPlayerConfig.minBufferMs
                  + " max="
                  + OrbitPlayerConfig.maxBufferMs
                  + " bfp="
                  + OrbitPlayerConfig.bufferForPlaybackMs
                  + " afterRebuffer="
                  + OrbitPlayerConfig.bufferForPlaybackAfterRebufferMs
                  + " maxHeight="
                  + OrbitPlayerConfig.maxVideoHeight
                  + " nightFocus="
                  + NightFocusDspConfig.enabled);
          if (OrbitPlayerConfig.minBufferMs > 0 && OrbitPlayerConfig.maxBufferMs > 0) {
            // Media3 impose minBufferMs >= bufferForPlaybackMs et
            // minBufferMs >= bufferForPlaybackAfterRebufferMs, sinon
            // IllegalArgumentException (« minBufferMs cannot be less than
            // bufferForPlaybackMs ») qui fait echouer la lecture entiere.
            // On borne donc les seuils de demarrage SOUS minBufferMs.
            int min = OrbitPlayerConfig.minBufferMs;
            int max = Math.max(OrbitPlayerConfig.maxBufferMs, min);
            int forPlayback =
                Math.min(
                    OrbitPlayerConfig.bufferForPlaybackMs > 0
                        ? OrbitPlayerConfig.bufferForPlaybackMs
                        : DefaultLoadControl.DEFAULT_BUFFER_FOR_PLAYBACK_MS,
                    min);
            int forPlaybackAfterRebuffer =
                Math.min(
                    OrbitPlayerConfig.bufferForPlaybackAfterRebufferMs > 0
                        ? OrbitPlayerConfig.bufferForPlaybackAfterRebufferMs
                        : DefaultLoadControl.DEFAULT_BUFFER_FOR_PLAYBACK_AFTER_REBUFFER_MS,
                    min);
            Log.i(
                "OrbitPlayer",
                "loadControl clamp min="
                    + min
                    + " max="
                    + max
                    + " bfp="
                    + forPlayback
                    + " afterRebuffer="
                    + forPlaybackAfterRebuffer);
            builder.setLoadControl(
                new DefaultLoadControl.Builder()
                    .setBufferDurationsMs(
                        min, max, forPlayback, forPlaybackAfterRebuffer)
                    .build());
          }
          if (OrbitPlayerConfig.maxVideoHeight > 0) {
            DefaultTrackSelector trackSelector = new DefaultTrackSelector(context);
            trackSelector.setParameters(
                new DefaultTrackSelector.Parameters.Builder(context)
                    .setMaxVideoSize(
                        OrbitPlayerConfig.maxVideoWidth > 0
                            ? OrbitPlayerConfig.maxVideoWidth
                            : Integer.MAX_VALUE,
                        OrbitPlayerConfig.maxVideoHeight)
                    .build());
            builder.setTrackSelector(trackSelector);
          }

          ExoPlayer player = builder.build();
          // Journalise l'etat reel du lecteur : sans ca, un flux fige a la
          // position 0 est indistinguable d'un probleme reseau, d'un decodeur
          // qui ne demarre pas ou d'un seuil de tampon inatteignable.
          final ExoPlayer[] ref = new ExoPlayer[] {player};
          player.addListener(
              new Player.Listener() {
                private void dump(String why) {
                  ExoPlayer p = ref[0];
                  Format audio = p.getAudioFormat();
                  Format video = p.getVideoFormat();
                  Log.i(
                      "OrbitPlayer",
                      why
                          + " state="
                          + p.getPlaybackState()
                          + " loading="
                          + p.isLoading()
                          + " pos="
                          + p.getCurrentPosition()
                          + " bufferedPos="
                          + p.getBufferedPosition()
                          + " totalBuffered="
                          + p.getTotalBufferedDuration()
                          + " dur="
                          + p.getDuration()
                          + " size="
                          + p.getVideoSize().width
                          + "x"
                          + p.getVideoSize().height
                          + " audio="
                          + (audio == null ? "none" : audio.sampleRate + "Hz/" + audio.channelCount + "ch/" + audio.sampleMimeType)
                          + " video="
                          + (video == null ? "none" : video.width + "x" + video.height + "/" + video.sampleMimeType));
                }

                @Override
                public void onPlaybackStateChanged(int state) {
                  dump("state" + state);
                }

                @Override
                public void onIsPlayingChanged(boolean isPlaying) {
                  dump("isPlaying=" + isPlaying);
                }

                @Override
                public void onPlayerError(PlaybackException error) {
                  Log.e("OrbitPlayer", "error", error);
                }
              });
          return player;
        },
        events,
        surfaceProducer,
        asset.getMediaItem(),
        options);
  }

  /** A closure-compatible signature since {@link java.util.function.Supplier} is API level 24. */
  interface ExoPlayerProvider {
    /**
     * Returns a new {@link ExoPlayer}.
     *
     * @return new instance.
     */
    ExoPlayer get();
  }

  @VisibleForTesting
  VideoPlayer(
      @NonNull ExoPlayerProvider exoPlayerProvider,
      @NonNull VideoPlayerCallbacks events,
      @NonNull TextureRegistry.SurfaceProducer surfaceProducer,
      @NonNull MediaItem mediaItem,
      @NonNull VideoPlayerOptions options) {
    this.exoPlayerProvider = exoPlayerProvider;
    this.videoPlayerEvents = events;
    this.surfaceProducer = surfaceProducer;
    this.mediaItem = mediaItem;
    this.options = options;
    this.exoPlayer = createVideoPlayer();
    surfaceProducer.setCallback(this);
  }

  @RestrictTo(RestrictTo.Scope.LIBRARY)
  // TODO(matanlurey): https://github.com/flutter/flutter/issues/155131.
  @SuppressWarnings({"deprecation", "removal"})
  public void onSurfaceCreated() {
    if (savedStateDuring != null) {
      exoPlayer = createVideoPlayer();
      savedStateDuring.restore(exoPlayer);
      savedStateDuring = null;
    }
  }

  @RestrictTo(RestrictTo.Scope.LIBRARY)
  public void onSurfaceDestroyed() {
    // Intentionally do not call pause/stop here, because the surface has already been released
    // at this point (see https://github.com/flutter/flutter/issues/156451).
    savedStateDuring = ExoPlayerState.save(exoPlayer);
    exoPlayer.release();
  }

  private ExoPlayer createVideoPlayer() {
    ExoPlayer exoPlayer = exoPlayerProvider.get();
    exoPlayer.setMediaItem(mediaItem);
    exoPlayer.prepare();

    exoPlayer.setVideoSurface(surfaceProducer.getSurface());

    boolean wasInitialized = savedStateDuring != null;
    // Listener unique : ExoPlayerEventListener porte aussi la detection des
    // sous-titres (onTracksChanged -> SubtitleDetector, journalisee
    // « OrbitSubtitle » pour valider les trois cas du cahier des charges).
    // Ré-ajouté à chaque (ré)création du player ci-dessus.
    exoPlayer.addListener(new ExoPlayerEventListener(exoPlayer, videoPlayerEvents, wasInitialized));
    setAudioAttributes(exoPlayer, options.mixWithOthers);

    return exoPlayer;
  }

  void sendBufferingUpdate() {
    videoPlayerEvents.onBufferingUpdate(exoPlayer.getBufferedPosition());
  }

  private static void setAudioAttributes(ExoPlayer exoPlayer, boolean isMixMode) {
    exoPlayer.setAudioAttributes(
        new AudioAttributes.Builder().setContentType(C.AUDIO_CONTENT_TYPE_MOVIE).build(),
        !isMixMode);
  }

  void play() {
    exoPlayer.play();
  }

  void pause() {
    exoPlayer.pause();
  }

  void setLooping(boolean value) {
    exoPlayer.setRepeatMode(value ? REPEAT_MODE_ALL : REPEAT_MODE_OFF);
  }

  void setVolume(double value) {
    float bracketedValue = (float) Math.max(0.0, Math.min(1.0, value));
    exoPlayer.setVolume(bracketedValue);
  }

  void setPlaybackSpeed(double value) {
    // We do not need to consider pitch and skipSilence for now as we do not handle them and
    // therefore never diverge from the default values.
    final PlaybackParameters playbackParameters = new PlaybackParameters(((float) value));

    exoPlayer.setPlaybackParameters(playbackParameters);
  }

  void seekTo(int location) {
    exoPlayer.seekTo(location);
  }

  long getPosition() {
    return exoPlayer.getCurrentPosition();
  }

  /**
   * Lists the audio tracks currently exposed by the player.
   *
   * <p>Each entry carries the metadata understood by the Dart layer (id is
   * {@code "<groupIndex>_<trackIndex>"}).
   */
  List<Map<String, Object>> getAudioTracks() {
    List<Map<String, Object>> tracks = new ArrayList<>();
    Tracks currentTracks = exoPlayer.getCurrentTracks();
    if (currentTracks == null) {
      return tracks;
    }
    int groupIndex = 0;
    for (Tracks.Group group : currentTracks.getGroups()) {
      if (group.getType() == C.TRACK_TYPE_AUDIO) {
        for (int trackIndex = 0; trackIndex < group.length; trackIndex++) {
          if (!group.isTrackSupported(trackIndex)) {
            continue;
          }
          Format format = group.getTrackFormat(trackIndex);
          Map<String, Object> track = new HashMap<>();
          track.put("id", groupIndex + "_" + trackIndex);
          track.put("label", audioTrackLabel(format));
          track.put("language", format.language);
          track.put("isSelected", group.isTrackSelected(trackIndex));
          track.put("bitrate", format.bitrate > 0 ? format.bitrate : null);
          track.put("sampleRate", format.sampleRate > 0 ? format.sampleRate : null);
          track.put("channelCount", format.channelCount > 0 ? format.channelCount : null);
          track.put("codec", format.codecs);
          tracks.add(track);
        }
      }
      groupIndex++;
    }
    return tracks;
  }

  /** Lists the video quality variants currently exposed by the player. */
  List<Map<String, Object>> getVideoTracks() {
    List<Map<String, Object>> tracks = new ArrayList<>();
    Tracks currentTracks = exoPlayer.getCurrentTracks();
    if (currentTracks == null) {
      return tracks;
    }
    int groupIndex = 0;
    for (Tracks.Group group : currentTracks.getGroups()) {
      if (group.getType() == C.TRACK_TYPE_VIDEO) {
        for (int trackIndex = 0; trackIndex < group.length; trackIndex++) {
          if (!group.isTrackSupported(trackIndex)) {
            continue;
          }
          Format format = group.getTrackFormat(trackIndex);
          Map<String, Object> track = new HashMap<>();
          track.put("id", groupIndex + "_" + trackIndex);
          track.put("label", videoTrackLabel(format));
          track.put("isSelected", group.isTrackSelected(trackIndex));
          track.put("bitrate", format.bitrate > 0 ? format.bitrate : null);
          track.put("width", format.width > 0 ? format.width : null);
          track.put("height", format.height > 0 ? format.height : null);
          track.put("frameRate", format.frameRate > 0 ? (double) format.frameRate : null);
          track.put("codec", format.codecs);
          tracks.add(track);
        }
      }
      groupIndex++;
    }
    return tracks;
  }

  /** Forces the audio track identified by {@code "<groupIndex>_<trackIndex>"}. */
  void selectAudioTrack(String trackId) {
    applyTrackSelection(trackId, C.TRACK_TYPE_AUDIO);
  }

  /**
   * Lists the embedded subtitle tracks currently exposed by the player.
   *
   * <p>Seules les pistes supportées par le pipeline (media3 acharne un decoder
   * texte pour elles) sont retournées : les ISO 1.9.3 les marquent via {@code
   * group.isTrackSupported(...)}. Chaque entrée porte l'id
   * {@code "<groupIndex>_<trackIndex>"} compris du Dart.
   */
  List<Map<String, Object>> getSubtitleTracks() {
    List<Map<String, Object>> tracks = new ArrayList<>();
    Tracks currentTracks = exoPlayer.getCurrentTracks();
    if (currentTracks == null) {
      return tracks;
    }
    int groupIndex = 0;
    for (Tracks.Group group : currentTracks.getGroups()) {
      if (group.getType() == C.TRACK_TYPE_TEXT) {
        for (int trackIndex = 0; trackIndex < group.length; trackIndex++) {
          if (!group.isTrackSupported(trackIndex)) {
            continue;
          }
          Format format = group.getTrackFormat(trackIndex);
          Map<String, Object> track = new HashMap<>();
          track.put("id", groupIndex + "_" + trackIndex);
          track.put("label", subtitleTrackLabel(format));
          track.put("language", format.language);
          track.put("isSelected", group.isTrackSelected(trackIndex));
          track.put("isForced", (format.selectionFlags & C.SELECTION_FLAG_FORCED) != 0);
          track.put("mimeType", format.sampleMimeType);
          tracks.add(track);
        }
      }
      groupIndex++;
    }
    return tracks;
  }

  /** Forces the embedded subtitle track identified by {@code "<groupIndex>_<trackIndex>"}. */
  void selectSubtitleTrack(String trackId) {
    applyTrackSelection(trackId, C.TRACK_TYPE_TEXT);
  }

  /**
   * Désactive tous les sous-titres intégrés.
   *
   * <p>Media3 n'expose pas de « clear override » public par type quand le lecteur
   * est démarré : on nettoie les overrides TEXT et on marque le type désactivé.
   */
  void clearSubtitleTracks() {
    DefaultTrackSelector trackSelector = trackSelectorOrNull();
    if (trackSelector == null) {
      return;
    }
    DefaultTrackSelector.Parameters parameters =
        trackSelector
            .getParameters()
            .buildUpon()
            .clearOverridesOfType(C.TRACK_TYPE_TEXT)
            .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, true)
            .build();
    trackSelector.setParameters(parameters);
  }

  /**
   * Instantané des sous-titres actuellement affichés par le pipeline (Media3
   * maintient un seul {@link CueGroup}, ré-émis à chaque changement de piste ou
   * de rendu, vidé dès que la piste est désactivée). Le Dart vide les cues à
   * chaque lecture et poll cette méthode pendant que des sous-titres intégrés
   * sont actifs.
   */
  @OptIn(markerClass = UnstableApi.class)
  Map<String, Object> getCurrentCues() {
    CueGroup cueGroup = exoPlayer.getCurrentCues();
    Map<String, Object> result = new HashMap<>();
    result.put("presentationTimeUs", cueGroup.presentationTimeUs);
    List<Map<String, Object>> cues = new ArrayList<>();
    for (Cue cue : cueGroup.cues) {
      if (cue.text == null) {
        continue;
      }
      String text = cue.text.toString();
      if (text.trim().isEmpty()) {
        continue;
      }
      Map<String, Object> cueMap = new HashMap<>();
      cueMap.put("text", text);
      cues.add(cueMap);
    }
    result.put("cues", cues);
    return result;
  }

  /**
   * Forces the video quality variant identified by {@code "<groupIndex>_<trackIndex>"}, or
   * restores automatic selection when {@code track} is {@code null}.
   */
  void selectVideoTrack(Map<String, Object> track) {
    if (track == null) {
      DefaultTrackSelector trackSelector = trackSelectorOrNull();
      if (trackSelector != null) {
        DefaultTrackSelector.Parameters parameters =
            trackSelector
                .getParameters()
                .buildUpon()
                .clearOverridesOfType(C.TRACK_TYPE_VIDEO)
                .build();
        trackSelector.setParameters(parameters);
      }
      return;
    }
    Object id = track.get("id");
    if (!(id instanceof String)) {
      throw new IllegalArgumentException("selectVideoTrack requires a non-null track id.");
    }
    String[] parts = ((String) id).split("_");
    if (parts.length != 2) {
      throw new IllegalArgumentException("Invalid video track id: " + id);
    }
    int groupIndex = Integer.parseInt(parts[0]);
    int trackIndex = Integer.parseInt(parts[1]);
    applyTrackSelection(groupIndex, trackIndex, C.TRACK_TYPE_VIDEO);
  }

  private void applyTrackSelection(String trackId, @C.TrackType int trackType) {
    String[] parts = trackId.split("_");
    if (parts.length != 2) {
      throw new IllegalArgumentException("Invalid track id: " + trackId);
    }
    int groupIndex = Integer.parseInt(parts[0]);
    int trackIndex = Integer.parseInt(parts[1]);
    applyTrackSelection(groupIndex, trackIndex, trackType);
  }

  private void applyTrackSelection(int groupIndex, int trackIndex, @C.TrackType int trackType) {
    Tracks currentTracks = exoPlayer.getCurrentTracks();
    if (currentTracks == null) {
      throw new IllegalArgumentException("No tracks available.");
    }
    if (groupIndex < 0 || groupIndex >= currentTracks.getGroups().size()) {
      throw new IllegalArgumentException("Invalid track group: " + groupIndex);
    }
    Tracks.Group selectedGroup = currentTracks.getGroups().get(groupIndex);
    if (selectedGroup.getType() != trackType) {
      throw new IllegalArgumentException(
          "Group " + groupIndex + " is not of type " + trackType);
    }
    if (trackIndex < 0 || trackIndex >= selectedGroup.length) {
      throw new IllegalArgumentException("Invalid track index: " + trackIndex);
    }
    DefaultTrackSelector trackSelector = trackSelectorOrNull();
    if (trackSelector == null) {
      return;
    }
    TrackSelectionOverride override =
        new TrackSelectionOverride(selectedGroup.getMediaTrackGroup(), trackIndex);
    DefaultTrackSelector.Parameters parameters =
        trackSelector
            .getParameters()
            .buildUpon()
            .setTrackTypeDisabled(trackType, false)
            .setOverrideForType(override)
            .build();
    trackSelector.setParameters(parameters);
  }

  private DefaultTrackSelector trackSelectorOrNull() {
    if (!(exoPlayer.getTrackSelector() instanceof DefaultTrackSelector)) {
      return null;
    }
    return (DefaultTrackSelector) exoPlayer.getTrackSelector();
  }

  private static String audioTrackLabel(Format format) {
    StringBuilder label = new StringBuilder();
    if (format.language != null && !format.language.isEmpty() && !"und".equals(format.language)) {
      label.append(format.language);
    } else {
      label.append("Audio");
    }
    if (format.channelCount > 0) {
      label.append(" · ").append(format.channelCount).append(" can.");
    }
    if (format.codecs != null && !format.codecs.isEmpty()) {
      label.append(" · ").append(format.codecs);
    }
    return label.toString();
  }

  private static String videoTrackLabel(Format format) {
    if (format.width > 0 && format.height > 0) {
      return format.width + "×" + format.height;
    }
    if (format.bitrate > 0) {
      return (format.bitrate / 1000) + " kbps";
    }
    return "Vidéo";
  }

  private static String subtitleTrackLabel(Format format) {
    if (format.label != null && !format.label.trim().isEmpty()) {
      return format.label.trim();
    }
    if (format.language != null && !format.language.isEmpty() && !"und".equals(format.language)) {
      return format.language;
    }
    return "Sous-titres";
  }

  void dispose() {
    exoPlayer.release();
    surfaceProducer.release();

    // TODO(matanlurey): Remove when embedder no longer calls-back once released.
    // https://github.com/flutter/flutter/issues/156434.
    surfaceProducer.setCallback(null);
  }
}
