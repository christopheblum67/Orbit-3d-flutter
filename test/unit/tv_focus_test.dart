import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';

void main() {
  testWidgets('TvFocus without an action lets activation keys bubble',
      (tester) async {
    var parentHandledActivation = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter) {
                  parentHandledActivation = true;
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: const TvFocus(
                autofocus: true,
                child: SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);

    expect(parentHandledActivation, isTrue);
  });

  Future<void> pumpFocus(
    WidgetTester tester, {
    VoidCallback? onActivate,
    VoidCallback? onLongPress,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TvFocus(
              autofocus: true,
              onActivate: onActivate,
              onLongPress: onLongPress,
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('short press activates, long press only fires onLongPress',
      (tester) async {
    var activations = 0;
    var longPresses = 0;
    await pumpFocus(
      tester,
      onActivate: () => activations++,
      onLongPress: () => longPresses++,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(activations, 1);
    expect(longPresses, 0);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    expect(longPresses, 1);
    expect(activations, 1);
  });

  testWidgets('long press via child registration (MediaCard-style)',
      (tester) async {
    var activations = 0;
    var cardLongPresses = 0;
    var favToggles = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TvFocus(
              autofocus: true,
              onActivate: () => activations++,
              child: Builder(builder: (context) {
                registerTvLongPress(context, () => cardLongPresses++);
                return const SizedBox(width: 100, height: 100);
              }),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(activations, 1);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    expect(cardLongPresses, 1);
    expect(activations, 1);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TvFocus(
              autofocus: true,
              onActivate: () => activations++,
              child: Builder(builder: (context) {
                registerTvLongPress(context, () => cardLongPresses++);
                registerTvFavoriteToggle(context, () => favToggles++);
                return const SizedBox(width: 100, height: 100);
              }),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    expect(favToggles, 1);
    expect(cardLongPresses, 1);
    expect(activations, 1);
  });

  testWidgets('without onLongPress activation stays on key down',
      (tester) async {
    var activations = 0;
    await pumpFocus(tester, onActivate: () => activations++);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    expect(activations, 1);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    expect(activations, 1);
  });
}