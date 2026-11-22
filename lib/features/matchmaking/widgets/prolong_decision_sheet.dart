import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/recommendation.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/matchmaking_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// Ouvre la feuille de décision pour [reco], puis Confirmer / Annuler.
///
/// ## Pourquoi une confirmation explicite
///
/// Les deux premières options ont des conséquences durables sur l'algorithme :
/// « déjà vu » exclut le contenu des propositions futures, « pas intéressé »
/// l'écarte définitivement. Un appui long perdu — geste accidentel, tactile
/// mal placé — aurait donc un effet durable et invisible.
///
/// D'où les trois étapes : choisir l'intention, puis **Valider / Annuler**.
/// L'annulation ne modifie rien et laisse la recommandation en place.
///
/// Retourne `true` si l'utilisateur a validé, `false` sinon.
enum _Decision { seen, notInterested, favorite }

Future<bool> showProlongDecision(
  BuildContext context,
  WidgetRef ref,
  Recommendation reco,
) async {
  final initialProfileId = ref.read(currentProfileProvider)?.id;
  final initialSubscriptionId = ref.read(activeSubscriptionProvider)?.id;
  final heldKeys = HardwareKeyboard.instance.logicalKeysPressed.intersection({
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.gameButtonA,
  });
  KeyEventResult blockHeldKey(KeyEvent event) {
    if (!heldKeys.contains(event.logicalKey)) return KeyEventResult.ignored;
    if (event is KeyUpEvent) heldKeys.remove(event.logicalKey);
    return KeyEventResult.handled;
  }

  if (heldKeys.isNotEmpty) {
    FocusManager.instance.addEarlyKeyEventHandler(blockHeldKey);
  }
  _Decision? decision;
  try {
    decision = await showModalBottomSheet<_Decision>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _ProlongDecisionSheet(reco: reco),
    );
  } finally {
    FocusManager.instance.removeEarlyKeyEventHandler(blockHeldKey);
  }
  if (decision == null || !context.mounted) return false;
  final l = AppLocalizations.of(context);

  // L'effet n'est appliqué qu'après validation explicite : c'est ce qui
  // distingue un choix d'un geste accidentel.
  //
  // `seenRecoIdsProvider` est indexé par **profil**, pas par contenu : les
  // marqueurs sont persistés par profil pour que « déjà vu » sur le profil
  // enfant n'affecte pas les propositions du profil parent.
  final profile = ref.read(currentProfileProvider);
  if (profile == null || profile.id != initialProfileId) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l.episodeProfileChanged),
    ));
    return false;
  }
  if (decision == _Decision.favorite) {
    if (ref.read(activeSubscriptionProvider)?.id != initialSubscriptionId) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.recommendationSubscriptionChanged),
      ));
      return false;
    }
    if (reco.id.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.recommendationCannotFavorite),
      ));
      return false;
    }
    final isMovie = reco.kind == RecommendationKind.movie;
    final entry = FavoriteEntry(
      type: isMovie ? ContentType.vod : ContentType.series,
      id: reco.id,
      title: reco.title,
      posterUrl: reco.posterUrl,
      subtitle: isMovie ? (reco.year > 0 ? '${reco.year}' : '') : reco.genre,
      streamUrl: isMovie
          ? reco.movie!.streamUrl
          : (reco.series!.episodes.isNotEmpty
              ? reco.series!.episodes.first.streamUrl
              : ''),
    );
    try {
      await ref.read(favoritesProvider.notifier).add(entry);
    } on FavoriteScopeRequired {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.favoritesNeedScope)));
      }
      return false;
    } on StateError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
      return false;
    } catch (error, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'matchmaking',
        context: ErrorDescription('while adding a favorite'),
      ));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.recommendationFavoriteFailed),
        ));
      }
      return false;
    }
    if (!context.mounted ||
        ref.read(currentProfileProvider)?.id != initialProfileId ||
        ref.read(activeSubscriptionProvider)?.id != initialSubscriptionId) {
      return false;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l.addedToFavorites(reco.title)),
    ));
    return true;
  }
  final notifier = decision == _Decision.seen
      ? ref.read(seenRecoIdsProvider(profile.id).notifier)
      : ref.read(dismissedRecoIdsProvider(profile.id).notifier);
  await notifier.add(reco.id);
  if (context.mounted) ref.invalidate(matchmakingTabProvider);
  return true;
}

class _ProlongDecisionSheet extends StatefulWidget {
  const _ProlongDecisionSheet({required this.reco});

  final Recommendation reco;

  @override
  State<_ProlongDecisionSheet> createState() => _ProlongDecisionSheetState();
}

class _ProlongDecisionSheetState extends State<_ProlongDecisionSheet> {
  _Decision? _selected;
  final _confirmFocus = FocusNode();

  void _select(_Decision decision) {
    setState(() => _selected = decision);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _confirmFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _confirmFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isMovie = widget.reco.kind == RecommendationKind.movie;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMovie
                            ? l.recommendationMovieQuestion
                            : l.recommendationSeriesQuestion,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.reco.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      _DecisionTile(
                        icon: Icons.visibility_off_outlined,
                        label: isMovie
                            ? l.recommendationMovieSeen
                            : l.recommendationSeriesSeen,
                        detail: l.recommendationRemovedFuture,
                        autofocus: true,
                        selected: _selected == _Decision.seen,
                        onTap: () => _select(_Decision.seen),
                      ),
                      const SizedBox(height: 8),
                      _DecisionTile(
                        icon: Icons.thumb_down_alt_outlined,
                        label: l.recommendationNotInterested,
                        detail: l.recommendationExcluded,
                        selected: _selected == _Decision.notInterested,
                        onTap: () => _select(_Decision.notInterested),
                      ),
                      const SizedBox(height: 8),
                      _DecisionTile(
                        icon: Icons.favorite_border,
                        label: l.favoritesAdd,
                        detail: l.recommendationFavoriteProfile,
                        selected: _selected == _Decision.favorite,
                        onTap: () => _select(_Decision.favorite),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      focusNode: _confirmFocus,
                      onPressed: _selected == null
                          ? null
                          : () => Navigator.of(context).pop(_selected),
                      child: Text(l.cloudConfirm),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DecisionTile extends StatelessWidget {
  const _DecisionTile({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
    required this.selected,
    this.autofocus = false,
  });

  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;
  final bool selected;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color:
          selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        canRequestFocus: false,
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: TvFocus(
          autofocus: autofocus,
          onActivate: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: scheme.onSurfaceVariant),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
