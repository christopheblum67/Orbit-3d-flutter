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
        expect(l.subtitleOnlineNeedsLogin,
            equals(french.subtitleOnlineNeedsLogin),);
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

  test('chaque locale distingue « clé refusée » de « clé absente »', () {
    // Sans cette clé, un 401 (clé présente mais refusée) retombait sur le
    // message « clé absente » : l'utilisateur était prié de saisir une clé
    // qu'il avait déjà saisie.
    const locales = ['fr', 'en', 'de', 'es', 'it', 'ar'];
    final rejects = <String>{};
    for (final code in locales) {
      final l = lookupAppLocalizations(Locale(code, ''));
      expect(
        l.subtitleOnlineKeyRejected,
        isNotEmpty,
        reason: '$code doit avoir une traduction de subtitleOnlineKeyRejected',
      );
      expect(
        l.subtitleOnlineKeyRejected,
        isNot(equals(l.subtitleOnlineNoApiKey)),
        reason: '$code ne doit pas réutiliser le message « clé absente » pour '
            'une clé refusée',
      );
      rejects.add(l.subtitleOnlineKeyRejected);
    }
    expect(rejects.length, locales.length,
        reason: 'chaque locale doit avoir sa propre tournure, sans repli FR',);
  });

  test('les boutons de vérification de clé sont traduits partout', () {
    const locales = ['fr', 'en', 'de', 'es', 'it', 'ar'];
    for (final code in locales) {
      final l = lookupAppLocalizations(Locale(code, ''));
      expect(l.opensubtitlesKeyCheck, isNotEmpty, reason: '$code : bouton');
      expect(l.opensubtitlesKeyValid, isNotEmpty, reason: '$code : valide');
      expect(
        l.opensubtitlesKeyRejected,
        isNotEmpty,
        reason: '$code : refusée',
      );
      expect(
        l.opensubtitlesKeyUnreachable,
        isNotEmpty,
        reason: '$code : injoignable',
      );
    }
  });
}
