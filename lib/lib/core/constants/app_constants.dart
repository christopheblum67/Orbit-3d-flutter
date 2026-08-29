import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Orbit 3D';
  static const String appVersion = '1.0.0';
  static const String appDescription = '3D Orbit Visualization';

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
  static const double maxContentWidth = 1200.0;

  static const Duration cacheDuration = Duration(hours: 24);
  static const int maxCacheSize = 100;

  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  static const int minPasswordLength = 8;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;

  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);

  static const Color darkPrimaryColor = Color(0xFF90CAF9);
  static const Color darkSecondaryColor = Color(0xFF03DAC6);
  static const Color darkErrorColor = Color(0xFFCF6679);
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkTextColor = Color(0xFFE0E0E0);
  static const Color darkTextSecondaryColor = Color(0xFF9E9E9E);
}
