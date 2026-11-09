import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/media_card.dart';
import 'package:orbit_3d_flutter/features/matchmaking/widgets/matchmaking_tab.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/recommendation.dart';
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/matchmaking_provider.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

class _TestPreferences extends PreferencesNotifier {
  @override
  UserPreferences build() => const UserPreferences();
}

void main() {
  final profile = UserProfile(
    id: 'one',
    firstName: 'Alex',
    dateOfBirth: DateTime(2000),
    gender: '',
    favoriteGenres: const [],
  );
  final other = profile.copyWith(id: 'two', firstName: 'Camille');

  for (final kind in RecommendationKind.values) {
    for (final group in [false, true]) {
      testWidgets('${kind.name} ${group ? "group" : "solo"} opens the menu',
          (tester) async {
        final reco = Recommendation.fromMetadata(kind: kind, title: 'Test');
        final scored = ScoredReco(reco, 1, 0, 0);
        final grouped = GroupReco(reco: reco, affinities: [0.5, 0.6]);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              preferencesProvider.overrideWith(_TestPreferences.new),
              currentProfileProvider
                  .overrideWithBuild((ref, notifier) => profile),
              profilesProvider.overrideWith((ref) async => [profile, other]),
              matchmakingTabProvider.overrideWith(
                (ref, id) async => (movies: [scored], series: [scored]),
              ),
              matchmakingGroupTabProvider.overrideWith(
                (ref, key) async => (movies: [grouped], series: [grouped]),
              ),
            ],
            child: MaterialApp(
              locale: const Locale('fr'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: MatchmakingTab(
                  kind: kind,
                  initialGroup: group ? ['one', 'two'] : null,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        Focus.of(tester.element(find.byType(MediaCard))).requestFocus();
        await tester.pump();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
        await tester.pumpAndSettle();
        await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
        await tester.pumpAndSettle();

        expect(
          find.text(kind == RecommendationKind.movie
              ? 'Film déjà vu'
              : 'Série déjà vue'),
          findsOneWidget,
        );
        expect(find.text('Pas intéressé'), findsOneWidget);
        await tester.tap(find.text('Annuler'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
