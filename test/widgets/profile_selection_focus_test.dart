import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/profile_avatar.dart';
import 'package:orbit_3d_flutter/features/profile/profile_selection_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

void main() {
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
    await tester.pumpWidget(ProviderScope(
      overrides: [
        profilesProvider.overrideWith((ref) async => [profile, second]),
        currentProfileProvider.overrideWithBuild((ref, notifier) => null),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
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
