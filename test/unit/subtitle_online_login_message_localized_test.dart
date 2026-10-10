import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Chaque locale doit traduire le message « téléchargement OpenSubtitles
/// refusé » dans SA langue, jamais dans celle du template.
///
/// La clé `subtitleOnlineNeedsLogin` n'existait que dans `app_fr.arb` : tous
/// les autres fichiers générés portaient le texte français par repli sur le
/// template, et l'utilisateur anglais lisait un message en français (503 de
/// `/download`). Ce test échoue sur ce repli silencieux.
void main() {
  final french = lookupAppLocalizations(const Locale('fr', ''));

  test('chaque locale traduit subtitleOnlineNeedsLogin dans sa langue', () {
    // (fr, en, de, es, it, ar) — l'ordre du template `app_fr.arb`.
    const locales = ['fr', 'en', 'de', 'es', 'it', 'ar'];

    for (final code in locales) {
      final l = lookupAppLocalizations(Locale(code, ''));
      expect(
        l.subtitleOnlineNeedsLogin,
        isNotEmpty,
        reason: '$code doit avoir une traduction de subtitleOnlineNeedsLogin',
      );
      if (code == 'fr') {
        expect(l.subtitleOnlineNeedsLogin, equals(french.subtitleOnlineNeedsLogin));
      } else {
        expect(
          l.subtitleOnlineNeedsLogin,
          isNot(equals(french.subtitleOnlineNeedsLogin)),
          reason: '$code ne doit pas servir le repli français : '
              '${l.subtitleOnlineNeedsLogin}',
        );
      }
    }
  });

  test('les locales non-françaises ont leurs propres traductions dédiées', () {
    final en = lookupAppLocalizations(const Locale('en', ''));
    final de = lookupAppLocalizations(const Locale('de', ''));

    expect(en.subtitleOnlineNeedsLogin, contains('account'));
    expect(de.subtitleOnlineNeedsLogin, contains('Konto'));
  });
}