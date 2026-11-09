package io.flutter.plugins.videoplayer;

import android.content.Context;
import android.util.Log;
import androidx.media3.common.PlaybackException;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

/** Private bounded diagnostic log. Exception messages and media URLs are never written. */
final class OrbitPlaybackErrorLog {
  private static final long MAX_BYTES = 256 * 1024;
  private static final ThreadPoolExecutor WRITER =
      new ThreadPoolExecutor(
          1, 1, 0, TimeUnit.SECONDS, new ArrayBlockingQueue<>(32),
          runnable -> {
            Thread thread = new Thread(runnable, "orbit-error-log");
            thread.setDaemon(true);
            return thread;
          },
          (runnable, executor) -> Log.e("OrbitErrorLog", "Diagnostic queue full"));

  private final File file;

  OrbitPlaybackErrorLog(Context context) {
    file = new File(context.getFilesDir(), "orbit_crash.log");
  }

  void record(PlaybackException error, String decoderName, String decoderKind) {
    String record = format(error, error.errorCode, decoderName, decoderKind);
    WRITER.execute(() -> {
      try {
        append(file, record);
      } catch (IOException | SecurityException e) {
        Log.e("OrbitErrorLog", "Unable to write playback diagnostic: " + e.getClass().getSimpleName());
      }
    });
  }

  static String format(Throwable error, int code, String decoder, String kind) {
    StringBuilder result = new StringBuilder();
    result.append("timestamp=").append(System.currentTimeMillis())
        .append(" code=").append(code)
        .append(" decoder=").append(safe(decoder))
        .append(" kind=").append(safe(kind)).append('\n');
    Throwable current = error;
    for (int cause = 0; current != null && cause < 8; cause++) {
      result.append("exception=").append(safe(current.getClass().getName())).append('\n');
      StackTraceElement[] frames = current.getStackTrace();
      for (int i = 0; i < frames.length && i < 80; i++) {
        StackTraceElement frame = frames[i];
        result.append(" at ").append(safe(frame.getClassName())).append('.')
            .append(safe(frame.getMethodName())).append('(')
            .append(safe(frame.getFileName())).append(':').append(frame.getLineNumber()).append(")\n");
      }
      Throwable next = current.getCause();
      if (next == current) break;
      current = next;
    }
    return result.append('\n').toString();
  }

  private static String safe(String value) {
    if (value == null || value.length() > 200 || !value.matches("[A-Za-z0-9_.$<>-]+")) {
      return "unknown";
    }
    return value;
  }

  static void append(File file, String record) throws IOException {
    byte[] bytes = record.getBytes(StandardCharsets.UTF_8);
    if (bytes.length > MAX_BYTES) throw new IOException("diagnostic too large");
    if (file.exists() && file.length() + bytes.length > MAX_BYTES) {
      File previous = new File(file.getParentFile(), file.getName() + ".1");
      if (previous.exists() && !previous.delete()) throw new IOException("rotation delete failed");
      if (!file.renameTo(previous)) throw new IOException("rotation rename failed");
    }
    try (FileOutputStream stream = new FileOutputStream(file, true)) {
      stream.write(bytes);
    }
  }
}
