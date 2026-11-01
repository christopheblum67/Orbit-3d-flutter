import 'dart:io' show Platform;
import 'dart:math' show sqrt;

import 'package:flutter/material.dart';

/// Catégorisation de la plateforme en cours, pour adapter l'UI
/// (densité de grille, taille des cartes, navigation D-pad, etc.).
///
/// Sur Android TV, la résolution logique est souvent en paysage large
/// (ex. 1920×1080 ou 1280×720). L'heuristique ci-dessous suffit dans
/// la grande majorité des cas ; pour une robustesse absolue, coupler avec
/// `device_info_plus` (voir [isAndroidTv]) qui vérifie la caractéristique
/// `FEATURE_TELEVISION` côté système.
enum OrbitDeviceType { mobile, tablet, tv, desktop }

extension DeviceTypeExtension on BuildContext {
  /// Type de device déduit de la taille d'écran et de la plateforme.
  OrbitDeviceType get deviceType {
    if (Platform.isAndroid) {
      final size = MediaQuery.of(this).size;
      // Heuristique TV : écran large en paysage.
      if (size.width > 900 && size.aspectRatio > 1.2) {
        return OrbitDeviceType.tv;
      }
    }
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return OrbitDeviceType.desktop;
    }
    final shortestSide = MediaQuery.of(this).size.shortestSide;
    if (shortestSide < 600) {
      return OrbitDeviceType.mobile;
    }
    return OrbitDeviceType.tablet;
  }

  bool get isTv => deviceType == OrbitDeviceType.tv;
  bool get isMobile => deviceType == OrbitDeviceType.mobile;
  bool get isTablet => deviceType == OrbitDeviceType.tablet;
  bool get isDesktop => deviceType == OrbitDeviceType.desktop;
}

/// Échelle typographique et d'espacement dynamique pour la TV.
///
/// Sur un téléviseur, la distance de lecture est bien supérieure à celle d'un
/// smartphone : les textes et les marges sont multipliés par [tvScaleFactor]
/// (1.4× sur TV) pour rester lisibles depuis un canapé.
extension OrbitTypographyExtension on BuildContext {
  double get tvScaleFactor => isTv ? 1.4 : 1.0;

  TextStyle get headlineLarge => TextStyle(
        fontSize: 26.0 * tvScaleFactor,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.5,
      );

  TextStyle get titleMedium => TextStyle(
        fontSize: 18.0 * tvScaleFactor,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
      );

  TextStyle get bodyMedium => TextStyle(
        fontSize: 14.0 * tvScaleFactor,
        fontWeight: FontWeight.normal,
        color: Colors.white60,
      );

  double get defaultSpacing => isTv ? 24.0 : 12.0;
  double get screenPadding => isTv ? 48.0 : 16.0;
}
