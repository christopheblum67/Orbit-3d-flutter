// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.videoplayer;

import android.app.UiModeManager;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.content.Context;
import android.content.res.Configuration;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.LongSparseArray;
import android.view.PixelCopy;
import android.view.SurfaceView;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.FlutterInjector;
import io.flutter.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.videoplayer.Messages.AndroidVideoPlayerApi;
import io.flutter.plugins.videoplayer.Messages.CreateMessage;
import io.flutter.view.TextureRegistry;
import java.util.Map;
import java.util.HashMap;

/** Android platform implementation of the VideoPlayerPlugin. */
public class VideoPlayerPlugin implements FlutterPlugin, AndroidVideoPlayerApi {
  private static final String TAG = "VideoPlayerPlugin";
  private static final String TRACK_CHANNEL = "flutter.io/videoPlayer/tracks";
  private final LongSparseArray<VideoPlayer> videoPlayers = new LongSparseArray<>();
  private FlutterState flutterState;
  private MethodChannel trackChannel;
  private final VideoPlayerOptions options = new VideoPlayerOptions();
  private final java.util.Set<Long> surfaceViewPlayers = new java.util.HashSet<>();
  private final Map<Long, SurfaceView> surfaceViews = new HashMap<>();
  private long nextSurfaceViewId = 1_000_000_000L;
  private final PendingWidevineConfigurations pendingWidevine = new PendingWidevineConfigurations();

  /** Register this with the v2 embedding for the plugin to respond to lifecycle callbacks. */
  public VideoPlayerPlugin() {}

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    final FlutterInjector injector = FlutterInjector.instance();
    this.flutterState =
        new FlutterState(
            binding.getApplicationContext(),
            binding.getBinaryMessenger(),
            injector.flutterLoader()::getLookupKeyForAsset,
            injector.flutterLoader()::getLookupKeyForAsset,
            binding.getTextureRegistry());
    flutterState.startListening(this, binding.getBinaryMessenger());
    trackChannel = new MethodChannel(binding.getBinaryMessenger(), TRACK_CHANNEL);
    trackChannel.setMethodCallHandler(this::onTrackMethodCall);
    binding
        .getPlatformViewRegistry()
        .registerViewFactory(
            SurfaceViewFactory.VIEW_TYPE,
            new SurfaceViewFactory(videoPlayers::get, surfaceViews));
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    if (flutterState == null) {
      Log.wtf(TAG, "Detached from the engine before registering to it.");
    }
    flutterState.stopListening(binding.getBinaryMessenger());
    flutterState = null;
    if (trackChannel != null) {
      trackChannel.setMethodCallHandler(null);
      trackChannel = null;
    }
    onDestroy();
  }

  private void disposeAllPlayers() {
    for (int i = 0; i < videoPlayers.size(); i++) {
      videoPlayers.valueAt(i).dispose();
    }
    videoPlayers.clear();
    surfaceViewPlayers.clear();
    surfaceViews.clear();
  }

  public void onDestroy() {
    // The whole FlutterView is being destroyed. Here we release resources acquired for all
    // instances
    // of VideoPlayer. Once https://github.com/flutter/flutter/issues/19358 is resolved this may
    // be replaced with just asserting that videoPlayers.isEmpty().
    // https://github.com/flutter/flutter/issues/20989 tracks this.
    disposeAllPlayers();
    pendingWidevine.clear();
  }

  @Override
  public void initialize() {
    disposeAllPlayers();
  }

  @Override
  public @NonNull Long create(@NonNull CreateMessage arg) {
    Map<String, String> requestHeaders = new HashMap<>(arg.getHttpHeaders());
    WidevineMediaConfig drmConfig = pendingWidevine.take(requestHeaders);
    if (drmConfig != null && (arg.getUri() == null
        || !(arg.getUri().startsWith("https://") || arg.getUri().startsWith("http://")))) {
      throw new IllegalArgumentException("Widevine requires an HTTP media URL");
    }
    final boolean surfaceViewMode = useSurfaceView();
    final TextureRegistry.SurfaceProducer handle =
        surfaceViewMode ? null : flutterState.textureRegistry.createSurfaceProducer();
    final long playerId = surfaceViewMode ? nextSurfaceViewId++ : handle.id();
    if (surfaceViewMode) {
      surfaceViewPlayers.add(playerId);
    }
    EventChannel eventChannel =
        new EventChannel(
            flutterState.binaryMessenger, "flutter.io/videoPlayer/videoEvents" + playerId);

    final VideoAsset videoAsset;
    if (arg.getAsset() != null) {
      String assetLookupKey;
      if (arg.getPackageName() != null) {
        assetLookupKey =
            flutterState.keyForAssetAndPackageName.get(arg.getAsset(), arg.getPackageName());
      } else {
        assetLookupKey = flutterState.keyForAsset.get(arg.getAsset());
      }
      videoAsset = VideoAsset.fromAssetUrl("asset:///" + assetLookupKey);
    } else if (arg.getUri().startsWith("rtsp://")) {
      videoAsset = VideoAsset.fromRtspUrl(arg.getUri());
    } else {
      VideoAsset.StreamingFormat streamingFormat = VideoAsset.StreamingFormat.UNKNOWN;
      String formatHint = arg.getFormatHint();
      if (formatHint != null) {
        switch (formatHint) {
          case "ss":
            streamingFormat = VideoAsset.StreamingFormat.SMOOTH;
            break;
          case "dash":
            streamingFormat = VideoAsset.StreamingFormat.DYNAMIC_ADAPTIVE;
            break;
          case "hls":
            streamingFormat = VideoAsset.StreamingFormat.HTTP_LIVE;
            break;
        }
      }
      videoAsset = drmConfig == null
          ? VideoAsset.fromRemoteUrl(arg.getUri(), streamingFormat, requestHeaders)
          : VideoAsset.fromRemoteUrl(arg.getUri(), streamingFormat, requestHeaders, drmConfig);
    }
    videoPlayers.put(
        playerId,
        VideoPlayer.create(
            flutterState.applicationContext,
            VideoPlayerEventCallbacks.bindTo(eventChannel),
            handle,
            videoAsset,
            options));

    return playerId;
  }

  private boolean useSurfaceView() {
    if (!OrbitPlayerConfig.useSurfaceView) {
      return false;
    }
    UiModeManager uiMode =
        (UiModeManager) flutterState.applicationContext.getSystemService(Context.UI_MODE_SERVICE);
    return uiMode != null && uiMode.getCurrentModeType() == Configuration.UI_MODE_TYPE_TELEVISION;
  }

  @NonNull
  private VideoPlayer getPlayer(long textureId) {
    VideoPlayer player = videoPlayers.get(textureId);

    // Avoid a very ugly un-debuggable NPE that results in returning a null player.
    if (player == null) {
      String message = "No player found with textureId <" + textureId + ">";
      if (videoPlayers.size() == 0) {
        message += " and no active players created by the plugin.";
      }
      throw new IllegalStateException(message);
    }

    return player;
  }

  @Override
  public void dispose(@NonNull Long textureId) {
    VideoPlayer player = getPlayer(textureId);
    player.dispose();
    videoPlayers.remove(textureId);
    surfaceViewPlayers.remove(textureId);
  }

  @Override
  public void setLooping(@NonNull Long textureId, @NonNull Boolean looping) {
    VideoPlayer player = getPlayer(textureId);
    player.setLooping(looping);
  }

  @Override
  public void setVolume(@NonNull Long textureId, @NonNull Double volume) {
    VideoPlayer player = getPlayer(textureId);
    player.setVolume(volume);
  }

  @Override
  public void setPlaybackSpeed(@NonNull Long textureId, @NonNull Double speed) {
    VideoPlayer player = getPlayer(textureId);
    player.setPlaybackSpeed(speed);
  }

  @Override
  public void play(@NonNull Long textureId) {
    VideoPlayer player = getPlayer(textureId);
    player.play();
  }

  @Override
  public @NonNull Long position(@NonNull Long textureId) {
    VideoPlayer player = getPlayer(textureId);
    long position = player.getPosition();
    player.sendBufferingUpdate();
    return position;
  }

  @Override
  public void seekTo(@NonNull Long textureId, @NonNull Long position) {
    VideoPlayer player = getPlayer(textureId);
    player.seekTo(position.intValue());
  }

  @Override
  public void pause(@NonNull Long textureId) {
    VideoPlayer player = getPlayer(textureId);
    player.pause();
  }

  @Override
  public void setMixWithOthers(@NonNull Boolean mixWithOthers) {
    options.mixWithOthers = mixWithOthers;
  }

  /** Dispatches the audio/video track commands from the Dart layer. */
  private void onTrackMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
    try {
      if ("registerWidevine".equals(call.method)) {
        String token = call.argument("token");
        String licenseUrl = call.argument("licenseUrl");
        Map<String, String> headers = call.argument("headers");
        if (token == null || token.isEmpty() || licenseUrl == null || headers == null) {
          result.error("InvalidWidevine", "Invalid Widevine configuration", null);
          return;
        }
        pendingWidevine.register(token, new WidevineMediaConfig(licenseUrl, headers));
        result.success(null);
        return;
      }
      if ("discardWidevine".equals(call.method)) {
        String token = call.argument("token");
        if (token != null) pendingWidevine.discard(token);
        result.success(null);
        return;
      }
      Number playerIdNumber = call.argument("playerId");
      if (playerIdNumber == null) {
        result.error("MissingArgument", "playerId is required.", null);
        return;
      }
      long playerId = playerIdNumber.longValue();
      if ("isSurfaceView".equals(call.method)) {
        result.success(surfaceViewPlayers.contains(playerId));
        return;
      }
      if ("sampleGreenFrame".equals(call.method)) {
        sampleGreenFrame(surfaceViews.get(playerId), result);
        return;
      }
      switch (call.method) {
        case "getAudioTracks":
          result.success(getPlayer(playerId).getAudioTracks());
          break;
        case "getVideoTracks":
          result.success(getPlayer(playerId).getVideoTracks());
          break;
        case "selectAudioTrack":
          String audioTrackId = call.argument("trackId");
          if (audioTrackId == null) {
            result.error("MissingArgument", "trackId is required.", null);
            return;
          }
          getPlayer(playerId).selectAudioTrack(audioTrackId);
          result.success(null);
          break;
        case "clearAudioTracks":
          getPlayer(playerId).clearAudioTracks();
          result.success(null);
          break;
        case "selectVideoTrack":
          @SuppressWarnings("unchecked")
          Map<String, Object> videoTrack = (Map<String, Object>) call.argument("track");
          getPlayer(playerId).selectVideoTrack(videoTrack);
          result.success(null);
          break;
        case "getSubtitleTracks":
          result.success(getPlayer(playerId).getSubtitleTracks());
          break;
        case "selectSubtitleTrack":
          String subtitleTrackId = call.argument("trackId");
          if (subtitleTrackId == null) {
            result.error("MissingArgument", "trackId is required.", null);
            return;
          }
          getPlayer(playerId).selectSubtitleTrack(subtitleTrackId);
          result.success(null);
          break;
        case "clearSubtitleTracks":
          getPlayer(playerId).clearSubtitleTracks();
          result.success(null);
          break;
        case "getCurrentCues":
          result.success(getPlayer(playerId).getCurrentCues());
          break;
        default:
          result.notImplemented();
      }
    } catch (IllegalArgumentException e) {
      result.error("InvalidTrack", e.getMessage(), null);
    } catch (IllegalStateException e) {
      result.error("NoPlayer", e.getMessage(), null);
    }
  }

  private void sampleGreenFrame(
      @Nullable SurfaceView surfaceView, @NonNull MethodChannel.Result result) {
    if (surfaceView == null
        || Build.VERSION.SDK_INT < Build.VERSION_CODES.O
        || !surfaceView.isAttachedToWindow()
        || surfaceView.getWidth() <= 0
        || surfaceView.getHeight() <= 0
        || !surfaceView.getHolder().getSurface().isValid()) {
      result.success(null);
      return;
    }

    Bitmap bitmap = Bitmap.createBitmap(96, 54, Bitmap.Config.ARGB_8888);
    try {
      PixelCopy.request(
          surfaceView,
          bitmap,
          copyResult -> {
            try {
              result.success(
                  copyResult == PixelCopy.SUCCESS ? greenPixelRatio(bitmap) : null);
            } finally {
              bitmap.recycle();
            }
          },
          new Handler(Looper.getMainLooper()));
    } catch (IllegalArgumentException error) {
      bitmap.recycle();
      Log.w(TAG, "Unable to sample video surface: " + error.getClass().getSimpleName());
      result.success(null);
    }
  }

  private static double greenPixelRatio(@NonNull Bitmap bitmap) {
    int width = bitmap.getWidth();
    int height = bitmap.getHeight();
    int[] pixels = new int[width * height];
    bitmap.getPixels(pixels, 0, width, 0, 0, width, height);

    int greenPixels = 0;
    for (int pixel : pixels) {
      int red = Color.red(pixel);
      int green = Color.green(pixel);
      int blue = Color.blue(pixel);
      if (green >= 100 && green - red >= 64 && green - blue >= 64) {
        greenPixels++;
      }
    }
    return greenPixels / (double) pixels.length;
  }

  private interface KeyForAssetFn {
    String get(String asset);
  }

  private interface KeyForAssetAndPackageName {
    String get(String asset, String packageName);
  }

  private static final class FlutterState {
    final Context applicationContext;
    final BinaryMessenger binaryMessenger;
    final KeyForAssetFn keyForAsset;
    final KeyForAssetAndPackageName keyForAssetAndPackageName;
    final TextureRegistry textureRegistry;

    FlutterState(
        Context applicationContext,
        BinaryMessenger messenger,
        KeyForAssetFn keyForAsset,
        KeyForAssetAndPackageName keyForAssetAndPackageName,
        TextureRegistry textureRegistry) {
      this.applicationContext = applicationContext;
      this.binaryMessenger = messenger;
      this.keyForAsset = keyForAsset;
      this.keyForAssetAndPackageName = keyForAssetAndPackageName;
      this.textureRegistry = textureRegistry;
    }

    void startListening(VideoPlayerPlugin methodCallHandler, BinaryMessenger messenger) {
      AndroidVideoPlayerApi.setUp(messenger, methodCallHandler);
    }

    void stopListening(BinaryMessenger messenger) {
      AndroidVideoPlayerApi.setUp(messenger, null);
    }
  }
}
