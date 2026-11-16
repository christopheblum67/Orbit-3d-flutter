import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/orbit_cached_image.dart';

void main() {
  testWidgets('bounds decoding to the displayed width and pixel ratio',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 56,
            height: 84,
            child: OrbitCachedImage(imageUrl: 'https://example.test/a'),
          ),
        ),
      ),
    );
    final image =
        tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
    final context = tester.element(find.byType(OrbitCachedImage));
    expect(
      image.memCacheWidth,
      (56 * MediaQuery.devicePixelRatioOf(context)).ceil(),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('retries a transient failure once, but not a permanent failure',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OrbitCachedImage(imageUrl: 'https://example.test/b'),
      ),
    );
    final finder = find.byType(CachedNetworkImage);
    final context = tester.element(finder);
    var image = tester.widget<CachedNetworkImage>(finder);
    image.errorWidget!(
      context,
      image.imageUrl,
      const SocketException('offline'),
    );
    await tester.pump(const Duration(seconds: 2));
    image = tester.widget<CachedNetworkImage>(finder);
    expect(image.key, const ValueKey(1));
    image.errorWidget!(
      context,
      image.imageUrl,
      const SocketException('offline'),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(tester.widget<CachedNetworkImage>(finder).key, const ValueKey(1));

    await tester.pumpWidget(
      const MaterialApp(
        home: OrbitCachedImage(imageUrl: 'https://example.test/c'),
      ),
    );
    image = tester.widget<CachedNetworkImage>(finder);
    image.errorWidget!(
      tester.element(finder),
      image.imageUrl,
      const HttpExceptionWithStatus(404, 'missing'),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(tester.widget<CachedNetworkImage>(finder).key, const ValueKey(0));
    image.errorWidget!(
      tester.element(finder),
      image.imageUrl,
      const HttpExceptionWithStatus(429, 'rate limited'),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(tester.widget<CachedNetworkImage>(finder).key, const ValueKey(0));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('cancels a pending retry when removed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OrbitCachedImage(imageUrl: 'https://example.test/d'),
      ),
    );
    final finder = find.byType(CachedNetworkImage);
    final image = tester.widget<CachedNetworkImage>(finder);
    image.errorWidget!(
      tester.element(finder),
      image.imageUrl,
      const SocketException('offline'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
