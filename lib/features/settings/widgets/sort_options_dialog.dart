import 'package:flutter/material.dart';

import 'package:orbit_3d_flutter/core/services/media_library_manager.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

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

  /// Inclut le mode « Affinité » (triché par le score matchmaking du profil
  /// courant). Seuls les écrans Films et Séries le proposent : ailleurs, ce
  /// mode dépasse l'objet du tri (note/année/nom) et l'écran n'a pas le
  /// contexte de profil.
  final bool withAffinity;

  const SortOptionsDialogTV({
    super.key,
    required this.currentMode,
    required this.onSortSelected,
    this.withAffinity = false,
  });

  /// Méthode d'ouverture statique
  static Future<void> show(
    BuildContext context, {
    required SortMode currentMode,
    required Function(SortMode) onSortSelected,
    bool withAffinity = false,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => SortOptionsDialogTV(
        currentMode: currentMode,
        onSortSelected: onSortSelected,
        withAffinity: withAffinity,
      ),
    );
  }

  @override
  State<SortOptionsDialogTV> createState() => _SortOptionsDialogTVState();
}

class _SortOptionsDialogTVState extends State<SortOptionsDialogTV> {
  // Liste des options de tri avec métadonnées visuelles.
  //
  // Un seul représentant par critère : le sens ne se choisit plus ici mais
  // avec le bouton ↑/↓ de la barre d'outils (`SortModeDirection.reversed`).
  // L'ordre alphabétique n'y figure pas non plus : il a son propre bouton
  // (A→Z / Z→A) dans la même barre d'outils.
  List<SortOptionData> _getOptions(AppLocalizations l) {
    return [
      SortOptionData(
        mode: SortMode.recentlyAdded,
        label: l.sortLatestM3UXtream,
        description: l.sortRecentDescription,
        icon: Icons.access_time,
      ),
      SortOptionData(
        mode: SortMode.resumeFirst,
        label: l.sortResumePriority,
        description: l.sortResumeDescription,
        icon: Icons.play_circle_outline,
      ),
      SortOptionData(
        mode: SortMode.ratingDesc,
        label: l.sortByRating,
        description: l.sortRatingDescription,
        icon: Icons.star,
      ),
      SortOptionData(
        mode: SortMode.yearDesc,
        label: l.sortByYear,
        description: l.sortYearDescription,
        icon: Icons.calendar_today,
      ),
      SortOptionData(
        mode: SortMode.durationShort,
        label: l.sortByDuration,
        description: l.sortDurationDescription,
        icon: Icons.timer,
      ),
      // Ajouté en fin de liste pour ne pas voler l'autofocus D-Pad (index 0 =
      // « Récents »). N'apparaît que sur les écrans Films/Séries : le score
      // vient du profil matchmaking courant (voir `withAffinity`).
      if (widget.withAffinity)
        SortOptionData(
          mode: SortMode.affinity,
          label: l.sortAffinity,
          description: l.sortAffinityDescription,
          icon: Icons.auto_awesome,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final options = _getOptions(l);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF16181E),
          borderRadius: BorderRadius.circular(16),
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
            Row(
              children: [
                const Icon(
                  Icons.filter_alt,
                  color: Color(0xFF8B5CF6),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.sortOptionsTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l.sortOptionsHelp,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
            const Divider(color: Color(0xFF262933), height: 12),

            // Liste scrollable des options — FocusTraversalGroup : ordre de
            // navigation D-pad télécommande TV explicite.
            Flexible(
              child: FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    // Comparaison sur le critère seul : le mode courant peut être
                    // le sens inverse (`yearAsc`) choisi via le bouton ↑/↓, et
                    // l'entrée « Par année » doit rester marquée active.
                    final isActive =
                        option.mode.criterion == widget.currentMode.criterion;

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
            ),
          ],
        ),
      ),
    );
  }
}

/// Éléments individuels gérant le Focus D-Pad (wrapper [TvFocus] : halo TV +
/// Enter/Select = sélection de l'option).
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: TvFocus(
        enableTvEffects: false,
        autofocus: widget.autofocus,
        onActivate: widget.onSelect,
        onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
        child: Semantics(
          button: true,
          selected: widget.isActive,
          child: GestureDetector(
            onTap: widget.onSelect,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isFocused
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.22)
                        : (widget.isActive
                            ? Colors.amber.withValues(alpha: 0.12)
                            : const Color(0xFF262933)),
                    border: Border.all(
                      color: _isFocused
                          ? const Color(0xFF8B5CF6)
                          : (widget.isActive
                              ? Colors.amber
                              : Colors.transparent),
                      width: _isFocused ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    widget.option.icon,
                    color: _isFocused
                        ? const Color(0xFFBFA6FF)
                        : (widget.isActive ? Colors.amber : Colors.white70),
                    size: 17,
                  ),
                ),
                const SizedBox(width: 8),

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
                              : (widget.isActive
                                  ? Colors.amber
                                  : Colors.white70),
                          fontSize: 12,
                          fontWeight: _isFocused || widget.isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      Text(
                        widget.option.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),

                if (widget.isActive)
                  const Padding(
                    padding: EdgeInsetsDirectional.only(start: 4),
                    child:
                        Icon(Icons.check_circle, color: Colors.amber, size: 15),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
