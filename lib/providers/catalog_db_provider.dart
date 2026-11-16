import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/catalog_db.dart';
import 'package:orbit_3d_flutter/core/utils/catalog_diagnostic.dart';

/// Suit [CatalogDb.revision] : change à chaque catalogue réécrit en base.
class _CatalogDbRevision extends Notifier<int> {
  @override
  int build() {
    void listener() => state = CatalogDb.revision.value;
    CatalogDb.revision.addListener(listener);
    ref.onDispose(() => CatalogDb.revision.removeListener(listener));
    return CatalogDb.revision.value;
  }
}

final catalogDbRevisionProvider =
    NotifierProvider<_CatalogDbRevision, int>(_CatalogDbRevision.new);

/// Clé d'abonnement sous laquelle le catalogue [kind] peut être lu en base,
/// ou `null` quand le chemin SQLite n'est pas utilisable : playlist M3U,
/// filtre de contenu actif (il inspecte des champs non stockés), base
/// indisponible ou catalogue pas encore écrit.
final catalogDbKeyProvider =
    FutureProvider.family<String?, CatalogKind>((ref, kind) async {
  ref.watch(catalogDbRevisionProvider);
  final sub = ref.watch(activeSubscriptionProvider);
  if (sub == null || sub.type == SubscriptionType.m3u) return null;
  if (!ref.watch(contentFilterProvider).isPermissive) return null;
  return traceCatalogStep(kind.name, 'database_key', () async {
    final key =
        await ref.watch(apiServiceProvider).resolveSubscriptionCacheKey();
    if (key == null) return null;
    final db = CatalogDb.instance;
    if (!db.isAvailable) return null;
    return await db.hasData(kind, key) ? key : null;
  });
});

String catalogSetSignature(Set<String>? values) {
  if (values == null) return 'null';
  return jsonEncode(values.toList()..sort());
}

/// Liste paginée : charge [pageSize] éléments à la fois et notifie via
/// [onChange]. Les réponses d'une génération périmée sont ignorées.
class CatalogPager<T> {
  CatalogPager({
    required this.fetch,
    required this.onChange,
    this.fetchAfter,
    this.pageSize = 72,
    this.diagnosticKind,
  });

  final Future<List<T>> Function(int limit, int offset) fetch;
  final Future<List<T>> Function(int limit, T? after)? fetchAfter;
  final void Function() onChange;
  final int pageSize;
  final String? diagnosticKind;

  final List<T> items = <T>[];
  bool done = false;
  bool loading = false;

  /// `false` tant que la première page n'est pas arrivée : permet d'afficher
  /// un indicateur de chargement plutôt qu'un faux « aucun résultat ».
  bool loaded = false;
  int _generation = 0;

  Future<void> reset() async {
    _generation++;
    items.clear();
    done = false;
    loading = false;
    loaded = false;
    await loadMore();
  }

  Future<void> loadMore() async {
    if (loading || done) return;
    loading = true;
    final gen = _generation;
    Future<List<T>> fetchPage() => fetchAfter != null
        ? fetchAfter!(pageSize, items.isEmpty ? null : items.last)
        : fetch(pageSize, items.length);
    final page = diagnosticKind != null && items.isEmpty
        ? await traceCatalogStep(diagnosticKind!, 'first_page', fetchPage)
        : await fetchPage();
    if (gen != _generation) return;
    items.addAll(page);
    if (page.length < pageSize) done = true;
    loading = false;
    loaded = true;
    onChange();
  }

  void invalidate() => _generation++;
}
