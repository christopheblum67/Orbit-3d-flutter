package io.flutter.plugins.videoplayer;

import android.content.Context;
import androidx.annotation.NonNull;
import androidx.media3.common.audio.AudioProcessor;
import androidx.media3.exoplayer.DefaultRenderersFactory;
import androidx.media3.exoplayer.audio.AudioSink;
import androidx.media3.exoplayer.audio.DefaultAudioSink;

/**
 * Fabrique de renderers ExoPlayer dont le {@code AudioSink} embarque le
 * processeur « Night Focus » {@link NightFocusAudioProcessor}.
 *
 * Le point d'injection est {@link #buildAudioSink}, surchargé dans
 * {@code DefaultRenderersFactory} (media3 1.4.1) — la seule extension native
 * permettant de brancher des AudioProcessors sur la sortie audio.
 *
 * Quand le switch Night Focus est OFF, le processeur se désactive
 * ({@code isActive() == false}) et le {@code DefaultAudioSink} contourne le
 * traitement : la sortie audio reste identique à la config par défaut.
 */
public final class NightFocusRenderersFactory extends DefaultRenderersFactory {
  public NightFocusRenderersFactory(@NonNull Context context) {
    super(context);
  }

  @Override
  protected AudioSink buildAudioSink(
      Context context, boolean enableFloatOutput, boolean enableAudioTrackPlaybackParams) {
    AudioProcessor[] dsp = {new NightFocusAudioProcessor()};
    return new DefaultAudioSink.Builder(context).setAudioProcessors(dsp).build();
  }
}