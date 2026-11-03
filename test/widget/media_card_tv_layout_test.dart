import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/media_card.dart';

void main() {
  Future<double> maxCardWidth(WidgetTester tester, Size screenSize) async {
    late double maxExtent;

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: screenSize),
        child: Builder(
          builder: (context) {
            final delegate = mediaCardGridDelegate(
              context,
              childAspectRatio: 0.55,
            );
            maxExtent = delegate.maxCrossAxisExtent;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    return maxExtent;
  }

  testWidgets('uses smaller poster cards on wide TV layouts', (tester) async {
    expect(
      await maxCardWidth(tester, const Size(1280, 720)),
      160,
    );
    expect(await maxCardWidth(tester, const Size(390, 844)), 200);
  });
}
