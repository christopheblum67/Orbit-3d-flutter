import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
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
  final List<FocusNode> _tabFocusNodes =
      List.generate(3, (index) => FocusNode(debugLabel: 'Category tab $index'));

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
    for (final node in _tabFocusNodes) {
      node.dispose();
    }
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
          SnackBar(
            content: Text(AppLocalizations.of(context).categoryScanFailed),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
        title: Text(l.categoryTitle),
        actions: [
          if (filter.hiddenCount > 0)
            TextButton(
              onPressed: notifier.resetToAllVisible,
              child: Text(l.categoryShowAll),
            ),
        ],
      ),
      body: sub == null
          ? Center(child: Text(l.accountNoSubscription))
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
                    _focusTab(
                        0, l.liveTv, filter.hiddenLiveCategoryIds.length),
                    _focusTab(1, l.films, filter.hiddenVodCategoryIds.length),
                    _focusTab(
                        2, l.series, filter.hiddenSeriesCategoryIds.length),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _tabList(
                        _CategorySection(
                          title: l.liveTv,
                          emptyMessage: l.categoryEmptyLive,
                          categories: liveCategories,
                          isHidden: filter.isLiveHidden,
                          onToggle: notifier.setLiveCategoryVisible,
                          channels: true,
                        ),
                      ),
                      _tabList(
                        _CategorySection(
                          title: l.films,
                          emptyMessage: l.categoryEmptyMovies,
                          categories: vodCategories,
                          isHidden: filter.isVodHidden,
                          onToggle: notifier.setVodCategoryVisible,
                        ),
                      ),
                      _tabList(
                        _CategorySection(
                          title: l.series,
                          emptyMessage: l.categoryEmptySeries,
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
      focusNode: _tabFocusNodes[index],
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        final direction = event.logicalKey == LogicalKeyboardKey.arrowRight
            ? 1
            : event.logicalKey == LogicalKeyboardKey.arrowLeft
                ? -1
                : 0;
        final next = index + direction;
        if (direction == 0 || next < 0 || next >= _tabFocusNodes.length) {
          return KeyEventResult.ignored;
        }
        _tabFocusNodes[next].requestFocus();
        return KeyEventResult.handled;
      },
      onFocusChange: (focused) {
        if (focused && _tabController.index != index) {
          _tabController.animateTo(index);
        }
      },
      child: Tab(
        text: hiddenCount > 0
            ? AppLocalizations.of(context).categoryHidden(label, hiddenCount)
            : label,
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

  String _scannedLabel(AppLocalizations l) {
    final at = scannedAt;
    if (at == null) return l.categoryNeverScanned;
    final days = DateTime.now().difference(at).inDays;
    if (days <= 0) return l.categoryScannedToday;
    if (days == 1) return l.categoryScannedYesterday;
    return l.categoryScannedDaysAgo(days);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
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
            l.categorySubscriptionSettings(_scannedLabel(l)),
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
              label: Text(scanning ? l.categoryScanning : l.categoryRescan),
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
    this.channels = false,
  });

  final bool channels;
  final String title;
  final String emptyMessage;
  final List<MediaCategory> categories;
  final bool Function(String categoryId) isHidden;
  final Future<void> Function(String categoryId, bool visible) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
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
              subtitle: category.count > 0
                  ? Text(channels
                      ? l.categoryChannelsCount(category.count)
                      : l.categoryTitlesCount(category.count))
                  : null,
            );
          },
        ),
      ],
    );
  }
}
