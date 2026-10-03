import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/utils/language_label.dart';
import 'package:orbit_3d_flutter/services/subtitle_discovery.dart';

void main() {
  group('LanguageLabel — sous-titre forcé', () {
    test('la forme usuelle est reconnue', () {
      expect(LanguageLabel.of('fr_forced'), 'Français (forcé)');
      expect(LanguageLabel.of('fr-forced'), 'Français (forcé)');
      expect(LanguageLabel.of('eng_forced'), 'English (forcé)');
    });

    test('la forme inversée est reconnue aussi', () {
      // Sans ce cas, le premier jeton vaut « forced » et s'affiche comme un nom
      // de langue.
      expect(LanguageLabel.of('forced_fr'), 'Français (forcé)');
      expect(LanguageLabel.of('forced-en'), 'English (forcé)');
    });

    test('la forme collée et le nom de fichier sont reconnus', () {
      expect(LanguageLabel.of('fr_subforced'), 'Français (forcé)');
      expect(LanguageLabel.of('1234_fr_subforced.srt'), 'Français (forcé)');
      expect(LanguageLabel.of('1234_fr.srt'), 'Français');
      // `subforced` seul ne porte AUCUNE langue : l'afficher « Français » serait
      // inventer une piste française. Le descripteur est renvoyé tel quel.
      expect(LanguageLabel.of('subforced'), 'subforced');
      expect(LanguageLabel.isForced('subforced'), isTrue);
    });

    test('les codes courts de forcé sont reconnus', () {
      expect(LanguageLabel.of('fr_ffr'), 'Français (forcé)');
      expect(LanguageLabel.of('fr_frc'), 'Français (forcé)');
    });

    test('forcé et normal donnent deux libellés distincts', () {
      expect(LanguageLabel.of('fr'), isNot(LanguageLabel.of('fr_forced')));
    });

    test('SDH et malentendants', () {
      expect(
        LanguageLabel.of('en_sdh'),
        'English (sourds et malentendants)',
      );
      expect(
        LanguageLabel.of('fr-cc'),
        'Français (sourds et malentendants)',
      );
    });

    // Régression : `contains('hi')` ou `contains('cc')` sur le descripteur entier
    // faisait passer une langue ordinaire pour une piste malentendante.
    test('un code court ne produit pas de faux positif', () {
      expect(LanguageLabel.isHearingImpaired('hi'), isFalse);
      expect(LanguageLabel.isHearingImpaired('cc'), isFalse);
      expect(LanguageLabel.isForced('fr'), isFalse);
      expect(LanguageLabel.isForced('en'), isFalse);
      // `hi` seul n'est PAS un modificateur : c'est un code de langue inconnu,
      // rendu tel quel plutôt que masqué.
      expect(LanguageLabel.of('hi'), 'hi');
      // Accompagné d'une langue, il redevient bien « malentendants ».
      expect(LanguageLabel.of('fr_hi'), contains('malentendants'));
    });

    test('un libellé déjà rédigé reste tel quel', () {
      expect(LanguageLabel.of('Français'), 'Français');
      expect(LanguageLabel.of('English (forced)'), 'English (forcé)');
    });
  });

  group('Voie A — candidats déduits, variantes forcées', () {
    final ctx = SubtitleDiscoveryContext(
      baseUrl: 'http://panel.example.com:8080',
      username: 'u',
      password: 'p',
      streamId: '7819',
    );

    test('les variantes forcé sont proposées', () {
      final codes = SubtitleDiscovery.defaultConventionLanguages(
        deviceLanguageCode: 'fr',
      );
      expect(codes, contains('fr'));
      expect(codes, contains('fr_forced'));
      expect(codes, contains('fre_forced'));
      expect(codes, contains('en_forced'));
    });

    test('normal et forcé sont deux entrées distinctes', () {
      final tracks = SubtitleDiscovery.synthesizeFromConvention(
        context: ctx,
        languages: ['fr', 'fr_forced'],
      );
      expect(tracks.length, 2);
      expect(
        tracks.map((t) => t.label).toSet(),
        {'Français', 'Français (forcé)'},
      );
    });

    test('les formes longue et courte restent des replis, pas des doublons',
        () {
      final tracks = SubtitleDiscovery.synthesizeFromConvention(
        context: ctx,
        languages: ['fr', 'fre'],
      );
      expect(tracks.length, 1);
      expect(tracks.single.url, endsWith('_fr.srt'));
      expect(
        tracks.single.alternates.length,
        greaterThan(1),
        reason: 'les variantes de forme et de code sont des replis',
      );
      expect(
        tracks.single.alternates.every((a) => a.label == tracks.single.label),
        isTrue,
        reason: 'tous les replis appartiennent à la même langue',
      );
    });

    test('les formes d\'URL couvrent les variantes connues', () {
      final urls = ctx.urlsForLanguage('fr');
      expect(urls.length, 4);
      // La convention Xtream documentée passe en premier : la plus probable
      // doit être testée en premier.
      expect(urls.first, endsWith('/subtitles/u/p/7819_fr.srt'));
      expect(urls.any((u) => u.endsWith('/7819.fr.srt')), isTrue,
          reason: 'séparateur pointu');
      expect(urls.any((u) => u.contains('/timingsubtitles/')), isTrue);
      expect(urls.any((u) => u.endsWith('.vtt')), isTrue);
    });

    test('l\'URL forcée est bien construite', () {
      final tracks = SubtitleDiscovery.synthesizeFromConvention(
        context: ctx,
        languages: ['fr_forced'],
      );
      expect(tracks.single.url, endsWith('/7819_fr_forced.srt'));
    });

    test('la piste forcée est marquée dans ses drapeaux', () {
      final tracks = SubtitleDiscovery.synthesizeFromConvention(
        context: ctx,
        languages: ['fr_forced', 'fr'],
      );
      final forced = tracks.firstWhere((t) => t.label.contains('forcé'));
      expect(LanguageLabel.isForced(forced.language), isTrue);
      final normal = tracks.firstWhere((t) => !t.label.contains('forcé'));
      expect(LanguageLabel.isForced(normal.language), isFalse);
    });
  });
}
