import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/widgets/cast_button.dart';
import 'package:orbit_3d_flutter/features/player/widgets/player_footer_bars.dart';
import 'package:orbit_3d_flutter/features/player/widgets/player_footer_content.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

void main() {
  for (final type in PlaybackContentType.values) {
    testWidgets('footer wiring for ${type.name}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final controller = VideoPlayerController.networkUrl(
        Uri.parse('https://example.test/stream'),
      );
      addTearDown(controller.dispose);
      final channel = Channel(
        id: '1',
        name: 'Channel',
        logoUrl: '',
        streamUrl: '',
        group: '',
      );
      var back = 0;
      var forward = 0;
      var progress = 0;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ContentFooterBar(
                child: PlayerFooterContent(
                  controller: controller,
                  contentType: type,
                  streamUrl: 'https://example.test/stream',
                  progressId: 'progress',
                  channel: channel,
                  title: null,
                  subtitle: 'Subtitle',
                  seriesName: 'Series',
                  episodeLabel: 'Episode',
                  rating: 7,
                  genre: 'Drama',
                  index: 1,
                  total: 3,
                  onExit: () {},
                  onPrevious: () {},
                  onNext: () {},
                  onTogglePlayPause: () {},
                  onPip: null,
                  onSeekBack30: () => back++,
                  onSeekForward30: () => forward++,
                  onToggleNightFocus: () {},
                  onDetailsOpened: () {},
                  onDetailsClosed: () {},
                  onProgressInteraction: () => progress++,
                ),
              ),
            ),
          ),
        ),
      );
      final cast = tester.widget<CastButton>(find.byType(CastButton));
      expect(cast.isLive, type == PlaybackContentType.live);
      expect(cast.streamUrl, 'https://example.test/stream');
      if (type == PlaybackContentType.live ||
          type == PlaybackContentType.replay) {
        final footer = tester.widget<LiveFooterBar>(find.byType(LiveFooterBar));
        expect(footer.channel, same(channel));
        expect(
          footer.fallbackTitle,
          type == PlaybackContentType.live ? 'Channel' : 'Replay',
        );
        expect(footer.showSeek, type == PlaybackContentType.replay);
        expect(footer.streamDetails.mediaKey, 'progress');
        expect(footer.streamDetails.isLive, type == PlaybackContentType.live);
        if (type == PlaybackContentType.live) {
          expect(footer.controller, isNull);
          expect(footer.onSeekBack30, isNull);
          expect(footer.onProgressInteraction, isNull);
        } else {
          expect(footer.controller, same(controller));
          footer.onSeekBack30!();
          footer.onSeekForward30!();
          footer.onProgressInteraction!();
        }
      } else {
        final footer = tester.widget<VodFooterBar>(find.byType(VodFooterBar));
        expect(footer.title, 'Series');
        expect(footer.episodeLabel, 'Episode');
        expect(footer.streamDetails.mediaKey, 'progress');
        expect(footer.streamDetails.isLive, isFalse);
        footer.onSeekBack30();
        footer.onSeekForward30();
        footer.onProgressInteraction();
      }
      expect(back, type == PlaybackContentType.live ? 0 : 1);
      expect(forward, type == PlaybackContentType.live ? 0 : 1);
      expect(progress, type == PlaybackContentType.live ? 0 : 1);
    });
  }
}
