import 'package:flutter/material.dart';

/// Utilitaires de grille responsifs unifiés pour toute l'application.
///
/// Fournit des delegates de grille qui s'adaptent automatiquement à la largeur
/// de l'écran (mobile, tablette, TV, desktop) en calculant dynamiquement :
/// - Le nombre de colonnes (crossAxisCount)
/// - Le ratio d'aspect (childAspectRatio) pour garder des proportions harmonieuses
/// - Les espacements cohérents

class ResponsiveGrid {
  ResponsiveGrid._();

  // ──────────────────────────────────────────────────────────────────
  // Points de rupture (breakpoints) standards
  // ──────────────────────────────────────────────────────────────────
  static const double mobileBreakpoint = 600;    // < 600dp : mobile
  static const double tabletBreakpoint = 900;    // 600-900dp : tablette
  static const double desktopBreakpoint = 1200;  // 900-1200dp : desktop
  // > 1200dp : TV / grand écran

  // ──────────────────────────────────────────────────────────────────
  // Configuration par type de contenu
  // ──────────────────────────────────────────────────────────────────

  /// Configuration pour grilles de contenu principal (Films, Séries, Live, Replay)
  static const contentGridConfig = _GridConfig(
    minItemWidth: 160,
    maxItemWidth: 240,
    baseAspectRatio: 0.68,
    wideAspectRatio: 0.72,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
    minColumns: 2,
    maxColumns: 12,
  );

  /// Configuration pour grilles compactes (avatars, cast, petits éléments)
  static const compactGridConfig = _GridConfig(
    minItemWidth: 80,
    maxItemWidth: 130,
    baseAspectRatio: 1.0,
    wideAspectRatio: 1.0,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    minColumns: 4,
    maxColumns: 16,
  );

  /// Configuration pour carousel horizontal (Home screen)
  static const carouselConfig = _CarouselConfigData(
    minItemWidth: 240,
    maxItemWidth: 340,
    minItemHeight: 320,
    maxItemHeight: 480,
    aspectRatio: 0.7,
  );

  // ──────────────────────────────────────────────────────────────────
  // API Publique
  // ──────────────────────────────────────────────────────────────────

  /// Calcule le nombre optimal de colonnes pour une largeur donnée
  static int calculateCrossAxisCount(
    double width, {
    double minItemWidth = 160,
    double spacing = 16,
    int minColumns = 2,
    int maxColumns = 12,
  }) {
    final availableWidth = width - spacing;
    final count = (availableWidth / (minItemWidth + spacing)).floor();
    return count.clamp(minColumns, maxColumns);
  }

  /// Calcule le ratio d'aspect optimal pour une largeur d'item donnée
  static double calculateAspectRatio(double itemWidth, {bool isWide = false}) {
    final baseRatio = isWide ? 0.72 : 0.68;
    final ratio = baseRatio + (itemWidth - 160) * 0.0002;
    return ratio.clamp(0.55, 0.85);
  }

  /// Calcule les dimensions optimales pour un item de carousel horizontal
  static _CarouselDimensions carouselDimensions(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isTv = isTvContext(context);

    final targetWidth = isTv
        ? carouselConfig.maxItemWidth
        : carouselConfig.minItemWidth +
              (width - mobileBreakpoint).clamp(0.0, 600.0) / 600.0 *
                  (carouselConfig.maxItemWidth - carouselConfig.minItemWidth);

    final clampedWidth = targetWidth.clamp(
      carouselConfig.minItemWidth,
      carouselConfig.maxItemWidth,
    );

    final height = clampedWidth / carouselConfig.aspectRatio;

    return _CarouselDimensions(
      width: clampedWidth.clamp(carouselConfig.minItemWidth, carouselConfig.maxItemWidth),
      height: height.clamp(carouselConfig.minItemHeight, carouselConfig.maxItemHeight),
    );
  }

  /// Détecte si on est sur un contexte TV
  static bool isTvContext(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    return width >= 1200 && height >= 720;
  }
}

/// Configuration interne pour grille de contenu
class _GridConfig {
  const _GridConfig({
    required this.minItemWidth,
    required this.maxItemWidth,
    required this.baseAspectRatio,
    required this.wideAspectRatio,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.minColumns,
    required this.maxColumns,
  });

  final double minItemWidth;
  final double maxItemWidth;
  final double baseAspectRatio;
  final double wideAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final int minColumns;
  final int maxColumns;
}

/// Configuration pour carousel
class _CarouselConfigData {
  const _CarouselConfigData({
    required this.minItemWidth,
    required this.maxItemWidth,
    required this.minItemHeight,
    required this.maxItemHeight,
    required this.aspectRatio,
  });

  final double minItemWidth;
  final double maxItemWidth;
  final double minItemHeight;
  final double maxItemHeight;
  final double aspectRatio;
}

/// Résultat dimensions carousel
class _CarouselDimensions {
  const _CarouselDimensions({required this.width, required this.height});
  final double width;
  final double height;
}

/// Helper pour créer un GridView.builder responsif
class ResponsiveGridView {
  /// Crée un GridView.builder avec delegate responsif pour contenu principal
  static Widget contentBuilder({
    required Key? key,
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = ResponsiveGrid.calculateCrossAxisCount(
          constraints.maxWidth,
          minItemWidth: ResponsiveGrid.contentGridConfig.minItemWidth,
          spacing: ResponsiveGrid.contentGridConfig.crossAxisSpacing,
          minColumns: ResponsiveGrid.contentGridConfig.minColumns,
          maxColumns: ResponsiveGrid.contentGridConfig.maxColumns,
        );

        final totalSpacing = ResponsiveGrid.contentGridConfig.crossAxisSpacing * (crossAxisCount - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
        final isWide = constraints.maxWidth >= ResponsiveGrid.tabletBreakpoint;
        final aspectRatio = ResponsiveGrid.calculateAspectRatio(itemWidth, isWide: isWide);
        final itemHeight = itemWidth / aspectRatio;

        return GridView.builder(
          key: key,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: itemWidth / itemHeight,
            crossAxisSpacing: ResponsiveGrid.contentGridConfig.crossAxisSpacing,
            mainAxisSpacing: ResponsiveGrid.contentGridConfig.mainAxisSpacing,
          ),
          itemBuilder: itemBuilder,
          itemCount: itemCount,
          padding: padding,
          shrinkWrap: shrinkWrap,
          physics: physics,
        );
      },
    );
  }

  /// Crée un GridView.builder avec delegate responsif pour contenu compact
  static Widget compactBuilder({
    required Key? key,
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = ResponsiveGrid.calculateCrossAxisCount(
          constraints.maxWidth,
          minItemWidth: ResponsiveGrid.compactGridConfig.minItemWidth,
          spacing: ResponsiveGrid.compactGridConfig.crossAxisSpacing,
          minColumns: ResponsiveGrid.compactGridConfig.minColumns,
          maxColumns: ResponsiveGrid.compactGridConfig.maxColumns,
        );

        final totalSpacing = ResponsiveGrid.compactGridConfig.crossAxisSpacing * (crossAxisCount - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
        final isWide = constraints.maxWidth >= ResponsiveGrid.tabletBreakpoint;
        final aspectRatio = ResponsiveGrid.calculateAspectRatio(itemWidth, isWide: isWide);
        final itemHeight = itemWidth / aspectRatio;

        return GridView.builder(
          key: key,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: itemWidth / itemHeight,
            crossAxisSpacing: ResponsiveGrid.compactGridConfig.crossAxisSpacing,
            mainAxisSpacing: ResponsiveGrid.compactGridConfig.mainAxisSpacing,
          ),
          itemBuilder: itemBuilder,
          itemCount: itemCount,
          padding: padding,
          shrinkWrap: shrinkWrap,
          physics: physics,
        );
      },
    );
  }
}

/// Helper pour créer un SliverGrid responsif dans CustomScrollView
class ResponsiveSliverGrid {
  /// Crée un SliverGrid avec delegate responsif pour contenu principal
  static Widget content({
    required Key? key,
    required SliverChildDelegate childrenDelegate,
    EdgeInsetsGeometry? padding,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = ResponsiveGrid.calculateCrossAxisCount(
          constraints.maxWidth,
          minItemWidth: ResponsiveGrid.contentGridConfig.minItemWidth,
          spacing: ResponsiveGrid.contentGridConfig.crossAxisSpacing,
          minColumns: ResponsiveGrid.contentGridConfig.minColumns,
          maxColumns: ResponsiveGrid.contentGridConfig.maxColumns,
        );

        final totalSpacing = ResponsiveGrid.contentGridConfig.crossAxisSpacing * (crossAxisCount - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
        final isWide = constraints.maxWidth >= ResponsiveGrid.tabletBreakpoint;
        final aspectRatio = ResponsiveGrid.calculateAspectRatio(itemWidth, isWide: isWide);
        final itemHeight = itemWidth / aspectRatio;

        return SliverGrid(
          key: key,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: itemWidth / itemHeight,
            crossAxisSpacing: ResponsiveGrid.contentGridConfig.crossAxisSpacing,
            mainAxisSpacing: ResponsiveGrid.contentGridConfig.mainAxisSpacing,
          ),
          childrenDelegate: childrenDelegate,
          padding: padding,
        );
      },
    );
  }

  /// Crée un SliverGrid avec delegate responsif pour contenu compact
  static Widget compact({
    required Key? key,
    required SliverChildDelegate childrenDelegate,
    EdgeInsetsGeometry? padding,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = ResponsiveGrid.calculateCrossAxisCount(
          constraints.maxWidth,
          minItemWidth: ResponsiveGrid.compactGridConfig.minItemWidth,
          spacing: ResponsiveGrid.compactGridConfig.crossAxisSpacing,
          minColumns: ResponsiveGrid.compactGridConfig.minColumns,
          maxColumns: ResponsiveGrid.compactGridConfig.maxColumns,
        );

        final totalSpacing = ResponsiveGrid.compactGridConfig.crossAxisSpacing * (crossAxisCount - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
        final isWide = constraints.maxWidth >= ResponsiveGrid.tabletBreakpoint;
        final aspectRatio = ResponsiveGrid.calculateAspectRatio(itemWidth, isWide: isWide);
        final itemHeight = itemWidth / aspectRatio;

        return SliverGrid(
          key: key,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: itemWidth / itemHeight,
            crossAxisSpacing: ResponsiveGrid.compactGridConfig.crossAxisSpacing,
            mainAxisSpacing: ResponsiveGrid.compactGridConfig.mainAxisSpacing,
          ),
          childrenDelegate: childrenDelegate,
          padding: padding,
        );
      },
    );
  }
}