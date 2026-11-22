package io.flutter.plugins.videoplayer;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertSame;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.net.Uri;
import androidx.media3.datasource.DataSource;
import androidx.media3.datasource.DataSpec;
import androidx.media3.datasource.HttpDataSource;
import java.io.InterruptedIOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;

@RunWith(RobolectricTestRunner.class)
public final class LoggingDataSourceTest {
  private static final DataSpec SPEC = new DataSpec(Uri.parse("https://example.invalid/video"));

  private static HttpDataSource.InvalidResponseCodeException response(int code, String retryAfter) {
    return new HttpDataSource.InvalidResponseCodeException(
        code,
        null,
        null,
        retryAfter == null
            ? Collections.emptyMap()
            : Collections.singletonMap("retry-after", Collections.singletonList(retryAfter)),
        SPEC,
        new byte[0]);
  }

  @Test
  public void concurrentOpeningsReserveDistinctSlots() throws Exception {
    LoggingDataSource.OpenGate gate = new LoggingDataSource.OpenGate(60);
    ExecutorService pool = Executors.newFixedThreadPool(4);
    CountDownLatch start = new CountDownLatch(1);
    try {
      List<Future<Long>> futures = new ArrayList<>();
      for (int i = 0; i < 4; i++) {
        futures.add(pool.submit(() -> {
          start.await();
          gate.awaitOpen();
          return TimeUnit.NANOSECONDS.toMillis(System.nanoTime());
        }));
      }
      start.countDown();
      List<Long> openings = new ArrayList<>();
      for (Future<Long> future : futures) openings.add(future.get(3, TimeUnit.SECONDS));
      Collections.sort(openings);
      for (int i = 1; i < openings.size(); i++) {
        assertTrue(openings.get(i) - openings.get(i - 1) >= 55);
      }
    } finally {
      pool.shutdownNow();
    }
  }

  @Test
  public void longerCooldownIsNotShortenedAndWaitersRecheck() throws Exception {
    LoggingDataSource.OpenGate gate = new LoggingDataSource.OpenGate(0);
    gate.defer(80);
    ExecutorService pool = Executors.newSingleThreadExecutor();
    CountDownLatch started = new CountDownLatch(1);
    try {
      Future<Long> opening = pool.submit(() -> {
        started.countDown();
        gate.awaitOpen();
        return TimeUnit.NANOSECONDS.toMillis(System.nanoTime());
      });
      assertTrue(started.await(1, TimeUnit.SECONDS));
      long extendedAt = TimeUnit.NANOSECONDS.toMillis(System.nanoTime());
      gate.defer(180);
      gate.defer(10);
      assertTrue(opening.get(2, TimeUnit.SECONDS) - extendedAt >= 170);
    } finally {
      pool.shutdownNow();
    }
  }

  @Test
  public void interruptionCancelsGateWait() throws Exception {
    LoggingDataSource.OpenGate gate = new LoggingDataSource.OpenGate(0);
    gate.defer(5000);
    CountDownLatch started = new CountDownLatch(1);
    AtomicReference<Throwable> result = new AtomicReference<>();
    Thread waiter = new Thread(() -> {
      started.countDown();
      try {
        gate.awaitOpen();
        result.set(new AssertionError("wait should have been interrupted"));
      } catch (Throwable error) {
        result.set(error);
      }
    });
    waiter.start();
    assertTrue(started.await(1, TimeUnit.SECONDS));
    waiter.interrupt();
    waiter.join(1000);
    assertTrue(result.get() instanceof InterruptedIOException);
  }

  @Test
  public void retryAfterSupportsSecondsAndHttpDate() {
    assertEquals(5000, LoggingDataSource.retryAfterMs(response(429, "5"), 0));
    assertEquals(5000, LoggingDataSource.retryAfterMs(
        response(429, "Thu, 01 Jan 1970 00:00:10 GMT"), 5000));
    assertEquals(0, LoggingDataSource.retryAfterMs(response(429, "invalid"), 0));
    assertEquals(0, LoggingDataSource.retryAfterMs(response(403, "5"), 0));
    assertEquals(Long.MAX_VALUE,
        LoggingDataSource.retryAfterMs(response(429, "999999999999999999999"), 0));
  }

  @Test
  public void retries429AfterCooldown() throws Exception {
    DataSource delegate = mock(DataSource.class);
    when(delegate.open(SPEC)).thenThrow(response(429, "0")).thenReturn(123L);
    LoggingDataSource source =
        new LoggingDataSource(delegate, new LoggingDataSource.OpenGate(0), new long[] {80});
    long start = TimeUnit.NANOSECONDS.toMillis(System.nanoTime());
    assertEquals(123, source.open(SPEC));
    assertTrue(TimeUnit.NANOSECONDS.toMillis(System.nanoTime()) - start >= 70);
    verify(delegate, times(2)).open(SPEC);
    verify(delegate).close();
  }

  @Test
  public void respectsRetryAfterSecondsBeforeRetrying() throws Exception {
    DataSource delegate = mock(DataSource.class);
    when(delegate.open(SPEC)).thenThrow(response(429, "1")).thenReturn(123L);
    LoggingDataSource source =
        new LoggingDataSource(delegate, new LoggingDataSource.OpenGate(0), new long[] {1});
    long start = TimeUnit.NANOSECONDS.toMillis(System.nanoTime());
    assertEquals(123, source.open(SPEC));
    assertTrue(TimeUnit.NANOSECONDS.toMillis(System.nanoTime()) - start >= 990);
    verify(delegate, times(2)).open(SPEC);
  }

  @Test
  public void doesNotRetryOtherHttpErrors() throws Exception {
    DataSource delegate = mock(DataSource.class);
    HttpDataSource.InvalidResponseCodeException failure = response(500, "1");
    when(delegate.open(SPEC)).thenThrow(failure);
    LoggingDataSource source =
        new LoggingDataSource(delegate, new LoggingDataSource.OpenGate(0), new long[] {1});
    try {
      source.open(SPEC);
      fail("Expected the original exception");
    } catch (HttpDataSource.InvalidResponseCodeException actual) {
      assertSame(failure, actual);
    }
    verify(delegate, times(1)).open(SPEC);
  }

  @Test
  public void doesNotRetryEarlyWhenServerRequestsLongWait() throws Exception {
    DataSource delegate = mock(DataSource.class);
    HttpDataSource.InvalidResponseCodeException failure = response(429, "120");
    when(delegate.open(SPEC)).thenThrow(failure);
    LoggingDataSource source =
        new LoggingDataSource(delegate, new LoggingDataSource.OpenGate(0), new long[] {1});
    try {
      source.open(SPEC);
      fail("Expected the original exception");
    } catch (HttpDataSource.InvalidResponseCodeException actual) {
      assertSame(failure, actual);
    }
    verify(delegate, times(1)).open(SPEC);
  }
}
