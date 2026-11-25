import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/widgets/audio_controls_sheet.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final language in ['fr', 'en', 'de', 'es', 'it', 'ar']) {
    for (final size in [const Size(360, 720), const Size(640, 360)]) {
      testWidgets('audio checkboxes share a row in $language at $size',
          (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(ProviderScope(
          child: MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: AudioControlsSheet()),
          ),
        ));
        await tester.pumpAndSettle();
        final l = lookupAppLocalizations(Locale(language));
        final dialogue =
            find.widgetWithText(CheckboxListTile, l.audioDialogueBoost);
        final bass = find.widgetWithText(CheckboxListTile, l.audioBassLimiter);
        final left = tester.getRect(dialogue);
        final right = tester.getRect(bass);
        expect(left.top, closeTo(right.top, 0.1));
        expect(
            language == 'ar'
                ? right.right <= left.left
                : left.right <= right.left,
            isTrue);
        expect(
            tester
                .widget<Text>(find.text(l.audioDialogueBoost))
                .style!
                .fontSize,
            lessThanOrEqualTo(12));
        await tester.drag(find.byType(ListView), const Offset(0, -1000));
        await tester.pumpAndSettle();
        expect(find.text(l.audioSyncLimitations), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final language in ['en', 'ar']) {
    testWidgets('audio checkboxes navigate horizontally in $language',
        (tester) async {
      SharedPreferences.setMockInitialValues(
          {AdvancedSettings.kNightFocus: true});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(advancedSettingsProvider.notifier).load();
      const channel = MethodChannel('orbit/night_focus');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => null);
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null));
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: AudioControlsSheet()),
        ),
      ));
      await tester.pumpAndSettle();
      final l = lookupAppLocalizations(Locale(language));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      bool focused(String title) => find
          .descendant(
            of: find
                .byWidget(FocusManager.instance.primaryFocus!.context!.widget),
            matching: find.text(title),
          )
          .evaluate()
          .isNotEmpty;
      expect(focused(l.audioDialogueBoost), isTrue);
      await tester.sendKeyEvent(language == 'ar'
          ? LogicalKeyboardKey.arrowLeft
          : LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(focused(l.audioBassLimiter), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(container.read(advancedSettingsProvider).nightFocusBassKiller,
          isFalse);
      await tester.sendKeyEvent(language == 'ar'
          ? LogicalKeyboardKey.arrowRight
          : LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(focused(l.audioDialogueBoost), isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('audio controls are localized', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AudioControlsSheet()),
      ),
    ));
    await tester.pump();
    expect(find.text('Night optimization (Night Focus)'), findsOneWidget);
    expect(find.text('Dialogue boost'), findsOneWidget);
    expect(find.text('Bass reduction and limiter'), findsOneWidget);
  });

  testWidgets('D-pad skips the hidden vocal gain slider', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AudioControlsSheet()),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsNothing);
    for (var i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    expect(
      find.descendant(
        of: find.byWidget(FocusManager.instance.primaryFocus!.context!.widget),
        matching: find.byTooltip('-50 ms'),
      ),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    final focused = FocusManager.instance.primaryFocus!.context!.widget;
    expect(
      find.descendant(
        of: find.byWidget(focused),
        matching: find.text('Bass reduction and limiter'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
