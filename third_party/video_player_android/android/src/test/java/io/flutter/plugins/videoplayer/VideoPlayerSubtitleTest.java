// Copyright 2026 The Orbit Project Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.videoplayer;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.view.Surface;
import androidx.media3.common.C;
import androidx.media3.common.Format;
import androidx.media3.common.MimeTypes;
import androidx.media3.common.TrackGroup;
import androidx.media3.common.TrackSelectionOverride;
import androidx.media3.common.Tracks;
import androidx.media3.common.text.Cue;
import androidx.media3.common.text.CueGroup;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector;
import io.flutter.view.TextureRegistry;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnit;
import org.mockito.junit.MockitoRule;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

/**
 * Unit tests for the embedded-subtitle surface of {@link VideoPlayer} (getSubtitleTracks,
 * selectSubtitleTrack, clearSubtitleTracks, getCurrentCues).
 *
 * <p>Suivant le patron de {@link SubtitleDetectorTest} : les {@code Tracks}/{@code CueGroup} sont
 * construits avec les vrais constructeurs Media3, seuls {@link ExoPlayer} et {@link
 * DefaultTrackSelector} sont mockés.
 */
@RunWith(RobolectricTestRunner.class)
@Config(sdk = 28)
public final class VideoPlayerSubtitleTest {
  private static final String FAKE_ASSET_URL = "https://flutter.dev/movie.mp4";

  private FakeVideoAsset fakeVideoAsset;

  @Mock private VideoPlayerCallbacks mockEvents;
  @Mock private TextureRegistry.SurfaceProducer mockProducer;
  @Mock private ExoPlayer mockExoPlayer;
  @Mock private DefaultTrackSelector mockTrackSelector;
  @Captor private ArgumentCaptor<DefaultTrackSelector.Parameters> parametersCaptor;

  @Rule public MockitoRule initRule = MockitoJUnit.rule();

  @Before
  public void setUp() {
    fakeVideoAsset = new FakeVideoAsset(FAKE_ASSET_URL);
    // Même stub de surface que `VideoPlayerTest.setUp()` :
    // `VideoPlayer.createVideoPlayer()` la consomme dès la construction.
    when(mockProducer.getSurface()).thenReturn(mock(Surface.class));
    when(mockExoPlayer.getTrackSelector()).thenReturn(mockTrackSelector);
  }

  private VideoPlayer createVideoPlayer() {
    return new VideoPlayer(
        () -> mockExoPlayer,
        mockEvents,
        mockProducer,
        fakeVideoAsset.getMediaItem(),
        new VideoPlayerOptions());
  }

  // --- Helpers de construction de pistes (mêmes conventions que SubtitleDetectorTest) ---

  private static Format video() {
    return new Format.Builder().setSampleMimeType(MimeTypes.VIDEO_H264).build();
  }

  private static Format text(int selectionFlags, String language, String label) {
    return new Format.Builder()
        .setSampleMimeType(MimeTypes.TEXT_VTT)
        .setLanguage(language)
        .setLabel(label)
        .setSelectionFlags(selectionFlags)
        .build();
  }

  private static Tracks.Group textGroup(
      Format format, boolean selected, @C.FormatSupport int support) {
    return new Tracks.Group(
        new TrackGroup(format),
        /* adaptiveSupported= */ false,
        new int[] {support},
        new boolean[] {selected});
  }

  private static Tracks.Group avGroup() {
    return new Tracks.Group(
        new TrackGroup(video()),
        /* adaptiveSupported= */ false,
        new int[] {C.FORMAT_HANDLED},
        new boolean[] {true});
  }

  /** Vidéo + deux pistes texte françaises (forced puis full). */
  private static Tracks frenchTracks() {
    return new Tracks(
        Arrays.asList(
            avGroup(),
            textGroup(text(C.SELECTION_FLAG_FORCED, "fr", "VFF : Forced"), true, C.FORMAT_HANDLED),
            textGroup(text(0, "fr", "VFF : Full"), false, C.FORMAT_HANDLED)));
  }

  private DefaultTrackSelector.Parameters defaultSelectorParameters() {
    return DefaultTrackSelector.Parameters.getDefaults(RuntimeEnvironment.getApplication());
  }

  // --- getSubtitleTracks ---

  @Test
  public void getSubtitleTracks_listsSupportedTextTracksWithMetadata() {
    VideoPlayer videoPlayer = createVideoPlayer();
    when(mockExoPlayer.getCurrentTracks()).thenReturn(frenchTracks());

    List<Map<String, Object>> tracks = videoPlayer.getSubtitleTracks();

    assertEquals(2, tracks.size());
    Map<String, Object> forced = tracks.get(0);
    assertEquals("1_0", forced.get("id"));
    assertEquals("VFF : Forced", forced.get("label"));
    assertEquals("fr", forced.get("language"));
    assertEquals(Boolean.TRUE, forced.get("isSelected"));
    assertEquals(Boolean.TRUE, forced.get("isForced"));
    assertEquals(MimeTypes.TEXT_VTT, forced.get("mimeType"));
    Map<String, Object> full = tracks.get(1);
    assertEquals("2_0", full.get("id"));
    assertEquals("VFF : Full", full.get("label"));
    assertEquals(Boolean.FALSE, full.get("isSelected"));
    assertEquals(Boolean.FALSE, full.get("isForced"));

    videoPlayer.dispose();
  }

  @Test
  public void getSubtitleTracks_skipsUnsupportedTextTracks() {
    VideoPlayer videoPlayer = createVideoPlayer();
    when(mockExoPlayer.getCurrentTracks())
        .thenReturn(
            new Tracks(
                Arrays.asList(
                    textGroup(text(C.SELECTION_FLAG_FORCED, "fr", "Forcé"), true, C.FORMAT_HANDLED),
                    textGroup(text(0, "en", "English"), false, C.FORMAT_UNSUPPORTED_TYPE))));

    List<Map<String, Object>> tracks = videoPlayer.getSubtitleTracks();

    // La piste <en> n'est pas supportée par le pipeline : elle ne doit pas
    // apparaître (elle provoquerait un échec de sélection côté Dart).
    assertEquals(1, tracks.size());
    assertEquals("0_0", tracks.get(0).get("id"));

    videoPlayer.dispose();
  }

  @Test
  public void getSubtitleTracks_noCurrentTracks_returnsEmpty() {
    VideoPlayer videoPlayer = createVideoPlayer();
    when(mockExoPlayer.getCurrentTracks()).thenReturn(null);

    assertTrue(videoPlayer.getSubtitleTracks().isEmpty());

    videoPlayer.dispose();
  }

  // --- selectSubtitleTrack / clearSubtitleTracks ---

  @Test
  public void selectSubtitleTrack_setsOverrideForTrackAndKeepsTextEnabled() {
    VideoPlayer videoPlayer = createVideoPlayer();
    Tracks tracks = frenchTracks();
    when(mockExoPlayer.getCurrentTracks()).thenReturn(tracks);
    when(mockTrackSelector.getParameters()).thenReturn(defaultSelectorParameters());

    videoPlayer.selectSubtitleTrack("2_0");

    verify(mockTrackSelector).setParameters(parametersCaptor.capture());
    DefaultTrackSelector.Parameters parameters = parametersCaptor.getValue();
    TrackGroup mediaTrackGroup = tracks.getGroups().get(2).getMediaTrackGroup();
    TrackSelectionOverride override = parameters.overrides.get(mediaTrackGroup);
    assertEquals(0, (int) override.trackIndices.get(0));
    assertFalse(parameters.disabledTrackTypes.contains(C.TRACK_TYPE_TEXT));

    videoPlayer.dispose();
  }

  @Test
  public void selectSubtitleTrack_afterClearReenablesTextType() {
    VideoPlayer videoPlayer = createVideoPlayer();
    when(mockExoPlayer.getCurrentTracks()).thenReturn(frenchTracks());
    when(mockTrackSelector.getParameters()).thenReturn(defaultSelectorParameters());

    videoPlayer.clearSubtitleTracks();
    videoPlayer.selectSubtitleTrack("1_0");

    // clearSubtitleTracks (1) puis selectSubtitleTrack (2) : on inspecte le
    // dernier jeu de paramètres appliqué.
    verify(mockTrackSelector, org.mockito.Mockito.times(2))
        .setParameters(parametersCaptor.capture());
    assertFalse(
        parametersCaptor.getValue().disabledTrackTypes.contains(C.TRACK_TYPE_TEXT));

    videoPlayer.dispose();
  }

  @Test
  public void clearSubtitleTracks_disablesTextAndDropsOverrides() {
    VideoPlayer videoPlayer = createVideoPlayer();
    Tracks tracks = frenchTracks();
    when(mockExoPlayer.getCurrentTracks()).thenReturn(tracks);
    when(mockTrackSelector.getParameters()).thenReturn(defaultSelectorParameters());

    videoPlayer.clearSubtitleTracks();

    verify(mockTrackSelector).setParameters(parametersCaptor.capture());
    DefaultTrackSelector.Parameters parameters = parametersCaptor.getValue();
    assertTrue(parameters.disabledTrackTypes.contains(C.TRACK_TYPE_TEXT));
    for (Tracks.Group group : tracks.getGroups()) {
      assertNull(parameters.overrides.get(group.getMediaTrackGroup()));
    }

    videoPlayer.dispose();
  }

  @Test(expected = IllegalArgumentException.class)
  public void selectSubtitleTrack_unknownTrackId_throws() {
    VideoPlayer videoPlayer = createVideoPlayer();
    when(mockExoPlayer.getCurrentTracks()).thenReturn(frenchTracks());

    try {
      videoPlayer.selectSubtitleTrack("9_9");
    } finally {
      videoPlayer.dispose();
    }
  }

  // --- getCurrentCues ---

  @Test
  public void getCurrentCues_returnsRenderedTextCuesWithPresentationTime() {
    VideoPlayer videoPlayer = createVideoPlayer();
    CueGroup rendered =
        new CueGroup(
            Arrays.asList(
                new Cue.Builder().setText("Première ligne").build(),
                new Cue.Builder().setText("Deuxième ligne").build(),
                new Cue.Builder()
                    .setBitmap(
                        android.graphics.Bitmap.createBitmap(
                            2, 2, android.graphics.Bitmap.Config.ARGB_8888))
                    .build()),
            9_000_000L);
    when(mockExoPlayer.getCurrentCues()).thenReturn(rendered);

    Map<String, Object> result = videoPlayer.getCurrentCues();

    assertEquals(9_000_000L, result.get("presentationTimeUs"));
    @SuppressWarnings("unchecked")
    List<Map<String, Object>> cues = (List<Map<String, Object>>) result.get("cues");
    assertEquals(2, cues.size()); // la cue bitmap (sans texte) est ignorée
    assertEquals("Première ligne", cues.get(0).get("text"));
    assertEquals("Deuxième ligne", cues.get(1).get("text"));

    videoPlayer.dispose();
  }

  @Test
  public void getCurrentCues_emptyGroup_returnsEmptyCues() {
    VideoPlayer videoPlayer = createVideoPlayer();
    when(mockExoPlayer.getCurrentCues()).thenReturn(new CueGroup(Arrays.asList(), 0L));

    Map<String, Object> result = videoPlayer.getCurrentCues();

    assertEquals(0L, result.get("presentationTimeUs"));
    @SuppressWarnings("unchecked")
    List<Map<String, Object>> cues = (List<Map<String, Object>>) result.get("cues");
    assertTrue(cues.isEmpty());

    videoPlayer.dispose();
  }
}