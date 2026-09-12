// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.videoplayer;

import static androidx.media3.common.Player.REPEAT_MODE_ALL;
import static androidx.media3.common.Player.REPEAT_MODE_OFF;

import android.content.Context;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RestrictTo;
import androidx.annotation.VisibleForTesting;
import androidx.media3.common.AudioAttributes;
import androidx.media3.common.C;
import androidx.media3.common.Format;
import androidx.media3.common.MediaItem;
import androidx.media3.common.PlaybackParameters;
import androidx.media3.common.TrackSelectionOverride;
import androidx.media3.common.Tracks;
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
          if (OrbitPlayerConfig.minBufferMs > 0 && OrbitPlayerConfig.maxBufferMs > 0) {
            builder.setLoadControl(
                new DefaultLoadControl.Builder()
                    .setBufferDurationsMs(
                        OrbitPlayerConfig.minBufferMs,
                        OrbitPlayerConfig.maxBufferMs,
                        OrbitPlayerConfig.bufferForPlaybackMs > 0
                            ? OrbitPlayerConfig.bufferForPlaybackMs
                            : DefaultLoadControl.DEFAULT_BUFFER_FOR_PLAYBACK_MS,
                        OrbitPlayerConfig.bufferForPlaybackAfterRebufferMs > 0
                            ? OrbitPlayerConfig.bufferForPlaybackAfterRebufferMs
                            : DefaultLoadControl.DEFAULT_BUFFER_FOR_PLAYBACK_AFTER_REBUFFER_MS)
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

          return builder.build();
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
        trackSelector.getParameters().buildUpon().setOverrideForType(override).build();
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

  void dispose() {
    exoPlayer.release();
    surfaceProducer.release();

    // TODO(matanlurey): Remove when embedder no longer calls-back once released.
    // https://github.com/flutter/flutter/issues/156434.
    surfaceProducer.setCallback(null);
  }
}
