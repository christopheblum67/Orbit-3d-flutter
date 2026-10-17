import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';

/// Sélecteur d'identité visuelle : 8 palettes prédéfinies.
///
/// Chaque palette définit `primary`, `secondary`, `tertiary` du theme.
/// L'utilisateur choisit sa palette dans le profil → tout l'app adopte
/// cette couleur (boutons, icônes, bordures, texte de mise en valeur).
class ProfilePalettePicker extends ConsumerWidget {
  const ProfilePalettePicker({super.key});

  static const _palettes = <_PaletteDef>[
    _PaletteDef(name: 'Cyan', color: Color(0xFF00B8D4), key: 'cyan'),
    _PaletteDef(name: 'Indigo', color: Color(0xFF5B5BD6), key: 'indigo'),
    _PaletteDef(name: 'Rose', color: Color(0xFFFF4D8D), key: 'rose'),
    _PaletteDef(name: 'Violet', color: Color(0xFF7C4DFF), key: 'violet'),
    _PaletteDef(name: 'Vert', color: Color(0xFF00E676), key: 'vert'),
    _PaletteDef(name: 'Orange', color: Color(0xFFFFAB00), key: 'orange'),
    _PaletteDef(name: 'Rouge', color: Color(0xFFFF5252), key: 'rouge'),
    _PaletteDef(name: 'Bleu profond', color: Color(0xFF448AFF), key: 'bleu'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: Text(l.theme ?? 'Palette'),
          subtitle: Text('Identité visuelle personnalisée'),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final p in _palettes)
              _PaletteChip(
                def: p,
                selected: prefs.palette == p.key,
                onTap: () {
                  notifier.setPalette(p.key);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Palette « ${p.name} » appliquée — redémarrage recommandé'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Redémarrer l'application pour appliquer complètement la nouvelle palette.",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PaletteDef {
  const _PaletteDef({required this.name, required this.color, required this.key});
  final String name;
  final Color color;
  final String key;
}

class _PaletteChip extends StatelessWidget {
  const _PaletteChip({
    super.key,
    required this.def,
    required this.selected,
    required this.onTap,
  });

  final _PaletteDef def;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: def.color,
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? Border.all(color: scheme.onSurface, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: def.color.withValues(alpha: 0.35),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            def.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}
