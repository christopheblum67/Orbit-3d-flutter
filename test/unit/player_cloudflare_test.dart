import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/player_cloudflare.dart';
import 'package:orbit_3d_flutter/services/cloudflare_session_manager.dart';

class _Session implements CloudflareSessionManager {
  @override
  bool isReady = false;
  @override
  bool isChallenging = false;
  @override
  String baseUrl = '';
  final calls = <String>[];
  Completer<void>? gate;
  bool fail = false;
  int headerReads = 0;
  Map<String, String> headers = {'X-Test': 'session'};

  @override
  Future<void> initialize({required String baseUrl}) async {
    calls.add(baseUrl);
    await gate?.future;
    if (fail) throw StateError('unavailable');
    this.baseUrl = baseUrl;
    isReady = true;
  }

  @override
  Map<String, String> getFreshHeaders() {
    headerReads++;
    return Map.of(headers);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final origin = Uri(scheme: 'https', host: 'provider.test').origin;
  final target = Uri.parse(origin).replace(path: '/video').toString();

  test('non-secret session headers leave ordinary DASH available', () {
    final ordinaryHeaders = {
      'User-Agent': 'browser',
      'Referer': origin,
      'Accept': '*/*',
      'Accept-Language': 'fr',
      'Sec-CH-UA': 'browser',
      'Sec-CH-UA-Mobile': '?1',
      'Sec-CH-UA-Platform': 'device',
      'Sec-Fetch-Dest': 'video',
      'Sec-Fetch-Mode': 'playback',
      'Sec-Fetch-Site': 'cross-site',
    };
    bool protected(Map<String, String> headers,
            {Map<String, String>? supplied, bool local = false}) =>
        needsProtectedPlaybackProxy(
          isLocalFile: local,
          suppliedHeaders: supplied,
          sessionHeaders: headers,
        );
    final session = _Session()
      ..isReady = true
      ..baseUrl = origin
      ..headers = ordinaryHeaders;
    final resolved = playerCloudflareHeaders(
      session: session,
      isLocalFile: false,
      panelUrl: origin,
      playbackUrl: target,
    );
    expect(protected(resolved), isFalse);
    expect(
      protectedPlaybackRoute(
        needsProtection: protected(ordinaryHeaders),
        target: Uri.parse(origin).replace(path: '/video.mpd'),
      ),
      ProtectedPlaybackRoute.direct,
    );
    expect(protected({...ordinaryHeaders, 'cOoKiE': 'private'}), isTrue);
    expect(protected({...ordinaryHeaders, 'X-Unknown': 'private'}), isTrue);
    expect(
        protected(ordinaryHeaders, supplied: {'User-Agent': 'custom'}), isTrue);
    expect(protected(ordinaryHeaders, supplied: {'Authorization': 'private'}),
        isTrue);
    expect(
        protected(ordinaryHeaders,
            supplied: {'X-Data': 'private'}, local: true),
        isFalse);
  });

  test('protected headers require the inspectable proxy or fail closed', () {
    expect(
      protectedPlaybackRoute(
        needsProtection: true,
        target: Uri.parse(target),
      ),
      ProtectedPlaybackRoute.proxy,
    );
    expect(
      protectedPlaybackRoute(
        needsProtection: true,
        target: Uri.parse(origin).replace(path: '/video.mpd'),
      ),
      ProtectedPlaybackRoute.unsupported,
    );
    expect(
      protectedPlaybackRoute(
        needsProtection: true,
        target: Uri(scheme: 'http', host: '127.0.0.1', port: 8787),
      ),
      ProtectedPlaybackRoute.unsupported,
    );
    expect(
      protectedPlaybackRoute(
        needsProtection: false,
        target: Uri.parse(origin).replace(path: '/video.mpd'),
      ),
      ProtectedPlaybackRoute.direct,
    );
  });

  test('awaits preparation, reuses only the matching ready session', () async {
    final session = _Session()..gate = Completer<void>();
    var completed = false;
    final pending = preparePlayerCloudflare(
      session: session,
      isLocalFile: false,
      isXtream: true,
      panelUrl: '$origin/path',
    ).then((_) => completed = true);
    expect(session.calls, [origin]);
    expect(completed, isFalse);
    session.gate!.complete();
    await pending;
    expect(completed, isTrue);
    await preparePlayerCloudflare(
      session: session,
      isLocalFile: false,
      isXtream: true,
      panelUrl: origin,
    );
    expect(session.calls, hasLength(1));
    session.baseUrl = Uri(scheme: 'https', host: 'other.test').origin;
    await preparePlayerCloudflare(
      session: session,
      isLocalFile: false,
      isXtream: true,
      panelUrl: origin,
    );
    expect(session.calls, hasLength(2));
  });

  test('local, non-Xtream and invalid providers do not start a challenge',
      () async {
    final session = _Session();
    final issues = <PlayerCloudflareIssue>[];
    for (final args in [
      (local: true, xtream: true, panel: origin),
      (local: false, xtream: false, panel: origin),
      (local: false, xtream: true, panel: 'invalid'),
    ]) {
      await preparePlayerCloudflare(
        session: session,
        isLocalFile: args.local,
        isXtream: args.xtream,
        panelUrl: args.panel,
        onIssue: issues.add,
      );
    }
    expect(session.calls, isEmpty);
    expect(issues, [PlayerCloudflareIssue.invalidOrigin]);
    session.fail = true;
    issues.clear();
    await preparePlayerCloudflare(
      session: session,
      isLocalFile: false,
      isXtream: true,
      panelUrl: origin,
      onIssue: issues.add,
    );
    expect(session.isReady, isFalse);
    expect(issues, [PlayerCloudflareIssue.failed]);
  });

  test('preparation has a bounded wait and shares pending attempts', () async {
    final session = _Session()..gate = Completer<void>();
    final issues = <PlayerCloudflareIssue>[];
    Future<void> prepare(String panel) => preparePlayerCloudflare(
          session: session,
          isLocalFile: false,
          isXtream: true,
          panelUrl: panel,
          waitBudget: const Duration(milliseconds: 10),
          onIssue: issues.add,
        );

    await prepare(origin);
    await prepare(origin);
    expect(session.calls, hasLength(1));
    expect(issues, [
      PlayerCloudflareIssue.timedOut,
      PlayerCloudflareIssue.timedOut,
    ]);
    await prepare(Uri(scheme: 'https', host: 'other.test').origin);
    expect(issues.last, PlayerCloudflareIssue.busy);
    expect(session.calls, hasLength(1));
    session.gate!.complete();
    await Future<void>.delayed(Duration.zero);
    expect(session.isReady, isTrue);
  });

  test('a different provider challenge is not queued', () async {
    final session = _Session()
      ..isChallenging = true
      ..baseUrl = Uri(scheme: 'https', host: 'other.test').origin;
    final issues = <PlayerCloudflareIssue>[];
    await preparePlayerCloudflare(
      session: session,
      isLocalFile: false,
      isXtream: true,
      panelUrl: origin,
      onIssue: issues.add,
    );
    expect(session.calls, isEmpty);
    expect(issues, [PlayerCloudflareIssue.busy]);
  });

  test('a failure after the wait is still reported without error details',
      () async {
    final session = _Session()
      ..gate = Completer<void>()
      ..fail = true;
    final issues = <PlayerCloudflareIssue>[];
    await preparePlayerCloudflare(
      session: session,
      isLocalFile: false,
      isXtream: true,
      panelUrl: origin,
      waitBudget: const Duration(milliseconds: 10),
      onIssue: issues.add,
    );
    session.gate!.complete();
    await Future<void>.delayed(Duration.zero);
    expect(issues, [
      PlayerCloudflareIssue.timedOut,
      PlayerCloudflareIssue.failed,
    ]);
  });

  test('session headers are only supplied to the matching origin', () {
    final session = _Session()
      ..isReady = true
      ..baseUrl = origin;
    Map<String, String> headers(String url, {bool local = false}) =>
        playerCloudflareHeaders(
          session: session,
          isLocalFile: local,
          panelUrl: origin,
          playbackUrl: url,
        );
    expect(headers(target), {'X-Test': 'session'});
    expect(headers(target, local: true), isEmpty);
    expect(
        headers(Uri(scheme: 'https', host: 'other.test').toString()), isEmpty);
    expect(headers(Uri(scheme: 'http', host: 'provider.test').toString()),
        isEmpty);
    expect(
        headers(
            Uri(scheme: 'https', host: 'provider.test', port: 444).toString()),
        isEmpty);
    expect(
      headers(
          Uri(scheme: 'https', host: 'provider.test.other.test').toString()),
      isEmpty,
    );
    expect(
      headers(Uri(scheme: 'https', userInfo: 'user', host: 'provider.test')
          .toString()),
      isEmpty,
    );
    session.baseUrl = Uri(scheme: 'https', host: 'other.test').origin;
    expect(headers(target), isEmpty);
    session
      ..baseUrl = origin
      ..isReady = false;
    expect(headers(target), isEmpty);
    expect(session.headerReads, 1);
  });
}
