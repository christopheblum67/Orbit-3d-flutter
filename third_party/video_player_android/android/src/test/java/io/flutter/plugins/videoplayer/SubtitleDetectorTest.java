// Copyright 2026 The Orbit Project Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.videoplayer;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.when;

import androidx.annotation.Nullable;
import androidx.media3.common.C;
import androidx.media3.common.Format;
import androidx.media3.common.MimeTypes;
import androidx.media3.common.Player;
import androidx.media3.common.TrackGroup;
import androidx.media3.common.Tracks;
import java.util.Arrays;
import java.util.Collections;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnit;
import org.mockito.junit.MockitoRule;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

/**
 * Unit tests for {@link SubtitleDetector}.
 *
 * <p>The {@code Tracks} instances are built with the real Media3 constructors ({@code
 * TrackGroup}/{@code Tracks.Group}/{@code Tracks}) so that the detector is exercised against the
 * actual runtime objects — no mocking of final classes.
 */
@RunWith(RobolectricTestRunner.class)
@Config(sdk = 28)
public final class SubtitleDetectorTest {

  @Mock private Player mockPlayer;
  @Rule public MockitoRule initRule = MockitoJUnit.rule();

  private SubtitleDetector detector;

  @Before
  public void setUp() {
    detector = new SubtitleDetector();
  }

  private static Format video() {
    return new Format.Builder().setSampleMimeType(MimeTypes.VIDEO_H264).build();
  }

  private static Format audio() {
    return new Format.Builder().setSampleMimeType(MimeTypes.AUDIO_AAC).build();
  }

  /** Piste texte à partir d'une langue, d'un libellé et de flags de sélection. */
  private static Format text(
      @Nullable String language, @Nullable String label, int selectionFlags) {
    return new Format.Builder()
        .setSampleMimeType(MimeTypes.TEXT_VTT)
        .setLanguage(language)
        .setLabel(label)
        .setSelectionFlags(selectionFlags)
        .build();
  }

  private static Tracks.Group textGroup(
      @Nullable String language,
      @Nullable String label,
      int selectionFlags,
      boolean selected,
      int support) {
    return new Tracks.Group(
        new TrackGroup(text(language, label, selectionFlags)),
        /* adaptiveSupported= */ false,
        new int[] {support},
        new boolean[] {selected});
  }

  private static Tracks.Group avGroup(Format format, int support, boolean selected) {
    return new Tracks.Group(
        new TrackGroup(format),
        /* adaptiveSupported= */ false,
        new int[] {support},
        new boolean[] {selected});
  }

  private SubtitleDetector.DetectionResult detect(Tracks tracks) {
    when(mockPlayer.getCurrentTracks()).thenReturn(tracks);
    return detector.detect(mockPlayer);
  }

  private static void assertFrenchTrack(
      SubtitleDetector.SubtitleTrackInfo track,
      String language,
      boolean supported,
      boolean selected) {
    assertEquals(language, track.language);
    assertEquals(supported, track.supported);
    assertEquals(selected, track.selected);
  }

  @Test
  public void frenchSupportedSelected_returnsFRENCH_SELECTED() {
    Tracks tracks =
        new Tracks(
            Arrays.asList(
                avGroup(video(), C.FORMAT_HANDLED, true),
                avGroup(audio(), C.FORMAT_HANDLED, true),
                textGroup("fr", "Français", 0, true, C.FORMAT_HANDLED)));

    SubtitleDetector.DetectionResult result = detect(tracks);

    assertEquals(SubtitleDetector.Status.FRENCH_SELECTED, result.status);
    assertEquals(1, result.tracks.size());
    assertFrenchTrack(result.tracks.get(0), "fr", true, true);
  }

  @Test
  public void frenchSupportedNotSelected_returnsFRENCH_AVAILABLE() {
    Tracks tracks =
        new Tracks(
            Arrays.asList(
                avGroup(video(), C.FORMAT_HANDLED, true),
                avGroup(audio(), C.FORMAT_HANDLED, true),
                textGroup("fr", "Français", 0, false, C.FORMAT_HANDLED)));

    SubtitleDetector.DetectionResult result = detect(tracks);

    assertEquals(SubtitleDetector.Status.FRENCH_AVAILABLE, result.status);
    assertFrenchTrack(result.tracks.get(0), "fr", true, false);
  }

  @Test
  public void englishOnlySupported_returnsFRENCH_UNAVAILABLE() {
    Tracks tracks =
        new Tracks(
            Arrays.asList(
                avGroup(video(), C.FORMAT_HANDLED, true),
                textGroup("en", "English", 0, true, C.FORMAT_HANDLED)));

    SubtitleDetector.DetectionResult result = detect(tracks);

    assertEquals(SubtitleDetector.Status.FRENCH_UNAVAILABLE, result.status);
    assertEquals("en", result.tracks.get(0).language);
  }

  @Test
  public void noTracksYet_returnsDETECTION_PENDING() {
    SubtitleDetector.DetectionResult result = detect(Tracks.EMPTY);

    assertEquals(SubtitleDetector.Status.DETECTION_PENDING, result.status);
    assertTrue(result.tracks.isEmpty());
  }

  @Test
  public void videoAudioWithoutText_returnsFRENCH_UNAVAILABLE() {
    Tracks tracks =
        new Tracks(
            Arrays.asList(
                avGroup(video(), C.FORMAT_HANDLED, true),
                avGroup(audio(), C.FORMAT_HANDLED, true)));

    SubtitleDetector.DetectionResult result = detect(tracks);

    // Des groupes existent (vidéo/audio) : la détection est complète, il n'y a
    // simplement aucun sous-titre. Le gestionnaire peut autoriser la recherche.
    assertEquals(SubtitleDetector.Status.FRENCH_UNAVAILABLE, result.status);
  }

  @Test
  public void unsupportedFrenchTrack_isListedButNotAvailable() {
    Tracks tracks =
        new Tracks(
            Arrays.asList(
                avGroup(video(), C.FORMAT_HANDLED, true),
                textGroup("fr", "Français", 0, false, C.FORMAT_UNSUPPORTED_TYPE)));

    SubtitleDetector.DetectionResult result = detect(tracks);

    assertEquals(SubtitleDetector.Status.FRENCH_UNAVAILABLE, result.status);
    assertEquals(1, result.tracks.size());
    assertFrenchTrack(result.tracks.get(0), "fr", false, false);
  }

  @Test
  public void forcedFrenchSelected_surfacesForcedFlag_returnsFRENCH_SELECTED() {
    Tracks tracks =
        new Tracks(
            Arrays.asList(
                avGroup(video(), C.FORMAT_HANDLED, true),
                textGroup("fr", "Forcé", C.SELECTION_FLAG_FORCED, true, C.FORMAT_HANDLED)));

    SubtitleDetector.DetectionResult result = detect(tracks);

    assertEquals(SubtitleDetector.Status.FRENCH_SELECTED, result.status);
    assertTrue(result.tracks.get(0).forced);
  }

  @Test
  public void forcedFrenchNotSelected_remainsAvailable() {
    Tracks tracks =
        new Tracks(
            Arrays.asList(
                avGroup(video(), C.FORMAT_HANDLED, true),
                textGroup("fr", "Forcé", C.SELECTION_FLAG_FORCED, false, C.FORMAT_HANDLED)));

    SubtitleDetector.DetectionResult result = detect(tracks);

    assertEquals(SubtitleDetector.Status.FRENCH_AVAILABLE, result.status);
    assertTrue(result.tracks.get(0).forced);
  }

  @Test
  public void languageVariants_fra_fre_fr_FR_fr_CA_allCountAsFrench() {
    // Media3 normalise déjà la langue (Format.Builder -> Util.normalizeLanguageCode,
    // ex. "fra" -> "fr"). Peu importe la forme reçue : le détecteur doit la
    // CLASSER comme française. On vérifie donc le statut, pas la chaîne exacte.
    for (String variant : new String[] {"fra", "fre", "fr-FR", "fr-CA", "fr_CA"}) {
      Tracks tracks =
          new Tracks(
              Arrays.asList(
                  avGroup(video(), C.FORMAT_HANDLED, true),
                  textGroup(variant, "Titre", 0, true, C.FORMAT_HANDLED)));
      SubtitleDetector.DetectionResult result = detect(tracks);
      assertEquals("variant=" + variant, SubtitleDetector.Status.FRENCH_SELECTED, result.status);
      assertTrue(
          "variant=" + variant + " -> langue reportée vide",
          result.tracks.get(0).language != null && !result.tracks.get(0).language.isEmpty());
    }
  }

  @Test
  public void missingLanguage_labelFallbackFrancais_countsAsFrench() {
    Tracks tracks =
        new Tracks(Collections.singletonList(textGroup(null, "Français", 0, true, C.FORMAT_HANDLED)));

    SubtitleDetector.DetectionResult result = detect(tracks);

    assertEquals(SubtitleDetector.Status.FRENCH_SELECTED, result.status);
    assertEquals("fr", result.tracks.get(0).language);
  }

  @Test
  public void missingLanguage_frenchCommentary_isNotPlainFrench() {
    // « French Commentary » est une piste de commentaire, pas des sous-titres
    // français complets : elle ne doit pas faire passer la vidéo en
    // FRENCH_AVAILABLE.
    Tracks tracks =
        new Tracks(
            Collections.singletonList(
                textGroup(null, "French Commentary", 0, false, C.FORMAT_HANDLED)));

    SubtitleDetector.DetectionResult result = detect(tracks);

    assertEquals(SubtitleDetector.Status.FRENCH_UNAVAILABLE, result.status);
    assertEquals("und", result.tracks.get(0).language);
  }

  @Test
  public void sdhLabels_sdh_hearingImpaired_malentendant_areDetected() {
    for (String sdhLabel :
        new String[] {"French (SDH)", "English (Hearing Impaired)", "Français (Malentendant)"}) {
      Tracks tracks =
          new Tracks(
              Collections.singletonList(textGroup(null, sdhLabel, 0, false, C.FORMAT_HANDLED)));
      SubtitleDetector.DetectionResult result = detect(tracks);
      assertTrue("label=" + sdhLabel, result.tracks.get(0).sdh);
    }

    Tracks plain =
        new Tracks(Collections.singletonList(textGroup("fr", "Français", 0, false, C.FORMAT_HANDLED)));
    assertFalse(detect(plain).tracks.get(0).sdh);
  }

  @Test
  public void id_reflectsGroupPositionIgnoringNonTextGroups() {
    // groupe 0 = vidéo, 1 = audio, 2 = texte français.
    Tracks tracks =
        new Tracks(
            Arrays.asList(
                avGroup(video(), C.FORMAT_HANDLED, true),
                avGroup(audio(), C.FORMAT_HANDLED, true),
                textGroup("fr", "Français", 0, true, C.FORMAT_HANDLED)));

    SubtitleDetector.DetectionResult result = detect(tracks);

    assertEquals("2_0", result.tracks.get(0).id);
  }

  @Test
  public void multipleTextGroups_reportsAllWithGroupIndices() {
    Tracks tracks =
        new Tracks(
            Arrays.asList(
                avGroup(video(), C.FORMAT_HANDLED, true),
                textGroup("en", "English", 0, true, C.FORMAT_HANDLED),
                textGroup("fr", "Français", 0, true, C.FORMAT_HANDLED)));

    SubtitleDetector.DetectionResult result = detect(tracks);

    assertEquals(SubtitleDetector.Status.FRENCH_SELECTED, result.status);
    assertEquals(2, result.tracks.size());
    assertEquals("en", result.tracks.get(0).language);
    assertEquals("fr", result.tracks.get(1).language);
    assertEquals("1_0", result.tracks.get(0).id);
    assertEquals("2_0", result.tracks.get(1).id);
  }
}