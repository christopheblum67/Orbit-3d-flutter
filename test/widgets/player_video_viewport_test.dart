import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/player/widgets/player_video_viewport.dart';

void main() {
  testWidgets('fills a matching screen without a frame', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox.expand(
          child: PlayerVideoViewport(
            aspectRatio: 4 / 3,
            child: ColoredBox(key: Key('video'), color: Colors.blue),
          ),
        ),
      ),
    );

    expect(
      tester.getRect(find.byKey(const Key('video'))),
      const Rect.fromLTWH(0, 0, 800, 600),
    );
  });

  testWidgets('preserves the video aspect ratio within the screen',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox.expand(
          child: PlayerVideoViewport(
            aspectRatio: 16 / 9,
            child: ColoredBox(key: Key('video'), color: Colors.blue),
          ),
        ),
      ),
    );

    final rect = tester.getRect(find.byKey(const Key('video')));
    expect(rect.width, 800);
    expect(rect.height, 450);
    expect(rect.top, 75);
  });

  testWidgets('covers the screen without changing proportions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox.expand(
          child: PlayerVideoViewport(
            aspectRatio: 16 / 9,
            cover: true,
            child: ColoredBox(key: Key('video'), color: Colors.blue),
          ),
        ),
      ),
    );
    final rect = tester.getRect(find.byKey(const Key('video')));
    expect(rect.width, closeTo(1066.67, 0.1));
    expect(rect.height, closeTo(600, 0.1));
    expect(rect.left, closeTo(-133.33, 0.1));
  });
}
