import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/utils/catalog_diagnostic.dart';

void main() {
  testWidgets('records a waiting operation and its completion', (tester) async {
    final messages = <String>[];
    final pending = Completer<int>();
    final result = traceCatalogStep(
      'vod',
      'network',
      () => pending.future,
      log: messages.add,
      warningAfter: const Duration(seconds: 1),
    );
    expect(messages.single, contains('kind=vod step=network state=start'));
    await tester.pump(const Duration(seconds: 1));
    expect(messages.last, contains('state=waiting'));
    pending.complete(42);
    await tester.pump();
    expect(await result, 42);
    expect(messages.last, contains('state=complete'));
    expect(messages.length, 3);
  });

  testWidgets('records only the error type and propagates the failure',
      (tester) async {
    final messages = <String>[];
    final result = traceCatalogStep<void>(
      'series',
      'parse',
      () async => throw const FormatException('sensitive content'),
      log: messages.add,
    );
    await expectLater(result, throwsFormatException);
    expect(messages.last, contains('state=failed'));
    expect(messages.last, contains('errorType=FormatException'));
    expect(messages.join(), isNot(contains('sensitive content')));
    await tester.pump(const Duration(seconds: 16));
    expect(messages.length, 2);
  });
}
