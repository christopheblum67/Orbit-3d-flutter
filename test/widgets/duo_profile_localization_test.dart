import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/features/matchmaking/duo_profile_selection_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

void main() {
  testWidgets('duo selection follows the locale and selected profiles',
      (tester) async {
    final first = UserProfile(
      id: 'one',
      firstName: 'Alex',
      dateOfBirth: DateTime(2000),
      gender: '',
      favoriteGenres: const [],
    );
    final second = first.copyWith(id: 'two', firstName: 'Sam');
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const DuoProfileSelectionScreen(),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        profilesProvider.overrideWith((ref) async => [first, second]),
        currentProfileProvider.overrideWithBuild((ref, notifier) => first),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Duo mode'), findsOneWidget);
    expect(find.textContaining('With “Alex”'), findsOneWidget);
    expect(find.text('Start Duo'), findsOneWidget);
    await tester.tap(find.text('Sam'));
    await tester.pump();
    expect(find.text('2 profiles selected — ready for Duo'), findsOneWidget);
    expect(find.text('Selected'), findsOneWidget);
  });
}
