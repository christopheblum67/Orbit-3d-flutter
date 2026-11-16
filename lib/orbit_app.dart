import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/navigation/app_router.dart';
import 'package:orbit_3d_flutter/core/theme/app_theme.dart';
import 'package:orbit_3d_flutter/core/utils/error_handler.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/home_widget_provider.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/tmdb_api_key_provider.dart';
import 'package:orbit_3d_flutter/services/home_widget_service.dart';

class OrbitApp extends ConsumerStatefulWidget {
  const OrbitApp({super.key});

  @override
  ConsumerState<OrbitApp> createState() => _OrbitAppState();
}

class _OrbitAppState extends ConsumerState<OrbitApp> {
  @override
  void initState() {
    super.initState();
    // Riverpod 3 : build() doit être passé avant toute utilisation du notifier.
    ref.read(advancedSettingsProvider);
    ref.read(tmdbApiKeyOverrideProvider);
    unawaited(ref.read(advancedSettingsProvider.notifier).load());
    unawaited(ref.read(tmdbApiKeyOverrideProvider.notifier).load());
    // Analytics : init non bloquante (fire-and-forget après le premier frame).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(analyticsServiceProvider).init());
    });
    // Garde le widget d'accueil Android synchronisé (profil + favoris) tant que
    // l'app vit. Lecture volontaire à l'initialisation pour installer les écouteurs.
    ref.watch(homeWidgetSyncProvider);
    // Lancement possible depuis le widget d'accueil (tap/action) : on y répond.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleWidgetLaunch();
    });
  }

  Future<void> _handleWidgetLaunch() async {
    await safeAsync(
      () async {
        final uri = await HomeWidgetService.instance.initiallyLaunched();
        final route = routeForWidgetUri(uri);
        if (route != null) {
          router.go(route);
        }
      },
      context: '_handleWidgetLaunch',
    );
  }

  @override
  Widget build(BuildContext context) {
    final advancedSettings = ref.watch(advancedSettingsProvider);
    final prefs = ref.watch(preferencesProvider);

    // Locale chargée depuis les préférences (défaut 'fr'). Retombe sur la
    // locale système si la langue choisie n'est pas supportée.
    Locale? resolveLocale() {
      final supported = AppLocalizations.supportedLocales;
      for (final l in supported) {
        if (l.languageCode == prefs.language) return l;
      }
      final system = WidgetsBinding.instance.platformDispatcher.locale;
      if (supported.any((l) => l.languageCode == system.languageCode)) {
        return system;
      }
      return null;
    }

    return MaterialApp.router(
      builder: (context, child) => TvModeDetector(
        child: child ?? const SizedBox.shrink(),
      ),
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: resolveLocale(),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.lightTheme(highContrast: advancedSettings.highContrast),
      darkTheme:
          AppTheme.darkTheme(highContrast: advancedSettings.highContrast),
      // Le thème est un réglage utilisateur (PreferencesNotifier.setTheme) :
      // il était codé en dur sur `system`, ce qui rendait le thème clair
      // inatteignable même en le sélectionnant dans les préférences.
      themeMode: switch (prefs.theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      routerConfig: router,
    );
  }
}
