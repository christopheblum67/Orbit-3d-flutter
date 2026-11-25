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
  for (final size in [
    const Size(1280, 720),
    const Size(960, 540),
    const Size(800, 480),
  ]) {
    for (final language in ['fr', 'en', 'de', 'es', 'it', 'ar']) {
      testWidgets('all engine options fit without scrolling in $language $size',
          (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(ProviderScope(
          child: MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showPlayerEngineConfigSheet(context),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        final scroll = tester.widget<SingleChildScrollView>(
          find.byType(SingleChildScrollView).first,
        );
        final viewport = tester.getRect(find.byType(SingleChildScrollView).first);
        final grid = tester.getRect(find.byKey(const ValueKey('engine-grid')));
        final options =
            tester.getRect(find.byKey(const ValueKey('engine-side-options')));
        expect(scroll.controller!.position.maxScrollExtent, 0,
            reason: '$language $size viewport=$viewport grid=$grid '
                'options=$options');
        for (final key in ['engine-grid', 'engine-side-options']) {
          final rect = tester.getRect(find.byKey(ValueKey(key)));
          expect(rect.top, greaterThanOrEqualTo(viewport.top));
          expect(rect.bottom, lessThanOrEqualTo(viewport.bottom));
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final language in ['fr', 'en', 'de', 'es', 'it', 'ar']) {
    testWidgets('side options fit the two-by-two grid in $language',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showPlayerEngineConfigSheet(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final grid = tester.getRect(find.byKey(const ValueKey('engine-grid')));
      final options =
          tester.getRect(find.byKey(const ValueKey('engine-side-options')));
      expect(options.bottom, lessThanOrEqualTo(grid.bottom),
          reason: 'grid=$grid options=$options');
      expect(tester.takeException(), isNull);
    });
  }

  for (final language in ['en', 'ar']) {
    testWidgets('engine grid follows horizontal D-pad direction in $language',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showPlayerEngineConfigSheet(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(PlayerEngineConfigSheet)).width,
          lessThanOrEqualTo(1000));
      final grid = tester.getRect(find.byKey(const ValueKey('engine-grid')));
      final options =
          tester.getRect(find.byKey(const ValueKey('engine-side-options')));
      expect(
          language == 'ar'
              ? options.right <= grid.left
              : grid.right <= options.left,
          isTrue);
      final dropdowns = find.byType(DropdownButton<PlayerEngine>);
      final live = tester.widget<DropdownButton<PlayerEngine>>(dropdowns.at(0));
      final vod = tester.widget<DropdownButton<PlayerEngine>>(dropdowns.at(2));
      expect(tester.getSize(dropdowns.first).width, lessThanOrEqualTo(132));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(live.focusNode!.hasFocus, isTrue);
      BoxDecoration haloFor(Finder child) {
        final halos = tester.widgetList<AnimatedContainer>(find.ancestor(
          of: child,
          matching: find.byType(AnimatedContainer),
        ));
        return halos
            .map((halo) => halo.decoration)
            .whereType<BoxDecoration>()
            .firstWhere((decoration) => decoration.boxShadow != null);
      }

      expect(haloFor(dropdowns.first).boxShadow, isNotEmpty);
      await tester.sendKeyEvent(language == 'ar'
          ? LogicalKeyboardKey.arrowLeft
          : LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(vod.focusNode!.hasFocus, isTrue);
      await tester.sendKeyEvent(language == 'ar'
          ? LogicalKeyboardKey.arrowLeft
          : LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      final checkbox = find.byType(CheckboxListTile).first;
      final checkboxFocus = Focus.of(tester.element(find
          .ancestor(
            of: checkbox,
            matching: find.byType(Focus),
          )
          .first));
      expect(checkboxFocus.hasFocus, isTrue);
      expect(haloFor(checkbox).boxShadow, isNotEmpty);
      await tester.sendKeyEvent(language == 'ar'
          ? LogicalKeyboardKey.arrowRight
          : LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<DropdownButton<PlayerEngine>>(dropdowns.at(3))
              .focusNode!
              .hasFocus,
          isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(vod.focusNode!.hasFocus, isTrue);
      await tester.sendKeyEvent(language == 'ar'
          ? LogicalKeyboardKey.arrowRight
          : LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(live.focusNode!.hasFocus, isTrue);

      final expectedDown = [1, 4, 5];
      for (final index in expectedDown) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<DropdownButton<PlayerEngine>>(dropdowns.at(index))
              .focusNode!
              .hasFocus,
          isTrue,
        );
      }
      await tester.sendKeyEvent(language == 'ar'
          ? LogicalKeyboardKey.arrowLeft
          : LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButton<PlayerEngine>>(dropdowns.at(7))
            .focusNode!
            .hasFocus,
        isTrue,
      );
      for (final index in [6, 3, 2]) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<DropdownButton<PlayerEngine>>(dropdowns.at(index))
              .focusNode!
              .hasFocus,
          isTrue,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('moving between Live and VOD keeps the help text visible',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
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
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    final help = find
        .text(lookupAppLocalizations(const Locale('fr')).engineSelectionHelp);
    final scroll = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView).first,
    );
    final top = tester.getTopLeft(help).dy;
    final offset = scroll.controller!.offset;
    for (final key in [
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowLeft,
    ]) {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
      expect(scroll.controller!.offset, offset);
      expect(tester.getTopLeft(help).dy, top);
      expect(
        tester.getRect(help).top,
        greaterThanOrEqualTo(
          tester.getRect(find.byType(SingleChildScrollView).first).top,
        ),
      );
    }
    expect(tester.takeException(), isNull);
  });

  for (final language in ['fr', 'en', 'de', 'es', 'it', 'ar']) {
    testWidgets('merged player options fit in $language', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showPlayerEngineConfigSheet(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final l = lookupAppLocalizations(Locale(language));
      final live =
          tester.getRect(find.byKey(const ValueKey('engine-type-live')));
      final vod = tester.getRect(find.byKey(const ValueKey('engine-type-vod')));
      final series =
          tester.getRect(find.byKey(const ValueKey('engine-type-series')));
      final replay =
          tester.getRect(find.byKey(const ValueKey('engine-type-replay')));
      final grid = tester.getRect(find.byKey(const ValueKey('engine-grid')));
      final options =
          tester.getRect(find.byKey(const ValueKey('engine-side-options')));
      expect(options.top, greaterThanOrEqualTo(grid.bottom));
      expect(live.top, vod.top);
      expect(series.top, replay.top);
      expect(series.top, greaterThan(live.top));
      expect(language == 'ar' ? vod.right <= live.left : live.right <= vod.left,
          isTrue);
      expect(find.text(l.engineSubtitleDefault), findsOneWidget);
      expect(find.text(l.engineSubtitleForced), findsOneWidget);
      expect(find.text(l.engineSubtitleDisabled), findsOneWidget);
      expect(find.text(l.engineAutoRecommended), findsOneWidget);
      expect(find.text(l.engineHardware), findsOneWidget);
      expect(find.text(l.engineSoftware), findsOneWidget);
      expect(find.text(l.instantZapping), findsOneWidget);
      await tester.ensureVisible(find.text(l.instantZapping));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('engine subtitle choice clears the old force-off preference',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      AdvancedSettings.kForceNoSubtitles: true,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(advancedSettingsProvider.notifier).load();
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(UncontrolledProviderScope(
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
    ));
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    final disabled = find.widgetWithText(CheckboxListTile, 'Sans sous-titres');
    final forced = find.widgetWithText(CheckboxListTile, 'Sous-titres forcés');
    expect(tester.widget<CheckboxListTile>(disabled).value, isTrue);
    await tester.ensureVisible(forced);
    await tester.tap(forced);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();
    final settings = container.read(advancedSettingsProvider);
    expect(settings.vodSubtitleMode, VodSubtitleMode.forcedOnly);
    expect(settings.subtitlesDisabled, isFalse);
  });

  testWidgets('player and subtitle choices are localized', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showPlayerEngineConfigSheet(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Playback engines'), findsOneWidget);
    expect(find.text('ExoPlayer'), findsWidgets);
    await tester.tap(find.byType(DropdownButton<PlayerEngine>).first);
    await tester.pumpAndSettle();
    expect(find.text('ExoPlayer (Internal)'), findsWidgets);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Movie and series subtitles'), findsOneWidget);
  });

  testWidgets(
      'information sur les lecteurs externes accessible à la télécommande',
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
    expect(find.textContaining('préférences audio et sous-titres'),
        findsOneWidget);
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
    expect(sheetHeight, lessThanOrEqualTo(480 * 0.86));
    final engines = find.byType(DropdownButton<PlayerEngine>);
    final checkboxNodes = [
      for (final checkbox
          in tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile)))
        Focus.of(tester.element(find
            .ancestor(
              of: find.byWidget(checkbox),
              matching: find.byType(Focus),
            )
            .first)),
    ];
    final nodes = [
      for (final i in [0, 1, 4, 5])
        tester.widget<DropdownButton<PlayerEngine>>(engines.at(i)).focusNode!,
      ...checkboxNodes,
    ];
    for (final node in nodes) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue);
    }
    final previousNodes = [
      ...checkboxNodes.reversed.skip(1),
      for (final i in [7, 6, 3, 2])
        tester.widget<DropdownButton<PlayerEngine>>(engines.at(i)).focusNode!,
    ];
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
    final software = find.widgetWithText(CheckboxListTile, 'Logiciel');
    await tester.ensureVisible(software);
    await tester.tap(software);
    await tester.pumpAndSettle();
    Focus.of(tester.element(find
            .ancestor(
              of: find.byType(CheckboxListTile).last,
              matching: find.byType(Focus),
            )
            .first))
        .requestFocus();
    await tester.pump();
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
    final hardware = find.widgetWithText(CheckboxListTile, 'Matériel');
    await tester.ensureVisible(hardware);
    await tester.tap(hardware);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();
    expect(VideoDecoderPrefs.mode, VideoDecoderMode.hardware);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('video_decoder_mode'), 'hardware');
  });

  testWidgets('player checkboxes are drafted, coordinated and saved',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      AdvancedSettings.kVodSubtitleMode: VodSubtitleMode.forcedOnly.name,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(advancedSettingsProvider.notifier).load();
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showPlayerEngineConfigSheet(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ));

    Future<void> open() async {
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    final disabled = find.widgetWithText(CheckboxListTile, 'No subtitles');
    final forced = find.widgetWithText(CheckboxListTile, 'Forced subtitles');
    final defaultMode = find.widgetWithText(CheckboxListTile, 'Default');
    final zapping = find.widgetWithText(CheckboxListTile,
        lookupAppLocalizations(const Locale('en')).instantZapping);
    await open();
    await tester.ensureVisible(disabled);
    await tester.tap(disabled);
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(disabled).value, isTrue);
    expect(tester.widget<CheckboxListTile>(forced).value, isFalse);
    expect(container.read(advancedSettingsProvider).subtitlesDisabled, isFalse);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(container.read(advancedSettingsProvider).subtitlesDisabled, isFalse);

    await open();
    await tester.ensureVisible(disabled);
    await tester.tap(disabled);
    await tester.ensureVisible(zapping);
    await tester.tap(zapping);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();
    expect(container.read(advancedSettingsProvider).subtitlesDisabled, isTrue);
    expect(container.read(advancedSettingsProvider).zeroLagPrefetch, isFalse);
    expect(container.read(advancedSettingsProvider).vodSubtitleMode,
        VodSubtitleMode.disabled);

    await open();
    await tester.ensureVisible(defaultMode);
    await tester.tap(defaultMode);
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(defaultMode).value, isTrue);
    expect(tester.widget<CheckboxListTile>(disabled).value, isFalse);
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();
    expect(container.read(advancedSettingsProvider).subtitlesDisabled, isFalse);
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
