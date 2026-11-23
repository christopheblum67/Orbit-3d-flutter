import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/avatar_catalog.dart';
import 'package:orbit_3d_flutter/core/widgets/avatar_picker_grid.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/features/profile/profile_edit_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

Widget _localizedApp(Widget child, {Locale? locale, TvModeNotifier? tvMode}) {
  return ProviderScope(
    overrides: [
      if (tvMode != null) tvModeNotifierProvider.overrideWithValue(tvMode),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('gender choices are absent in every supported language',
      (tester) async {
    for (final locale in AppLocalizations.supportedLocales) {
      await tester.pumpWidget(
        _localizedApp(const ProfileEditScreen(), locale: locale),
      );
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(
        tester.element(find.byType(ProfileEditScreen)),
      );
      final scrollable = find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text(l.genreAdventure),
        300,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      for (final label in [
        l.noneOption,
        l.actorGenderMale,
        l.actorGenderFemale,
        l.onboardingOtherNetwork,
      ]) {
        expect(find.text(label), findsNothing, reason: locale.languageCode);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets(
      'profile editor and discard confirmation use the selected language',
      (tester) async {
    await tester.pumpWidget(
      _localizedApp(const ProfileEditScreen(), locale: const Locale('en')),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Create a profile'), findsOneWidget);
    expect(find.text('Avatar theme'), findsOneWidget);
    final scrollable = find
        .descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(find.text('Adventure'), 300,
        scrollable: scrollable);
    await tester.pumpAndSettle();
    expect(find.text('Adventure'), findsOneWidget);
    expect(find.text('Comedy'), findsOneWidget);
    expect(find.text('Aventure'), findsNothing);
    await tester.scrollUntilVisible(find.byType(TextFormField), -300,
        scrollable: scrollable);
    expect(find.text('Continue'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Camille');
    await tester.scrollUntilVisible(
      find.text('Create profile'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Create profile'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Unsaved changes will be lost. Leave anyway?'),
        findsOneWidget);
    expect(find.text('Leave'), findsOneWidget);
  });

  testWidgets('D-pad selects an avatar from the grid', (tester) async {
    String? selectedUrl;
    await tester.pumpWidget(
      _localizedApp(
        Scaffold(
          body: SingleChildScrollView(
            child: AvatarPickerGrid(
              categoryId: 'characters',
              selectedImageUrl: '',
              onAvatarSelected: (url) => selectedUrl = url,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    FocusScope.of(tester.element(find.byType(AvatarPickerGrid))).nextFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();

    expect(selectedUrl, selectableOrbit3DAvatars[1].imageUrl);
    for (var i = 0; i < 5; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(selectedUrl, contains('/avatar_collection/char_'));
  });

  testWidgets('D-pad moves from profile name to next and into settings',
      (tester) async {
    await tester.pumpWidget(
      _localizedApp(const ProfileEditScreen()),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.scrollUntilVisible(
      find.byType(TextFormField),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Camille');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    await tester.pumpAndSettle();

    expect(
        FocusManager.instance.primaryFocus?.debugLabel, 'profile.firstGenre');
  });

  testWidgets('TV continue validates the name and keeps D-pad editing',
      (tester) async {
    final tvMode = TvModeNotifier()..enable();
    addTearDown(tvMode.dispose);
    await tester.pumpWidget(
      _localizedApp(
        const ProfileEditScreen(),
        locale: const Locale('fr'),
        tvMode: tvMode,
      ),
    );
    final scrollable = find
        .descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byType(TextFormField),
      300,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    final editable = find.descendant(
      of: find.byType(TextFormField),
      matching: find.byType(EditableText),
    );
    final name = tester.widget<EditableText>(editable);
    name.focusNode.requestFocus();
    await tester.pump();

    expect(tester.widget<EditableText>(editable).readOnly, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'profile.continue');
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'profile.name');
    expect(find.text('Obligatoire'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(tester.widget<EditableText>(editable).readOnly, isFalse);
    await tester.enterText(find.byType(TextFormField), 'Zoë 李');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(
        FocusManager.instance.primaryFocus?.debugLabel, 'profile.firstGenre');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'profile.continue');
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(
        FocusManager.instance.primaryFocus?.debugLabel, 'profile.firstGenre');
    expect(name.controller.text, 'Zoë 李');
  });

  testWidgets('continue button validates and advances on tap', (tester) async {
    await tester.pumpWidget(
      _localizedApp(const ProfileEditScreen(), locale: const Locale('fr')),
    );
    final scrollable = find
        .descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Continuer'),
      300,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.text('Obligatoire'), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'profile.name');

    await tester.enterText(find.byType(TextFormField), 'Camille');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continuer'));
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(
        FocusManager.instance.primaryFocus?.debugLabel, 'profile.firstGenre');
  });

  testWidgets('TV can reach continue from the name in RTL', (tester) async {
    final tvMode = TvModeNotifier()..enable();
    addTearDown(tvMode.dispose);
    await tester.pumpWidget(
      _localizedApp(
        const ProfileEditScreen(),
        locale: const Locale('ar'),
        tvMode: tvMode,
      ),
    );
    final scrollable = find
        .descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byType(TextFormField),
      300,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    final editable = find.descendant(
      of: find.byType(TextFormField),
      matching: find.byType(EditableText),
    );
    tester.widget<EditableText>(editable).focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'profile.continue');
  });
}
