import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';

Future<bool> launchExternalPlayback({
  required PlayerEngine engine,
  required String url,
}) async {
  if (!engine.isExternal) return false;
  final result = await safeAsync<bool>(
    () async {
      if (defaultTargetPlatform != TargetPlatform.android) return false;
      return await const MethodChannel('orbit/external_player')
              .invokeMethod<bool>('open', {
            'url': url,
            'engine': engine.name,
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
