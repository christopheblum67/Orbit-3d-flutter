import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';

class SettingsBackupService {
  static const String _appName = 'orbit';
  static const int _version = 1;

  Future<String> exportToJson({
    required AdvancedSettings advancedSettings,
    required UserPreferences userPreferences,
  }) async {
    final map = <String, dynamic>{
      'app': _appName,
      'version': _version,
      'exportedAt': DateTime.now().toIso8601String(),
      'advancedSettings': _advancedSettingsToJson(advancedSettings),
      'userPreferences': userPreferences.toMap(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  Map<String, dynamic> _advancedSettingsToJson(AdvancedSettings s) {
    return {
      'useTlsImpersonation': s.useTlsImpersonation,
      'dnsProvider': s.dnsProvider,
      'zeroLagPrefetch': s.zeroLagPrefetch,
      'playerLive': _playerConfigToJson(s.playerLive),
      'playerVod': _playerConfigToJson(s.playerVod),
      'playerSeries': _playerConfigToJson(s.playerSeries),
      'playerReplay': _playerConfigToJson(s.playerReplay),
      'nightFocusEnabled': s.nightFocusEnabled,
      'nightFocusDialogueBoost': s.nightFocusDialogueBoost,
      'nightFocusBassKiller': s.nightFocusBassKiller,
      'nightFocusVocalGainDb': s.nightFocusVocalGainDb,
      'nightFocusAudioShiftMs': s.nightFocusAudioShiftMs,
      'highContrast': s.highContrast,
    };
  }

  Map<String, dynamic> _playerConfigToJson(PlayerPerTypeConfig c) {
    return {
      'primary': c.primary.name,
      'fallback': c.fallback.name,
    };
  }

  Future<void> writeToFile(String json) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/orbit_settings_backup.json');
    await file.writeAsString(json);
  }

  Future<void> copyToClipboard(String json) async {
    await Clipboard.setData(ClipboardData(text: json));
  }

  Future<SettingsBackupResult> importFromJson(
    String json,
    AdvancedSettingsNotifier advancedNotifier,
    PreferencesNotifier preferencesNotifier,
  ) async {
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;

      if (map['app'] != _appName) {
        return SettingsBackupResult.failure('Fichier invalide : application non reconnue');
      }
      final version = map['version'] as int?;
      if (version == null || version > _version) {
        return SettingsBackupResult.failure('Version de backup non supportée ($version)');
      }

      final advJson = map['advancedSettings'] as Map<String, dynamic>?;
      final prefsJson = map['userPreferences'] as Map<String, dynamic>?;

      if (advJson != null) {
        final adv = _advancedSettingsFromJson(advJson);
        await advancedNotifier.importFromJson(adv);
      }
      if (prefsJson != null) {
        final prefs = UserPreferences.fromMap(prefsJson);
        await preferencesNotifier.importFromJson(prefs);
      }

      return SettingsBackupResult.success('Réglages importés avec succès');
    } on FormatException {
      return SettingsBackupResult.failure('JSON invalide');
    } catch (e) {
      return SettingsBackupResult.failure('Erreur lors de l\'import: $e');
    }
  }

  AdvancedSettings _advancedSettingsFromJson(Map<String, dynamic> map) {
    return AdvancedSettings(
      useTlsImpersonation: map['useTlsImpersonation'] ?? true,
      dnsProvider: map['dnsProvider'] ?? '1.1.1.1 (Cloudflare DoH)',
      zeroLagPrefetch: map['zeroLagPrefetch'] ?? true,
      playerLive: _playerConfigFromJson(map['playerLive']),
      playerVod: _playerConfigFromJson(map['playerVod']),
      playerSeries: _playerConfigFromJson(map['playerSeries']),
      playerReplay: _playerConfigFromJson(map['playerReplay']),
      nightFocusEnabled: map['nightFocusEnabled'] ?? false,
      nightFocusDialogueBoost: map['nightFocusDialogueBoost'] ?? true,
      nightFocusBassKiller: map['nightFocusBassKiller'] ?? true,
      nightFocusVocalGainDb: (map['nightFocusVocalGainDb'] as num?)?.toDouble() ?? 3.0,
      nightFocusAudioShiftMs: map['nightFocusAudioShiftMs'] ?? 0,
      highContrast: map['highContrast'] ?? false,
    );
  }

  PlayerPerTypeConfig _playerConfigFromJson(Map<String, dynamic>? map) {
    if (map == null) {
      return const PlayerPerTypeConfig();
    }
    return PlayerPerTypeConfig(
      primary: PlayerEngine.values.firstWhere(
        (e) => e.name == map['primary'],
        orElse: () => PlayerEngine.exoPlayer,
      ),
      fallback: PlayerEngine.values.firstWhere(
        (e) => e.name == map['fallback'],
        orElse: () => PlayerEngine.vlc,
      ),
    );
  }
}

class SettingsBackupResult {
  final bool success;
  final String message;

  const SettingsBackupResult._(this.success, this.message);

  factory SettingsBackupResult.success(String message) =>
      SettingsBackupResult._(true, message);

  factory SettingsBackupResult.failure(String message) =>
      SettingsBackupResult._(false, message);
}