import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/vod_category_filter_provider.dart';

/// Réglages d'affichage des catégories Films / Séries.
///
/// Les réglages sont **par abonnement** : le contenu servi par une ligne ne
/// dépend que de cette ligne. Changer d'utilisateur ne change rien, changer
/// d'abonnement restaure ses propres préférences.
class CategoryFilterScreen extends ConsumerStatefulWidget {
  const CategoryFilterScreen({super.key});

  @override
  ConsumerState<CategoryFilterScreen> createState() =>
      _CategoryFilterScreenState();
}

class _CategoryFilterScreenState extends ConsumerState<CategoryFilterScreen>
    with SingleTickerProviderStateMixin {
  bool _scanning = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // À l'ouverture, la liste peut être périmée (catégORIES ajoutées ou
    // renommées par le panel, changement d'abonnement). `rescan` respecte le
    // TTL de 12 h : n'y a une requête réseau que si le scan précédent est
    // réellement périmé. Le `_rescan` manuel reste disponible.
    WidgetsBinding.instance.addPostFrameCallback((_) => _rescan());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _rescan() async {
    if (_scanning) return;
    setState(() => _scanning = true);
    final notifier = ref.read(vodCategoryFilterProvider.notifier);
    // `force: true` : ce rescannen est déclenché à chaque ouverture (ou par un
    // appui manuel) et doit rafraîchir la liste sans attendre le TTL.
    final done = await notifier.rescan(force: true);
    if (!mounted) return;
    setState(() => _scanning = false);
    if (!done) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Analyse impossible : le panel ne répond pas.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = ref.watch(activeSubscriptionProvider);
    final filter = ref.watch(vodCategoryFilterProvider);
    final notifier = ref.read(vodCategoryFilterProvider.notifier);
    final vodSource = ref.watch(vodCategoriesProvider);
    final seriesSource = ref.watch(seriesCategoriesProvider);
    final liveChannels =
        ref.watch(liveChannelsAllProvider).value ?? const <Channel>[];
    final liveCategories = _liveCategories(liveChannels);
    // Catalogue preferential : celui du scan s'il existe (donc même les
    // catégories sans contenu), sinon la réponse live du panel.
    final vodCategories = filter.knownVodCategories.isNotEmpty
        ? filter.knownVodCategories
        : (vodSource.value ?? const <MediaCategory>[]);
    final seriesCategories = filter.knownSeriesCategories.isNotEmpty
        ? filter.knownSeriesCategories
        : (seriesSource.value ?? const <MediaCategory>[]);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text('Catégories'),
        actions: [
          if (filter.hiddenCount > 0)
            TextButton(
              onPressed: notifier.resetToAllVisible,
              child: const Text('Tout afficher'),
            ),
        ],
      ),
      body: sub == null
          ? const Center(child: Text('Aucun abonnement actif'))
          : Column(
              children: [
                _SubscriptionHeader(
                  subscriptionName: sub.name,
                  scannedAt: filter.scannedAt,
                  scanning: _scanning,
                  onRescan: _rescan,
                ),
                TabBar(
                  controller: _tabController,
                  tabs: [
                    _focusTab(0, 'Live TV', filter.hiddenLiveCategoryIds.length),
                    _focusTab(1, 'Films', filter.hiddenVodCategoryIds.length),
                    _focusTab(
                        2, 'Séries', filter.hiddenSeriesCategoryIds.length),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _tabList(
                        _CategorySection(
                          title: 'Live TV',
                          emptyMessage: 'Aucune catégorie Live TV sur ce panel.',
                          categories: liveCategories,
                          isHidden: filter.isLiveHidden,
                          onToggle: notifier.setLiveCategoryVisible,
                          unit: 'chaînes',
                        ),
                      ),
                      _tabList(
                        _CategorySection(
                          title: 'Films',
                          emptyMessage: 'Aucune catégorie Films sur ce panel.',
                          categories: vodCategories,
                          isHidden: filter.isVodHidden,
                          onToggle: notifier.setVodCategoryVisible,
                        ),
                      ),
                      _tabList(
                        _CategorySection(
                          title: 'Séries',
                          emptyMessage: 'Aucune catégorie Séries sur ce panel.',
                          categories: seriesCategories,
                          isHidden: filter.isSeriesHidden,
                          onToggle: notifier.setSeriesCategoryVisible,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// Onglet qui s'active dès qu'il reçoit le focus (D-pad gauche/droite).
  Widget _focusTab(int index, String label, int hiddenCount) {
    return Focus(
      canRequestFocus: false,
      onFocusChange: (focused) {
        if (focused && _tabController.index != index) {
          _tabController.animateTo(index);
        }
      },
      child: Tab(
        text: hiddenCount > 0 ? '$label ($hiddenCount masquées)' : label,
      ),
    );
  }

  Widget _tabList(Widget section) => ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [section],
      );

  /// Catégories Live dérivées des chaînes (sans masquage), clé = [liveCategoryKey].
  static List<MediaCategory> _liveCategories(List<Channel> channels) {
    final names = <String, String>{};
    final counts = <String, int>{};
    for (final c in channels) {
      final key = liveCategoryKey(c);
      if (key.isEmpty) continue;
      names.putIfAbsent(
        key,
        () => c.groupLabel.isNotEmpty ? c.groupLabel : key,
      );
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return [
      for (final e in names.entries)
        MediaCategory(id: e.key, name: e.value, count: counts[e.key] ?? 0),
    ];
  }
}

class _SubscriptionHeader extends StatelessWidget {
  const _SubscriptionHeader({
    required this.subscriptionName,
    required this.scannedAt,
    required this.scanning,
    required this.onRescan,
  });

  final String subscriptionName;
  final DateTime? scannedAt;
  final bool scanning;
  final Future<void> Function() onRescan;

  String get _scannedLabel {
    final at = scannedAt;
    if (at == null) return 'Jamais analysé';
    final days = DateTime.now().difference(at).inDays;
    if (days <= 0) return 'Analysé aujourd\'hui';
    if (days == 1) return 'Analysé hier';
    return 'Analysé il y a $days jours';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dns_rounded,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subscriptionName,
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Réglages propres à cet abonnement — $_scannedLabel',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: scanning ? null : onRescan,
              icon: scanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(scanning ? 'Analyse…' : 'Réanalyser les catégories'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.emptyMessage,
    required this.categories,
    required this.isHidden,
    required this.onToggle,
    this.unit = 'titres',
  });

  final String unit;
  final String title;
  final String emptyMessage;
  final List<MediaCategory> categories;
  final bool Function(String categoryId) isHidden;
  final Future<void> Function(String categoryId, bool visible) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(
          emptyMessage,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    final sorted = [...categories]..sort((a, b) => a.name.compareTo(b.name));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(
            '$title (${categories.length})',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...sorted.map(
          (category) {
            final hidden = isHidden(category.id);
            return SwitchListTile.adaptive(
              dense: true,
              value: !hidden,
              onChanged: (visible) => onToggle(category.id, visible),
              title: Text(
                category.name,
                style: TextStyle(
                  color: hidden ? theme.colorScheme.onSurfaceVariant : null,
                ),
              ),
              subtitle:
                  category.count > 0 ? Text('${category.count} $unit') : null,
            );
          },
        ),
      ],
    );
  }
}
