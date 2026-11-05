import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/catalog_db.dart';

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
  final key = await ref.watch(apiServiceProvider).resolveSubscriptionCacheKey();
  if (key == null) return null;
  final db = CatalogDb.instance;
  if (!db.isAvailable) return null;
  return await db.hasData(kind, key) ? key : null;
});

/// Liste paginée : charge [pageSize] éléments à la fois et notifie via
/// [onChange]. Les réponses d'une génération périmée sont ignorées.
class CatalogPager<T> {
  CatalogPager({
    required this.fetch,
    required this.onChange,
    this.pageSize = 120,
  });

  final Future<List<T>> Function(int limit, int offset) fetch;
  final void Function() onChange;
  final int pageSize;

  final List<T> items = <T>[];
  bool done = false;
  bool loading = false;
  int _generation = 0;

  Future<void> reset() async {
    _generation++;
    items.clear();
    done = false;
    loading = false;
    await loadMore();
  }

  Future<void> loadMore() async {
    if (loading || done) return;
    loading = true;
    final gen = _generation;
    final page = await fetch(pageSize, items.length);
    if (gen != _generation) return;
    items.addAll(page);
    if (page.length < pageSize) done = true;
    loading = false;
    onChange();
  }

  void invalidate() => _generation++;
}
