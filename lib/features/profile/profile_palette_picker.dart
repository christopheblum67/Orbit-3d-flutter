import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';

/// Selecteur d'identite visuelle : 8 palettes predefinies.
///
/// Chaque palette definit `primary`, `secondary`, `tertiary` du theme.
/// L'utilisateur choisit sa palette dans le profil -> tout l'app adopte
/// cette couleur (boutons, icones, bordures, texte de mise en valeur).
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
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ListTile(
          leading: Icon(Icons.palette_outlined),
          title: Text('Palette'),
          subtitle: Text('Identite visuelle personnalisee'),
        ),
        const SizedBox(height: 8),
        FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (int i = 0; i < _palettes.length; i++)
                _PaletteChip(
                  def: _palettes[i],
                  selected: prefs.palette == _palettes[i].key,
                  autofocus: i == 0 && prefs.palette == _palettes[i].key,
                  onTap: () {
                    notifier.setPalette(_palettes[i].key);
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            'Palette "${_palettes[i].name}" appliquee -- redemarrage recommande',
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Redemarrer l'application pour appliquer completement la nouvelle palette.",
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.white70,
            fontSize: 12,
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

class _PaletteChip extends StatefulWidget {
  const _PaletteChip({
    required this.def,
    required this.selected,
    required this.onTap,
    this.autofocus = false,
  });

  final _PaletteDef def;
  final bool selected;
  final VoidCallback onTap;
  final bool autofocus;

  @override
  State<_PaletteChip> createState() => _PaletteChipState();
}

class _PaletteChipState extends State<_PaletteChip> {
  bool _focused = false;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      widget.onTap();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (v) => setState(() => _focused = v),
      onKeyEvent: _onKey,
      child: Semantics(
        button: true,
        selected: widget.selected,
        label: 'Palette ${widget.def.name}',
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: widget.def.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _focused
                    ? scheme.primary
                    : widget.selected
                        ? scheme.onSurface
                        : Colors.transparent,
                width: _focused ? 4 : widget.selected ? 3 : 0,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.def.color.withValues(
                      alpha: _focused ? 0.9 : widget.selected ? 0.6 : 0.35),
                  blurRadius: _focused ? 24 : widget.selected ? 14 : 8,
                  spreadRadius: _focused ? 6 : widget.selected ? 2 : 1,
                ),
                if (_focused)
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.6),
                    blurRadius: 36,
                    spreadRadius: 8,
                  ),
              ],
            ),
            child: Center(
              child: Text(
                widget.def.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}