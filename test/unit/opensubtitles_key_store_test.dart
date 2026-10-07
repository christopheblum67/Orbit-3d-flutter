import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/opensubtitles_key_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Exactitude de la clé stockée, au sens BYTE.
///
/// Une clé d'API est une suite de caractères ASCII. Un copier-coller depuis une
/// page web y introduit régulièrement des caractères invisibles, et `trim()` ne
/// les retire pas : ils sont À L'INTÉRIEUR, ou en bord sous une forme que Dart
/// ne reconnaît pas comme espace.
///
/// Le symptôme est un `401` sur une clé pourtant correcte — que rien ne
/// distingue, pour l'utilisateur, d'une clé qu'il a mal tapée.
void main() {
  const clean = '0123456789abcdef0123456789abcdef';
  const prefsKey = 'opensubtitles_api_key';

  String ch(int rune) => String.fromCharCode(rune);

  group('nettoyage à la saisie', () {
    test('une clé propre ne bouge pas', () {
      expect(OpenSubtitlesKeyStore.sanitise(clean), clean);
    });

    test('les espaces de bord partent', () {
      expect(OpenSubtitlesKeyStore.sanitise('  $clean  '), clean);
    });

    test('un espace insécable en bord est retiré', () {
      expect(OpenSubtitlesKeyStore.sanitise('${ch(0x00A0)}$clean'), clean);
    });

    test('un zéro-espace final est retiré', () {
      expect(
        OpenSubtitlesKeyStore.sanitise('$clean${ch(0x200B)}'),
        clean,
        reason: 'U+200B est invisible mais n\'est PAS un espace pour trim() : '
            'c\'est exactement le cas qui échappait',
      );
    });

    test('une marque bidirectionnelle est retirée', () {
      expect(
        OpenSubtitlesKeyStore.sanitise('${ch(0x200F)}$clean'),
        clean,
        reason: 'U+200F arrive en collant depuis une page web en RTL',
      );
    });

    test('un BOM est retiré', () {
      expect(OpenSubtitlesKeyStore.sanitise('${ch(0xFEFF)}$clean'), clean);
    });

    test('une coupure de ligne au milieu est refermée', () {
      expect(
        OpenSubtitlesKeyStore.sanitise(
          '${clean.substring(0, 16)}\n${clean.substring(16)}',
        ),
        clean,
        reason: 'une clé affichée sur deux lignes puis recopiée ne doit pas '
            'rester invalide',
      );
    });

    test('un invisible entre chaque caractère ne laisse aucun résidu', () {
      expect(
        OpenSubtitlesKeyStore.sanitise(clean.split('').join(ch(0x200B))),
        clean,
        reason: 'sinon la clé conserve la BONNE longueur tout en étant invalide, '
            'ce qui est le pire cas : rien ne paraît anormal',
      );
    });

    test('une clé entièrement invisible devient vide', () {
      expect(OpenSubtitlesKeyStore.sanitise(ch(0x200B) * 5), isEmpty);
    });
  });

  group('persistance', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    /// Ce qui est RÉELLEMENT écrit dans les préférences.
    Future<String?> stored() async =>
        (await SharedPreferences.getInstance()).getString(prefsKey);

    test('ce qui est écrit ne contient aucun invisible', () async {
      await OpenSubtitlesKeyStore.instance.setApiKey('$clean${ch(0x200B)}');

      final value = await stored();
      expect(value, clean);
      expect(
        value!.runes.every((r) => r > 0x20 && r < 0x7F),
        isTrue,
        reason: 'la clé stockée doit être de l\'ASCII imprimable : c\'est ce que '
            'l\'API attend',
      );
    });

    test('une clé enregistrée avant le nettoyage est nettoyée à la lecture',
        () async {
      // Simule une clé écrite par une version antérieure du code.
      SharedPreferences.setMockInitialValues(
        {prefsKey: '${ch(0x200B)}$clean${ch(0xFEFF)}'},
      );

      await OpenSubtitlesKeyStore.instance.load();

      expect(OpenSubtitlesKeyStore.instance.apiKey, clean);
    });

    test('une clé vide efface la précédente', () async {
      await OpenSubtitlesKeyStore.instance.setApiKey(clean);
      await OpenSubtitlesKeyStore.instance.setApiKey('   ');

      expect(await stored(), isNull);
      expect(OpenSubtitlesKeyStore.instance.apiKey, isEmpty);
    });
  });
}