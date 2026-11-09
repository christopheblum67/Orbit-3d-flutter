import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/utils/image_cache_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('limite le cache image sur Android sans modifier les autres plateformes', () {
    final cache = PaintingBinding.instance.imageCache;
    final originalSize = cache.maximumSize;
    final originalBytes = cache.maximumSizeBytes;
    addTearDown(() {
      cache.maximumSize = originalSize;
      cache.maximumSizeBytes = originalBytes;
    });

    configureOrbitImageCache(TargetPlatform.android);
    expect(cache.maximumSize, 100);
    expect(cache.maximumSizeBytes, 40 * 1024 * 1024);
    cache.maximumSize = 234;
    cache.maximumSizeBytes = 123456;
    configureOrbitImageCache(TargetPlatform.windows);
    expect(cache.maximumSize, 234);
    expect(cache.maximumSizeBytes, 123456);
  });
}
