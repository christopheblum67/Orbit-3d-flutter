import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

/// Préférences de filtrage des catégories Films / Séries.
///
/// ## Portée = l'ABONNEMENT, pas l'utilisateur
///
/// Le contenu d'un abonnement ne dépend que de cet abonnement : deux
/// utilisateurs partageant la même ligne FTP doivent voir exactement les mêmes
/// catégories, et changer d'utilisateur ne doit jamais reveals/masquer une
/// catégorie. Toute la persistance est donc indexée sur [Subscription.id]
/// (`vodCategoryPrefs.<id>.hidden`), jamais sur un profil ni sur l'index de
/// l'abonnement actif.
///
/// ## Ce qui est mémorisé
/// - le catalogue des catégories discovered au premier lancement, afin que
///   l'écran de réglages puisse proposer l'affichage/le masquage même pour une
///   catégorie vide (le panel la déclare, mais aucun contenu ne s'y rattache) ;
/// - l'ensemble des identifiants masqués ;
/// - l'horodatage du dernier scan, pour proposer un rafraîchissement manuel.
class VodCategoryFilter {
  const VodCategoryFilter({
    required this.subscriptionId,
    this.knownVodCategories = const <MediaCategory>[],
    this.knownSeriesCategories = const <MediaCategory>[],
    this.hiddenVodCategoryIds = const <String>{},
    this.hiddenSeriesCategoryIds = const <String>{},
    this.scannedAt,
  });

  final String subscriptionId;

  /// Catalogue connu au dernier scan (films).
  final List<MediaCategory> knownVodCategories;

  /// Catalogue connu au dernier scan (séries).
  final List<MediaCategory> knownSeriesCategories;

  final Set<String> hiddenVodCategoryIds;
  final Set<String> hiddenSeriesCategoryIds;

  /// Instant du premier scan réussi pour cet abonnement.
  final DateTime? scannedAt;

  /// Vrai dès qu'un scan a abouti au moins une fois : c'est ce drapeau qui
  /// déclenche la découverte au premier lancement, et lui seul.
  bool get hasScanned => scannedAt != null;

  /// Durée de validité d'une liste de catégories découverte.
  ///
  /// Les panels réorganisent leurs catégories (fusion, renommage, ajout) sans
  /// prévenir : au-delà de cette fenêtre, la liste connue est considérée comme
  /// périmée et doit être actualisée.
  static const Duration scanTtl = Duration(hours: 12);

  /// Vrai si le dernier scan est encore suffisamment récent pour être réutilisé.
  bool get isFresh {
    final at = scannedAt;
    if (at == null) return false;
    return DateTime.now().difference(at) < scanTtl;
  }

  bool isVodHidden(String categoryId) =>
      hiddenVodCategoryIds.contains(categoryId);

  bool isSeriesHidden(String categoryId) =>
      hiddenSeriesCategoryIds.contains(categoryId);

  int get hiddenCount =>
      hiddenVodCategoryIds.length + hiddenSeriesCategoryIds.length;

  /// Ne laisse que les catégories visibles, à l'ordre du panel.
  List<MediaCategory> visibleVodCategories(Iterable<MediaCategory> source) =>
      source
          .where((c) => !hiddenVodCategoryIds.contains(c.id))
          .toList(growable: false);

  List<MediaCategory> visibleSeriesCategories(
    Iterable<MediaCategory> source,
  ) => source
      .where((c) => !hiddenSeriesCategoryIds.contains(c.id))
      .toList(growable: false);

  VodCategoryFilter copyWith({
    String? subscriptionId,
    List<MediaCategory>? knownVodCategories,
    List<MediaCategory>? knownSeriesCategories,
    Set<String>? hiddenVodCategoryIds,
    Set<String>? hiddenSeriesCategoryIds,
    DateTime? scannedAt,
  }) {
    return VodCategoryFilter(
      subscriptionId: subscriptionId ?? this.subscriptionId,
      knownVodCategories: knownVodCategories ?? this.knownVodCategories,
      knownSeriesCategories: knownSeriesCategories ?? this.knownSeriesCategories,
      hiddenVodCategoryIds: hiddenVodCategoryIds ?? this.hiddenVodCategoryIds,
      hiddenSeriesCategoryIds:
          hiddenSeriesCategoryIds ?? this.hiddenSeriesCategoryIds,
      scannedAt: scannedAt ?? this.scannedAt,
    );
  }
}

/// Notifier des préférences de catégories, persistées par abonnement.
class VodCategoryFilterNotifier extends Notifier<VodCategoryFilter> {
  static const String _keyPrefix = 'vodCategoryPrefs';

  SharedPreferences? _prefs;

  @override
  VodCategoryFilter build() {
    final sub = ref.watch(activeSubscriptionProvider);
    if (sub == null) {
      return const VodCategoryFilter(subscriptionId: '');
    }
    // Premier passage : lecture asynchrone des préférences. L'UI n'affiche
    // aucune catégorie masquée jusqu'à la première écriture — un aller-retour
    // disque au build() bloquerait le premier frame.
    unawaited(_loadAsync(sub));
    return VodCategoryFilter(subscriptionId: sub.id);
  }

  Future<void> _loadAsync(Subscription sub) async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final vod = _decodeCategories(prefs.getString(_key(sub.id, 'vod')));
    final series = _decodeCategories(prefs.getString(_key(sub.id, 'series')));
    final hiddenVod =
        (prefs.getStringList(_key(sub.id, 'hiddenVod')) ?? const <String>[])
            .toSet();
    final hiddenSeries =
        (prefs.getStringList(_key(sub.id, 'hiddenSeries')) ?? const <String>[])
            .toSet();
    final scannedMs = prefs.getInt(_key(sub.id, 'scannedAtMs'));
    final loaded = VodCategoryFilter(
      subscriptionId: sub.id,
      knownVodCategories: vod,
      knownSeriesCategories: series,
      hiddenVodCategoryIds: hiddenVod,
      hiddenSeriesCategoryIds: hiddenSeries,
      scannedAt: scannedMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(scannedMs),
    );
    // Ne pas écraser un état plus récent si l'utilisateur a déjà interagi
    // pendant que la lecture était en cours.
    if (state.subscriptionId == sub.id && state.hasScanned) return;
    state = loaded;
  }

  String _key(String subscriptionId, String field) =>
      '$_keyPrefix.$subscriptionId.$field';

  Future<void> _persist(VodCategoryFilter next) async {
    state = next;
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs!;
    await Future.wait([
      prefs.setString(
        _key(next.subscriptionId, 'vod'),
        jsonEncode(
          next.knownVodCategories
              .map((c) => {'category_id': c.id, 'category_name': c.name})
              .toList(),
        ),
      ),
      prefs.setString(
        _key(next.subscriptionId, 'series'),
        jsonEncode(
          next.knownSeriesCategories
              .map((c) => {'category_id': c.id, 'category_name': c.name})
              .toList(),
        ),
      ),
      prefs.setStringList(
        _key(next.subscriptionId, 'hiddenVod'),
        next.hiddenVodCategoryIds.toList(),
      ),
      prefs.setStringList(
        _key(next.subscriptionId, 'hiddenSeries'),
        next.hiddenSeriesCategoryIds.toList(),
      ),
      prefs.setInt(
        _key(next.subscriptionId, 'scannedAtMs'),
        (next.scannedAt ?? DateTime.now()).millisecondsSinceEpoch,
      ),
    ]);
  }

  static List<MediaCategory> _decodeCategories(String? raw) {
    if (raw == null || raw.isEmpty) return const <MediaCategory>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <MediaCategory>[];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(MediaCategory.fromMap)
        .toList(growable: false);
  }

  /// Affiche / masque une catégorie Films pour l'abonnement courant.
  Future<void> setVodCategoryVisible(String categoryId, bool visible) {
    final hidden = Set<String>.from(state.hiddenVodCategoryIds);
    if (visible) {
      hidden.remove(categoryId);
    } else {
      hidden.add(categoryId);
    }
    return _persist(state.copyWith(hiddenVodCategoryIds: hidden));
  }

  /// Affiche / masque une catégorie Séries pour l'abonnement courant.
  Future<void> setSeriesCategoryVisible(String categoryId, bool visible) {
    final hidden = Set<String>.from(state.hiddenSeriesCategoryIds);
    if (visible) {
      hidden.remove(categoryId);
    } else {
      hidden.add(categoryId);
    }
    return _persist(state.copyWith(hiddenSeriesCategoryIds: hidden));
  }

  Future<void> resetToAllVisible() {
    return _persist(
      state.copyWith(
        hiddenVodCategoryIds: const <String>{},
        hiddenSeriesCategoryIds: const <String>{},
      ),
    );
  }

  /// Scan complet des catégories de l'abonnement (Films + Séries).
  ///
  /// Idempotent et sans effet de bord sur les masquages : sert à alimenter
  /// l'écran de réglages et à marquer l'abonnement comme « déjà analysé ».
  Future<bool> rescan({ApiService? api, bool force = false}) async {
    final sub = ref.read(activeSubscriptionProvider);
    if (sub == null) return false;
    final state = ref.read(vodCategoryFilterProvider);
    // Sans `force`, on respecte le drapeau : un scan déjà effectué pour cet
    // abonnement n'est pas refait. Le rescan lié au changement d'abonnement
    // passe `force: true` pour actualiser une liste potentiellement périmée.
    if (!force &&
        state.subscriptionId == sub.id &&
        state.hasScanned &&
        state.isFresh) {
      return false;
    }
    final ApiService service = api ?? ref.read(apiServiceProvider);
    final vod = await safeAsync<List<MediaCategory>>(
      () => service.fetchVodCategories(),
      context: 'VodCategoryFilter.rescan(vod)',
    );
    final series = await safeAsync<List<MediaCategory>>(
      () => service.fetchSeriesCategories(),
      context: 'VodCategoryFilter.rescan(series)',
    );
    if (vod.isFailure && series.isFailure) {
      LoggerService.instance
          .warning('VodCategoryFilter: scan impossible pour ${sub.id}');
      return false;
    }
    await _persist(
      state.copyWith(
        knownVodCategories: vod.valueOrNull ?? state.knownVodCategories,
        knownSeriesCategories:
            series.valueOrNull ?? state.knownSeriesCategories,
        scannedAt: DateTime.now(),
      ),
    );
    return true;
  }
}

final vodCategoryFilterProvider =
    NotifierProvider<VodCategoryFilterNotifier, VodCategoryFilter>(
      VodCategoryFilterNotifier.new,
    );

/// Scan automatique au premier lancement de chaque abonnement.
///
/// Renvoie `true` si un scan a été lancé. Le déclenchement est idempotent : le
/// drapeau `scannedAt` est écrit en base, un second appel ne refait rien.
final initialCategoryScanProvider = FutureProvider<bool>((ref) async {
  final filter = ref.watch(vodCategoryFilterProvider);
  if (filter.subscriptionId.isEmpty) return false;
  if (filter.hasScanned) return false;
  final notifier = ref.read(vodCategoryFilterProvider.notifier);
  final done = await notifier.rescan();
  if (done) {
    LoggerService.instance.info(
      'VodCategoryFilter: premier scan effectué '
      '(${filter.knownVodCategories.length} films / '
      '${filter.knownSeriesCategories.length} séries)',
    );
  }
  return done;
});

/// Rescan à chaque bascule d'abonnement actif.
///
/// [initialCategoryScanProvider] ne joue qu'une fois par abonnement (drapeau
/// `scannedAt`), ce qui est insuffisant : si l'utilisateur masque une catégorie,
/// ajoute un abonnement, ou si le panel a réorganisé ses catégories entre deux
/// sessions, la liste connue devient périmée et l'écran de filtres affiche des
/// catégories qui n'existent plus — ou n'en affiche pas de nouvelles.
///
/// Ce provider est donc keyé sur l'identifiant de l'abonnement actif et
/// rescanne à chaque changement, indépendamment du drapeau `hasScanned`.
final categoryScanOnSubscriptionChangeProvider = FutureProvider<bool>((ref) async {
  final filter = ref.watch(vodCategoryFilterProvider);
  final subId = filter.subscriptionId;
  if (subId.isEmpty) return false;

  // `keepAlive` évite que le scan soit relancé à chaque reconstruction de
  // l'écran : le provider vit tant que l'abonnement actif ne change pas.
  ref.keepAlive();

  final notifier = ref.read(vodCategoryFilterProvider.notifier);
  final done = await notifier.rescan(force: true);
  if (done) {
    LoggerService.instance.info(
      'VodCategoryFilter: rescan abonnement $subId '
      '(${filter.knownVodCategories.length} films / '
      '${filter.knownSeriesCategories.length} séries)',
    );
  }
  return done;
});
