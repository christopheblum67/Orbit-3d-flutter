import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Search Algorithms', () {
    group('_normalize', () {
      test('should handle accents', () {
        expect(_normalize('Éléphant'), 'elephant');
        expect(_normalize('CAFÉ'), 'cafe');
        expect(_normalize('niño'), 'nino');
      });

      test('should handle special chars', () {
        expect(_normalize('Test@#\$%'), 'test');
        expect(_normalize('Movie!'), 'movie');
      });

      test('should normalize spaces', () {
        expect(_normalize('  Multiple   Spaces  '), 'multiple spaces');
        expect(_normalize('\tTab\nNewline'), 'tab newline');
      });

      test('should lowercase', () {
        expect(_normalize('UPPERCASE'), 'uppercase');
        expect(_normalize('MiXeD'), 'mixed');
      });
    });

    group('_levenshteinDistance', () {
      test('should calculate correct distances', () {
        expect(_levenshteinDistance('kitten', 'sitting'), 3);
        expect(_levenshteinDistance('flaw', 'lawn'), 2);
        expect(_levenshteinDistance('test', 'test'), 0);
        expect(_levenshteinDistance('', 'abc'), 3);
        expect(_levenshteinDistance('abc', ''), 3);
      });

      test('should handle single char differences', () {
        expect(_levenshteinDistance('cat', 'bat'), 1);
        expect(_levenshteinDistance('cat', 'cats'), 1);
        expect(_levenshteinDistance('cat', 'at'), 1);
      });
    });

    group('_fuzzyScore', () {
      test('exact match should score 1.0', () {
        expect(_fuzzyScore('matrix', 'matrix'), 1.0);
        expect(_fuzzyScore('Matrix', 'matrix'), 1.0);
      });

      test('prefix match should score 0.9', () {
        expect(_fuzzyScore('mat', 'matrix'), 0.9);
        expect(_fuzzyScore('star', 'star wars'), 0.9);
      });

      test('substring match should score 0.7', () {
        expect(_fuzzyScore('trix', 'matrix'), 0.7);
        expect(_fuzzyScore('war', 'star wars'), 0.7);
      });

      test('typos should score based on similarity', () {
        final score = _fuzzyScore('matrx', 'matrix');
        expect(score, greaterThan(0.0));
        expect(score, lessThan(0.7));

        final score2 = _fuzzyScore('incepton', 'inception');
        expect(score2, greaterThan(0.0));
      });

      test('completely different strings should score 0', () {
        expect(_fuzzyScore('abc', 'xyz'), 0.0);
        expect(_fuzzyScore('hello', 'world'), 0.0);
      });

      test('empty strings should score 0', () {
        expect(_fuzzyScore('', 'test'), 0.0);
        expect(_fuzzyScore('test', ''), 0.0);
        expect(_fuzzyScore('', ''), 0.0);
      });
    });
  });
}

String _normalize(String query) {
  const accents = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a', 'å': 'a',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n',
    'ý': 'y', 'ÿ': 'y',
  };
  
  final buffer = StringBuffer();
  for (final char in query.toLowerCase().split('')) {
    buffer.write(accents[char] ?? char);
  }
  
  return buffer.toString()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[^\w\s-]'), '')
      .trim();
}

int _levenshteinDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  final matrix = List.generate(a.length + 1, (i) => List.filled(b.length + 1, 0));
  for (var i = 0; i <= a.length; i++) matrix[i][0] = i;
  for (var j = 0; j <= b.length; j++) matrix[0][j] = j;

  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      matrix[i][j] = [
        matrix[i - 1][j] + 1,
        matrix[i][j - 1] + 1,
        matrix[i - 1][j - 1] + cost,
      ].reduce((a, b) => a < b ? a : b);
    }
  }
  return matrix[a.length][b.length];
}

double _fuzzyScore(String query, String target) {
  final normalizedQuery = _normalize(query);
  final normalizedTarget = _normalize(target);

  if (normalizedQuery.isEmpty) return 0.0;
  if (normalizedTarget.isEmpty) return 0.0;

  if (normalizedTarget == normalizedQuery) return 1.0;
  if (normalizedTarget.startsWith(normalizedQuery)) return 0.9;
  if (normalizedTarget.contains(normalizedQuery)) return 0.7;

  final distance = _levenshteinDistance(normalizedQuery, normalizedTarget);
  final maxLen = normalizedQuery.length > normalizedTarget.length
      ? normalizedQuery.length
      : normalizedTarget.length;
  if (maxLen == 0) return 0.0;

  final similarity = 1.0 - (distance / maxLen);
  if (similarity > 0.6) return similarity * 0.5;
  return 0.0;
}