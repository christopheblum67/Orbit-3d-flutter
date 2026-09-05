import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Orbit IPTV';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'IPTV Streaming Platform';

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );
  static const int apiTimeout = 30;

  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration transitionDuration = Duration(milliseconds: 250);

  static const double defaultPadding = 16.0;
  static const double defaultMargin = 16.0;
  static const double defaultRadius = 12.0;
  static const double radiusSm = 8.0;
  static const double radiusLg = 18.0;
  static const double radiusXl = 26.0;
  static const double maxContentWidth = 1200.0;

  static const Duration cacheDuration = Duration(hours: 24);
  static const int maxCacheSize = 100;

  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  static const int minPasswordLength = 8;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;

  // Palette "jeune" : indigo/violet en seed, rose & cyan en accents.
  static const Color seedColor = Color(0xFF5B5BD6);
  static const Color primaryColor = Color(0xFF5B5BD6);
  static const Color secondaryColor = Color(0xFFFF4D8D);
  static const Color tertiaryColor = Color(0xFF00B8D4);
  static const Color errorColor = Color(0xFFB00020);
  static const Color backgroundColor = Color(0xFFF6F5FF);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF1C1B33);
  static const Color textSecondaryColor = Color(0xFF6C6B85);

  static const Color darkPrimaryColor = Color(0xFFAEB3FF);
  static const Color darkSecondaryColor = Color(0xFFFF86B0);
  static const Color darkTertiaryColor = Color(0xFF54D6E8);
  static const Color darkErrorColor = Color(0xFFCF6679);
  static const Color darkBackgroundColor = Color(0xFF0F0E16);
  static const Color darkSurfaceColor = Color(0xFF1D1B2B);
  static const Color darkTextColor = Color(0xFFE7E6F2);
  static const Color darkTextSecondaryColor = Color(0xFF9A99B0);
}
