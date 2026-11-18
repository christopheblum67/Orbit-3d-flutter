import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';

const _externalPlayerChannel = MethodChannel('orbit/external_player');
final _externalResults = StreamController<ExternalPlaybackResult>.broadcast();
int _nextSession = 0;

class ExternalPlaybackResult {
  const ExternalPlaybackResult({
    required this.session,
    required this.completed,
  });

  final int session;
  final bool completed;
}

int newExternalPlaybackSession() => ++_nextSession;

Stream<ExternalPlaybackResult> get externalPlaybackResults {
  _externalPlayerChannel.setMethodCallHandler((call) async {
    if (call.method != 'playbackFinished') return;
    final args = call.arguments;
    if (args is! Map || args['session'] is! int || args['completed'] is! bool) {
      return;
    }
    _externalResults.add(
      ExternalPlaybackResult(
        session: args['session'] as int,
        completed: args['completed'] as bool,
      ),
    );
  });
  return _externalResults.stream;
}

Future<bool> launchExternalPlayback({
  required PlayerEngine engine,
  required String url,
  int? session,
}) async {
  if (!engine.isExternal) return false;
  final result = await safeAsync<bool>(
    () async {
      if (defaultTargetPlatform != TargetPlatform.android) return false;
      return await _externalPlayerChannel.invokeMethod<bool>('open', {
            'url': url,
            'engine': engine.name,
            if (session != null) 'session': session,
          }) ??
          false;
    },
    context: 'PlayerScreen.launchExternal',
    fallbackValue: false,
  );
  return result.valueOrNull ?? false;
}

Uri? providerVerificationUri(String? baseUrl) {
  final providerUri = baseUrl == null ? null : Uri.tryParse(baseUrl);
  if (providerUri == null ||
      providerUri.host.isEmpty ||
      (providerUri.scheme != 'http' && providerUri.scheme != 'https')) {
    return null;
  }
  return Uri(
    scheme: providerUri.scheme,
    host: providerUri.host,
    port: providerUri.hasPort ? providerUri.port : null,
  );
}
