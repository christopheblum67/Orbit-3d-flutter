import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_3d_flutter/core/utils/epg_lookup.dart';
import 'package:orbit_3d_flutter/core/widgets/cached_image.dart';
import 'package:orbit_3d_flutter/core/widgets/orbit_loading_cinematic.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/features/live_tv/widgets/live_channel_video.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// Navigation Live TV, ouverte après le choix d'une chaîne dans la grille.
///
/// Le contenu est identique partout — les chaînes de la catégorie courante, la
/// diffusion en cours de la chaîne sélectionnée, et les programmes diffusés sur
/// cette chaîne — seule la MISE EN PAGE s'adapte à l'écran, car les trois
/// surfaces possibles n'ont rien de commun en proportions :
///
/// - **large** (téléphone en paysage, écran TV) : la maquette à deux zones,
///   chaîne à gauche, diffusion en haut à droite et EPG dans l'espace restant
///   en bas à droite ;
/// - **étroit** (téléphone en portrait) : la colonne de gauche laisserait une
///   largeur de logo inexploitable, donc on empile — diffusion en haut, puis les
///   chaînes en bandeau horizontal, puis l'EPG ;
/// - **très large** (TV) : chaînes à gauche, vidéo et EPG empilés à droite.
///
/// Les noms de chaînes sont affichés **tels que le panel les publie**
/// (« |FR| TF1 FHD ») : c'est cette forme que l'utilisateur reconnaît, et la
/// simplifier faisait disparaître la variante (HD, 4K) dans une troncature.
class ChannelBrowseView extends ConsumerWidget {
  const ChannelBrowseView({
    super.key,
    required this.channels,
    required this.selected,
    required this.onSelect,
    required this.onWatch,
    required this.onBack,
    required this.categoryName,
    this.previewActive = true,
    this.onPreviousCategory,
    this.onNextCategory,
  });

  /// Les chaînes de la catégorie courante.
  final List<Channel> channels;

  /// Chaîne dont la diffusion et l'EPG sont affichés.
  final Channel selected;

  final ValueChanged<Channel> onSelect;

  /// Lance la lecture plein écran.
  final VoidCallback onWatch;

  /// Retour à la grille (et donc au rail de catégories).
  final VoidCallback onBack;

  /// Nom de la catégorie affichée, entre les deux flèches.
  final String categoryName;

  /// `false` pendant que le lecteur plein écran recouvre cette vue.
  final bool previewActive;

  /// Catégorie précédente, ou `null` s'il n'y en a pas d'autre qui ait du
  /// contenu — la flèche disparaît alors plutôt que d'être inerte.
  final VoidCallback? onPreviousCategory;

  /// Catégorie suivante, voir [onPreviousCategory].
  final VoidCallback? onNextCategory;

  /// En dessous de cette largeur, la maquette à deux zones ne tient pas.
  static const double _wideBreakpoint = 720;

  /// Part de la hauteur que le cadre vidéo peut occuper en portrait. Le reste
  /// revient au bandeau de chaînes et à l'EPG, qui doit rester visible sans
  /// défilement.
  static const double _videoHeightRatio = 0.30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowDown &&
            liveWatchFocusNode.hasPrimaryFocus &&
            liveWatchFocusNode.focusInDirection(TraversalDirection.down)) {
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          onBack();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              _BrowseHeader(
                categoryName: categoryName,
                onBack: onBack,
                onPreviousCategory: onPreviousCategory,
                onNextCategory: onNextCategory,
              ),
              Expanded(
                child: constraints.maxWidth >= _wideBreakpoint
                    ? _buildWide(constraints)
                    : _buildCompact(constraints),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Maquette à deux zones : chaînes à gauche, diffusion + EPG à droite.
  Widget _buildWide(BoxConstraints constraints) {
    // Proportionnel à l'espace, pour tenir aussi bien sur un téléphone en
    // paysage que sur un écran TV.
    final listWidth = (constraints.maxWidth * 0.26).clamp(230.0, 380.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: listWidth,
          child: _ChannelList(
            channels: channels,
            selected: selected,
            onSelect: onSelect,
            onWatch: onWatch,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: LiveChannelVideo(
                    channel: selected,
                    onWatch: onWatch,
                    active: previewActive,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 4,
                  child: _EpgList(channel: selected, dense: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Empilement pour le téléphone en portrait.
  Widget _buildCompact(BoxConstraints constraints) {
    // Le cadre vidéo ne doit pas manger la hauteur disponible : en pleine
    // largeur (400 dp), un 16:9 occupe 230 dp de haut, et les deux programmes
    // EPG passaient sous le bord de l'écran. On le borne donc aussi par la
    // hauteur, pour qu'il prenne au plus [_videoHeightRatio] de la place
    // verticale — l'EPG garde ainsi toujours sa part, sans défilement.
    final byWidth = constraints.maxWidth / (16 / 9);
    final maxByHeight = constraints.maxHeight * _videoHeightRatio;
    final videoHeight = byWidth < maxByHeight ? byWidth : maxByHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SizedBox(
            height: videoHeight,
            child: LiveChannelVideo(
              channel: selected,
              onWatch: onWatch,
              active: previewActive,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Les chaînes passent en bandeau horizontal : sur 400 dp de large, une
        // colonne verticale ne laisserait qu'un logo illisible par ligne.
        SizedBox(
          height: 84,
          child: _ChannelStrip(
            channels: channels,
            selected: selected,
            onSelect: onSelect,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _EpgList(channel: selected, dense: true),
          ),
        ),
      ],
    );
  }
}

/// Barre haute de la vue de navigation.
///
/// Le retour ramène à la grille, et les deux flèches font défiler les
/// catégories SANS y repasser : c'était le manque le plus visible, il fallait
/// revenir à la grille puis re-cliquer le rail pour comparer deux groupes. La
/// catégorie courante est écrite entre les deux flèches, les catégories vides
/// étant sautées.
class _BrowseHeader extends StatelessWidget {
  const _BrowseHeader({
    required this.categoryName,
    required this.onBack,
    required this.onPreviousCategory,
    required this.onNextCategory,
  });

  final String categoryName;
  final VoidCallback onBack;
  final VoidCallback? onPreviousCategory;
  final VoidCallback? onNextCategory;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final canStep = onPreviousCategory != null || onNextCategory != null;
    final label = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Text(
        categoryName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 0),
      child: Row(
        children: [
          _HeaderButton(
            icon: Icons.arrow_back_rounded,
            tooltip: AppLocalizations.of(context).liveBackToChannels,
            onPressed: onBack,
          ),
          // Deux espaces élastiques : le nom de catégorie reste centré malgré
          // la touche retour à gauche.
          const Spacer(),
          if (canStep) ...[
            _HeaderButton(
              icon: Icons.chevron_left_rounded,
              tooltip: AppLocalizations.of(context).livePreviousCategory,
              onPressed: onPreviousCategory,
            ),
            label,
            _HeaderButton(
              icon: Icons.chevron_right_rounded,
              tooltip: AppLocalizations.of(context).liveNextCategory,
              onPressed: onNextCategory,
            ),
          ] else
            label,
          const Spacer(),
        ],
      ),
    );
  }
}

/// Touche ronde compacte de la barre haute.
///
/// Volontairement plus petite qu'un `IconButton` par défaut : ces trois
/// commandes servent à se déplacer, pas à agir sur la lecture, et elles
/// cohabitent avec la liste des chaînes.
class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      iconSize: 20,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        foregroundColor: scheme.onSurface,
        disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.3),
        shape: const CircleBorder(),
      ),
    );
  }
}

/// Colonne des chaînes (écran large).
class _ChannelList extends StatelessWidget {
  const _ChannelList({
    required this.channels,
    required this.selected,
    required this.onSelect,
    required this.onWatch,
  });

  final List<Channel> channels;
  final Channel selected;
  final ValueChanged<Channel> onSelect;
  final VoidCallback onWatch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final channel = channels[index];
        final isSelected = channel.id == selected.id;
        return Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.arrowRight &&
                liveWatchFocusNode.canRequestFocus &&
                liveWatchFocusNode.context != null) {
              liveWatchFocusNode.requestFocus();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: TvFocus(
            key: ValueKey(channel.id),
            onActivate: () => isSelected ? onWatch() : onSelect(channel),
            onFocusChange: (focused) {
              // Le focus suit le mouvement D-pad : l'aperçu et l'EPG suivent la
              // chaîne survolée, sans geste de validation pour explorer.
              if (focused && !isSelected) onSelect(channel);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Material(
                color:
                    isSelected ? scheme.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                // Geste tactile : sans lui, la seule façon de changer de chaîne
                // était la télécommande.
                child: InkWell(
                  canRequestFocus: false,
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => isSelected ? onWatch() : onSelect(channel),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 52,
                          height: 32,
                          child: CachedImage(
                            // 52x32 logiques : borné à ~112 px physiques, donc
                            // pas de décodage d'un logo de 1024 px en mémoire
                            // (une image `original` 2000×3000 = ~24 Mo).
                            // Passe aussi par le cache disque partagé
                            // (5000 objets, TTL 30 j) au lieu de le contourner.
                            imageUrl: channel.logoUrl,
                            width: 52,
                            height: 32,
                            memCacheWidth: 112,
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => Icon(
                              Icons.tv_rounded,
                              size: 20,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            channel.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Bandeau horizontal des chaînes (téléphone en portrait).
class _ChannelStrip extends StatelessWidget {
  const _ChannelStrip({
    required this.channels,
    required this.selected,
    required this.onSelect,
  });

  final List<Channel> channels;
  final Channel selected;
  final ValueChanged<Channel> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: channels.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final channel = channels[index];
        final isSelected = channel.id == selected.id;
        return TvFocus(
          onActivate: () => onSelect(channel),
          onFocusChange: (focused) {
            if (focused && !isSelected) onSelect(channel);
          },
          child: SizedBox(
            width: 104,
            child: Material(
              color: isSelected
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8),
              // Geste tactile : sans lui, le bandeau pouvait se faire défiler
              // au doigt mais aucun appui ne changeait de chaîne.
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onSelect(channel),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: CachedImage(
                          // Bandeau horizontal : la bande défilait en
                          // logos décodés en pleine résolution.
                          imageUrl: channel.logoUrl,
                          memCacheWidth: 112,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => Icon(
                            Icons.tv_rounded,
                            size: 20,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        channel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Les programmes diffusés sur la chaîne : le programme en cours et les
/// suivants des prochaines heures.
class _EpgList extends ConsumerStatefulWidget {
  const _EpgList({required this.channel, required this.dense});

  final Channel channel;

  /// `true` sur les écrans étroits : une ligne compacte, sans description.
  final bool dense;

  /// Nombre maximal de programmes listés (en cours + à venir, défilables).
  static const int _maxPrograms = 8;

  /// Horizon de la liste : au-delà, les programmes n'aident pas au choix.
  static const Duration _horizon = Duration(hours: 8);

  @override
  ConsumerState<_EpgList> createState() => _EpgListState();
}

class _EpgListState extends ConsumerState<_EpgList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final programsAsync = ref.watch(channelPreviewEpgProvider(widget.channel));

    return Focus(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        if (node.hasPrimaryFocus &&
            event.logicalKey == LogicalKeyboardKey.arrowUp &&
            (!_scrollController.hasClients || _scrollController.offset <= 0)) {
          liveWatchFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
        if (node.hasPrimaryFocus &&
            (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                event.logicalKey == LogicalKeyboardKey.arrowUp) &&
            _scrollController.hasClients) {
          final position = _scrollController.position;
          final delta =
              event.logicalKey == LogicalKeyboardKey.arrowDown ? 72.0 : -72.0;
          _scrollController.jumpTo(
            (position.pixels + delta).clamp(0.0, position.maxScrollExtent),
          );
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: programsAsync.when(
        loading: () => const Center(child: OrbitDelayedLoadingIndicator()),
        error: (_, __) => Center(
          child: Text(
            l.liveGuideUnavailable,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        data: (programs) {
          if (programs.isEmpty) {
            return Center(
              child: Text(
                l.liveNoPrograms,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          final now = DateTime.now();
          // Programme en cours puis à venir, jusqu'à l'horizon ; la liste défile
          // si la place manque.
          final limit = now.add(_EpgList._horizon);
          final visible = epgPreviewPrograms(
            programs.where((p) => p.start.isBefore(limit)).toList(),
            now,
            maxPrograms: _EpgList._maxPrograms,
          );
          final current = epgCurrentProgram(programs, now);
          if (visible.isEmpty) {
            return Center(
              child: Text(
                l.liveNoUpcomingPrograms,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              itemCount: visible.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final program = visible[index];
                return _EpgRow(
                  program: program,
                  isCurrent: current?.start == program.start,
                  dense: widget.dense,
                  first: index == 0,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Une ligne EPG : « 20:00 - 20:30   JT 20h ».
class _EpgRow extends StatelessWidget {
  const _EpgRow({
    required this.program,
    required this.isCurrent,
    required this.dense,
    required this.first,
  });

  final EPGProgram program;
  final bool isCurrent;
  final bool dense;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    void showDetails() {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(program.title),
          content: SingleChildScrollView(
            child: Text(
              '${_hhmm(program.start)} - ${_hhmm(program.end)}\n\n'
              '${program.description.isEmpty ? l.liveNoDescription : program.description}',
            ),
          ),
          actions: [
            TextButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(),
              child: Text(MaterialLocalizations.of(context).closeButtonLabel),
            ),
          ],
        ),
      );
    }

    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) {
        if (first &&
            event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowUp) {
          liveWatchFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TvFocus(
        onActivate: showDetails,
        onFocusChange: (focused) {
          if (focused) Scrollable.ensureVisible(context);
        },
        child: GestureDetector(
          onTap: showDetails,
          child: Container(
            color: isCurrent
                ? scheme.primaryContainer.withValues(alpha: 0.35)
                : null,
            padding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: dense ? 7 : 10,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: dense ? 96 : 116,
                  child: Text(
                    '${_hhmm(program.start)} - ${_hhmm(program.end)}',
                    style: textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        program.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isCurrent ? FontWeight.w700 : FontWeight.w400,
                          color: isCurrent ? scheme.primary : scheme.onSurface,
                        ),
                      ),
                      // La description n'a de la place que sur les écrans larges.
                      if (!dense &&
                          program.description.isNotEmpty &&
                          isCurrent) ...[
                        const SizedBox(height: 2),
                        Text(
                          program.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
