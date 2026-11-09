package io.flutter.plugins.videoplayer;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertSame;
import static org.junit.Assert.assertThrows;

import java.util.HashMap;
import java.util.Map;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;

@RunWith(RobolectricTestRunner.class)
public class PendingWidevineConfigurationsTest {
  @Test
  public void concurrentPlayersConsumeOnlyTheirOwnConfiguration() {
    PendingWidevineConfigurations registry = new PendingWidevineConfigurations();
    WidevineMediaConfig first = new WidevineMediaConfig("https://first.example", new HashMap<>());
    WidevineMediaConfig second = new WidevineMediaConfig("https://second.example", new HashMap<>());
    registry.register("first", first);
    registry.register("second", second);
    Map<String, String> clearHeaders = new HashMap<>();
    assertNull(registry.take(clearHeaders));

    Map<String, String> headers = new HashMap<>();
    headers.put("User-Agent", "test");
    headers.put(PendingWidevineConfigurations.TOKEN_HEADER, "second");
    assertSame(second, registry.take(headers));
    assertEquals(1, headers.size());
    assertEquals("test", headers.get("User-Agent"));

    headers.put(PendingWidevineConfigurations.TOKEN_HEADER, "first");
    assertSame(first, registry.take(headers));
    headers.put(PendingWidevineConfigurations.TOKEN_HEADER, "first");
    assertThrows(IllegalStateException.class, () -> registry.take(headers));
  }

  @Test
  public void duplicateTokensAndDiscardedConfigurationsCannotBeUsed() {
    PendingWidevineConfigurations registry = new PendingWidevineConfigurations();
    WidevineMediaConfig config = new WidevineMediaConfig("https://license.example", new HashMap<>());
    registry.register("token", config);
    assertThrows(IllegalArgumentException.class, () -> registry.register("token", config));
    registry.discard("token");
    Map<String, String> headers = new HashMap<>();
    headers.put(PendingWidevineConfigurations.TOKEN_HEADER, "token");
    assertThrows(IllegalStateException.class, () -> registry.take(headers));
    assertNull(headers.get(PendingWidevineConfigurations.TOKEN_HEADER));
  }
}
