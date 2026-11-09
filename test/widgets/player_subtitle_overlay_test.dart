import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/widgets/player_subtitle_overlay.dart';
import 'package:orbit_3d_flutter/features/player/widgets/subtitle_overlay.dart';
import 'package:orbit_3d_flutter/providers/subtitle_providers.dart';
import 'package:orbit_3d_flutter/services/embedded_subtitles.dart';
import 'package:orbit_3d_flutter/services/subtitle_controller.dart';
import 'package:orbit_3d_flutter/services/subtitle_parser.dart';
import 'package:video_player/video_player.dart';

class _Subtitles extends SubtitleController {
  bool embedded = false;
  EmbeddedSubtitleCues? cues;
  SubtitleTrack? track;

  @override
  bool get hasActiveEmbedded => embedded;
  @override
  EmbeddedSubtitleCues? get liveEmbeddedCues => cues;
  @override
  SubtitleTrack? get activeTrack => track;

  void update({
    required bool useEmbedded,
    EmbeddedSubtitleCues? newCues,
    SubtitleTrack? newTrack,
  }) {
    embedded = useEmbedded;
    cues = newCues;
    track = newTrack;
    notifyListeners();
  }
}

void main() {
  testWidgets('overlay follows subtitle notifications and player position',
      (tester) async {
    final subtitles = _Subtitles();
    final video = VideoPlayerController.networkUrl(
      Uri.parse('https://example.test/stream'),
    );
    addTearDown(video.dispose);
    const track = SubtitleTrack(
      language: 'fr',
      label: 'French',
      cues: [
        SubtitleCue(startMs: 1000, endMs: 2000, text: 'First'),
        SubtitleCue(startMs: 3000, endMs: 4000, text: 'Second'),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subtitleControllerProvider.overrideWith((ref) => subtitles),
        ],
        child: MaterialApp(
          home: Scaffold(body: PlayerSubtitleOverlay(controller: video)),
        ),
      ),
    );
    expect(find.text('First'), findsNothing);
    subtitles.update(useEmbedded: false, newTrack: track);
    video.value =
        video.value.copyWith(position: const Duration(milliseconds: 1500));
    await tester.pump();
    expect(find.text('First'), findsOneWidget);
    video.value =
        video.value.copyWith(position: const Duration(milliseconds: 3500));
    await tester.pump();
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
    subtitles.update(
      useEmbedded: true,
      newTrack: track,
      newCues: const EmbeddedSubtitleCues(
        presentationTimeUs: 0,
        texts: ['Embedded'],
      ),
    );
    await tester.pump();
    expect(find.byType(VideoSubtitleOverlay), findsNothing);
    expect(find.text('Second'), findsNothing);
    expect(find.text('Embedded'), findsOneWidget);
    subtitles.update(
      useEmbedded: true,
      newCues: const EmbeddedSubtitleCues(
        presentationTimeUs: 1,
        texts: ['Updated'],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Updated'), findsOneWidget);
    expect(find.text('Embedded'), findsNothing);
    subtitles.update(useEmbedded: true, newTrack: track);
    await tester.pump();
    expect(find.byType(EmbeddedSubtitleOverlay), findsOneWidget);
    expect(find.byType(VideoSubtitleOverlay), findsNothing);
    expect(find.text('Second'), findsNothing);
    subtitles.update(useEmbedded: false, newTrack: track);
    await tester.pump();
    expect(find.text('Second'), findsOneWidget);
    subtitles.update(useEmbedded: false);
    await tester.pump();
    expect(find.text('Updated'), findsNothing);
    expect(find.text('Second'), findsNothing);
  });
}
