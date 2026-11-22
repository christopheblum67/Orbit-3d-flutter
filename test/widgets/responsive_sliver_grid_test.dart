import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/responsive_grid.dart';

void main() {
  for (final compact in [false, true]) {
    for (final padded in [false, true]) {
      testWidgets(
          'responsive ${compact ? 'compact' : 'content'} sliver '
          '${padded ? 'accounts for padding' : 'renders without padding'}',
          (tester) async {
        final children = SliverChildBuilderDelegate(
          (context, index) => Text('Item $index'),
          childCount: 12,
        );
        final padding =
            padded ? const EdgeInsets.symmetric(horizontal: 100) : null;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: CustomScrollView(
                  slivers: [
                    if (compact)
                      ResponsiveSliverGrid.compact(
                        key: null,
                        childrenDelegate: children,
                        padding: padding,
                      )
                    else
                      ResponsiveSliverGrid.content(
                        key: null,
                        childrenDelegate: children,
                        padding: padding,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Item 0'), findsOneWidget);
        final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
        final delegate =
            grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        expect(delegate.crossAxisCount,
            compact ? (padded ? 6 : 8) : (padded ? 3 : 4));
        expect(
            find.byType(SliverPadding), padded ? findsOneWidget : findsNothing);
      });
    }
  }
}
