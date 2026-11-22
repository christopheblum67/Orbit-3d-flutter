package io.flutter.plugins.videoplayer;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertSame;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.net.Uri;
import androidx.media3.common.C;
import androidx.media3.common.Format;
import androidx.media3.common.MimeTypes;
import androidx.media3.common.PlaybackException;
import androidx.media3.common.TrackGroup;
import androidx.media3.common.Tracks;
import androidx.media3.datasource.DataSource;
import androidx.media3.datasource.DataSpec;
import androidx.media3.exoplayer.ExoPlayer;
import java.io.IOException;
import java.util.Collections;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.shadows.ShadowLog;

@RunWith(RobolectricTestRunner.class)
public final class PlayerLogPrivacyTest {
  private static final String MARKER = "private-marker-123";
  private static final Uri SOURCE = Uri.parse("https://example.invalid/" + MARKER);

  @Before
  public void clearLogs() {
    ShadowLog.clear();
  }

  private static void assertPrivate(String tag) {
    assertFalse(ShadowLog.getLogsForTag(tag).isEmpty());
    for (ShadowLog.LogItem item : ShadowLog.getLogsForTag(tag)) {
      assertFalse(item.msg.contains(MARKER));
      assertNull(item.throwable);
    }
  }

  @Test
  public void dataSourceLogsProgressWithoutUris() throws IOException {
    DataSource delegate = mock(DataSource.class);
    DataSpec spec = new DataSpec(SOURCE);
    byte[] buffer = new byte[1024 * 1024];
    when(delegate.open(spec)).thenReturn((long) buffer.length);
    when(delegate.read(buffer, 0, buffer.length)).thenReturn(buffer.length);
    when(delegate.getUri()).thenReturn(SOURCE);
    LoggingDataSource source = new LoggingDataSource(delegate);

    assertEquals(buffer.length, source.open(spec));
    assertEquals(buffer.length, source.read(buffer, 0, buffer.length));
    assertSame(SOURCE, source.getUri());
    source.close();

    verify(delegate).close();
    assertPrivate("OrbitHttp");
    assertTrue(ShadowLog.getLogsForTag("OrbitHttp").stream().anyMatch(i -> i.msg.contains("READ total=")));
  }

  @Test
  public void dataSourceRethrowsOriginalExceptionWithoutLoggingItsMessage() throws IOException {
    DataSource delegate = mock(DataSource.class);
    DataSpec spec = new DataSpec(SOURCE);
    IOException failure = new IOException(MARKER);
    when(delegate.open(spec)).thenThrow(failure);
    LoggingDataSource source = new LoggingDataSource(delegate);

    try {
      source.open(spec);
      fail("Expected the original exception");
    } catch (IOException actual) {
      assertSame(failure, actual);
    }
    assertPrivate("OrbitHttp");
    assertTrue(ShadowLog.getLogsForTag("OrbitHttp").stream().anyMatch(i -> i.msg.contains("FAILED type=IOException")));
  }

  @Test
  public void playbackErrorLogsCodeWithoutExceptionOrCause() {
    PlaybackException failure =
        new PlaybackException(MARKER, new IOException(MARKER), PlaybackException.ERROR_CODE_IO_UNSPECIFIED);

    VideoPlayer.logPlaybackError(failure);

    assertPrivate("OrbitPlayer");
    assertTrue(ShadowLog.getLogsForTag("OrbitPlayer").get(0).msg.contains("code=" + failure.errorCode));
  }

  @Test
  public void subtitleLogExcludesUntrustedTrackMetadata() {
    Format format = new Format.Builder().setSampleMimeType(MimeTypes.TEXT_VTT)
        .setLanguage("en").setLabel(MARKER).build();
    Tracks tracks = new Tracks(Collections.singletonList(new Tracks.Group(
        new TrackGroup(format), false, new int[] {C.FORMAT_HANDLED}, new boolean[] {false})));
    ExoPlayer player = mock(ExoPlayer.class);
    when(player.getCurrentTracks()).thenReturn(tracks);
    ExoPlayerEventListener listener = new ExoPlayerEventListener(player, mock(VideoPlayerCallbacks.class));

    listener.onTracksChanged(tracks);

    assertPrivate("OrbitSubtitle");
    assertTrue(ShadowLog.getLogsForTag("OrbitSubtitle").get(0).msg.contains("count=1"));
  }
}
