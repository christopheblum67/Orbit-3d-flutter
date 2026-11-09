import 'dart:io';

import 'package:orbit_3d_flutter/services/video_disk_cache.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Une instance partagée garantit un seul quota et une seule file d'écriture.
class VideoCacheManager {
  VideoCacheManager._();

  static Future<VideoDiskCache>? _pending;

  static Future<VideoDiskCache> get instance => _pending ??= _create();

  static Future<VideoDiskCache> _create() async {
    try {
      final directory = await getTemporaryDirectory();
      final cache = VideoDiskCache(
          Directory(p.join(directory.path, 'orbit_video_cache')));
      await cache.initialize(discardExisting: true);
      return cache;
    } catch (_) {
      _pending = null;
      rethrow;
    }
  }
}
