import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/services/playback_progress_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_progress_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  test('sauvegarde et relit la progression d\'un média', () async {
    final service = PlaybackProgressService();
    await service.init();

    expect(service.get('movie-1'), isNull);

    await service.save('movie-1', 45000, 600000);
    final progress = service.get('movie-1');
    expect(progress, isNotNull);
    expect(progress!.positionMs, 45000);
    expect(progress.durationMs, 600000);
    expect(progress.hasProgress, isTrue);
  });

  test('hasProgress est faux pour une lecture terminée', () async {
    final service = PlaybackProgressService();
    await service.init();

    await service.save('movie-1', 590000, 600000);
    expect(service.get('movie-1')!.hasProgress, isTrue);

    await service.save('movie-2', 620000, 600000);
    expect(service.get('movie-2')!.hasProgress, isFalse);
  });

  test('clear efface la progression', () async {
    final service = PlaybackProgressService();
    await service.init();

    await service.save('movie-1', 10000, 600000);
    expect(service.get('movie-1'), isNotNull);

    await service.clear('movie-1');
    expect(service.get('movie-1'), isNull);
  });

  test('fraction borne la progression entre 0 et 1', () async {
    final service = PlaybackProgressService();
    await service.init();

    await service.save('movie-1', 150000, 600000);
    expect(service.get('movie-1')!.fraction, closeTo(0.25, 0.001));

    await service.save('movie-2', 900000, 600000);
    expect(service.get('movie-2')!.fraction, 1.0);
  });
}
