/// Tri d'une liste par affinité, sans connaissance de Riverpod ni du profil.
///
/// ## Pourquoi
///
/// Les écrans Films et Séries trient aujourd'hui par note, année, nom ou date
/// d'ajout ([MediaLibraryManager.applySort]). Le matchmaking sait déjà scorer
/// un contenu pour le profil courant (`ProfileAffinityScorer`, qui réutilise la
/// même formule que l'onglet Matchmaking : `profileAffinityWithSignals`). Ce
/// tri expose la même affinité comme **mode de tri** : le score est calculé par
/// l'appelant (qui seul connaît le profil et le genre TMDB corrigé), ce helper
/// ne fait que réordonner de façon déterministe.
///
/// ## Stabilité
///
/// `List.sort` (quicksort dual-pivot, en place) n'est pas stable : deux
/// contenus au score égal s'inverseraient d'un build à l'autre selon l'ordre
/// initial. L'égalité est départagée par la qualité, puis par titre croissant.
///
/// ## Sens
///
/// `descending` (défaut) classe du plus affin au moins affin ; `false` classe du
/// moins affin au plus affin (mode « affinité croissante »). La qualité reste
/// décroissante dans les deux sens.
///
/// ## La logique corrective est préservée, pas dupliquée
///
/// Ce tri ne recalcule AUCUNE affinité : il prend le score fourni tel quel.
/// C'est l'appelant qui choisit d'où vient le genre (catégorie Xtream, ou vrai
/// genre TMDB résolu — le correctif « Horreur, Mystère, … » déjà appliqué aux
/// tuiles Films/Séries). Dupliquer la formule ici aurait créé une deuxième
/// source de vérité, exactement la divergence que le score unique avait
/// éliminée (`ProfileAffinityScorer` documente ce choix).
List<T> sortByAffinityDesc<T>(
  List<T> items, {
  required double Function(T) score,
  required String Function(T) title,
  double Function(T)? quality,
  bool descending = true,
}) {
  final keyed = <_AffinitySortEntry<T>>[];
  for (var i = 0; i < items.length; i++) {
    keyed.add(_AffinitySortEntry(items[i], score(items[i])));
  }
  keyed.sort((a, b) {
    final c = descending
        ? b.score.compareTo(a.score)
        : a.score.compareTo(b.score);
    if (c != 0) return c;
    if (quality != null) {
      final qualityOrder = b.quality(quality).compareTo(a.quality(quality));
      if (qualityOrder != 0) return qualityOrder;
    }
    return title(a.item).toLowerCase().compareTo(title(b.item).toLowerCase());
  });
  return [for (final e in keyed) e.item];
}

class _AffinitySortEntry<T> {
  _AffinitySortEntry(this.item, this.score);

  final T item;
  final double score;
  double? _quality;

  double quality(double Function(T) calculate) =>
      _quality ??= calculate(item);
}
