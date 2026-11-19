// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/player_engine_config_sheet.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/services/video_decoder_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('information sur les lecteurs externes accessible à la télécommande',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showPlayerEngineConfigSheet(context),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    final info = find.byTooltip('Limites des lecteurs externes');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    final infoButton = find.ancestor(
      of: info,
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(infoButton).focusNode!.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.textContaining('préférences audio et sous-titres'), findsOneWidget);
    expect(find.textContaining('lecteur de secours'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation TV et sauvegarde ou annulation du décodage',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await VideoDecoderPrefs.setMode(VideoDecoderMode.auto);
    addTearDown(() => VideoDecoderPrefs.setMode(VideoDecoderMode.auto));
    tester.view.physicalSize = const Size(800, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showPlayerEngineConfigSheet(context),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    final sheetHeight =
        tester.getSize(find.byType(PlayerEngineConfigSheet)).height;
    expect(sheetHeight, closeTo(480 * 0.84, 0.1));
    final engines = find.byType(DropdownButton<PlayerEngine>);
    final subtitles = find.byType(DropdownButton<VodSubtitleMode>);
    final decoder = find.byType(DropdownButton<VideoDecoderMode>);
    final nodes = [
      tester.widget<DropdownButton<PlayerEngine>>(engines.at(0)).focusNode!,
      tester.widget<DropdownButton<PlayerEngine>>(engines.at(1)).focusNode!,
      tester.widget<DropdownButton<PlayerEngine>>(engines.at(2)).focusNode!,
      tester.widget<DropdownButton<PlayerEngine>>(engines.at(3)).focusNode!,
      tester.widget<DropdownButton<VodSubtitleMode>>(subtitles).focusNode!,
      for (var i = 4; i < 8; i++)
        tester.widget<DropdownButton<PlayerEngine>>(engines.at(i)).focusNode!,
      tester.widget<DropdownButton<VideoDecoderMode>>(decoder).focusNode!,
    ];
    for (final node in nodes) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue);
    }
    final previousNodes = nodes.reversed.skip(1).toList();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(previousNodes.first.hasFocus, isTrue);
    for (final node in previousNodes.skip(1)) {
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue);
    }
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowUp);
    final scroll = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView).first,
    );
    expect(scroll.controller!.offset, 0);
    final viewport = tester.getRect(find.byType(SingleChildScrollView).first);
    final liveTitle = tester.getRect(find.text(PlaybackContentType.live.label));
    expect(liveTitle.top, greaterThanOrEqualTo(viewport.top));
    expect(liveTitle.bottom, lessThanOrEqualTo(viewport.bottom));
    await tester.ensureVisible(decoder);
    await tester.tap(decoder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logiciel').last);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    final cancel = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Annuler'),
    );
    expect(cancel.focusNode?.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(VideoDecoderPrefs.mode, VideoDecoderMode.auto);

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(decoder);
    await tester.tap(decoder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Matériel').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();
    expect(VideoDecoderPrefs.mode, VideoDecoderMode.hardware);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('video_decoder_mode'), 'hardware');
  });

  testWidgets('sauvegarde le moteur VOD et le recharge', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(advancedSettingsProvider.notifier).load();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showPlayerEngineConfigSheet(context),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<PlayerEngine>).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text(PlayerEngine.mxPlayer.label).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<PlayerEngine>).at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text(PlayerEngine.exoPlayer.label).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();

    final savedConfig = container.read(advancedSettingsProvider).playerVod;
    expect(savedConfig.primary, PlayerEngine.mxPlayer);
    expect(savedConfig.fallback, PlayerEngine.exoPlayer);
    final reloaded = ProviderContainer();
    addTearDown(reloaded.dispose);
    await reloaded.read(advancedSettingsProvider.notifier).load();
    final reloadedConfig = reloaded.read(advancedSettingsProvider).playerVod;
    expect(reloadedConfig.primary, PlayerEngine.mxPlayer);
    expect(reloadedConfig.fallback, PlayerEngine.exoPlayer);
  });
}
