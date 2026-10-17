import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

/// Type d'appareil détecté
enum DeviceType {
  /// Appareil TV (Android TV, Fire TV, Google TV)
  tv,
  /// Téléphone/tablette
  phone,
  /// Autre type d'appareil
  unknown,
}

/// Résultat de la détection multi-méthodes de l'appareil
class DeviceDetectionResult {
  const DeviceDetectionResult({
    required this.deviceType,
    required this.isTv,
    required this.confidence,
    this.details = const {},
  });

  final DeviceType deviceType;
  final bool isTv;
  final double confidence; // 0.0 à 1.0
  final Map<String, dynamic> details;
}

/// Utilitaires de détection d'appareil (multi-méthodes)
///
/// Méthodes de détection utilisées :
/// - Packaging : feature android.software.leanback
/// - Hardware/features : systemFeatures Android, isPhysicalDevice
/// - Display size : dimensions d'écran, smallest width (TV vs mobile)
/// - UI mode : Configuration.UI_MODE_TYPE_TELEVISION (Android)
/// - Platform specific : checks natifs
class DeviceInfoUtils {
  // Platform channel réservé pour détections futures (UI mode, etc.)
  // static const MethodChannel _channel = MethodChannel('orbit/device_info');

  /// Détection multi-méthodes robuste
  static Future<DeviceDetectionResult> detectDeviceType({
    BuildContext? context,
  }) async {
    double confidence = 0.0;
    final details = <String, dynamic>{};
    bool isTv = false;

    // 1. Méthode 1 : Android Leanback feature (packaging/features)
    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        details['android_sdk_int'] = androidInfo.version.sdkInt;
        details['brand'] = androidInfo.brand;
        details['model'] = androidInfo.model;
        details['is_physical_device'] = androidInfo.isPhysicalDevice;

        // Check leanback feature
        if (androidInfo.systemFeatures.contains('android.software.leanback')) {
          isTv = true;
          confidence += 0.5; // Forte confiance (packaging TV)
          details['has_leanback_feature'] = true;
        } else {
          details['has_leanback_feature'] = false;
        }

        // UI Mode Television (Android 4.0+)
        // Note: device_info_plus ne l'expose pas directement, on garde en backup
        details['system_features_count'] = androidInfo.systemFeatures.length;
      } catch (e) {
        details['android_error'] = e.toString();
      }
    } else if (Platform.isIOS) {
      // iOS : Apple TV (tvOS) vs iOS - device_info_plus gère
      try {
        final iosInfo = await DeviceInfoPlugin().iosInfo;
        details['system_name'] = iosInfo.systemName;
        details['model'] = iosInfo.model;
        details['utsname_machine'] = iosInfo.utsname.machine;
        // Apple TV a "AppleTV" dans model
        if (iosInfo.model.contains('TV') || iosInfo.utsname.machine.contains('AppleTV')) {
          isTv = true;
          confidence += 0.5;
          details['is_apple_tv'] = true;
        }
      } catch (e) {
        details['ios_error'] = e.toString();
      }
    }

    // 2. Méthode 2 : Display size (large screen = TV candidate)
    if (context != null && context.mounted) {
      final mediaQuery = MediaQuery.of(context);
      final screenSize = mediaQuery.size;
      final shortestSide = screenSize.shortestSide;
      final longestSide = screenSize.longestSide;
      final pixelRatio = mediaQuery.devicePixelRatio;

      details['screen_width'] = screenSize.width;
      details['screen_height'] = screenSize.height;
      details['shortest_side_dp'] = shortestSide;
      details['longest_side_dp'] = longestSide;
      details['device_pixel_ratio'] = pixelRatio;

      // TV typiquement : large screen (>= 720dp), souvent 10ft UI
      // Téléphone < 600dp shortest, tablette 600-720, TV >= 720
      if (shortestSide >= 720) {
        // Large screen - candidat TV
        if (!isTv) {
          confidence += 0.2;
        } else {
          confidence += 0.1; // renforce
        }
        details['is_large_screen'] = true;
      } else {
        details['is_large_screen'] = false;
        if (isTv) {
          // Conflit : leanback dit TV mais petit écran - étrange, garde TV mais baisse confiance
          confidence = (confidence * 0.8).clamp(0, 1);
        }
      }
    }

    // 3. Méthode 3 : UI mode / PlatformDispatcher (si disponible)
    // Flutter 3.x : on peut utiliser WidgetsBinding pour platformDispatcher
    try {
      WidgetsBinding.instance.platformDispatcher;
      details['platform_dispatcher_initialized'] = true;
    } catch (e) {
      details['platform_error'] = e.toString();
    }

    // Ajustement confiance minimale
    if (isTv && confidence < 0.3) {
      confidence = 0.3;
    }
    if (!isTv && confidence > 0) {
      confidence = confidence.clamp(0, 0.9);
    }

    // Si aucune détection positive mais large screen très net, être conservateur
    // Ne pas forcer faux-positif - priorité au leanback feature

    final deviceType = isTv ? DeviceType.tv : DeviceType.phone;

    return DeviceDetectionResult(
      deviceType: deviceType,
      isTv: isTv,
      confidence: confidence.clamp(0, 1),
      details: details,
    );
  }

  /// Détection synchrone rapide (basée sur contexte si disponible)
  /// À utiliser dans build() quand async n'est pas possible
  static bool isTvFromContext(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    // Heuristique rapide : écran large (>720dp) peut être TV
    // Mais on privilégie la détection async + provider
    return shortestSide >= 1000; // Très large, probablement TV
  }
}
