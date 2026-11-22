import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/playback_error_policy.dart';
import 'package:orbit_3d_flutter/features/player/widgets/player_error_view.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations_fr.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';

void main() {
  testWidgets('player recovery messages use the selected language',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PlayerErrorView(
            errorDescription: null,
            externalPlaybackLaunched: true,
            contentType: PlaybackContentType.vod,
            onRetry: () {},
            onProviderWebsite: () {},
            nextEpisodeTitle: 'Episode 2',
            nextEpisodeSeconds: 5,
            onNextEpisode: () {},
          ),
        ),
      ),
    );
    expect(find.text('Playback opened in an external player'), findsOneWidget);
    expect(find.text('Next episode: Episode 2 (5 s)'), findsOneWidget);
    expect(find.text('Lecture ouverte dans un lecteur externe'), findsNothing);
  });

  testWidgets('error presentation preserves priority and website action',
      (tester) async {
    final l = AppLocalizationsFr();
    var opened = 0;
    Future<void> render({
      required String? error,
      required bool external,
      bool greenScreenDetected = false,
      required PlaybackContentType contentType,
    }) =>
        tester.pumpWidget(
          MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: PlayerErrorView(
                errorDescription: error,
                externalPlaybackLaunched: external,
                greenScreenDetected: greenScreenDetected,
                contentType: contentType,
                onRetry: () {},
                onProviderWebsite: () => opened++,
              ),
            ),
          ),
        );
    await render(
      error: '403 Cloudflare',
      external: false,
      contentType: PlaybackContentType.vod,
    );
    expect(find.text(l.cloudflareCheckRequired), findsOneWidget);
    await tester.ensureVisible(find.text(l.openProviderWebsite));
    await tester.tap(find.text(l.openProviderWebsite));
    expect(opened, 1);
    await render(
      error: '401 Source error 403',
      external: false,
      contentType: PlaybackContentType.live,
    );
    expect(find.text('Flux temporairement bloqué par le fournisseur'),
        findsOneWidget);
    expect(find.text(l.openProviderWebsite), findsOneWidget);
    await render(
      error: '401 403',
      external: true,
      contentType: PlaybackContentType.live,
    );
    expect(
        find.text('Lecture ouverte dans un lecteur externe'), findsOneWidget);
    await render(
      error: null,
      external: false,
      contentType: PlaybackContentType.vod,
    );
    expect(find.text(l.playbackUnavailableTitle), findsOneWidget);
    expect(find.text(l.openProviderWebsite), findsNothing);
    await render(
      error: protectedPlaybackUnsupported,
      external: false,
      contentType: PlaybackContentType.vod,
    );
    expect(find.text(l.protectedPlaybackUnsupportedMessage), findsOneWidget);
    expect(find.text(l.playbackUnavailableMessage), findsNothing);
    await render(
      error: null,
      external: false,
      greenScreenDetected: true,
      contentType: PlaybackContentType.vod,
    );
    expect(find.text(l.greenScreenDetectedTitle), findsOneWidget);
    expect(find.text(l.greenScreenDetectedMessage), findsOneWidget);
  });
}
