import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/ai_service.dart';

void main() {
  group('AiService.parseJsonObject', () {
    test('parse un objet JSON inline', () {
      final result =
          AiService.parseJsonObject('{"year": 2023, "genre": "Action"}');
      expect(result, isNotNull);
      expect(result!['year'], 2023);
      expect(result['genre'], 'Action');
    });

    test('ignore le texte autour de l\'objet JSON', () {
      const content = '''
Voici les métadonnées demandées :
{"year": 1999, "director": "John Doe"}
Fin de la réponse.''';
      final result = AiService.parseJsonObject(content);
      expect(result, isNotNull);
      expect(result!['director'], 'John Doe');
    });

    test('gère les blocs de code JSON', () {
      const content = '```json\n{"runtime": 118, "keywords": ["a", "b"]}\n```';
      final result = AiService.parseJsonObject(content);
      expect(result, isNotNull);
      expect(result!['runtime'], 118);
      expect(result['keywords'], isA<List<dynamic>>());
    });

    test('renvoie null pour un JSON invalide', () {
      expect(AiService.parseJsonObject('pas du json'), isNull);
      expect(AiService.parseJsonObject(''), isNull);
      expect(AiService.parseJsonObject('[1, 2, 3]'), isNull);
    });

    test('renvoie null pour un contenu vide', () {
      expect(AiService.parseJsonObject('   '), isNull);
    });
  });
}