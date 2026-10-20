import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/device_profile_provider.dart';
import 'package:orbit_3d_flutter/core/hardware/hardware_detector.dart';
import 'package:orbit_3d_flutter/core/hardware/player_config.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Accent de marque, partagé avec le reste de l'application.
const Color _kAccent = Color(0xFF00CFE8);

/// Dimensions (colonnes, lignes) de la grille multi-vue pour [count] flux.
///
/// La grille remplit **tout** l'espace disponible : chaque cellule a le même
/// poids (`Expanded`). C'est précisément ce qu'un `GridView` à
/// `childAspectRatio` fixe ne savait pas faire — il occupait la hauteur
/// dictée par le ratio, laissant le bas de l'écran vide.
///
/// - 1 flux  → 1×1
/// - 2 flux  → 2×1 en paysage, 1×2 en portrait
/// - 3 ou 4  → 2×2
({int columns, int rows}) multiViewGridDimensions(
  int count, {
  required bool landscape,
}) {
  if (count <= 1) return (columns: 1, rows: 1);
  if (count == 2) {
    return landscape ? (columns: 2, rows: 1) : (columns: 1, rows: 2);
  }
  return (columns: 2, rows: 2);
}

class MultiVideoScreen extends ConsumerStatefulWidget {
  const MultiVideoScreen({super.key});

  @override
  ConsumerState<MultiVideoScreen> createState() => MultiVideoScreenState();
}

class MultiVideoScreenState extends ConsumerState<MultiVideoScreen> {
  /// Chaînes affichées, dans l'ordre d'ajout.
  final List<Channel> _selectedChannels = [];

  /// Index de la tuile dont le son est actif.
  ///
  /// Toutes les tuiles jouent en continu (« simultanément »), mais une seule
  /// porte le son : sans cela, quatre flux parlaient en même temps.
  int _activeIndex = 0;

  /// Libère tous les lecteurs (appelé par la gestion du bouton retour).
  void disposeAllControllers() {
    if (_selectedChannels.isEmpty) return;
    setState(() {
      _selectedChannels.clear();
      _activeIndex = 0;
    });
  }

  bool _isSelected(Channel channel) =>
      _selectedChannels.any((c) => c.id == channel.id);

  void _removeChannel(Channel channel) {
    final index = _selectedChannels.indexWhere((c) => c.id == channel.id);
    if (index < 0) return;
    setState(() {
      _selectedChannels.removeAt(index);
      if (_selectedChannels.isEmpty) {
        _activeIndex = 0;
      } else if (index < _activeIndex) {
        // On a retiré une tuile AVANT la tuile active : elle a reculé d'un cran,
        // sinon le son passerait à la mauvaise chaîne.
        _activeIndex--;
      } else if (_activeIndex >= _selectedChannels.length) {
        _activeIndex = _selectedChannels.length - 1;
      }
    });
  }

  void _toggleChannel(Channel channel, int maxStreams) {
    if (_isSelected(channel)) {
      _removeChannel(channel);
      return;
    }
    if (_selectedChannels.length >= maxStreams) {
      HapticFeedback.mediumImpact();
      return;
    }
    setState(() {
      _selectedChannels.add(channel);
      if (_selectedChannels.length == 1) _activeIndex = 0;
    });
  }

  void _clearAll() {
    setState(() {
      _selectedChannels.clear();
      _activeIndex = 0;
    });
  }

  Future<void> _openPicker(List<Channel> channels, int maxStreams) async {
    final searchController = TextEditingController();
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF161A22),
        builder: (sheetContext) {
          final l = AppLocalizations.of(sheetContext);
          return StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              final query = searchController.text.trim().toLowerCase();
              final filtered = query.isEmpty
                  ? channels
                  : channels
                      .where((c) => c.name.toLowerCase().contains(query))
                      .toList(growable: false);
              return _ChannelPickerSheet(
                title: l.addChannel,
                hint: l.searchChannel,
                closeLabel: l.close,
                removeLabel: l.removeChannel,
                controller: searchController,
                onQueryChanged: () => setSheetState(() {}),
                channels: filtered,
                isSelected: _isSelected,
                canAddMore: _selectedChannels.length < maxStreams,
                onToggle: (channel) {
                  _toggleChannel(channel, maxStreams);
                  setSheetState(() {});
                },
              );
            },
          );
        },
      );
    } finally {
      searchController.dispose();
    }
  }

  AppBar _buildAppBar(
    BuildContext context, {
    required String title,
    List<Channel> channels = const [],
    int maxStreams = 0,
  }) {
    final l = AppLocalizations.of(context);
    return AppBar(
      leading: GoRouter.of(context).canPop()
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Retour',
              onPressed: () => GoRouter.of(context).pop(),
            )
          : null,
      title: Text(title),
      actions: [
        if (_selectedChannels.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            tooltip: l.removeAll,
            onPressed: _clearAll,
          ),
        if (maxStreams > 0)
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: l.addChannel,
            onPressed: channels.isEmpty
                ? null
                : () => _openPicker(channels, maxStreams),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final channelsAsync = ref.watch(liveChannelsProvider);
    final deviceProfile = ref.watch(deviceProfileProvider);
    final maxStreams = deviceProfile.maxMultiView;

    if (maxStreams <= 0) {
      return Scaffold(
        appBar: _buildAppBar(context, title: l.multiVideo),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Multi-vue désactivée par le profil Économique.\n'
              'Réglez le profil dans Configurer l\'appareil.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final channels = channelsAsync.value ?? const <Channel>[];

    return Scaffold(
      appBar: _buildAppBar(
        context,
        title: l.multiVideo,
        channels: channels,
        maxStreams: maxStreams,
      ),
      body: channelsAsync.when(
        loading: () => const LoadingState(message: 'Chargement…'),
        error: (err, _) => ErrorState(
          icon: Icons.live_tv_outlined,
          title: l.channelsUnavailable,
          message: userFriendlyError(err),
          onRetry: () => ref.invalidate(liveChannelsProvider),
        ),
        data: (channels) => _buildBody(context, channels, maxStreams, deviceProfile),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<Channel> channels,
    int maxStreams,
    DeviceProfile profile,
  ) {
    final l = AppLocalizations.of(context);

    if (_selectedChannels.isEmpty) {
      return _EmptyMultiView(
        message: l.noChannelSelected,
        actionLabel: l.addChannel,
        onAdd: channels.isEmpty
            ? null
            : () => _openPicker(channels, maxStreams),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final landscape = constraints.maxWidth >= constraints.maxHeight;
        final dims = multiViewGridDimensions(
          _selectedChannels.length,
          landscape: landscape,
        );
        return Column(
          children: [
            for (var row = 0; row < dims.rows; row++)
              Expanded(
                child: Row(
                  children: [
                    for (var col = 0; col < dims.columns; col++)
                      Expanded(
                        child: _buildCell(row * dims.columns + col, profile),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCell(int index, DeviceProfile profile) {
    if (index >= _selectedChannels.length) {
      // Cellule de remplissage (3 flux dans une grille 2×2) : elle garde la
      // place pour que les tuiles présentes ne soient pas déformées.
      return const ColoredBox(color: Colors.black);
    }
    final channel = _selectedChannels[index];
    return VideoTile(
      key: ValueKey<String>(channel.id),
      url: channel.streamUrl,
      profile: profile,
      title: channel.name,
      active: index == _activeIndex,
      onActivate: () => setState(() => _activeIndex = index),
      onRemove: () => _removeChannel(channel),
    );
  }
}

/// État vide : aucune chaîne sélectionnée.
class _EmptyMultiView extends StatelessWidget {
  const _EmptyMultiView({
    required this.message,
    required this.actionLabel,
    this.onAdd,
  });

  final String message;
  final String actionLabel;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.grid_view_rounded, size: 56, color: _kAccent),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(backgroundColor: _kAccent),
              icon: const Icon(Icons.add_rounded, color: Colors.black),
              label: Text(
                actionLabel,
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Feuille de sélection des chaînes : recherche + liste cochable.
///
/// Remplace la barre de `FilterChip` de 120 px qui listait toutes les chaînes
/// en vrac, sans recherche ni indication de sélection, et consommait une bande
/// d'écran fixe au détriment de la vidéo.
class _ChannelPickerSheet extends StatelessWidget {
  const _ChannelPickerSheet({
    required this.title,
    required this.hint,
    required this.closeLabel,
    required this.removeLabel,
    required this.controller,
    required this.onQueryChanged,
    required this.channels,
    required this.isSelected,
    required this.canAddMore,
    required this.onToggle,
  });

  final String title;
  final String hint;
  final String closeLabel;
  final String removeLabel;
  final TextEditingController controller;
  final VoidCallback onQueryChanged;
  final List<Channel> channels;
  final bool Function(Channel) isSelected;
  final bool canAddMore;
  final void Function(Channel) onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final height = MediaQuery.sizeOf(context).height * 0.75;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Navigation D-pad TV : halo + Enter pour fermer la feuille.
                TvFocus(
                  onActivate: () => Navigator.of(context).pop(),
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: closeLabel,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: controller,
              onChanged: (_) => onQueryChanged(),
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: channels.length,
              itemBuilder: (context, index) {
                final channel = channels[index];
                final selected = isSelected(channel);
                // Navigation D-pad TV : halo + Enter = ajouter/retirer.
                return TvFocus(
                  autofocus: index == 0,
                  onActivate: () => onToggle(channel),
                  child: ListTile(
                    selected: selected,
                    leading: Icon(
                      Icons.live_tv_outlined,
                      color: selected ? scheme.primary : null,
                    ),
                    title: Text(
                      channel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: channel.groupLabel.isEmpty
                        ? null
                        : Text(
                            channel.groupLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    trailing: Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.add_circle_outline,
                      color: selected
                          ? scheme.primary
                          : (canAddMore ? null : Colors.white24),
                    ),
                    onTap: () => onToggle(channel),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Tuile vidéo d'un flux.
///
/// Toutes les tuiles **jouent** ; seule la tuile [active] émet du son. Taper une
/// tuile la rend active (son), ce qui répond au besoin « son uniquement sur
/// l'affichage en cours » sans couper l'image des autres flux.
class VideoTile extends StatefulWidget {
  const VideoTile({
    super.key,
    required this.url,
    required this.profile,
    required this.title,
    required this.active,
    required this.onActivate,
    required this.onRemove,
  });

  final String url;

  /// Profil d'appareil servant à configurer le lecteur avant sa création.
  final DeviceProfile profile;
  final String title;
  final bool active;
  final VoidCallback onActivate;
  final VoidCallback onRemove;

  @override
  State<VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<VideoTile> {
  VideoPlayerController? _controller;
  int _generation = 0;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(VideoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _load();
    } else if (oldWidget.active != widget.active) {
      _applyVolume();
    }
  }

  void _applyVolume() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    controller.setVolume(widget.active ? 1.0 : 0.0);
  }

  Future<void> _load() async {
    final gen = ++_generation;
    _failed = false;
    final old = _controller;
    _controller = null;
    if (old != null) {
      old.removeListener(_onControllerUpdate);
      old.dispose();
    }
    if (!mounted) return;
    // La config media3 est lue à la CONSTRUCTION de l'ExoPlayer : sans ce
    // `push` avant la création, chaque tuile conservait les seuils par défaut
    // d'ExoPlayer (tampons de 50 s) et ne bénéficiait pas du plafond de
    // résolution du profil — en multi-vue, c'est précisément là que le
    // décodage déborde.
    await PlayerProfileService.pushForDevice(widget.profile);
    if (!mounted || gen != _generation) return;
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;
    controller.addListener(_onControllerUpdate);
    final result = await safeAsync<void>(
      () => controller.initialize(),
      context: 'MultiVideoScreen._VideoTileState.load',
    );
    if (result.isFailure) {
      final error = result.errorOrNull!.originalError ?? result.errorOrNull!;
      debugPrint('Orbit3D multivideo error: $error');
      if (!mounted || gen != _generation) return;
      if (_controller == controller) {
        _controller = null;
        controller.removeListener(_onControllerUpdate);
        controller.dispose();
      }
      setState(() => _failed = true);
      return;
    }
    if (!mounted || gen != _generation || _controller != controller) return;
    if (controller.value.hasError) {
      setState(() => _failed = true);
      return;
    }
    // Toutes les tuiles jouent en continu ; le son suit la tuile active.
    controller.setVolume(widget.active ? 1.0 : 0.0);
    controller.play();
    setState(() {});
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    final controller = _controller;
    if (controller == null || !controller.value.hasError) return;
    setState(() => _failed = true);
  }

  @override
  void dispose() {
    _generation++;
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      controller.removeListener(_onControllerUpdate);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onActivate,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Colors.black, child: _buildVideo()),
          if (widget.active)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: _kAccent, width: 3),
                ),
              ),
            ),
          // Nom de la chaîne (bas-gauche)
          Positioned(
            left: 8,
            right: 56,
            bottom: 8,
            child: Align(
              alignment: Alignment.centerLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
          // Indicateur son (haut-gauche) : la tuile active porte le son.
          Positioned(
            left: 8,
            top: 8,
            child: Tooltip(
              message: l.activeAudio,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    widget.active ? Icons.volume_up : Icons.volume_off,
                    size: 16,
                    color: widget.active ? _kAccent : Colors.white54,
                  ),
                ),
              ),
            ),
          ),
          // Retirer cette tuile (haut-droite)
          Positioned(
            right: 4,
            top: 4,
            child: Tooltip(
              message: l.removeChannel,
              child: IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: Colors.white,
                onPressed: widget.onRemove,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideo() {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      // `contain` et non `cover` : on remplit toute la cellule mais on ne rogne
      // jamais le flux (une chaîne d'info en 4:3 ne doit pas perdre ses bords).
      return Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      );
    }
    if (_failed) {
      return Center(
        child: Icon(
          Icons.live_tv_rounded,
          color: Theme.of(context).colorScheme.error,
          size: 32,
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}
