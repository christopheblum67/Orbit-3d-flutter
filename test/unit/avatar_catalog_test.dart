import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/avatar_catalog.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Vérifie la refonte du catalogue d'avatars : 4 nouvelles catégories
/// (Personnages, Smileys, Noir & Blanc, Pixels), disparition complète des
/// anciennes (Smileys 3D, Animaux, Fantasy, Sci-Fi, Nature) et libellés
/// affichés localisés dans les 6 langues.
void main() {
  const legacyCategories = [
    'Smileys 3D',
    'Animaux',
    'Fantasy',
    'Sci-Fi',
    'Nature',
  ];
  const expectedCategoryIds = [
    'all',
    'characters',
    'smileys',
    'blackWhite',
    'pixels',
  ];

  group('avatar_catalog', () {
    test('expose les identifiants de catégories attendus, dans l\'ordre', () {
      expect(avatarCategoryIds, expectedCategoryIds);
    });

    test('contient 72 avatars (9 styles x 8)', () {
      expect(orbit3DAvatars.length, 72);
    });

    test('les anciennes catégories ont totalement disparu', () {
      final categories = orbit3DAvatars.map((a) => a.category).toSet();
      for (final legacy in legacyCategories) {
        expect(
          categories.contains(legacy),
          isFalse,
          reason: 'catégorie héritée encore présente : $legacy',
        );
      }
    });

    test('chaque catégorie a le nombre d\'avatars attendu (styles x 8)', () {
      const expectedCounts = {
        'characters': 24, // avataaars + adventurer + micah
        'smileys': 16, // marbles + fun-emoji
        'blackWhite': 16, // lorelei-neutral + notionists-neutral
        'pixels': 16, // voxel-art + voxel-bot
      };
      for (final entry in expectedCounts.entries) {
        final count =
            orbit3DAvatars.where((a) => a.category == entry.key).length;
        expect(count, entry.value, reason: 'catégorie ${entry.key}');
      }
    });

    test('chaque style DiceBear est décliné en 8 variantes', () {
      const expectedStyles = {
        'avataaars': 8,
        'adventurer': 8,
        'micah': 8,
        'marbles': 8,
        'fun-emoji': 8,
        'lorelei-neutral': 8,
        'notionists-neutral': 8,
        'voxel-art': 8,
        'voxel-bot': 8,
      };
      final perStyle = <String, int>{};
      for (final avatar in orbit3DAvatars) {
        final match = RegExp(r'api\.dicebear\.com/10\.x/([^/]+)/')
            .firstMatch(avatar.imageUrl);
        expect(match, isNotNull, reason: 'URL inattendue : ${avatar.imageUrl}');
        final style = match!.group(1)!;
        perStyle[style] = (perStyle[style] ?? 0) + 1;
      }
      expect(perStyle, expectedStyles);
    });

    test('toutes les URLs ciblent l\'API 10.x en PNG', () {
      for (final avatar in orbit3DAvatars) {
        expect(
          avatar.imageUrl,
          startsWith('https://api.dicebear.com/10.x/'),
          reason: avatar.id,
        );
        expect(avatar.imageUrl, contains('/png?seed='), reason: avatar.id);
      }
    });

    test('la catégorie Noir & Blanc reste du noir sur blanc natif', () {
      // Les styles *-neutral* dessinent une encre noire (#000) sur un fond
      // blanc (#FFF) fourni nativement par DiceBear. Aucun fond forcé ne doit
      // remplacer ce blanc (un gris délaverait le contraste).
      final bw = orbit3DAvatars.where((a) => a.category == 'blackWhite');
      expect(bw, isNotEmpty);
      for (final avatar in bw) {
        expect(
          avatar.imageUrl,
          anyOf(
            contains('/lorelei-neutral/'),
            contains('/notionists-neutral/'),
          ),
          reason: avatar.id,
        );
        expect(
          avatar.imageUrl,
          isNot(contains('backgroundColor=')),
          reason: '${avatar.id} : le fond ne doit pas être forcé',
        );
      }
    });

    test('identifiants et URLs sont uniques', () {
      final ids = orbit3DAvatars.map((a) => a.id).toList();
      final urls = orbit3DAvatars.map((a) => a.imageUrl).toList();
      expect(ids.toSet().length, ids.length, reason: 'ids dupliqués');
      expect(urls.toSet().length, urls.length, reason: 'URLs dupliquées');
    });

    test('chaque avatar a un nom non vide', () {
      for (final avatar in orbit3DAvatars) {
        expect(avatar.name.trim(), isNotEmpty, reason: avatar.id);
      }
    });

    test('les libellés de catégories sont localisés dans les 6 langues',
        () async {
      const locales = ['fr', 'en', 'de', 'es', 'it', 'ar'];
      for (final code in locales) {
        final l = await AppLocalizations.delegate.load(Locale(code));
        final labels = <String>[];
        for (final id in avatarCategoryIds) {
          final label = avatarCategoryLabel(l, id);
          expect(label.trim(), isNotEmpty, reason: '$code / $id');
          labels.add(label);
        }
        // Aucun doublon : chaque catégorie doit rester distinguable.
        expect(labels.toSet().length, labels.length,
            reason: '$code : libellés identiques');
      }
    });

    test('les libellés de catégories diffèrent d\'une langue à l\'autre',
        () async {
      final fr = await AppLocalizations.delegate.load(const Locale('fr'));
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(
        avatarCategoryLabel(fr, 'blackWhite'),
        'Noir & Blanc',
      );
      expect(
        avatarCategoryLabel(en, 'blackWhite'),
        'Black & White',
      );
    });
  });
}
