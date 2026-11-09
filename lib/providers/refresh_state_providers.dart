import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Horodatage de la dernière mise à jour des flux, persisté.
final lastRefreshTimestampProvider =
    NotifierProvider<LastRefreshTimestampNotifier, DateTime?>(
  LastRefreshTimestampNotifier.new,
);

final startupRefreshAttemptProvider =
    NotifierProvider<StartupRefreshAttemptNotifier, bool>(
  StartupRefreshAttemptNotifier.new,
);

class StartupRefreshAttemptNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markCompleted() => state = true;

  bool consume() {
    final attempted = state;
    state = false;
    return attempted;
  }
}

class LastRefreshTimestampNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  /// Met à jour l'horodatage affiché et le persiste sans bloquer l'affichage.
  void setTimestamp(DateTime? value, {String? subscriptionId}) {
    state = value;
    if (value == null) return;
    unawaited(persistLastRefresh(value, subscriptionId: subscriptionId));
  }

  void restoreTimestamp(DateTime? value) => state = value;
}

String _refreshTimestampKey(String? subscriptionId) => subscriptionId == null
    ? 'orbit_last_refresh'
    : 'orbit_last_refresh_${base64Url.encode(utf8.encode(subscriptionId))}';

Future<void> persistLastRefresh(
  DateTime timestamp, {
  String? subscriptionId,
}) async {
  final result = await safeAsync<void>(
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _refreshTimestampKey(subscriptionId),
        timestamp.toIso8601String(),
      );
    },
    context: 'persistLastRefresh',
  );
  return result.valueOrNull;
}

Future<DateTime?> loadLastRefresh({String? subscriptionId}) async {
  final result = await safeAsync<DateTime?>(
    () async {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_refreshTimestampKey(subscriptionId));
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    },
    context: 'loadLastRefresh',
  );
  return result.valueOrNull;
}
