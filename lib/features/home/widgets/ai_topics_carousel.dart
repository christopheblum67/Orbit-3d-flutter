import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/vod_category_filter_provider.dart';

/// Un topic = une catégorie de l'abonnement, cliquable vers le contenu filtré.
class AiTopic {
  const AiTopic({
    required this.id,
    required this.label,
    required this.icon,
    required this.count,
    required this.isSeries,
    required this.color,
  });

  final String id;
  final String label;
  final IconData icon;
  final int count;

  /// true = catégorie Séries, false = catégorie Films.
  final bool isSeries;
  final Color color;
}

/// Topics alimentés par les vraies catégories VOD / Séries de l'abonnement
/// actif, en excluant celles masquées par l'utilisateur.
final aiTopicsProvider = FutureProvider<List<AiTopic>>((ref) async {
  final filter = ref.watch(vodCategoryFilterProvider);
  final vodCategories =
      ref.watch(vodCategoriesProvider).value ?? const <MediaCategory>[];
  final seriesCategories =
      ref.watch(seriesCategoriesProvider).value ?? const <MediaCategory>[];

  // Palette alternée pour distinguer visuellement les deux types.
  const vodColors = <Color>[
    Color(0xFF6C5CE7),
    Color(0xFF0984E3),
    Color(0xFF00B894),
    Color(0xFFE17055),
  ];
  const seriesColors = <Color>[
    Color(0xFFE84393),
    Color(0xFF00CEC9),
    Color(0xFFFDCB6E),
    Color(0xFFA29BFE),
  ];

  final topics = <AiTopic>[];
  var vodIndex = 0;
  for (final cat in vodCategories) {
    if (filter.hiddenVodCategoryIds.contains(cat.id)) continue;
    topics.add(AiTopic(
      id: cat.id,
      label: cat.name,
      icon: Icons.movie_outlined,
      count: cat.count,
      isSeries: false,
      color: vodColors[vodIndex % vodColors.length],
    ));
    vodIndex++;
  }
  var seriesIndex = 0;
  for (final cat in seriesCategories) {
    if (filter.hiddenSeriesCategoryIds.contains(cat.id)) continue;
    topics.add(AiTopic(
      id: cat.id,
      label: cat.name,
      icon: Icons.tv_outlined,
      count: cat.count,
      isSeries: true,
      color: seriesColors[seriesIndex % seriesColors.length],
    ));
    seriesIndex++;
  }
  return topics;
});

/// Carrousel horizontal de topics.
class AiTopicsCarousel extends ConsumerWidget {
  const AiTopicsCarousel({super.key, this.showHeader = true});

  /// L'écran dédié masque le titre (il est déjà dans l'AppBar).
  final bool showHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final asyncTopics = ref.watch(aiTopicsProvider);

    return asyncTopics.when(
      loading: () => const SizedBox(height: 140),
      error: (_, __) => const SizedBox.shrink(),
      data: (topics) {
        if (topics.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(l.aiTopicsTitle,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            SizedBox(
              height: 140,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: topics.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    _AiTopicCard(topic: topics[index]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AiTopicCard extends StatelessWidget {
  const _AiTopicCard({required this.topic});

  final AiTopic topic;

  @override
  Widget build(BuildContext context) {
    final color = topic.color;
    return GestureDetector(
      onTap: () {
        final id = Uri.encodeComponent(topic.id);
        // films -> /vod?category=..., séries -> /series?category=...
        context.push(topic.isSeries
            ? '/series?category=$id'
            : '/vod?category=$id');
      },
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.25), color.withOpacity(0.10)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(topic.icon, color: color, size: 24),
                ),
                const Spacer(),
                if (topic.count > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${topic.count}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              topic.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                const Icon(Icons.tune_outlined, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(
                  topic.isSeries ? 'Séries' : 'Films',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
