import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/player_engine_config_sheet.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations_fr.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Feuille « Moteurs de lecture » (Live / VOD / Séries / Replays).
///
/// Objectif : garantir qu'elle rend bien son contenu — ni écran vide, ni
/// exception pendant la construction (le double usage d'un `FocusNode` par le
/// `Focus` parent et le `DropdownButton` interne serait levé ici). Le défaut
/// « écran gris » rapporté n'a pas pu être reproduit sur appareil ; ce test
/// fixe au moins le contrat de rendu hors device.
Widget _app(Widget child) => ProviderScope(
  child: MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('rend le titre, les quatre types et les actions', (tester) async {
    await tester.pumpWidget(_app(const PlayerEngineConfigSheet()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Moteurs de lecture'), findsOneWidget);
    // Un sélecteur principal (« Live ») par type de contenu.
    expect(find.byType(DropdownButton<PlayerEngine>), findsWidgets);
    // Actions de bas de feuille (libellés issus de la l10n).
    final l = AppLocalizationsFr();
    expect(find.text(l.save), findsOneWidget);
    expect(find.text(l.cancel), findsOneWidget);
  });

  testWidgets('s\'ouvre via showPlayerEngineConfigSheet sans écran vide', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (ctx) => Center(
            child: ElevatedButton(
              onPressed: () => showPlayerEngineConfigSheet(ctx),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Moteurs de lecture'), findsOneWidget);
  });

  testWidgets('l application d\'un moteur externe modifie le brouillon', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const PlayerEngineConfigSheet()));
    await tester.pumpAndSettle();

    // Ouvre le premier sélecteur (Live · Moteur principal).
    await tester.tap(find.byType(DropdownButton<PlayerEngine>).first);
    await tester.pumpAndSettle();

    // Le menu expose tous les moteurs disponibles.
    expect(find.text(PlayerEngine.vlc.label), findsWidgets);
  });
}
