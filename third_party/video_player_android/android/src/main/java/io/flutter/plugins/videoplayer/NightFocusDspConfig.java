package io.flutter.plugins.videoplayer;

/**
 * Config des réglages DSP « Night Focus ». Peuplé depuis Dart (player_screen)
 * avant/présentement pendant la lecture. Lu par
 * {@link NightFocusAudioProcessor} à chaque préparation/configuration.
 *
 * Cette classe est un holder statique volontairement simple : elle évite
 * de modifier le contrat Pigeon de video_player_android.
 */
public final class NightFocusDspConfig {
  /** Maître : false = pipeline audio par défaut, aucun traitement. */
  public static boolean enabled = false;

  /** Gain de la bande « dialogue » (1–4 kHz), en dB (0 = off). */
  public static double dialogueBoostDb = 4.0;

  /** Fréquence de coupure du « bass killer » (< 120 Hz), en Hz (0 = off). */
  public static double bassKillerCutoffHz = 120.0;

  /** Gain global de la voix, en dB (0 = désactivé). */
  public static double vocalGainDb = 3.0;

  /** Décalage audio (A/V sync), en ms (>0 : l'audio est retardé). */
  public static int audioDelayMs = 0;

  /** Normalisation du volume (AGC piloté par les pics) : true = limite les
   *  pics de volume entre chaînes/programmes. */
  public static boolean volumeNormalization = true;

  /** Version de la configuration. Incrémentée à chaque poussée du canal
   *  Dart -> natif pour que {@link NightFocusAudioProcessor} puisse recharger
   *  la config à chaud (hot-reload) pendant la lecture. Volatile car écrite
   *  sur le thread plateforme, lue sur le thread audio. */
  private static volatile int version;

  /** Incrémente la version de config après une écriture (hors onConfigure
   *  qui applique déjà la config). */
  public static void touchVersion() {
    version++;
  }

  public static int getVersion() {
    return version;
  }

  private NightFocusDspConfig() {}
}