import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';

/// Thème global "Orbit IPTV" — refonte moderne : palette seed indigo/violet,
/// accents rose/cyan, arrondis généreux et typographie dynamique.
class AppTheme {
  AppTheme._();

  static ThemeData lightTheme({bool highContrast = false}) =>
      _buildTheme(Brightness.light, highContrast);

  static ThemeData darkTheme({bool highContrast = false}) =>
      _buildTheme(Brightness.dark, highContrast);

  static ThemeData _buildTheme(Brightness brightness, bool highContrast) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppConstants.seedColor,
      brightness: brightness,
      primary:
          isDark ? AppConstants.darkPrimaryColor : AppConstants.primaryColor,
      secondary: isDark
          ? AppConstants.darkSecondaryColor
          : AppConstants.secondaryColor,
      tertiary:
          isDark ? AppConstants.darkTertiaryColor : AppConstants.tertiaryColor,
      error: isDark ? AppConstants.darkErrorColor : AppConstants.errorColor,
    );

    final contrastScheme = highContrast
        ? _applyHighContrast(scheme, isDark)
        : scheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: contrastScheme,
      scaffoldBackgroundColor: contrastScheme.surfaceContainerLowest,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: contrastScheme.onSurface,
        titleTextStyle: TextStyle(
          color: contrastScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: contrastScheme.surfaceContainer,
        indicatorColor: contrastScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            letterSpacing: 0.2,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? contrastScheme.onSecondaryContainer
                : contrastScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? contrastScheme.primary : contrastScheme.onSurfaceVariant,
            size: selected ? 26 : 24,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: contrastScheme.surfaceContainerLow,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultMargin,
          vertical: 6,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
        tileColor: contrastScheme.surfaceContainerLow,
        iconColor: contrastScheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: TextStyle(
          color: contrastScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(
          color: contrastScheme.onSurfaceVariant,
          fontSize: 13,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: contrastScheme.primary,
        foregroundColor: contrastScheme.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: contrastScheme.surfaceContainerHighest
            .withValues(alpha: isDark ? 0.35 : 0.45),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: contrastScheme.onSurfaceVariant),
        hintStyle:
            TextStyle(color: contrastScheme.onSurfaceVariant.withValues(alpha: 0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          borderSide: BorderSide(color: contrastScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          borderSide: BorderSide(color: contrastScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: contrastScheme.outlineVariant.withValues(alpha: 0.5),
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: contrastScheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: contrastScheme.onInverseSurface,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: contrastScheme.primary),
      textTheme: _buildTextTheme(contrastScheme, isDark),
    );
  }

  static ColorScheme _applyHighContrast(ColorScheme scheme, bool isDark) {
    if (isDark) {
      return scheme.copyWith(
        onSurface: Colors.white,
        onSurfaceVariant: Colors.white70,
        onBackground: Colors.white,
        onError: Colors.white,
        surface: Colors.black,
        surfaceContainerLowest: Colors.black,
        surfaceContainerLow: const Color(0xFF121212),
        surfaceContainer: const Color(0xFF1E1E1E),
        surfaceContainerHigh: const Color(0xFF2C2C2C),
        surfaceContainerHighest: const Color(0xFF383838),
        outline: Colors.white38,
        outlineVariant: Colors.white24,
        inverseSurface: Colors.white,
        onInverseSurface: Colors.black,
      );
    } else {
      return scheme.copyWith(
        onSurface: Colors.black,
        onSurfaceVariant: Colors.black54,
        onBackground: Colors.black,
        onError: Colors.white,
        surface: Colors.white,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFF5F5F5),
        surfaceContainer: const Color(0xFFEEEEEE),
        surfaceContainerHigh: const Color(0xFFE0E0E0),
        surfaceContainerHighest: const Color(0xFFD1D1D1),
        outline: Colors.black38,
        outlineVariant: Colors.black26,
        inverseSurface: Colors.black,
        onInverseSurface: Colors.white,
      );
    }
  }

  static TextTheme _buildTextTheme(ColorScheme scheme, bool isDark) {
    final typography = Typography.material2021();
    final base = isDark ? typography.white : typography.black;
    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: scheme.onSurface,
      ),
      bodyMedium: base.bodyMedium?.copyWith(color: scheme.onSurface),
      bodySmall: base.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
