package io.flutter.plugins.videoplayer;

import android.content.Context;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;
import java.util.Map;

/**
 * Vue native SurfaceView pour le rendu vidéo. Contrairement à la texture Flutter, la surface est
 * composée par le matériel, ce qui évite que le décodeur demande des dizaines de tampons de sortie
 * (les décodeurs OMX Realtek des Android TV les refusent et basculent sur le décodage logiciel).
 */
final class SurfaceViewFactory extends PlatformViewFactory {
  interface PlayerLookup {
    @Nullable
    VideoPlayer find(long playerId);
  }

  static final String VIEW_TYPE = "orbit/video_surface_view";

  private final PlayerLookup lookup;
  private final Map<Long, SurfaceView> surfaceViews;

  SurfaceViewFactory(
      @NonNull PlayerLookup lookup, @NonNull Map<Long, SurfaceView> surfaceViews) {
    super(StandardMessageCodec.INSTANCE);
    this.lookup = lookup;
    this.surfaceViews = surfaceViews;
  }

  @NonNull
  @Override
  public PlatformView create(Context context, int viewId, @Nullable Object args) {
    long playerId = args instanceof Number ? ((Number) args).longValue() : -1L;
    return new Holder(context, playerId, lookup, surfaceViews);
  }

  private static final class Holder implements PlatformView, SurfaceHolder.Callback {
    private final SurfaceView view;
    private final long playerId;
    private final PlayerLookup lookup;
    private final Map<Long, SurfaceView> surfaceViews;

    Holder(
        Context context,
        long playerId,
        PlayerLookup lookup,
        Map<Long, SurfaceView> surfaceViews) {
      this.view = new SurfaceView(context);
      this.playerId = playerId;
      this.lookup = lookup;
      this.surfaceViews = surfaceViews;
      surfaceViews.put(playerId, view);
      view.getHolder().addCallback(this);
    }

    @NonNull
    @Override
    public View getView() {
      return view;
    }

    @Override
    public void dispose() {
      view.getHolder().removeCallback(this);
      if (surfaceViews.get(playerId) == view) {
        surfaceViews.remove(playerId);
      }
      VideoPlayer player = lookup.find(playerId);
      if (player != null) {
        player.detachSurfaceHolder(view.getHolder());
      }
    }

    @Override
    public void surfaceCreated(@NonNull SurfaceHolder holder) {
      VideoPlayer player = lookup.find(playerId);
      if (player != null) {
        player.attachSurfaceHolder(holder);
      }
    }

    @Override
    public void surfaceChanged(@NonNull SurfaceHolder holder, int format, int width, int height) {}

    @Override
    public void surfaceDestroyed(@NonNull SurfaceHolder holder) {
      VideoPlayer player = lookup.find(playerId);
      if (player != null) {
        player.detachSurfaceHolder(holder);
      }
    }
  }
}
