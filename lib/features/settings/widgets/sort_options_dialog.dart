import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orbit_3d_flutter/core/services/media_library_manager.dart';

/// Définition d'une option de tri avec son libellé et son icône
class SortOptionData {
  final SortMode mode;
  final String label;
  final String description;
  final IconData icon;

  const SortOptionData({
    required this.mode,
    required this.label,
    required this.description,
    required this.icon,
  });
}

class SortOptionsDialogTV extends StatefulWidget {
  final SortMode currentMode;
  final Function(SortMode) onSortSelected;

  const SortOptionsDialogTV({
    super.key,
    required this.currentMode,
    required this.onSortSelected,
  });

  /// Méthode d'ouverture statique
  static Future<void> show(
    BuildContext context, {
    required SortMode currentMode,
    required Function(SortMode) onSortSelected,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => SortOptionsDialogTV(
        currentMode: currentMode,
        onSortSelected: onSortSelected,
      ),
    );
  }

  @override
  State<SortOptionsDialogTV> createState() => _SortOptionsDialogTVState();
}

class _SortOptionsDialogTVState extends State<SortOptionsDialogTV> {
  // Liste des options de tri avec métadonnées visuelles
  final List<SortOptionData> _options = [
    const SortOptionData(
      mode: SortMode.resumeFirst,
      label: 'À reprendre en priorité',
      description: 'Place les contenus commencés non terminés en haut',
      icon: Icons.play_circle_outline,
    ),
    const SortOptionData(
      mode: SortMode.ratingDesc,
      label: 'Les Mieux Notés (XCIPTV)',
      description: 'Classement selon les notes attribuées',
      icon: Icons.star,
    ),
    const SortOptionData(
      mode: SortMode.yearDesc,
      label: 'Année de Sortie (Récent -> Ancien)',
      description: 'Tri chronologique par année de production',
      icon: Icons.calendar_today,
    ),
    const SortOptionData(
      mode: SortMode.recentlyAdded,
      label: 'Derniers Ajouts M3U/Xtream',
      description: 'Contenus importés récemment dans la liste',
      icon: Icons.access_time,
    ),
    const SortOptionData(
      mode: SortMode.nameAsc,
      label: 'Nom (A -> Z)',
      description: 'Ordre alphabétique croissant',
      icon: Icons.sort,
    ),
    const SortOptionData(
      mode: SortMode.nameDesc,
      label: 'Nom (Z -> A)',
      description: 'Ordre alphabétique décroissant',
      icon: Icons.sort_by_alpha,
    ),
    const SortOptionData(
      mode: SortMode.durationShort,
      label: 'Durée : Plus courts d\'abord',
      description: 'Idéal pour visionner un contenu rapide',
      icon: Icons.timer,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 100, vertical: 40),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF16181E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF262933), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            const Row(
              children: [
                Icon(
                  Icons.filter_alt,
                  color: Color(0xFF8B5CF6),
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Options de Tri Avancé',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Sélectionnez un mode avec la télécommande :',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const Divider(color: Color(0xFF262933), height: 28),

            // Liste scrollable des options
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _options.length,
                itemBuilder: (context, index) {
                  final option = _options[index];
                  final isActive = option.mode == widget.currentMode;

                  return SortOptionTileTV(
                    option: option,
                    isActive: isActive,
                    autofocus: index == 0,
                    onSelect: () {
                      widget.onSortSelected(option.mode);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Éléments individuels gérant le Focus D-Pad
class SortOptionTileTV extends StatefulWidget {
  final SortOptionData option;
  final bool isActive;
  final bool autofocus;
  final VoidCallback onSelect;

  const SortOptionTileTV({
    super.key,
    required this.option,
    required this.isActive,
    this.autofocus = false,
    required this.onSelect,
  });

  @override
  State<SortOptionTileTV> createState() => _SortOptionTileTVState();
}

class _SortOptionTileTVState extends State<SortOptionTileTV> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Focus(
        autofocus: widget.autofocus,
        onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.select ||
                  event.logicalKey == LogicalKeyboardKey.enter)) {
            widget.onSelect();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: widget.onSelect,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isFocused
                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.18)
                  : (widget.isActive ? const Color(0xFF1C1F26) : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isFocused
                    ? const Color(0xFF8B5CF6)
                    : (widget.isActive ? Colors.amber.withValues(alpha: 0.5) : const Color(0xFF262933)),
                width: _isFocused ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Icône du mode de tri
                Icon(
                  widget.option.icon,
                  color: _isFocused
                      ? const Color(0xFF8B5CF6)
                      : (widget.isActive ? Colors.amber : Colors.white38),
                  size: 22,
                ),
                const SizedBox(width: 14),

                // Libellé et Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.option.label,
                        style: TextStyle(
                          color: _isFocused
                              ? Colors.white
                              : (widget.isActive ? Colors.amber : Colors.white70),
                          fontSize: 14,
                          fontWeight: _isFocused || widget.isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.option.description,
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),

                // Badge de statut Actif
                if (widget.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Actif',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}