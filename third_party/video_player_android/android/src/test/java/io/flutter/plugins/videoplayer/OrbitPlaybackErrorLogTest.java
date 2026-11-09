package io.flutter.plugins.videoplayer;

import static org.junit.Assert.*;
import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

public class OrbitPlaybackErrorLogTest {
  @Rule public TemporaryFolder temporaryFolder = new TemporaryFolder();

  @Test public void excludesExceptionMessagesAndUnsafeCodecNames() {
    Exception cause = new IllegalStateException("https://example.test/secret?token=private");
    Exception error = new IllegalArgumentException("username=private", cause);
    String result = OrbitPlaybackErrorLog.format(error, 4003, "c2.android.avc.decoder", "software");
    assertTrue(result.contains("java.lang.IllegalStateException"));
    assertTrue(result.contains("c2.android.avc.decoder"));
    assertFalse(result.contains("private"));
    assertFalse(result.contains("example.test"));
    assertFalse(OrbitPlaybackErrorLog.format(error, 1, "token=private", "hardware").contains("private"));
  }

  @Test public void rotatesAndPreservesPreviousRecord() throws IOException {
    File file = temporaryFolder.newFile("orbit_crash.log");
    String large = "x".repeat(200 * 1024);
    OrbitPlaybackErrorLog.append(file, large);
    OrbitPlaybackErrorLog.append(file, large);
    assertEquals(large, new String(Files.readAllBytes(file.toPath()), StandardCharsets.UTF_8));
    File previous = new File(file.getParentFile(), "orbit_crash.log.1");
    assertEquals(large, new String(Files.readAllBytes(previous.toPath()), StandardCharsets.UTF_8));
  }

  @Test public void reportsWriteFailure() {
    File file = new File(temporaryFolder.getRoot(), "missing/orbit_crash.log");
    assertThrows(IOException.class, () -> OrbitPlaybackErrorLog.append(file, "record"));
  }
}
