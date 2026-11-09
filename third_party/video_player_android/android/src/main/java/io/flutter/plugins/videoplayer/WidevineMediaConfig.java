package io.flutter.plugins.videoplayer;

import android.net.Uri;
import androidx.annotation.NonNull;
import androidx.media3.common.C;
import androidx.media3.common.MediaItem;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

final class WidevineMediaConfig {
  @NonNull private final String licenseUrl;
  @NonNull private final Map<String, String> licenseHeaders;

  WidevineMediaConfig(
      @NonNull String licenseUrl, @NonNull Map<String, String> licenseHeaders) {
    Uri uri = Uri.parse(licenseUrl);
    if (!"https".equalsIgnoreCase(uri.getScheme())
        || uri.getHost() == null
        || uri.getHost().isEmpty()
        || uri.getUserInfo() != null) {
      throw new IllegalArgumentException("Widevine requires an HTTPS license URL");
    }
    this.licenseUrl = licenseUrl;
    this.licenseHeaders = Collections.unmodifiableMap(new HashMap<>(licenseHeaders));
  }

  @NonNull
  MediaItem.DrmConfiguration toMedia3Configuration() {
    return new MediaItem.DrmConfiguration.Builder(C.WIDEVINE_UUID)
        .setLicenseUri(licenseUrl)
        .setLicenseRequestHeaders(licenseHeaders)
        .build();
  }
}
