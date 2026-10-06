import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// Budget du repli réseau EPG.
///
/// Ce budget existe parce d'une mesure, pas d'une intuition : sur le S20,
/// l'EPG déclenchait ~589 appels `get_short_epg`, le panel répondait
/// « Limite de requêtes dépassée (code 429) » et chaque chaîne échouait —
/// d'où une grille pleine de « cases » (blocs de trou) sans aucun programme.
void main() {
  group('EpgFallbackBudget', () {
    test('autorise jusqu\'à maxRequests, puis refuse', () {
      final budget = EpgFallbackBudget();
      for (var i = 0; i < EpgFallbackBudget.maxRequests; i++) {
        expect(
          budget.tryConsume(),
          isTrue,
          reason: 'la requête ${i + 1} doit être autorisée',
        );
      }
      expect(budget.remaining, 0);
      expect(budget.tryConsume(), isFalse);
      expect(budget.consumed, EpgFallbackBudget.maxRequests);
    });

    test('refuse au-delà du plafond, sans le dépasser', () {
      final budget = EpgFallbackBudget();
      // Beaucoup plus d'appels que le plafond : c'est le cas réel de la grille.
      var accepted = 0;
      for (var i = 0; i < EpgFallbackBudget.maxRequests * 20; i++) {
        if (budget.tryConsume()) accepted++;
      }
      expect(accepted, EpgFallbackBudget.maxRequests);
      expect(budget.remaining, 0);
    });

    test('le budget est partagé : deux consommateurs se le disputent', () {
      // La grille charge 8 chaînes en parallèle. Un budget par appel
      // n'aurait rien borné : c'est tout l'intérêt d'un objet partagé.
      final budget = EpgFallbackBudget();
      var accepted = 0;
      for (final _ in List.generate(8, (i) => i)) {
        for (var i = 0; i < 20; i++) {
          if (budget.tryConsume()) accepted++;
        }
      }
      expect(accepted, EpgFallbackBudget.maxRequests);
    });

    test('reset rend le plein budget', () {
      final budget = EpgFallbackBudget();
      for (var i = 0; i < EpgFallbackBudget.maxRequests; i++) {
        budget.tryConsume();
      }
      expect(budget.remaining, 0);
      budget.reset();
      expect(budget.remaining, EpgFallbackBudget.maxRequests);
      expect(budget.consumed, 0);
      expect(budget.tryConsume(), isTrue);
    });
  });
}