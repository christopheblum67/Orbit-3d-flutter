import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/models/recommendation.dart';
import 'package:orbit_3d_flutter/providers/matchmaking_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// Ouvre la feuille de décision pour [reco] : « film déjà vu » ou « pas
/// intéressé », puis Valider / Annuler.
///
/// ## Pourquoi une confirmation explicite
///
/// Les deux options ont des conséquences **irréversibles** sur l'algorithme :
/// « déjà vu » exclut le contenu des propositions futures, « pas intéressé »
/// l'écarte définitivement. Un appui long perdu — geste accidentel, tactile
/// mal placé — aurait donc un effet durable et invisible.
///
/// D'où les trois étapes : choisir l'intention, puis **Valider / Annuler**.
/// L'annulation ne modifie rien et laisse la recommandation en place.
///
/// Retourne `true` si l'utilisateur a validé, `false` sinon.
Future<bool> showProlongDecision(
  BuildContext context,
  WidgetRef ref,
  Recommendation reco,
) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => _ProlongDecisionSheet(reco: reco),
  );
  if (confirmed != true) return false;

  // L'effet n'est appliqué qu'après validation explicite : c'est ce qui
  // distingue un choix d'un geste accidentel.
  //
  // `seenRecoIdsProvider` est indexé par **profil**, pas par contenu : les
  // marqueurs sont persistés par profil pour que « déjà vu » sur le profil
  // enfant n'affecte pas les propositions du profil parent.
  final profile = ref.read(currentProfileProvider);
  if (profile != null) {
    await ref.read(seenRecoIdsProvider(profile.id).notifier).add(reco.id);
  }
  ref.invalidate(matchmakingTabProvider);
  return true;
}

class _ProlongDecisionSheet extends StatelessWidget {
  const _ProlongDecisionSheet({required this.reco});

  final Recommendation reco;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        // FocusTraversalGroup + TvFocus : navigation D-pad télécommande TV,
        // autofocus sur la première option de décision.
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ce film vous appartient ?',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                reco.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TvFocus(
                autofocus: true,
                onActivate: () => Navigator.of(context).pop(true),
                child: _DecisionTile(
                  icon: Icons.visibility_off_outlined,
                  label: 'Film déjà vu',
                  detail: 'Retiré des prochaines suggestions',
                  onTap: () => Navigator.of(context).pop(true),
                ),
              ),
              const SizedBox(height: 8),
              TvFocus(
                onActivate: () => Navigator.of(context).pop(true),
                child: _DecisionTile(
                  icon: Icons.thumb_down_alt_outlined,
                  label: 'Pas intéressé',
                  detail: 'Écarté définitivement des suggestions',
                  onTap: () => Navigator.of(context).pop(true),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TvFocus(
                      onActivate: () => Navigator.of(context).pop(false),
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Annuler'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TvFocus(
                      onActivate: () => Navigator.of(context).pop(true),
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Confirmer'),
                      ),
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
  });

  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
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
                    Text(label, style: Theme.of(context).textTheme.titleSmall),
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
    );
  }
}
