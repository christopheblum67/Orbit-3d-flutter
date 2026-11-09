package io.flutter.plugins.videoplayer;

import android.content.Context;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.media3.common.audio.AudioProcessor;
import androidx.media3.exoplayer.DefaultRenderersFactory;
import androidx.media3.exoplayer.audio.AudioSink;
import androidx.media3.exoplayer.audio.DefaultAudioSink;
import androidx.media3.exoplayer.mediacodec.MediaCodecInfo;
import androidx.media3.exoplayer.mediacodec.MediaCodecSelector;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

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
    // Si le décodeur matériel échoue à l'init (ex. OMX.realtek sur du H.264
    // level 5.0), bascule sur le décodeur suivant au lieu d'échouer.
    setEnableDecoderFallback(true);
    // Mode « logiciel d'abord » : les décodeurs vidéo logiciels (OMX.google,
    // c2.android) passent devant les décodeurs matériels, qui restent en
    // secours. Évalué à la construction du lecteur.
    final int decoderMode = OrbitPlayerConfig.decoderMode;
    setMediaCodecSelector(
          (mimeType, requiresSecureDecoder, requiresTunnelingDecoder) -> {
            List<MediaCodecInfo> infos =
                MediaCodecSelector.DEFAULT.getDecoderInfos(
                    mimeType, requiresSecureDecoder, requiresTunnelingDecoder);
            if (!mimeType.startsWith("video/")) {
              return infos;
            }
            List<MediaCodecInfo> sorted = new ArrayList<>(infos);
            Collections.sort(
                sorted,
                (a, b) -> decoderMode == 2
                    ? Boolean.compare(!a.softwareOnly, !b.softwareOnly)
                    : Boolean.compare(a.softwareOnly, b.softwareOnly));
            StringBuilder candidates = new StringBuilder();
            for (MediaCodecInfo info : sorted) {
              if (candidates.length() > 0) candidates.append(",");
              candidates.append(info.name).append(info.softwareOnly ? "(sw)" : "(hw)");
            }
            Log.i(
                "OrbitDecoder",
                "mode=" + decoderMode + " mime=" + mimeType + " secure="
                    + requiresSecureDecoder + " tunneled=" + requiresTunnelingDecoder
                    + " candidates=" + candidates);
            return sorted;
          });
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