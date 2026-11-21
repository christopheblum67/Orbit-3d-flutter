import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/avatar_catalog.dart';
import 'package:orbit_3d_flutter/core/widgets/avatar_picker_grid.dart';
import 'package:orbit_3d_flutter/core/widgets/profile_avatar.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';

void main() {
  group('avatar_catalog', () {
    test('expose les catégories attendues, dans l\'ordre', () {
      expect(avatarCategoryIds, [
        'all',
        'characters',
        'superheroes',
        'animals',
        'nature',
        'youth',
      ]);
    });

    test('les avatars historiques et les nouveaux avatars sont disponibles',
        () {
      expect(orbit3DAvatars.length, 322);
      const expected = {
        'characters': 62,
        'superheroes': 62,
        'animals': 74,
        'nature': 74,
        'youth': 50,
      };
      for (final e in expected.entries) {
        expect(
          orbit3DAvatars.where((a) => a.category == e.key).length,
          e.value,
          reason: e.key,
        );
      }
    });

    test('ids et valeurs uniques, noms non vides', () {
      expect(orbit3DAvatars.map((a) => a.id).toSet().length, 322);
      expect(orbit3DAvatars.map((a) => a.imageUrl).toSet().length, 322);
      for (final a in orbit3DAvatars) {
        expect(a.name.trim(), isNotEmpty, reason: a.id);
      }
    });

    test('seule la nouvelle collection est proposée aux profils', () {
      expect(selectableOrbit3DAvatars, hasLength(250));
      for (final category in avatarCategoryIds.skip(1)) {
        expect(selectableOrbit3DAvatars.where((a) => a.category == category),
            hasLength(50),
            reason: category);
      }
      expect(
          selectableOrbit3DAvatars.every((a) =>
              a.imageUrl.startsWith('asset:assets/images/avatar_collection/')),
          isTrue);
      expect(orbit3DAvatars.any((a) => a.id == 'an09'), isTrue);
    });

    test('chaque avatar pointe vers un fichier local existant', () {
      for (final a in orbit3DAvatars) {
        expect(a.isLocalAsset, isTrue, reason: a.id);
        final path = a.imageUrl.substring(avatarAssetPrefix.length);
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });

    testWidgets('les avatars sont inclus dans le bundle Flutter',
        (tester) async {
      for (final avatar in orbit3DAvatars) {
        final path = avatar.imageUrl.substring(avatarAssetPrefix.length);
        expect((await rootBundle.load(path)).lengthInBytes, greaterThan(0),
            reason: path);
      }
    });

    test('les libellés sont localisés et distincts dans les 6 langues',
        () async {
      for (final code in ['fr', 'en', 'de', 'es', 'it', 'ar']) {
        final l = await AppLocalizations.delegate.load(Locale(code));
        final labels = [
          for (final id in avatarCategoryIds) avatarCategoryLabel(l, id),
        ];
        expect(labels.every((e) => e.trim().isNotEmpty), isTrue, reason: code);
        expect(labels.toSet().length, labels.length, reason: code);
      }
    });
  });

  group('sélecteur et affichage', () {
    Widget host(Widget child) => ProviderScope(
            child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ));

    testWidgets('filtre par catégorie et renvoie la valeur asset',
        (tester) async {
      String? picked;
      await tester.binding.setSurfaceSize(const Size(900, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(host(AvatarPickerGrid(
        selectedImageUrl: '',
        onAvatarSelected: (v) => picked = v,
      )));
      expect(find.byType(Image), findsNWidgets(250));
      await tester.tap(find.text('Nature'));
      await tester.pump();
      expect(find.byType(Image), findsNWidgets(50));
      await tester.tap(find.byType(Image).first);
      await tester.pump();
      expect(picked, 'asset:assets/images/avatar_collection/nat_01.png');
    });

    testWidgets('ProfileAvatar affiche un asset et garde les anciens formats',
        (tester) async {
      UserProfile p(String url) => UserProfile(
            id: 'x',
            firstName: 'Zoé',
            dateOfBirth: DateTime(2000),
            gender: 'Autre',
            favoriteGenres: const [],
            avatarUrl: url,
          );
      await tester.pumpWidget(host(ProfileAvatar(
        profile: p('asset:assets/images/avatars/an01.png'),
      )));
      expect(find.byType(Image), findsOneWidget);
      await tester.pumpWidget(host(ProfileAvatar(profile: p('icone:face'))));
      expect(find.byIcon(Icons.face), findsOneWidget);
      await tester.pumpWidget(host(ProfileAvatar(profile: p('orbital:1'))));
      expect(find.text('Z'), findsOneWidget);
    });

    testWidgets('le focus TV des avatars est circulaire', (tester) async {
      final tvMode = TvModeNotifier()..enable();
      addTearDown(tvMode.dispose);
      await tester.pumpWidget(ProviderScope(
        overrides: [tvModeNotifierProvider.overrideWithValue(tvMode)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: AvatarPickerGrid(
                categoryId: 'characters',
                selectedImageUrl: '',
                onAvatarSelected: (_) {},
              ),
            ),
          ),
        ),
      ));
      final tile = find.byType(TvFocus).first;
      Focus.of(tester.element(find.byType(Image).first)).requestFocus();
      await tester.pumpAndSettle();
      final decoration = tester
          .widget<AnimatedContainer>(
            find
                .descendant(of: tile, matching: find.byType(AnimatedContainer))
                .first,
          )
          .decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
    });
  });
}
