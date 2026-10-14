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
  private int encoding = C.ENCODING_PCM_16BIT;
  private int lastConfigVersion = -2;

  /** Dernier format d'entrée connu, indispensable pour isActive(). */
  private AudioFormat lastInputFormat;

  /** Vrai une fois onConfigure() accepté (donc format de sortie stable). */
  private boolean configured;

  private boolean normalizationActive;

  /**
   * Niveau RMS du signal (moyenne quadratique lissée), 0..1.
   *
   * On mesure une moyenne et NON une crête : un suiveur de crête appliqué
   * échantillon par échantillon s'écroulait sur chaque consonne / cymbale puis
   * remontait lentement, ce qui s'entendait comme des « saccades » (pompage).
   * La moyenne est insensible aux transitoires isolés.
   */
  private double rmsEnv = 0.0;

  /** Gain actuellement appliqué par la normalisation du volume. */
  private double normGain = 1.0;

  /** Niveau RMS visé (~ -15 dBFS) : relève les dialogues, laisse le fort. */
  private static final double RMS_TARGET = 0.18;

  /** Plancher du niveau : évite un gain_inf pendant un silence. */
  private static final double RMS_FLOOR = 0.01;

  /**
   * Gains bornes de la normalisation.
   *
   * Le PLAFOND est le point critique, et il vaut 1.0 : l'AGC n'amplifie
   * jamais. Le contenu TV/IPTV est deja normalise (EBU R128, autour de
   * -23 dBFS RMS, cretes proches de 0 dBFS) ; une cible de normalisation plus
   * haute que la source revient a amplifier un signal deja a pleine echelle.
   * Combine au boost de dialogue (+4 dB) et au gain vocal (+3 dB), cela
   * poussait l'ensemble dans l'ecreteur en permanence : saturation, voix
   * illisible. En plafonnant a 1.0, la normalisation ne peut que reduire le
   * niveau — exactement le role d'un limiteur/leveleur, et le seul comportement
   * sur qui on peut garantir l'absence d'ecretage.
   *
   * Le plancher autorise en revanche -24 dB : sans marge d'atténuation
   * suffisante, la boucle ne peut pas ramener un signal amplifie sous la
   * cible et bute.
   */
  private static final double MIN_NORM_GAIN = 0.06;
  private static final double MAX_NORM_GAIN = 1.0;

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
  private int delayCap;
  private int delayWrite;
  private int delayRead;

  /** Coefficients de lissage, recalcules quand le sample rate change. */
  private double rmsCoeff = 1.0;
  private double gainAttackCoeff = 1.0;
  private double gainReleaseCoeff = 1.0;

  /**
   * Seuils de l'ecrature douce. Au-dessus de KNEE on compresse quadratiquement
   * jusqu'a 1.0 plein : aucun ecretage dur, donc aucun crissement, meme quand
   * le gain vocal et la normalisation se cumulent.
   *
   * KNEE a 0.70 (-3 dBFS) plutot que 0.75 : le signal dupliquera de l'ecrature
   * des que la voix monte, ce qui causait la saturation entendue sur les
   * génériques et les sous-titres voix haute.
   */
  private static final double KNEE = 0.70;
  private static final double FULL_SCALE = 32767.0;

  @Override
  public final boolean isActive() {
    // Contrat Media3 : isActive() == false court-circuite le processor, et
    // l'AudioSink ne rappelle PLUS jamais queueInput(). Or il ne réévalue pas
    // isActive() à chaud : basculer Night Focus en cours de lecture ne
    // réactivait donc rien, et les états DSP restaient désynchronisés
    // (gain résiduel, file de retard vide) -> son cassé / muet.
    //
    // On reste donc actif pour que l'activation à chaud fonctionne, et
    // l'on/off se joue dans queueInput() via applyConfig().
    //
    // SAUF en passthrough (AC3 / E-AC3 / Dolby) : ces formats ne sont pas
    // décodés, le processor ne peut rien en faire, et surtout forcer la
    // chaîne audio dessus casse le chemin de passthrough d'ExoPlayer (audio
    // instable, décrochages). On laisse donc ces formats intacts.
    AudioFormat format = lastInputFormat;
    if (format == null || !configured) {
      return false;
    }
    return format.encoding == C.ENCODING_PCM_16BIT;
  }

  /**
   * Coefficient d'un passe-bas d'ordre 1 pour une constante de temps [tauSec].
   * k = 1 - exp(-1 / (tau * fs)) : approximation largement suffisante.
   */
  private static double smoothingCoeff(double tauSec, int sampleRate) {
    if (tauSec <= 0 || sampleRate <= 0) {
      return 1.0;
    }
    return 1.0 - Math.exp(-1.0 / (tauSec * sampleRate));
  }

  private void refreshSmoothingCoefficients() {
    rmsEnv = 0.0;
    normGain = 1.0;
    // Mesure : 50 ms. Attaque du gain : 5 ms (suit la parole).
    // Relâche : 250 ms (évite toute modulation audible).
    rmsCoeff = smoothingCoeff(0.05, sampleRate);
    gainAttackCoeff = smoothingCoeff(0.005, sampleRate);
    gainReleaseCoeff = smoothingCoeff(0.25, sampleRate);
  }

  @NonNull
  @Override
  public AudioProcessor.AudioFormat onConfigure(
      @NonNull AudioProcessor.AudioFormat inputAudioFormat)
      throws AudioProcessor.UnhandledAudioFormatException {
    lastInputFormat = inputAudioFormat;
    if (!NightFocusDspConfig.enabled || inputAudioFormat.encoding != C.ENCODING_PCM_16BIT) {
      processingEnabled = false;
      configured = true;
      encoding = inputAudioFormat.encoding;
      lastConfigVersion = NightFocusDspConfig.getVersion();
      return inputAudioFormat;
    }
    processingEnabled = true;
    sampleRate = inputAudioFormat.sampleRate;
    channelCount = inputAudioFormat.channelCount;
    encoding = inputAudioFormat.encoding;
    recomputeCoefficients();
    normalizationActive = NightFocusDspConfig.volumeNormalization;
    refreshSmoothingCoefficients();
    lastConfigVersion = NightFocusDspConfig.getVersion();
    configured = true;
    return inputAudioFormat;
  }

  private void recomputeCoefficients() {
    applyConfig();
    // Frais démarrage : états des filtres et file de décalage remis à zéro.
    int ch = channelCount;
    hpX = new double[ch * 3];
    hpY = new double[ch * 3];
    peX = new double[ch * 3];
    peY = new double[ch * 3];
    configureDelay(delaySamples, true);
  }

  /**
   * (Re)dimensionne la file de retard.
   *
   * La capacité vaut `delay + 1` et l'on place l'écriture `delay` échantillons
   * devant la lecture : le retard effectif est alors exactement [delay]. Avant,
   * la capacité valait `delay` et lecture/écriture partaient du même index, donc
   * le réglage « décalage A/V » ne décalait rien du tout.
   *
   * La capacité n'est jamais réduite (on garde la plus grande vue), afin qu'un
   * réglage glissé en direct ne réalloue pas un tableau à chaque pas.
   */
  private void configureDelay(int newDelay, boolean reset) {
    delaySamples = Math.max(0, newDelay);
    int needed = delaySamples + 1;
    if (delayBuf == null || delayCap < needed) {
      delayCap = Math.max(needed, 1024);
      delayBuf = new short[delayCap];
      reset = true;
    }
    if (reset) {
      java.util.Arrays.fill(delayBuf, (short) 0);
    }
    // Le curseur de lecture est positionne a `delaySamples` echantillons
    // DERRIERE le curseur d'ecriture : c'est ce decalage qui realise le
    // retard. Les deux Avancent ensuite ensemble, l'ecart constant.
    //
    // Les deux branches sont identiques : le `if/else` etait mort, on garde
    // une seule affectation pour que la relation entre les deux curseurs reste
    // explicite.
    delayWrite = delaySamples % delayCap;
    delayRead = 0;
  }

  @Override
  public void queueInput(@NonNull ByteBuffer inputBuffer) {
    pollConfig();
    int channels = channelCount;
    if (channels <= 0) {
      return;
    }
    int frames = inputBuffer.remaining() / 2 / channels;

    if (!processingEnabled || frames <= 0) {
      // By-pass : copie integrale de l'entree vers la sortie. put + flip sont
      // inconditionnels : sans eux la sortie restait vide et l'AudioSink
      // n'obtenait aucune donnee (silence).
      int remaining = inputBuffer.remaining();
      if (remaining == 0) {
        return;
      }
      ByteBuffer out = replaceOutputBuffer(remaining);
      out.put(inputBuffer);
      out.flip();
      return;
    }

    // L'écriture doit passer par le ByteBuffer LUI-MÊME, pas par une vue
    // asShortBuffer() : une vue a sa propre position, donc les put() n'avançaient
    // pas le buffer sous-jacent et le flip() final produisait une sortie de
    // longueur 0. Le DefaultAudioSink n'obtenait alors jamais de données, le
    // renderer audio ne devenait jamais prêt et ExoPlayer ne faisait pas avancer
    // la position (écran figé + son muet).
    //
    // MÊME PIÈGE EN LECTURE, corrigé ici : `ShortBuffer in = inputBuffer
    // .asShortBuffer()` crée une vue à position INDÉPENDANTE ; `in.get()`
    // n'avançait donc jamais `inputBuffer.position()`. Or le contrat media3
    // (`AudioProcessor.queueInput`) impose que « its position will be advanced
    // by the number of bytes consumed ». Le DefaultAudioSink, voyant un buffer
    // d'entrée non consommé, le reproposait en boucle : dès l'activation du
    // traitement, le son se figeait sur une tonalité répétée. Le by-pass, lui,
    // consommait via `out.put(inputBuffer)`, d'où un son normal tant que Night
    // Focus restait inactif. On lit désormais `getShort()` sur le buffer
    // lui-même : la position avance d'elle-même, octet par octet.
    final int outBytes = frames * 2 * channels;
    inputBuffer.order(ByteOrder.nativeOrder());
    ByteBuffer out = replaceOutputBuffer(outBytes).order(ByteOrder.nativeOrder());

    for (int f = 0; f < frames; f++) {
      for (int ch = 0; ch < channels; ch++) {
        double x = inputBuffer.getShort();
        double v = biquad(x, ch, hpB, hpA, hpX, hpY);
        v = biquad(v, ch, peB, peA, peX, peY);
        v *= gain;
        v = normalize(v);
        short s = (short) Math.max(-32768.0, Math.min(32767.0, Math.round(v)));
        // putShort (et non une vue) fait avancer out.position : indispensable
        // pour que flip() expose réellement outBytes octets.
        out.putShort(delayPut(s));
      }
    }
    out.flip();
  }

  /**
   * Recharge la config à chaud si elle a changé depuis la dernière passe
   * (switch Night Focus, boosts, gain vocal, décalage, normalisation). Pollé
   * en tête de queueInput : latence d'au plus un buffer audio.
   */
  private void pollConfig() {
    int version = NightFocusDspConfig.getVersion();
    if (version == lastConfigVersion) {
      return;
    }
    lastConfigVersion = version;
    applyConfig();
  }

  /**
   * Applique la config courante SANS réinitialiser les états des filtres (pas
   * de clic audible pendant la lecture). Seule la file de décalage est
   * reconfigurée quand sa valeur change réellement.
   */
  private void applyConfig() {
    boolean enabledNow = NightFocusDspConfig.enabled && encoding == C.ENCODING_PCM_16BIT;
    normalizationActive = NightFocusDspConfig.volumeNormalization && enabledNow;

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
      // Peaking EQ (RBJ) normalisee par a0. Les coefficients de numerateur
      // utilisent alpha*A et ceux de denominateur alpha/A : ecrire alpha des
      // deux cote rendait la courbe non conforme (attenuation non desiree).
      double A = Math.pow(10.0, db / 40.0);
      double w0 = 2.0 * Math.PI * 2500.0 / fs;
      double alpha = Math.sin(w0) / (2.0 * 0.9);
      double cw = Math.cos(w0);
      double a0 = 1.0 + alpha / A;
      peB =
          new double[] {
            (1.0 + alpha * A) / a0, (-2.0 * cw) / a0, (1.0 - alpha * A) / a0
          };
      peA = new double[] {1, (-2.0 * cw) / a0, (1.0 - alpha / A) / a0};
    }

    gain = Math.pow(10.0, NightFocusDspConfig.vocalGainDb / 20.0);

    int newDelay = (int) ((long) NightFocusDspConfig.audioDelayMs * fs / 1000);
    if (newDelay != delaySamples) {
      // Reset uniquement si le delai revient a 0 : sinon on repositionne les
      // index sans effacer le contenu (pas de trou de silence en fin de flux).
      configureDelay(newDelay, newDelay == 0);
    }

    // Reprendre le traitement ou réparer des états vidés par onReset.
    int need = channelCount * 3;
    if (enabledNow && (hpX == null || hpX.length != need)) {
      hpX = new double[need];
      hpY = new double[need];
      peX = new double[need];
      peY = new double[need];
    }

    if (!enabledNow) {
      // Sans ceci, un gain résiduel (jusqu'à 4x) s'applique aux premiers
      // échantillons après une désactivation/reactivation : crissement.
      rmsEnv = 0.0;
      normGain = 1.0;
    }
    processingEnabled = enabledNow;
  }

  /**
   * Normalisation du volume (AGC) sur niveau moyen, puis ecrature douce.
   *
   * 1. Mesure : moyenne quadratique lissée sur 50 ms (insensible aux
   *    transitoires isolés, contrairement à un suiveur de crête).
   * 2. Gain : cible / niveau, borné, puis lissé (5 ms d'attaque, 250 ms de
   *    relâche) pour qu'aucune modulation ne soit audible.
   * 3. Ecrature : genou quadratique au-dessus de -2,5 dBFS, qui ne déborde
   *    jamais. Plus aucun ecretage dur, donc plus de crissement quand le gain
   *    vocal et la normalisation se cumulent.
   */
  private double normalize(double sample) {
    double s = sample / FULL_SCALE;
    if (!normalizationActive) {
      return softClip(s) * FULL_SCALE;
    }
    // Rétroaction sur le signal ÉCRÊTÉ et non sur l'entrée : sans cela,
    // l'AGC mesurait un niveau pré-écrêtage, poussait le gain sur un passage
    // fort, saturait, puis ne redescendait qu'en 250 ms — d'où la saturation
    // permanente sur lesodiaux et les génériques. En mesurant la sortie, le
    // gain converge vers un niveau réellement écrêté.
    double out = softClip(s * normGain);
    double sq = out * out;
    rmsEnv += (sq - rmsEnv) * rmsCoeff;
    double rms = Math.sqrt(rmsEnv);
    double target = RMS_TARGET / Math.max(RMS_FLOOR, rms);
    if (target > MAX_NORM_GAIN) {
      target = MAX_NORM_GAIN;
    } else if (target < MIN_NORM_GAIN) {
      target = MIN_NORM_GAIN;
    }
    double coeff = target < normGain ? gainAttackCoeff : gainReleaseCoeff;
    normGain += coeff * (target - normGain);
    return out * FULL_SCALE;
  }

  /**
   * Genou doux quadratique au-dessus de [KNEE], borne a 1.0.
   *
   * f(x) = x                     si |x| <= KNEE
   *      = KNEE + e - e^2/(2(1-KNEE))  sinon, avec e = |x| - KNEE
   *
   * La fonction est C1 a la jonction du genou et vaut exactement +/-1.0 pour
   * |x| >= 1 : impossible de surpasser la pleine echelle, donc aucune
   * distorsion par ecretage quel que soit le gain applique.
   */
  private static double softClip(double x) {
    double a = x < 0 ? -x : x;
    if (a <= KNEE) {
      return x;
    }
    double over = a - KNEE;
    double kneeWidth = 1.0 - KNEE;
    double soft = KNEE + over - (over * over) / (2.0 * kneeWidth);
    if (soft > 1.0) {
      soft = 1.0;
    }
    return x < 0 ? -soft : soft;
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
    if (delayBuf == null || delaySamples <= 0) {
      return s;
    }
    delayBuf[delayWrite] = s;
    short ret = delayBuf[delayRead];
    delayRead = (delayRead + 1) % delayCap;
    delayWrite = (delayWrite + 1) % delayCap;
    return ret;
  }

  @Override
  protected void onFlush() {
    int ch = channelCount;
    hpX = new double[ch * 3];
    hpY = new double[ch * 3];
    peX = new double[ch * 3];
    peY = new double[ch * 3];
    // onFlush suit un seek : on repart d'un etat neutre, sinon le niveau et le
    // gain measures avant le seek s'appliquent d'un coup a la nouvelle position
    // (clic / crissement).
    refreshSmoothingCoefficients();
    configureDelay(delaySamples, true);
  }

  @Override
  protected void onReset() {
    processingEnabled = false;
    lastInputFormat = null;
    configured = false;
    hpX = new double[0];
    hpY = new double[0];
    peX = new double[0];
    peY = new double[0];
    delayBuf = null;
    delayCap = 0;
    delayWrite = 0;
    delayRead = 0;
    delaySamples = 0;
    rmsEnv = 0.0;
    normGain = 1.0;
  }
}