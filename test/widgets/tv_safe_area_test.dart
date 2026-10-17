import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_safe_area.dart';
import 'package:orbit_3d_flutter/providers/tv_mode_provider.dart';

void main() {
  testWidgets('TvSafeArea applique des insets en mode TV', (tester) async {
    final container = ProviderContainer();
    container.read(tvModeControllerProvider).enable();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: TvSafeArea(
              child: SizedBox(
                width: 400,
                height: 300,
                child: Text('TV Content'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TvSafeArea), findsOneWidget);
    expect(find.text('TV Content'), findsOneWidget);
  });

  testWidgets('TvSafeArea sans mode TV n\'applique pas d\'overscan', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: TvSafeArea(
              child: SizedBox(
                width: 400,
                height: 300,
                child: Text('Mobile Content'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TvSafeArea), findsOneWidget);
    expect(find.text('Mobile Content'), findsOneWidget);
  });
}
