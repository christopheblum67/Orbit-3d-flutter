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
}
