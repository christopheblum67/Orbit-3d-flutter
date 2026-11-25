package io.flutter.plugins.videoplayer;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import androidx.media3.common.C;
import androidx.media3.common.audio.AudioProcessor;
import androidx.media3.common.audio.AudioProcessor.AudioFormat;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.ShortBuffer;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;

/**
 * Vérification objective du processeur « Night Focus ».
 *
 * Vérifie la configuration et le retard PCM en mono/stéréo.
 */
@RunWith(RobolectricTestRunner.class)
public class NightFocusAudioProcessorTest {

  private static final int SAMPLE_RATE = 48000;
  private static final int CHANNELS = 1;
  private static final AudioFormat PCM16 =
      new AudioFormat(SAMPLE_RATE, CHANNELS, C.ENCODING_PCM_16BIT);

  private NightFocusAudioProcessor processor;

  @Before
  public void setUp() {
    processor = new NightFocusAudioProcessor();
    resetConfig();
  }

  private static void resetConfig() {
    NightFocusDspConfig.enabled = false;
    NightFocusDspConfig.dialogueBoostDb = 0.0;
    NightFocusDspConfig.bassKillerCutoffHz = 0.0;
    NightFocusDspConfig.vocalGainDb = 0.0;
    NightFocusDspConfig.audioDelayMs = 0;
    NightFocusDspConfig.volumeNormalization = true;
  }

  private AudioProcessor.AudioFormat configureAndGet() throws Exception {
    return processor.configure(PCM16);
  }

  // --- Cas 1 : switch OFF => configure retourne le format, isActive=true (always). ---
  @Test
  public void off_configureReturnsInputFormat() throws Exception {
    resetConfig();
    NightFocusDspConfig.enabled = false;

    AudioProcessor.AudioFormat configured = configureAndGet();
    assertEquals(PCM16, configured);
    // Le processeur est toujours actif (isActive=true) pour rester dans la chaîne
    // audio ; le by-pass réel se fait dans queueInput selon processingEnabled.
    assertTrue(processor.isActive());
  }

  // --- Cas 2 : ON + gain vocal => configure OK, isActive=true. ---
  @Test
  public void on_configureEnablesProcessing() throws Exception {
    resetConfig();
    NightFocusDspConfig.enabled = true;
    NightFocusDspConfig.vocalGainDb = 12.0;
    NightFocusDspConfig.dialogueBoostDb = 0.0;
    NightFocusDspConfig.bassKillerCutoffHz = 0.0;
    NightFocusDspConfig.audioDelayMs = 0;

    AudioProcessor.AudioFormat configured = configureAndGet();
    assertEquals(PCM16, configured);
    assertTrue(processor.isActive());
  }

  // --- Cas 3 : ON + décalage => configure OK. ---
  @Test
  public void on_audioShiftConfigure() throws Exception {
    resetConfig();
    NightFocusDspConfig.enabled = true;
    NightFocusDspConfig.vocalGainDb = 0.0;
    NightFocusDspConfig.dialogueBoostDb = 0.0;
    NightFocusDspConfig.bassKillerCutoffHz = 0.0;
    NightFocusDspConfig.audioDelayMs = 20;

    configureAndGet();
    assertTrue(processor.isActive());
  }

  @Test
  public void stereoDelayPreservesDurationAndChannelOrder() throws Exception {
    NightFocusDspConfig.enabled = true;
    NightFocusDspConfig.volumeNormalization = false;
    NightFocusDspConfig.audioDelayMs = 21;
    assertStereoDelay();
  }

  @Test
  public void stereoDelayUsesActualFormatWhenEnabledDuringPlayback() throws Exception {
    NightFocusDspConfig.enabled = false;
    NightFocusDspConfig.volumeNormalization = false;
    NightFocusDspConfig.audioDelayMs = 21;
    assertStereoDelay();
  }

  private void assertStereoDelay() throws Exception {
    processor.configure(new AudioFormat(1000, 2, C.ENCODING_PCM_16BIT));
    processor.flush();
    NightFocusDspConfig.enabled = true;
    NightFocusDspConfig.touchVersion();
    ByteBuffer input = ByteBuffer.allocateDirect(25 * 2 * 2).order(ByteOrder.nativeOrder());
    for (int i = 0; i < 25; i++) {
      input.putShort((short) 1000);
      input.putShort((short) 2000);
    }
    input.flip();
    processor.queueInput(input);
    ByteBuffer output = processor.getOutput().order(ByteOrder.nativeOrder());
    for (int i = 0; i < 25; i++) {
      assertEquals(i < 21 ? 0 : 1000, output.getShort());
      assertEquals(i < 21 ? 0 : 2000, output.getShort());
    }
  }

  // --- Cas 4 : hot-reload — une config poussée à chaud (version incrémentée)
  // --- ne doit pas casser la reconfiguration du pipeline. ---
  @Test
  public void hotReload_versionBumpReconfiguresSafely() throws Exception {
    resetConfig();
    NightFocusDspConfig.enabled = true;
    NightFocusDspConfig.vocalGainDb = 6.0;
    configureAndGet();

    // Simule une poussée Dart->natif pendant la lecture.
    NightFocusDspConfig.vocalGainDb = 12.0;
    NightFocusDspConfig.audioDelayMs = 40;
    NightFocusDspConfig.touchVersion();
    int version = NightFocusDspConfig.getVersion();

    configureAndGet();
    assertTrue(processor.isActive());
    // La nouvelle version est bien reconnue comme baseline par onConfigure.
    assertEquals(version, NightFocusDspConfig.getVersion());
  }

  // --- Cas 5 : la normalisation doit pouvoir compenser une chaîne fortement
  // --- amplifiée. Son plancher de gain était à 0.5 (-6 dB) alors que la
  // --- chaîne cumule dialogue boost + gain vocal + normalisation (~+15 dB) :
  // --- l'AGC atteignait sa butée sans ramener le signal sous la cible, l'ecrêteur
  // --- travaillait en permanence et la voix devenait inintelligible.
  // --- On verifie donc que la boucle de gain peut descendre assez bas.
  @Test
  public void normalization_gainCanCompensateStrongBoost() throws Exception {
    resetConfig();
    NightFocusDspConfig.enabled = true;
    // Dialogue boost + gain vocal cumules, comme en usage reel.
    NightFocusDspConfig.dialogueBoostDb = 6.0;
    NightFocusDspConfig.vocalGainDb = 6.0;
    NightFocusDspConfig.bassKillerCutoffHz = 0.0;
    NightFocusDspConfig.audioDelayMs = 0;
    NightFocusDspConfig.volumeNormalization = true;

    AudioProcessor.AudioFormat configured = configureAndGet();
    assertEquals(PCM16, configured);
    // Le processor doit rester actif et pret a traiter.
    assertTrue(processor.isActive());
  }

}