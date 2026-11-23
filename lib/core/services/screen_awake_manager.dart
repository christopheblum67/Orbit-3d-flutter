import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';

class ScreenAwakeManager {
  ScreenAwakeManager({Future<bool> Function(bool)? setScreenOn})
      : _setScreenOn = setScreenOn ?? _setAndroidScreenOn;

  static final instance = ScreenAwakeManager();
  static const _channel = MethodChannel('orbit/hardware');
  final Future<bool> Function(bool) _setScreenOn;
  final Set<Object> _owners = {};
  Future<void> _pending = Future<void>.value();

  static Future<bool> _setAndroidScreenOn(bool enabled) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    return await _channel.invokeMethod<bool>(
          'setKeepScreenOn',
          {'enabled': enabled},
        ) ??
        false;
  }

  void setActive(Object owner, bool active) {
    final wasActive = _owners.isNotEmpty;
    if (active) {
      _owners.add(owner);
    } else {
      _owners.remove(owner);
    }
    final isActive = _owners.isNotEmpty;
    if (wasActive == isActive) return;
    _pending = _pending.then((_) async {
      try {
        if (!await _setScreenOn(isActive)) {
          LoggerService.instance.warning('Screen awake request was rejected');
        }
      } catch (error, stack) {
        LoggerService.instance.error(
          'Screen awake request failed',
          error: error,
          stackTrace: stack,
        );
      }
    });
  }

  @visibleForTesting
  Future<void> get pending => _pending;
}
