import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/github_update_service.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.response);
  final Future<ResponseBody> Function(RequestOptions) response;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      response(options);

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bytes = utf8.encode('apk test');
  final digest = sha256.convert(bytes).toString();
  Map<String, dynamic> release(String version) => {
        'tag_name': version,
        'body': 'Notes',
        'assets': [
          {
            'name': GithubUpdateService.assetName,
            'browser_download_url':
                'https://github.com/christopheblum67/Orbit-3d-flutter/releases/download/v1.1.0/orbit-3d-universal.apk',
            'size': bytes.length,
            'digest': 'sha256:$digest',
          },
        ],
      };

  test('compares semantic components and numeric build without downgrades', () {
    expect(GithubUpdateService.parseRelease(release('v1.0.0+1'), '1.0.0', 1),
        isNull);
    expect(GithubUpdateService.parseRelease(release('v1.0.0+2'), '1.0.0', 1),
        isNotNull);
    expect(GithubUpdateService.parseRelease(release('v1.0.0'), '1.0.0', 1),
        isNull);
    expect(GithubUpdateService.parseRelease(release('v1.0.9'), '1.0.10', 1),
        isNull);
    expect(GithubUpdateService.parseRelease(release('v1.1.0'), '1.0.10', 1),
        isNotNull);
    expect(
        () =>
            GithubUpdateService.parseRelease(release('v1.2-beta'), '1.0.0', 1),
        throwsA(isA<UpdateException>()));
  });

  test('rejects ambiguous, unsigned metadata and external download URLs', () {
    for (final asset in [
      {'name': 'split-arm64.apk'},
      {'name': GithubUpdateService.assetName, 'size': 1, 'digest': null},
      {
        'name': GithubUpdateService.assetName,
        'size': 1,
        'digest': 'sha256:$digest',
        'browser_download_url': 'https://evil.example/a.apk',
      },
    ]) {
      final data = release('v1.1.0')..['assets'] = [asset];
      expect(() => GithubUpdateService.parseRelease(data, '1.0.0', 1),
          throwsA(isA<UpdateException>()));
    }
    final duplicate = release('v1.1.0');
    final list = duplicate['assets'] as List;
    list.add(list.first);
    expect(() => GithubUpdateService.parseRelease(duplicate, '1.0.0', 1),
        throwsA(isA<UpdateException>()));
  });

  test('reports absence of a stable release rather than saying up to date',
      () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(GithubUpdateService.channel,
        (_) async => {'versionName': '1.0.0', 'versionCode': 1});
    addTearDown(() =>
        messenger.setMockMethodCallHandler(GithubUpdateService.channel, null));
    final dio = Dio()
      ..httpClientAdapter =
          _Adapter((_) async => ResponseBody.fromString('', 404));
    await expectLater(
      GithubUpdateService(dio: dio).check(),
      throwsA(
          isA<UpdateException>().having((e) => e.code, 'code', 'no_release')),
    );
  });

  test('passes the expected release to the Android installer', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(GithubUpdateService.channel,
        (call) async {
      expect(call.method, 'install');
      expect(call.arguments, {'version': 'v1.1.0'});
      return true;
    });
    addTearDown(() =>
        messenger.setMockMethodCallHandler(GithubUpdateService.channel, null));
    final info =
        GithubUpdateService.parseRelease(release('v1.1.0'), '1.0.0', 1)!;
    expect(await GithubUpdateService().install(info), isTrue);
  });

  test('downloads with integrity verification and refuses untrusted redirects',
      () async {
    final temp = await Directory.systemTemp.createTemp('orbit_update_test_');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => temp.path);
    addTearDown(() async {
      messenger.setMockMethodCallHandler(channel, null);
      await temp.delete(recursive: true);
    });
    final info =
        GithubUpdateService.parseRelease(release('v1.1.0'), '1.0.0', 1)!;
    final dio = Dio()
      ..httpClientAdapter = _Adapter((options) async {
        if (options.uri.host == 'github.com') {
          return ResponseBody.fromString('', 302, headers: {
            'location': ['https://release-assets.githubusercontent.com/file'],
          });
        }
        return ResponseBody.fromBytes(bytes, 200);
      });
    final progress = <double>[];
    await GithubUpdateService(dio: dio).download(info, progress.add);
    expect(progress.last, 1);
    expect(
        await File(
                '${temp.path}${Platform.pathSeparator}updates${Platform.pathSeparator}update.apk')
            .readAsBytes(),
        bytes);

    dio.httpClientAdapter =
        _Adapter((_) async => ResponseBody.fromString('', 302, headers: {
              'location': ['https://evil.example/file'],
            }));
    await expectLater(
        GithubUpdateService(dio: dio).download(info, (_) {}),
        throwsA(isA<UpdateException>()
            .having((e) => e.code, 'code', 'invalid_asset')));
    dio.httpClientAdapter = _Adapter(
        (_) async => ResponseBody.fromBytes(utf8.encode('bad data'), 200));
    await expectLater(
        GithubUpdateService(dio: dio).download(info, (_) {}),
        throwsA(
            isA<UpdateException>().having((e) => e.code, 'code', 'integrity')));
  });
}
