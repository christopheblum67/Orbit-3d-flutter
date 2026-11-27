import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/cast_carousel.dart';
import 'package:orbit_3d_flutter/models/cast.dart';

void main() {
  for (final compact in [false, true]) {
    testWidgets('actor carousel stops at horizontal edges: compact=$compact',
        (tester) async {
      final actors = [
        for (var i = 0; i < 10; i++)
          Actor(id: '$i', name: 'Actor $i', character: '', profilePath: ''),
      ];
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: compact
                ? CompactCastCarousel(actors: actors, maxVisible: 10)
                : CastCarousel(actors: actors),
          ),
        ),
      ));
      Focus.of(tester.element(find.text('Actor 0'))).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(Focus.of(tester.element(find.text('Actor 0'))).hasPrimaryFocus,
          isTrue);
      for (var i = 0; i < 12; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
      }
      expect(Focus.of(tester.element(find.text('Actor 9'))).hasPrimaryFocus,
          isTrue);
    });
  }
}
