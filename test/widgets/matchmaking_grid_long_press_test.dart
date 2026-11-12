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
import 'package:orbit_3d_flutter/services/storage_service.dart';

class _MemoryStorage extends StorageService {
  final settings = <String, dynamic>{};

  @override
  dynamic getSetting(String key) => settings[key];

  @override
  Future<void> setSetting(String key, dynamic value) async {
    settings[key] = value;
  }
}

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

  testWidgets(
      'held OK opens the group decision without selecting or confirming',
      (tester) async {
    final storage = _MemoryStorage();
    final reco = Recommendation.fromMetadata(
      kind: RecommendationKind.movie,
      title: 'Test',
    );
    final grouped = GroupReco(reco: reco, affinities: [0.5, 0.6]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        preferencesProvider.overrideWith(_TestPreferences.new),
        currentProfileProvider.overrideWithBuild((ref, notifier) => profile),
        profilesProvider.overrideWith((ref) async => [profile, other]),
        matchmakingGroupTabProvider.overrideWith(
          (ref, key) async => (movies: [grouped], series: [grouped]),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: MatchmakingTab(
            kind: RecommendationKind.movie,
            initialGroup: ['one', 'two'],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    Focus.of(tester.element(find.byType(MediaCard))).requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('Film déjà vu'), findsOneWidget);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('Film déjà vu'), findsOneWidget);
    expect(storage.settings, isEmpty);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Confirmer'))
            .onPressed,
        isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(storage.settings, isEmpty);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Confirmer'))
            .onPressed,
        isNotNull);
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(storage.settings['seen_recos_one'], contains(reco.id));
    Focus.of(tester.element(find.byType(MediaCard))).requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pas intéressé'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(storage.settings['dismissed_recos_one'], contains(reco.id));
  });

  testWidgets('selected group profile has a halo and contrasting color',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentProfileProvider.overrideWithBuild((ref, notifier) => profile),
        profilesProvider.overrideWith((ref) async => [profile, other]),
        matchmakingGroupTabProvider.overrideWith(
          (ref, key) async => (movies: <GroupReco>[], series: <GroupReco>[]),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MatchmakingTab(
            kind: RecommendationKind.movie,
            initialGroup: ['one', 'two'],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final chip = find.widgetWithText(FilterChip, 'Camille');
    final container = find.byKey(const ValueKey('matchmaking-profile-two'));
    BoxDecoration decoration() =>
        tester.widget<AnimatedContainer>(container).decoration!
            as BoxDecoration;
    expect(tester.widget<FilterChip>(chip).selected, isTrue);
    expect(decoration().boxShadow, isNotEmpty);
    expect(tester.widget<FilterChip>(chip).selectedColor,
        Theme.of(tester.element(chip)).colorScheme.primary);
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(chip).selected, isFalse);
    expect(decoration().boxShadow, isEmpty);
  });
}
