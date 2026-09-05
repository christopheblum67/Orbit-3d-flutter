import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// Heuristique de classification adulte / violence (Sprint 4).
///
/// ⚠️ **UTILITAIRE INACTIF DANS L'UI COURANTE** (depuis le Sprint 5) : le
/// masquage automatique de contenu est **abandonné** (décision produit).
/// Aucun écran n'applique plus [visibleList] ni ne `ref.watch`
/// [contentFilterProvider] ; les booléens du profil ne sont plus édités par
/// l'UI. La classe et le provider sont conservés (comportement inchangé,
/// garantis par les tests unitaires) pour être réutilisés plus tard :
/// badges « âge » sur les cartes et recommandations réglées par âge.
///
/// Historique de l'heuristique (non appliquée, mais documentée pour reprise) :
/// un contenu est masqué si :
/// 1. son `id` est dans [hiddenContentIds] (masquage manuel), OU
/// 2. [hideAdultContent] et le contenu est classé adulte, OU
/// 3. [hideViolentContent] et le contenu est classé violent.
///
/// ## Heuristique "adulte"
/// - PEGI / âge >= 18 (extraction des chiffres de `pegi`, `age`, `mpaa`…), ou
///   ratings US stricts (`NC-17`, `R`, `X`, `XXX`).
/// - Mots-clés de genre/titre/description FR + EN, avec frontières de mot
///   (pas de sous-chaîne) : adulte, adult, xxx, érotique, erotique, erotic,
///   porn, porno, hardcore, explicit(e), sexy, nude, nudité.
///
/// ## Heuristique "violence"
/// - Mots-clés de genre/titre/description FR + EN, avec frontières de mot :
///   violence, violent, horreur, horror, gore, thriller, meurtre, murder,
///   assassinat, torture, macabre, snuff, sadique.
/// - Volontairement pas de mise en cause des genres "Action"/"Combat"/"Guerre"
///   (trop large, bloquerait des films familiaux) : on reste proche de la
///   liste demandée (Horror, Violence, Gore, Thriller).
class ContentFilter {
  ContentFilter({
    required Set<String> hiddenContentIds,
    required this.hideAdultContent,
    required this.hideViolentContent,
  }) : hiddenContentIds = Set.unmodifiable(hiddenContentIds);

  const ContentFilter.none()
      : hiddenContentIds = const {},
        hideAdultContent = false,
        hideViolentContent = false;

  factory ContentFilter.fromProfile(UserProfile? profile) {
    if (profile == null) return const ContentFilter.none();
    return ContentFilter(
      hiddenContentIds: profile.hiddenContentIds.toSet(),
      hideAdultContent: profile.hideAdultContent,
      hideViolentContent: profile.hideViolentContent,
    );
  }

  final Set<String> hiddenContentIds;
  final bool hideAdultContent;
  final bool hideViolentContent;

  static const Set<String> _adultKeywords = {
    'adulte',
    'adult',
    'xxx',
    'erotique',
    'erotic',
    'erotik',
    'érotique',
    'porn',
    'porno',
    'hardcore',
    'explicit',
    'explicite',
    'sexy',
    'nude',
    'nudity',
    'nudité',
    '18+',
    '+18',
  };

  static const Set<String> _violentKeywords = {
    'violence',
    'violent',
    'horreur',
    'horror',
    'gore',
    'thriller',
    'meurtre',
    'murder',
    'assassinat',
    'assassination',
    'torture',
    'macabre',
    'snuff',
    'sadique',
    'sadistic',
  };

  // --- Classification adulte -------------------------------------------------

  bool isAdultMovie(Movie movie) {
    return _isAdult(movie.title, movie.genre, movie.description, movie.pegi);
  }

  bool isAdultSeries(Series series) {
    return _isAdult(
      series.title,
      series.genre,
      series.description,
      series.pegi,
    );
  }

  bool isAdultChannel(Channel channel) {
    return _isAdult(channel.name, channel.groupLabel, '', '');
  }

  bool isAdultReplay(ReplayItem replay) {
    return _isAdult(replay.title, '', '', '');
  }

  // --- Classification violence ----------------------------------------------

  bool isViolentMovie(Movie movie) {
    return _isViolent(
      movie.title,
      movie.genre,
      movie.description,
      movie.pegi,
    );
  }

  bool isViolentSeries(Series series) {
    return _isViolent(
      series.title,
      series.genre,
      series.description,
      series.pegi,
    );
  }

  bool isViolentChannel(Channel channel) {
    return _isViolent(channel.name, channel.groupLabel, '', '');
  }

  bool isViolentReplay(ReplayItem replay) {
    return _isViolent(replay.title, '', '', '');
  }

  // --- Décision de masquage --------------------------------------------------

  bool isHiddenMovie(Movie movie) {
    return hiddenContentIds.contains(movie.id) ||
        (hideAdultContent && isAdultMovie(movie)) ||
        (hideViolentContent && isViolentMovie(movie));
  }

  bool isHiddenSeries(Series series) {
    return hiddenContentIds.contains(series.id) ||
        (hideAdultContent && isAdultSeries(series)) ||
        (hideViolentContent && isViolentSeries(series));
  }

  bool isHiddenChannel(Channel channel) {
    return hiddenContentIds.contains(channel.id) ||
        (hideAdultContent && isAdultChannel(channel)) ||
        (hideViolentContent && isViolentChannel(channel));
  }

  bool isHiddenReplay(ReplayItem replay) {
    return hiddenContentIds.contains(replay.id) ||
        (hideAdultContent && isAdultReplay(replay)) ||
        (hideViolentContent && isViolentReplay(replay));
  }

  /// Filtre générique : retire les éléments masqués quelle que soit la liste
  /// source (VOD, Séries, Replay, Live), en laissant passer les types inconnus.
  List<T> visibleList<T>(List<T> items) {
    return items.where((item) {
      if (item is Movie) return !isHiddenMovie(item);
      if (item is Series) return !isHiddenSeries(item);
      if (item is ReplayItem) return !isHiddenReplay(item);
      if (item is Channel) return !isHiddenChannel(item);
      return true;
    }).toList();
  }

  // --- Implémentation --------------------------------------------------------

  bool _isAdult(String title, String genre, String description, String pegi) {
    if (_pegiAtLeast18(pegi)) return true;
    return _matchesAny(title, _adultKeywords) ||
        _matchesAny(genre, _adultKeywords) ||
        _matchesAny(description, _adultKeywords);
  }

  bool _isViolent(
    String title,
    String genre,
    String description,
    String pegi,
  ) {
    return _matchesAny(title, _violentKeywords) ||
        _matchesAny(genre, _violentKeywords) ||
        _matchesAny(description, _violentKeywords);
  }

  static bool _pegiAtLeast18(String pegi) {
    if (pegi.isEmpty) return false;
    final upper = pegi.toUpperCase();
    if (upper.contains('NC-17') || upper.contains('NC17')) return true;
    if (upper == 'R' || upper == 'X' || upper == 'XXX') return true;
    if (_matchesAny(upper, const ['18', '18+', '+18', '18 ANS'])) return true;
    final digits = upper.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return false;
    final n = int.tryParse(digits);
    return n != null && n >= 18;
  }

  /// Matche [tokens] dans [text] (insensible à la casse) en exigeant une
  /// frontière de mot : pas de sous-chaîne (ex: "sex" ne matche pas "essex").
  static bool _matchesAny(String text, Iterable<String> tokens) {
    if (text.isEmpty) return false;
    final lower = text.toLowerCase();
    const boundary = r'[^a-z0-9àâäéèêëîïôöùûüçœ]';
    for (final token in tokens) {
      final escaped = RegExp.escape(token.toLowerCase());
      if (RegExp(
        '(^|$boundary)$escaped($boundary|\$)',
        caseSensitive: false,
      ).hasMatch(lower)) {
        return true;
      }
    }
    return false;
  }
}

/// Filtre de contenu dérivé du profil courant.
///
/// ⚠️ **Inactif dans l'UI courante** (Sprint 5 — abandon du masquage
/// automatique) : aucun écran ne le `ref.watch` désormais. Conservé tel quel
/// pour être réutilisé par les réglages par âge / badges « âge » quand ils
/// seront conçus. S'il est réutilisé, il restera dérivé de
/// `currentProfileProvider` pour rester dynamique (toggles et démasquages
/// re-construisent alors les consommateurs).
final contentFilterProvider = Provider<ContentFilter>((ref) {
  return ContentFilter.fromProfile(ref.watch(currentProfileProvider));
});
