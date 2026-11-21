import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/profile_avatar.dart';
import 'package:orbit_3d_flutter/core/widgets/home_menu_drawer.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/features/profile/profile_selection_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

void main() {
  testWidgets('profile selection focuses the active profile', (tester) async {
    final tvMode = TvModeNotifier()..enable();
    addTearDown(tvMode.dispose);
    final profile = UserProfile(
      id: 'one',
      firstName: 'Camille',
      dateOfBirth: DateTime(1990),
      gender: '',
      favoriteGenres: const [],
    );
    final activeProfile = UserProfile(
      id: 'two',
      firstName: 'Alex',
      dateOfBirth: DateTime(1990),
      gender: '',
      favoriteGenres: const [],
    );
    final router = GoRouter(
      initialLocation: '/profiles',
      routes: [
        GoRoute(
          path: '/profiles',
          builder: (_, __) => const ProfileSelectionScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tvModeNotifierProvider.overrideWithValue(tvMode),
          profilesProvider
              .overrideWith((ref) async => [profile, activeProfile]),
          currentProfileProvider
              .overrideWithBuild((ref, notifier) => activeProfile),
        ],
        child: MaterialApp.router(
          locale: const Locale('en'),
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Select a profile to continue'), findsOneWidget);
    expect(
      find.text('Arrows + OK to navigate · Tap a card to select'),
      findsOneWidget,
    );
    expect(find.text('Active'), findsOneWidget);

    final profileBubbles = [
      for (final avatar in find.byType(ProfileAvatar).evaluate())
        find
            .ancestor(
              of: find.byWidget(avatar.widget),
              matching: find.byType(AnimatedScale),
            )
            .first,
    ];
    expect(tester.widget<AnimatedScale>(profileBubbles[0]).scale, 1);
    expect(tester.widget<AnimatedScale>(profileBubbles[1]).scale, 1.08);
    final menuIcon = find.byIcon(Icons.menu_rounded);
    expect(
      tester.widget<Opacity>(
        find.ancestor(of: menuIcon, matching: find.byType(Opacity)).first,
      ).opacity,
      0,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    await tester.pumpAndSettle();
    expect(find.byType(HomeMenuDrawer), findsOneWidget);
  });

  testWidgets('profile bubble is emphasized only on primary focus',
      (tester) async {
    final profile = UserProfile(
      id: 'one',
      firstName: 'Camille',
      dateOfBirth: DateTime(1990),
      gender: '',
      favoriteGenres: const [],
    );
    final second = UserProfile(
      id: 'two',
      firstName: 'Alex',
      dateOfBirth: DateTime(1990),
      gender: '',
      favoriteGenres: const [],
    );
    final router = GoRouter(
      initialLocation: '/profiles',
      routes: [
        GoRoute(
          path: '/profiles',
          builder: (_, __) => const ProfileSelectionScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profilesProvider.overrideWith((ref) async => [profile, second]),
          currentProfileProvider.overrideWithBuild((ref, notifier) => null),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final bubble = find
        .ancestor(
          of: find.byType(ProfileAvatar).first,
          matching: find.byType(AnimatedScale),
        )
        .first;
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Profile card');
    expect(tester.widget<AnimatedScale>(bubble).scale, 1.08);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Profile edit');
    expect(tester.widget<AnimatedScale>(bubble).scale, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Profile card');
    expect(tester.widget<AnimatedScale>(bubble).scale, 1.08);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Profile card');
    final secondBubble = find
        .ancestor(
          of: find.byType(ProfileAvatar).last,
          matching: find.byType(AnimatedScale),
        )
        .first;
    expect(tester.widget<AnimatedScale>(secondBubble).scale, 1.08);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Add profile');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Profile card');
    expect(tester.widget<AnimatedScale>(secondBubble).scale, 1.08);
  });
}
