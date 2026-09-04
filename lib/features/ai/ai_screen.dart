import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/models/ai_recommendation.dart';
import 'package:orbit_3d_flutter/services/ai_service.dart';

class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> {
  bool _generated = false;
  int _generation = 0;

  void _generate() {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun profil sélectionné')),
      );
      return;
    }
    setState(() {
      _generated = true;
      // Incrémente la génération : force un re-fetch même si la clé
      // précédente était déjà résolue en cache (autoDispose).
      _generation++;
    });
  }

  void _goBack() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(currentProfileProvider);
    final key = profile == null ? '' : '${profile.id}#$_generation';
    final async = ref.watch(aiRecommendationsProvider(key));

    final Widget content;
    if (!_generated || profile == null) {
      content = EmptyState(
        icon: Icons.auto_awesome,
        title: 'Recommandations IA',
        message: 'Obtenez des suggestions de films et séries adaptées à votre profil.',
        action: profile == null
            ? FilledButton.icon(
                icon: const Icon(Icons.person_outline),
                label: const Text('Choisir un profil'),
                onPressed: () => context.go('/profiles'),
              )
            : FilledButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Obtenir des recommandations'),
              ),
      );
    } else {
      content = async.when(
        data: (recommendations) {
          if (recommendations.isEmpty) {
            return ErrorState(
              icon: Icons.auto_awesome,
              title: 'Aucune recommandation',
              message: 'Le service IA n\'a renvoyé aucun contenu. Réessaie.',
              onRetry: _generate,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: recommendations.length,
            itemBuilder: (context, index) =>
                _RecommendationCard(recommendation: recommendations[index]),
          );
        },
        loading: () => const LoadingState(
          message: 'L\'IA réfléchit…',
          subtitle: 'Génération de tes recommandations',
        ),
        error: (error, _) => ErrorState(
          icon: Icons.auto_awesome,
          title: 'Recommandations indisponibles',
          message: _errorMessage(error),
          onRetry: _generate,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: _GeneratedBackLeading(
          onPressed: _goBack,
          generated: _generated && profile != null,
        ),
        title: const Text('Recommandations IA'),
        actions: [
          IconButton(
            tooltip: 'Obtenir des recommandations',
            onPressed: profile == null ? null : _generate,
            icon: const Icon(Icons.auto_awesome),
            color: scheme.secondary,
          ),
          if (_generated && profile != null)
            _RefreshButton(onPressed: _generate),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    profile == null
                        ? 'Sélectionne un profil pour commencer.'
                        : 'Suggestions pour ${profile.firstName}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: content,
            ),
          ),
        ],
      ),
    );
  }

  String _errorMessage(Object error) {
    if (error is StreamAiException) return error.message;
    return aiUserFriendlyError(error);
  }
}

/// Bouton retour en haut à gauche de l'écran IA (revient à l'accueil).
class _GeneratedBackLeading extends StatelessWidget {
  const _GeneratedBackLeading({required this.onPressed, required this.generated});

  final VoidCallback onPressed;
  final bool generated;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: 'Retour à l\'accueil',
      onPressed: onPressed,
      icon: Icon(
        generated ? Icons.arrow_back : Icons.arrow_back,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

/// Bouton de rafraîchissement explicite des recommandations IA.
class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: 'Rafraîchir les recommandations',
      onPressed: onPressed,
      icon: const Icon(Icons.refresh_rounded),
      color: scheme.tertiary,
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.recommendation});

  final AIRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CategoryIcon(category: recommendation.category),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recommendation.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      if (recommendation.rating != null) ...[
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(
                          recommendation.rating!.toStringAsFixed(1),
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (recommendation.reason.isNotEmpty) ...[
                    Text(
                      recommendation.reason,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  _CategoryBadge(category: recommendation.category),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSeries = category.toLowerCase().contains('série') ||
        category.toLowerCase().contains('serie');
    final color = isSeries ? scheme.tertiary : scheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        category,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSeries = category.toLowerCase().contains('série') ||
        category.toLowerCase().contains('serie');
    final color = isSeries ? scheme.tertiary : scheme.secondary;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.08)],
        ),
      ),
      child: Icon(
        isSeries ? Icons.live_tv : Icons.movie,
        color: color,
        size: 22,
      ),
    );
  }
}
