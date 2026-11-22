import 'dart:async';

import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/features/player/external_playback.dart';
import 'package:orbit_3d_flutter/services/cloudflare_session_manager.dart';
import 'package:orbit_3d_flutter/services/stream_relay.dart';

export 'playback_header_policy.dart';

enum PlayerCloudflareIssue { failed, timedOut, busy, invalidOrigin }

enum ProtectedPlaybackRoute { direct, proxy, unsupported }

ProtectedPlaybackRoute protectedPlaybackRoute({
  required bool needsProtection,
  required Uri target,
}) {
  if (!needsProtection) return ProtectedPlaybackRoute.direct;
  if (target.path.toLowerCase().endsWith('.mpd') ||
      (target.host == kRustProxyHost && target.port == kRustProxyPort)) {
    return ProtectedPlaybackRoute.unsupported;
  }
  return ProtectedPlaybackRoute.proxy;
}

class _PendingPreparation {
  _PendingPreparation(this.origin);

  final String origin;
  late Future<void> future;
}

final _pendingPreparations = Expando<_PendingPreparation>();

void _reportIssue(PlayerCloudflareIssue issue) {
  LoggerService.instance
      .warning('Cloudflare playback preparation: ${issue.name}');
}

/// Prepare the active Xtream provider before starting network playback.
Future<void> preparePlayerCloudflare({
  required CloudflareSessionManager session,
  required bool isLocalFile,
  required bool isXtream,
  required String? panelUrl,
  Duration waitBudget = const Duration(seconds: 3),
  void Function(PlayerCloudflareIssue)? onIssue,
}) async {
  if (isLocalFile || !isXtream) return;
  final report = onIssue ?? _reportIssue;
  final origin = providerVerificationUri(panelUrl);
  if (origin == null) {
    report(PlayerCloudflareIssue.invalidOrigin);
    return;
  }
  if (session.isReady && session.baseUrl == origin.origin) return;
  var pending = _pendingPreparations[session];
  if ((pending != null && pending.origin != origin.origin) ||
      (pending == null &&
          session.isChallenging &&
          session.baseUrl != origin.origin)) {
    report(PlayerCloudflareIssue.busy);
    return;
  }
  if (pending == null) {
    pending = _PendingPreparation(origin.origin);
    _pendingPreparations[session] = pending;
    final current = pending;
    Future<void> runPreparation() async {
      try {
        await session.initialize(baseUrl: current.origin);
      } catch (_) {
        report(PlayerCloudflareIssue.failed);
      } finally {
        if (identical(_pendingPreparations[session], current)) {
          _pendingPreparations[session] = null;
        }
      }
    }

    current.future = runPreparation();
  }
  await pending.future.timeout(
    waitBudget,
    onTimeout: () => report(PlayerCloudflareIssue.timedOut),
  );
}

/// Restrict session headers to the provider origin that created them.
Map<String, String> playerCloudflareHeaders({
  required CloudflareSessionManager session,
  required bool isLocalFile,
  required String? panelUrl,
  required String playbackUrl,
}) {
  if (isLocalFile || !session.isReady) return const {};
  final origin = providerVerificationUri(panelUrl);
  final target = Uri.tryParse(playbackUrl);
  if (origin == null ||
      target == null ||
      !target.hasAuthority ||
      target.userInfo.isNotEmpty ||
      (target.scheme != 'http' && target.scheme != 'https') ||
      target.origin != origin.origin ||
      session.baseUrl != origin.origin) {
    return const {};
  }
  return session.getFreshHeaders();
}
