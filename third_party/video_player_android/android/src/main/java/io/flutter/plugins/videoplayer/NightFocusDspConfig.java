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

  private NightFocusDspConfig() {}
}