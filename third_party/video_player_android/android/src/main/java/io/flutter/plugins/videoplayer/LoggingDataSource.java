package io.flutter.plugins.videoplayer;

import android.net.Uri;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.media3.datasource.DataSource;
import androidx.media3.datasource.DataSpec;
import androidx.media3.datasource.HttpDataSource;
import androidx.media3.datasource.TransferListener;
import java.io.IOException;
import java.io.InterruptedIOException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.TimeZone;
import java.util.concurrent.TimeUnit;

/**
 * Enveloppe un {@link DataSource} pour diagnostiquer les ouvertures et les lectures
 * sans journaliser les adresses ni les messages d'erreur.
 */
final class LoggingDataSource implements DataSource {
  private static final String TAG = "OrbitHttp";

  /** Nombre max d'ouvertures pour une meme demande. */
  private static final int MAX_ATTEMPTS = 4;

  /** Espacement minimal entre les departs, sans serialiser les lectures. */
  private static final long MIN_GAP_MS = 200L;

  /** Delais avant nouvelle tentative apres un refus. */
  private static final long[] BACKOFF_MS = {3000L, 8000L, 20000L};
  private static final long MAX_COOLDOWN_MS = 60000L;
  private static final OpenGate OPEN_GATE = new OpenGate(MIN_GAP_MS);

  private final DataSource delegate;
  private final OpenGate gate;
  private final long[] backoffs;
  private long bytesRead;
  private int lastLoggedBucket;

  LoggingDataSource(DataSource delegate) {
    this(delegate, OPEN_GATE, BACKOFF_MS);
  }

  LoggingDataSource(DataSource delegate, OpenGate gate, long[] backoffs) {
    this.delegate = delegate;
    this.gate = gate;
    this.backoffs = backoffs;
  }

  @Override
  public void addTransferListener(TransferListener transferListener) {
    delegate.addTransferListener(transferListener);
  }

  @Override
  public long open(DataSpec dataSpec) throws IOException {
    bytesRead = 0L;
    lastLoggedBucket = 0;
    for (int attempt = 0; ; attempt++) {
      gate.awaitOpen();
      try {
        Log.i(
            TAG,
            "OPEN(try "
                + (attempt + 1)
                + ") position="
                + dataSpec.position
                + " length="
                + dataSpec.length);
        long length = delegate.open(dataSpec);
        Log.i(TAG, "  OK length=" + length);
        return length;
      } catch (IOException e) {
        if (isRateLimited(e)) {
          long backoff = backoffs[Math.min(attempt, backoffs.length - 1)];
          long delay = Math.max(backoff, retryAfterMs(e, System.currentTimeMillis()));
          gate.defer(Math.min(delay, MAX_COOLDOWN_MS));
          if (attempt < MAX_ATTEMPTS - 1 && delay <= MAX_COOLDOWN_MS) {
            Log.w(TAG, "  HTTP throttle, retry in at least " + delay + "ms");
            try {
              delegate.close();
            } catch (IOException closeError) {
              closeError.addSuppressed(e);
              throw closeError;
            }
            continue;
          }
        }
        String status = e instanceof HttpDataSource.InvalidResponseCodeException
            ? " status=" + ((HttpDataSource.InvalidResponseCodeException) e).responseCode
            : "";
        Log.e(TAG, "  FAILED type=" + e.getClass().getSimpleName() + status);
        throw e;
      }
    }
  }

  private static boolean isRateLimited(IOException e) {
    if (e instanceof HttpDataSource.InvalidResponseCodeException) {
      int code = ((HttpDataSource.InvalidResponseCodeException) e).responseCode;
      return code == 401 || code == 403 || code == 429;
    }
    final String m = String.valueOf(e.getMessage());
    return m.contains("Response code: 401")
        || m.contains("Response code: 403")
        || m.contains("Response code: 429");
  }

  static long retryAfterMs(IOException error, long nowMs) {
    if (!(error instanceof HttpDataSource.InvalidResponseCodeException)
        || ((HttpDataSource.InvalidResponseCodeException) error).responseCode != 429) {
      return 0L;
    }
    Map<String, List<String>> headers =
        ((HttpDataSource.InvalidResponseCodeException) error).headerFields;
    for (Map.Entry<String, List<String>> entry : headers.entrySet()) {
      if (!"Retry-After".equalsIgnoreCase(entry.getKey()) || entry.getValue() == null) continue;
      for (String value : entry.getValue()) {
        if (value == null) continue;
        value = value.trim();
        if (value.matches("[0-9]+")) {
          try {
            long seconds = Long.parseLong(value);
            return seconds > Long.MAX_VALUE / 1000L ? Long.MAX_VALUE : seconds * 1000L;
          } catch (NumberFormatException ignored) {
            return Long.MAX_VALUE;
          }
        }
        SimpleDateFormat format =
            new SimpleDateFormat("EEE, dd MMM yyyy HH:mm:ss zzz", Locale.US);
        format.setTimeZone(TimeZone.getTimeZone("GMT"));
        format.setLenient(false);
        try {
          Date date = format.parse(value);
          if (date != null) return Math.max(0L, date.getTime() - nowMs);
        } catch (ParseException ignored) {
          // Invalid headers fall back to the progressive delay.
        }
      }
    }
    return 0L;
  }

  static final class OpenGate {
    private final long minGapMs;
    private long nextOpenMs;

    OpenGate(long minGapMs) {
      this.minGapMs = minGapMs;
    }

    synchronized void awaitOpen() throws InterruptedIOException {
      while (true) {
        if (Thread.currentThread().isInterrupted()) {
          throw new InterruptedIOException("Interrupted while waiting to open");
        }
        long now = TimeUnit.NANOSECONDS.toMillis(System.nanoTime());
        long remaining = nextOpenMs - now;
        if (remaining <= 0) {
          nextOpenMs = now + minGapMs;
          return;
        }
        try {
          wait(remaining);
        } catch (InterruptedException e) {
          Thread.currentThread().interrupt();
          throw new InterruptedIOException("Interrupted while waiting to open");
        }
      }
    }

    synchronized void defer(long delayMs) {
      long now = TimeUnit.NANOSECONDS.toMillis(System.nanoTime());
      nextOpenMs = Math.max(nextOpenMs, now + delayMs);
    }
  }

  @Override
  public Uri getUri() {
    return delegate.getUri();
  }

  @Nullable
  @Override
  public java.util.Map<String, java.util.List<String>> getResponseHeaders() {
    return delegate.getResponseHeaders();
  }

  @Override
  public int read(byte[] buffer, int offset, int length) throws IOException {
    int n = delegate.read(buffer, offset, length);
    if (n > 0) {
      bytesRead += n;
      // Un log par tranche de 1 Mo : assez pour voir si le flux avance,
      // assez rare pour ne pas noyer logcat (2,5 logs/s à 256 Ko aurait
      // saturé le buffer logcat sur une soirée de lecture).
      int bucket = (int) (bytesRead / (1024 * 1024));
      if (bucket != lastLoggedBucket) {
        lastLoggedBucket = bucket;
        Log.i(TAG, "  READ total=" + bytesRead + "B");
      }
    }
    return n;
  }

  @Override
  public void close() throws IOException {
    Log.i(TAG, "CLOSE totalRead=" + bytesRead + "B");
    delegate.close();
  }

  /**
   * Fabrique produisant des {@link LoggingDataSource} autour d'une source reelle.
   *
   * <p>Le rythme est partage statiquement : tous les controleurs de la page
   * passent par le meme intervalle minimal.
   */
  static final class Factory implements DataSource.Factory {
    private final DataSource.Factory delegate;

    Factory(DataSource.Factory delegate) {
      this.delegate = delegate;
    }

    @NonNull
    @Override
    public DataSource createDataSource() {
      return new LoggingDataSource(delegate.createDataSource());
    }
  }
}
