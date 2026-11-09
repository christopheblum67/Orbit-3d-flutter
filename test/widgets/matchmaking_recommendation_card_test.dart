import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/media_card.dart';
import 'package:orbit_3d_flutter/features/matchmaking/widgets/matchmaking_tab.dart';
import 'package:orbit_3d_flutter/features/matchmaking/widgets/prolong_decision_sheet.dart';
import 'package:orbit_3d_flutter/models/user_preferences.dart';
import 'package:orbit_3d_flutter/models/recommendation.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';

class _TestPreferences extends PreferencesNotifier {
  @override
  UserPreferences build() => const UserPreferences();
}

void main() {
  for (final kind in RecommendationKind.values) {
    testWidgets('OK long opens decision menu without opening ${kind.name}',
        (tester) async {
      var opened = 0;
      final reco = Recommendation.fromMetadata(
        kind: kind,
        title: 'Titre test',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [preferencesProvider.overrideWith(_TestPreferences.new)],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => Center(
                  child: SizedBox(
                    width: 180,
                    height: 300,
                    child: MatchmakingRecommendationCard(
                      reco: reco,
                      onOpen: () => opened++,
                      onLongPress: () =>
                          showProlongDecision(context, ref, reco),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      Focus.of(tester.element(find.byType(MediaCard))).requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      expect(opened, 1);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(opened, 1);
      final seen =
          kind == RecommendationKind.movie ? 'Film déjà vu' : 'Série déjà vue';
      expect(find.text(seen), findsOneWidget);
      expect(find.text('Pas intéressé'), findsOneWidget);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.text(seen), findsNothing);
      expect(opened, 1);
    });
  }
}
