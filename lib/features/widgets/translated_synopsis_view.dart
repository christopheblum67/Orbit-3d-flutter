import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/providers/synopsis_translation_provider.dart';

/// Bloc « Synopsis » qui affiche le texte traduit quand le contenu n'est pas
/// déjà en français, en indiquant explicitement la source de la traduction.
///
/// Résolution (cf. [SynopsisTranslationService]) : synopsis français TMDB en
/// priorité, sinon traduction automatique. Tant que la traduction n'est pas
/// arrivée, on affiche le texte d'origine — jamais d'écran vide.
class TranslatedSynopsisView extends ConsumerWidget {
  const TranslatedSynopsisView({
    super.key,
    required this.title,
    required this.rawSynopsis,
    this.isSeries = false,
  });

  final String title;
  final String rawSynopsis;

  /// Vrai si le contenu est une série : la résolution TMDB passe alors par
  /// `/search/tv` + `/tv/{id}` (overview fr-FR) au lieu du chemin film.
  final bool isSeries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rawSynopsis.trim().isEmpty) return const SizedBox.shrink();

    final async = ref.watch(
      translatedSynopsisProvider(
        (title: title, raw: rawSynopsis, isSeries: isSeries),
      ),
    );

    return async.when(
      // Texte d'origine le temps que la traduction arrive (ou si elle échoue).
      loading: () => _body(context, rawSynopsis, null),
      error: (_, __) => _body(context, rawSynopsis, null),
      data: (resolved) {
        if (resolved.text.trim().isEmpty) return const SizedBox.shrink();
        return _body(
          context,
          resolved.text,
          resolved.attribution,
          isTranslated: resolved.isTranslated,
        );
      },
    );
  }

  /// Couleur du texte quand le synopsis affiché provient d'une traduction
  /// (TMDB fr ou Google) : le rouge signale visuellement que ce n'est pas le
  /// texte d'origine du fournisseur.
  static const Color translatedTextColor = Colors.redAccent;

  Widget _body(
    BuildContext context,
    String text,
    String? attribution, {
    bool isTranslated = false,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Synopsis',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isTranslated ? translatedTextColor : scheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        if (attribution != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.translate, size: 12, color: scheme.outline),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  attribution,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: scheme.outline),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
