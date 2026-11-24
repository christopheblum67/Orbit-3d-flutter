import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/widgets/player_footer_bars.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

void main() {
  testWidgets('live footer keeps actions accessible to the remote',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = VideoPlayerController.networkUrl(
      Uri.parse('https://example.test/stream'),
    );
    addTearDown(controller.dispose);
    var playPause = 0;
    var next = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ContentFooterBar(
              child: LiveFooterBar(
                channel: null,
                fallbackTitle: 'Live',
                index: 0,
                total: 2,
                isPlaying: false,
                showSeek: false,
                onExit: () {},
                onNext: () => next++,
                onTogglePlayPause: () => playPause++,
                streamDetails: FooterStreamDetails(
                  onPressed: () {},
                ),
                onToggleNightFocus: () {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Live'), findsOneWidget);
    final pauseButton = find.byTooltip('Lire');
    final nextButton = find.byTooltip('Chaîne suivante');
    expect(pauseButton, findsOneWidget);
    expect(nextButton, findsOneWidget);
    Focus.of(tester.element(find.byIcon(Icons.play_arrow_rounded)))
        .requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(playPause, 1);
    Focus.of(tester.element(find.byIcon(Icons.skip_next_rounded)))
        .requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(next, 1);
    expect(tester.takeException(), isNull);
  });
}
