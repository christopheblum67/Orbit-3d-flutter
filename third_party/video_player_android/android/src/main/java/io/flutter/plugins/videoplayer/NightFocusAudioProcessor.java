package io.flutter.plugins.videoplayer;

import androidx.annotation.NonNull;
import androidx.media3.common.C;
import androidx.media3.common.audio.AudioProcessor;
import androidx.media3.common.audio.BaseAudioProcessor;
import androidx.media3.common.util.UnstableApi;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.ShortBuffer;

/**
 * Processeur audio « Night Focus » branché sur la sortie audio de l'ExoPlayer
 * via un {@code DefaultAudioSink} injecté dans VideoPlayer.java.
 *
 * Le processeur est TOUJOURS actif ({@link #isActive()} renvoie {@code true})
 * pour que le {@code DefaultAudioSink} ne le saute pas. Quand le switch Night
 * Focus est OFF ou que le format n'est pas PCM 16 bits, le traitement est un
 * by-pass identitaire (sortie = entrée).
 *
 * Traitements (PCM 16 bits) : bass killer (passe-haut Butterworth), dialogue
 * boost (peaking EQ 1-4 kHz), gain vocal, et décalage audio (file de retard).
 */
@UnstableApi
public final class NightFocusAudioProcessor extends BaseAudioProcessor {

  private boolean processingEnabled;
  private int sampleRate = 48000;
  private int channelCount = 2;

  private double[] hpB = {1, 0, 0};
  private double[] hpA = {1, 0, 0};
  private double[] peB = {1, 0, 0};
  private double[] peA = {1, 0, 0};
  private double[] hpX;
  private double[] hpY;
  private double[] peX;
  private double[] peY;

  private double gain = 1.0;
  private int delaySamples;
  private short[] delayBuf;
  private int delayWrite;
  private int delayRead;

  @Override
  public final boolean isActive() {
    // Toujours actif pour que le DefaultAudioSink ne saute pas ce processeur.
    // Le vrai by-pass se fait dans queueInput selon processingEnabled.
    return true;
  }

  @NonNull
  @Override
  public AudioProcessor.AudioFormat onConfigure(
      @NonNull AudioProcessor.AudioFormat inputAudioFormat)
      throws AudioProcessor.UnhandledAudioFormatException {
    if (!NightFocusDspConfig.enabled || inputAudioFormat.encoding != C.ENCODING_PCM_16BIT) {
      processingEnabled = false;
      return inputAudioFormat;
    }
    processingEnabled = true;
    sampleRate = inputAudioFormat.sampleRate;
    channelCount = inputAudioFormat.channelCount;
    recomputeCoefficients();
    return inputAudioFormat;
  }

  private void recomputeCoefficients() {
    float fs = sampleRate;

    double cutoff = NightFocusDspConfig.bassKillerCutoffHz;
    if (cutoff <= 0 || cutoff >= fs * 0.45) {
      hpB = new double[] {1, 0, 0};
      hpA = new double[] {1, 0, 0};
    } else {
      double wc = 2.0 * Math.PI * cutoff / fs;
      double k = Math.tan(wc / 2.0);
      double norm = 1.0 / (1.0 + Math.sqrt(2) * k + k * k);
      double b0 = norm;
      double b1 = -2.0 * b0;
      double b2 = b0;
      double a1 = 2.0 * (k * k - 1.0) * norm;
      double a2 = (1.0 - Math.sqrt(2) * k + k * k) * norm;
      hpB = new double[] {b0, b1, b2};
      hpA = new double[] {1, a1, a2};
    }

    double db = NightFocusDspConfig.dialogueBoostDb;
    if (db <= 0.0) {
      peB = new double[] {1, 0, 0};
      peA = new double[] {1, 0, 0};
    } else {
      double a = Math.pow(10.0, db / 40.0);
      double w0 = 2.0 * Math.PI * 2500.0 / fs;
      double alpha = Math.sin(w0) / (2.0 * 0.9);
      double cw = Math.cos(w0);
      double d0 = 1.0 + alpha * a;
      peB = new double[] {(1.0 + alpha / a) / d0, (-2.0 * cw) / d0, (1.0 - alpha / a) / d0};
      peA = new double[] {1, (-2.0 * cw) / d0, (1.0 - alpha * a) / d0};
    }

    gain = Math.pow(10.0, NightFocusDspConfig.vocalGainDb / 20.0);
    delaySamples = (int) ((long) NightFocusDspConfig.audioDelayMs * fs / 1000);

    int cap = Math.max(1, delaySamples);
    delayBuf = new short[cap];
    delayWrite = 0;
    delayRead = delaySamples > 0 ? (cap - delaySamples) % cap : 0;

    int ch = channelCount;
    hpX = new double[ch * 3];
    hpY = new double[ch * 3];
    peX = new double[ch * 3];
    peY = new double[ch * 3];
  }

  @Override
  public void queueInput(@NonNull ByteBuffer inputBuffer) {
    if (!processingEnabled) {
      // By-pass pur : copier l'entrée vers la sortie sans modification.
      ByteBuffer out = replaceOutputBuffer(inputBuffer.remaining());
      out.put(inputBuffer);
      out.flip();
      return;
    }

    int channels = channelCount;
    int frames = inputBuffer.remaining() / 2 / channels;
    ShortBuffer in = inputBuffer.order(ByteOrder.nativeOrder()).asShortBuffer();
    ByteBuffer out = replaceOutputBuffer(frames * 2 * channels);
    ShortBuffer outS = out.order(ByteOrder.nativeOrder()).asShortBuffer();

    for (int f = 0; f < frames; f++) {
      for (int ch = 0; ch < channels; ch++) {
        double x = in.get();
        double v = biquad(x, ch, hpB, hpA, hpX, hpY);
        v = biquad(v, ch, peB, peA, peX, peY);
        v *= gain;
        short s = (short) Math.max(-32768.0, Math.min(32767.0, Math.round(v)));
        outS.put(delayPut(s));
      }
    }
    out.flip();
  }

  private double biquad(
      double x, int ch, double[] b, double[] a, double[] xm, double[] ym) {
    int i = ch * 3;
    double y = b[0] * x + b[1] * xm[i] + b[2] * xm[i + 1] - a[1] * ym[i] - a[2] * ym[i + 1];
    xm[i + 1] = xm[i];
    xm[i] = x;
    ym[i + 1] = ym[i];
    ym[i] = y;
    return y;
  }

  private short delayPut(short s) {
    int cap = delayBuf.length;
    if (cap <= 1) {
      return s;
    }
    delayBuf[delayWrite] = s;
    short ret = delayBuf[delayRead];
    delayRead = (delayRead + 1) % cap;
    delayWrite = (delayWrite + 1) % cap;
    return ret;
  }

  @Override
  protected void onFlush() {
    int ch = channelCount;
    hpX = new double[ch * 3];
    hpY = new double[ch * 3];
    peX = new double[ch * 3];
    peY = new double[ch * 3];
    if (delayBuf == null) {
      delayBuf = new short[Math.max(1, delaySamples)];
    }
    delayWrite = 0;
    delayRead = delaySamples > 0 ? (delayBuf.length - delaySamples) % delayBuf.length : 0;
  }

  @Override
  protected void onReset() {
    processingEnabled = false;
    hpX = new double[0];
    hpY = new double[0];
    peX = new double[0];
    peY = new double[0];
    delayBuf = null;
    delayWrite = 0;
    delayRead = 0;
  }
}