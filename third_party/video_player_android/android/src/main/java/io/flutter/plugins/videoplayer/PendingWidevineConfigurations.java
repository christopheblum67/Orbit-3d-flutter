package io.flutter.plugins.videoplayer;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import java.util.HashMap;
import java.util.Map;

final class PendingWidevineConfigurations {
  static final String TOKEN_HEADER = "X-Orbit-Widevine-Token";
  private final Map<String, WidevineMediaConfig> pending = new HashMap<>();

  void register(@NonNull String token, @NonNull WidevineMediaConfig config) {
    if (token.isEmpty() || pending.containsKey(token)) {
      throw new IllegalArgumentException("Invalid or duplicate Widevine token");
    }
    pending.put(token, config);
  }

  @Nullable
  WidevineMediaConfig take(@NonNull Map<String, String> headers) {
    String token = headers.remove(TOKEN_HEADER);
    if (token == null) return null;
    WidevineMediaConfig config = pending.remove(token);
    if (config == null) {
      throw new IllegalStateException("Widevine configuration is no longer available");
    }
    return config;
  }

  void discard(@NonNull String token) {
    pending.remove(token);
  }

  void clear() {
    pending.clear();
  }
}
