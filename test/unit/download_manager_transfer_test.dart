import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/models/download.dart';
import 'package:orbit_3d_flutter/models/duration_adapter.dart';
import 'package:orbit_3d_flutter/services/download_manager.dart';
import 'package:path/path.dart' as path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late DownloadManager manager;
  HttpServer? server;

  setUpAll(() {
    Hive.registerAdapter(DownloadStatusAdapter());
    Hive.registerAdapter(DownloadProgressAdapter());
    Hive.registerAdapter(DownloadTaskAdapter());
    Hive.registerAdapter(DurationAdapter());
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('orbit_download_test_');
    Hive.init(directory.path);
    manager = DownloadManager();
    await manager.init();
    await manager.setConfig(DownloadManagerConfig(
      maxConcurrentDownloads: 1,
      downloadDirectory: directory.path,
    ));
  });

  tearDown(() async {
    for (final task in manager.currentTasks) {
      if (task.isActive || task.status == DownloadStatus.paused) {
        await manager.cancel(task.id);
      }
    }
    await server?.close(force: true);
    server = null;
    await Hive.close();
    await directory.delete(recursive: true);
  });

  for (final mode in [
    'range',
    'range ignoré',
    'sans validateur',
    'range 416'
  ]) {
    test('pause et reprise : $mode', () async {
      final supportsRange = mode == 'range';
      final hasValidator = mode != 'sans validateur';
      final bytes = List<int>.generate(262144, (i) => i % 251);
      final firstPartSent = Completer<void>();
      final releaseFirst = Completer<void>();
      final ranges = <String?>[];
      final ifRanges = <String?>[];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server!.listen((request) async {
        final range = request.headers.value(HttpHeaders.rangeHeader);
        ranges.add(range);
        ifRanges.add(request.headers.value(HttpHeaders.ifRangeHeader));
        if (hasValidator) {
          request.response.headers.set(HttpHeaders.etagHeader, '"version-1"');
        }
        if (ranges.length == 1) {
          request.response.contentLength = bytes.length;
          request.response.add(bytes.sublist(0, bytes.length ~/ 2));
          await request.response.flush();
          firstPartSent.complete();
          await releaseFirst.future;
          try {
            await request.response.close();
          } on SocketException {
            // Le client a fermé la connexion pour la pause.
          } on HttpException {
            // La réponse initiale est volontairement interrompue.
          }
        } else if (mode == 'range 416' && ranges.length == 2) {
          request.response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
          await request.response.close();
        } else {
          final start = supportsRange && range != null
              ? int.parse(RegExp(r'bytes=(\d+)-').firstMatch(range)![1]!)
              : 0;
          if (start > 0) {
            request.response.statusCode = HttpStatus.partialContent;
            request.response.headers.set(
              HttpHeaders.contentRangeHeader,
              'bytes $start-${bytes.length - 1}/${bytes.length}',
            );
          }
          request.response.contentLength = bytes.length - start;
          request.response.add(bytes.sublist(start));
          await request.response.close();
        }
      });

      final task = await manager.createTask(
        mediaItemId: 'film',
        title: 'Film',
        streamUrl: 'http://127.0.0.1:${server!.port}/film',
        contentType: 'vod',
      );
      await firstPartSent.future.timeout(const Duration(seconds: 5));
      await _waitUntil(() => task.progress.bytesDownloaded > 0,
          details: () =>
              'première progression: ${task.status} ${task.errorMessage} '
              '${task.localPath} ${task.isFileExists ? task.localFileSize : -1}');
      await manager.pause(task.id).timeout(const Duration(seconds: 5));
      expect(task.status, DownloadStatus.paused);
      expect(manager.activeCount, 0);
      final partialLength = await File(task.localPath).length();
      expect(partialLength, greaterThan(0));
      expect(partialLength, lessThan(bytes.length));
      releaseFirst.complete();

      await manager.resume(task.id);
      await _waitUntil(() => task.status == DownloadStatus.completed,
          details: () => 'reprise: ${task.status} ${task.errorMessage}');
      expect(ranges[1], hasValidator ? 'bytes=$partialLength-' : isNull);
      expect(ifRanges[1], hasValidator ? '"version-1"' : isNull);
      if (mode == 'range 416') expect(ranges.last, isNull);
      expect(await File(task.localPath).readAsBytes(), bytes);
      expect(manager.activeCount, 0);
    });
  }

  test('un échec libère le créneau et démarre la tâche en attente', () async {
    final releaseFailure = Completer<void>();
    final firstRequest = Completer<void>();
    var failing = true;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server!.listen((request) async {
      if (request.uri.path == '/fail' && failing) {
        firstRequest.complete();
        await releaseFailure.future;
        request.response.statusCode = HttpStatus.internalServerError;
      } else {
        request.response.add(List<int>.filled(64, 42));
      }
      await request.response.close();
    });
    final first = await manager.createTask(
      mediaItemId: '1',
      title: 'Erreur',
      streamUrl: 'http://127.0.0.1:${server!.port}/fail',
      contentType: 'vod',
    );
    await firstRequest.future.timeout(const Duration(seconds: 5));
    final second = await manager.createTask(
      mediaItemId: '2',
      title: 'Suivant',
      streamUrl: 'http://127.0.0.1:${server!.port}/ok',
      contentType: 'vod',
    );
    expect(second.status, DownloadStatus.queued);
    expect(manager.activeCount, 1);
    releaseFailure.complete();
    await _waitUntil(() => second.status == DownloadStatus.completed);
    expect(first.status, DownloadStatus.failed);
    expect(first.errorMessage, contains('HTTP 500'));
    expect(manager.activeCount, 0);
    failing = false;
    await manager.retry(first.id);
    await _waitUntil(() => first.status == DownloadStatus.completed);
    expect(first.errorMessage, isNull);
    expect(manager.activeCount, 0);
  });

  test('un certificat HTTPS autosigné est refusé', () async {
    final context = SecurityContext()
      ..useCertificateChain(
          path.join('test', 'fixtures', 'download_tls', 'test-only-cert.pem'))
      ..usePrivateKey(
          path.join('test', 'fixtures', 'download_tls', 'test-only-key.pem'));
    server =
        await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, context);
    server!.listen((request) async {
      request.response.write('unexpected');
      await request.response.close();
    }, onError: (Object _) {});
    final task = await manager.createTask(
      mediaItemId: 'tls',
      title: 'TLS',
      streamUrl: 'https://localhost:${server!.port}/film',
      contentType: 'vod',
    );
    await _waitUntil(() => task.status == DownloadStatus.failed);
    expect(task.errorMessage, contains('CERTIFICATE_VERIFY_FAILED'));
    expect(manager.activeCount, 0);
  });

  test('supprimer un transfert actif libère le créneau et son fichier',
      () async {
    final firstSent = Completer<void>();
    final releaseFirst = Completer<void>();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server!.listen((request) async {
      if (request.uri.path == '/slow') {
        request.response.contentLength = 262144;
        request.response.add(List<int>.filled(131072, 42));
        await request.response.flush();
        firstSent.complete();
        await releaseFirst.future;
        try {
          await request.response.close();
        } on SocketException {
          // La suppression a fermé la connexion.
        } on HttpException {
          // La réponse initiale est volontairement interrompue.
        }
      } else {
        request.response.write('contenu');
        await request.response.close();
      }
    });
    final first = await manager.createTask(
      mediaItemId: 'slow',
      title: 'En cours',
      streamUrl: 'http://127.0.0.1:${server!.port}/slow',
      contentType: 'vod',
    );
    await firstSent.future.timeout(const Duration(seconds: 5));
    await _waitUntil(() => first.progress.bytesDownloaded > 0);
    final localPath = first.localPath;
    final second = await manager.createTask(
      mediaItemId: 'next',
      title: 'Suivant',
      streamUrl: 'http://127.0.0.1:${server!.port}/next',
      contentType: 'vod',
    );
    expect(second.status, DownloadStatus.queued);
    await manager.delete(first.id).timeout(const Duration(seconds: 5));
    releaseFirst.complete();
    await _waitUntil(() => second.status == DownloadStatus.completed);
    expect(manager.getTask(first.id), isNull);
    expect(await File(localPath).exists(), isFalse);
    expect(manager.activeCount, 0);
  });

  test('une playlist courte est refusée sans laisser de fichier partiel',
      () async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server!.listen((request) async {
      request.response.headers.set(HttpHeaders.etagHeader, '"playlist"');
      request.response.write('#EXTM3U');
      await request.response.close();
    });
    final task = await manager.createTask(
      mediaItemId: 'playlist',
      title: 'Playlist',
      streamUrl: 'http://127.0.0.1:${server!.port}/playlist',
      contentType: 'vod',
    );
    await _waitUntil(() => task.status == DownloadStatus.failed);
    expect(task.errorMessage, contains('HLS/DASH'));
    expect(await File(task.localPath).exists(), isFalse);
    expect(task.downloadValidator, isNull);
    expect(manager.activeCount, 0);
  });

  test('les tâches en attente sont relancées après réouverture', () async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server!.listen((request) async {
      request.response.write('contenu');
      await request.response.close();
    });
    final box = Hive.box<DownloadTask>('downloads');
    await box.put(
      'queued',
      DownloadTask(
        id: 'queued',
        mediaItemId: 'queued',
        title: 'En attente',
        streamUrl: 'http://127.0.0.1:${server!.port}/queued',
        contentType: 'vod',
        createdAt: DateTime.now(),
      ),
    );
    await box.close();
    await manager.init();
    await _waitUntil(
      () => manager.getTask('queued')?.status == DownloadStatus.completed,
    );
    expect(manager.activeCount, 0);
  });

  test('une réponse Range incohérente ne corrompt pas le fichier', () async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server!.listen((request) async {
      request.response.statusCode = HttpStatus.partialContent;
      request.response.headers.set(HttpHeaders.etagHeader, '"version-1"');
      request.response.headers
          .set(HttpHeaders.contentRangeHeader, 'bytes 0-3/4');
      request.response.add([4, 3, 2, 1]);
      await request.response.close();
    });
    final file = File(path.join(directory.path, 'partial.mp4'));
    await file.writeAsBytes([1, 2, 3]);
    final task = DownloadTask(
      id: 'partial',
      mediaItemId: 'partial',
      title: 'Partiel',
      streamUrl: 'http://127.0.0.1:${server!.port}/partial',
      contentType: 'vod',
      createdAt: DateTime.now(),
      localPath: file.path,
      status: DownloadStatus.paused,
      downloadValidator: '"version-1"',
    );
    await Hive.box<DownloadTask>('downloads').put(task.id, task);
    await manager.resume(task.id);
    await _waitUntil(() => task.status == DownloadStatus.failed);
    expect(task.errorMessage, contains('Range invalide'));
    expect(await file.readAsBytes(), [1, 2, 3]);
    expect(manager.activeCount, 0);
  });

  test('une pause immédiate puis reprise ne perd pas la tâche', () async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server!.listen((request) async {
      request.response.write('contenu');
      await request.response.close();
    });
    final task = await manager.createTask(
      mediaItemId: 'immediate',
      title: 'Immédiat',
      streamUrl: 'http://127.0.0.1:${server!.port}/immediate',
      contentType: 'vod',
    );
    final paused = manager.pause(task.id);
    await manager.resume(task.id);
    await paused.timeout(const Duration(seconds: 5));
    await _waitUntil(() => task.status == DownloadStatus.completed);
    expect(await File(task.localPath).readAsString(), 'contenu');
    expect(manager.activeCount, 0);
  });
}

Future<void> _waitUntil(bool Function() condition,
    {String Function()? details}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 8));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException(
        'Le téléchargement n’a pas atteint l’état attendu: ${details?.call()}',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
