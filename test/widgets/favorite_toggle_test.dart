import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/features/favorites/widgets/favorite_toggle.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/favorites_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('favorite_toggle_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets(
      'cœur rempli et rouge quand l\'entrée (sans profileId) est déjà favorite du profil courant',
      (tester) async {
    const entry = FavoriteEntry(
      type: ContentType.vod,
      id: '42',
      title: 'Le Film',
      streamUrl: 'http://cdn/vod/42.mkv',
    );

    late FavoritesService service;
    late ProviderContainer container;
    await tester.runAsync(() async {
      service = FavoritesService();
      await service.init();
      container = ProviderContainer(
        overrides: [
          favoritesServiceProvider.overrideWithValue(service),
          currentProfileProvider.overrideWithBuild(
            (ref, notifier) => UserProfile(
              id: 'test_profile',
              firstName: 'Test',
              dateOfBirth: DateTime(2000, 1, 1),
              gender: 'male',
              favoriteGenres: const [],
            ),
          ),
        ],
      );
      final notifier = container.read(favoritesProvider.notifier);
      for (var i = 0;
          i < 100 && notifier.forType(ContentType.vod).isNotEmpty;
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await notifier.toggle(entry);
    });
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: FavoriteToggle(entry: entry)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(
      find.descendant(
        of: find.byType(FavoriteToggle),
        matching: find.byType(Icon),
      ),
    );
    expect(icon.icon, Icons.favorite);
    expect(icon.color, const Color(0xFFFF5252));
  });
}