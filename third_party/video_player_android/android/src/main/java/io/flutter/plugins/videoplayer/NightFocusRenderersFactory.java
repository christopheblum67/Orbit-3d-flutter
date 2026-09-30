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
 * <p>Le processeur est installé <b>en permanence</b> : c'est la condition pour
 * que l'activation à chaud fonctionne. Il se déclare inactif
 * ({@link NightFocusAudioProcessor#isActive()} == false) tant que Night Focus
 * est off ou que le format n'est pas PCM 16 bits, donc l'AudioSink le
 * court-circuite et la chaîne audio est rigoureusement identique à une chaîne
 * standard. L'ancienne version — processor injecté seulement si le switch était
 * déjà on à la construction du player — rendait l'icône 🌙 sans effet tant
 * qu'on ne changeait pas de chaîne.
 */
public final class NightFocusRenderersFactory extends DefaultRenderersFactory {
  public NightFocusRenderersFactory(@NonNull Context context) {
    super(context);
  }

  @Override
  protected AudioSink buildAudioSink(
      Context context, boolean enableFloatOutput, boolean enableAudioTrackPlaybackParams) {
    AudioProcessor[] dsp = {new NightFocusAudioProcessor()};
    return new DefaultAudioSink.Builder(context)
        .setAudioProcessors(dsp)
        .setEnableFloatOutput(enableFloatOutput)
        .setEnableAudioTrackPlaybackParams(enableAudioTrackPlaybackParams)
        .build();
  }
}