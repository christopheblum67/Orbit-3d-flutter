import 'dart:async';

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
import 'package:orbit_3d_flutter/core/widgets/dpad_search_field.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Accent de marque, partagé avec le reste de l'application.
const Color _kAccent = Color(0xFF00CFE8);

final multiViewHardwareProvider = FutureProvider<HardwareSpecs>(
  (ref) => HardwareDetectorService.analyze(),
);

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
  Future<void>? _playerConfiguration;
  Future<void> _startupQueue = Future<void>.value();

  Future<void> _waitForStartup() {
    final configuration = _playerConfiguration ??=
        PlayerProfileService.pushForDevice(ref.read(deviceProfileProvider));
    final turn = _startupQueue.then((_) async {
      try {
        await configuration;
      } catch (_) {
        if (identical(_playerConfiguration, configuration)) {
          _playerConfiguration = null;
        }
        rethrow;
      }
    });
    _startupQueue = turn.then(
      (_) => Future<void>.delayed(const Duration(milliseconds: 150)),
      onError: (Object _, StackTrace __) =>
          Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    return turn;
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum : $maxStreams flux sur cet appareil.')),
      );
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161A22),
      builder: (sheetContext) {
        final l = AppLocalizations.of(sheetContext);
        return _ChannelPickerSheet(
          title: l.addChannel,
          hint: l.searchChannel,
          closeLabel: l.close,
          channels: channels,
          isSelected: _isSelected,
          canAddMore: () => _selectedChannels.length < maxStreams,
          onToggle: (channel) => _toggleChannel(channel, maxStreams),
        );
      },
    );
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
    final profile = ref.watch(currentProfileProvider);
    ref.listen(currentProfileProvider, (previous, next) {
      if (previous?.id != next?.id || next?.multiTvEnabled == false) {
        disposeAllControllers();
      }
    });
    if (profile?.multiTvEnabled == false) {
      return Scaffold(
        appBar: _buildAppBar(context, title: l.multiVideo),
        body: const Center(
          child: Text(
            'Multi TV est désactivée pour ce profil. '
            'Activez-la dans les préférences du profil.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    ref.listen(deviceProfileProvider, (previous, next) {
      if (previous == next) return;
      disposeAllControllers();
      final configuration = _playerConfiguration;
      if (configuration != null) {
        _playerConfiguration = configuration.then(
          (_) => PlayerProfileService.pushForDevice(next),
        );
      }
    });
    final channelsAsync = ref.watch(liveChannelsProvider);
    final deviceProfile = ref.watch(deviceProfileProvider);
    final hardware = ref.watch(multiViewHardwareProvider);
    if (hardware.isLoading) {
      return Scaffold(
        appBar: _buildAppBar(context, title: l.multiVideo),
        body: const LoadingState(message: 'Analyse de l’appareil…'),
      );
    }
    if (hardware.hasError) {
      return Scaffold(
        appBar: _buildAppBar(context, title: l.multiVideo),
        body: ErrorState(
          icon: Icons.error_outline,
          title: 'Analyse de l’appareil impossible',
          message: userFriendlyError(hardware.error!),
          onRetry: () => ref.invalidate(multiViewHardwareProvider),
        ),
      );
    }
    final maxStreams = hardware.requireValue.safeMaxMultiView(deviceProfile);

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
          onRetry: () => ref.invalidate(liveChannelsAllProvider),
        ),
        data: (channels) => _buildBody(context, channels, maxStreams),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<Channel> channels,
    int maxStreams,
  ) {
    final l = AppLocalizations.of(context);

    if (_selectedChannels.isEmpty) {
      return _EmptyMultiView(
        message: l.noChannelSelected,
        actionLabel: l.addChannel,
        onAdd:
            channels.isEmpty ? null : () => _openPicker(channels, maxStreams),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final landscape = constraints.maxWidth >= constraints.maxHeight;
        final dims = multiViewGridDimensions(
          _selectedChannels.length,
          landscape: landscape,
        );
        final width = constraints.maxWidth / dims.columns;
        final height = constraints.maxHeight / dims.rows;
        return Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: Colors.black)),
            for (var index = 0; index < _selectedChannels.length; index++)
              Positioned(
                key: ValueKey<String>(_selectedChannels[index].id),
                left: (index % dims.columns) * width,
                top: (index ~/ dims.columns) * height,
                width: width,
                height: height,
                child: _buildCell(index),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCell(int index) {
    final channel = _selectedChannels[index];
    return VideoTile(
      key: ValueKey<String>(channel.id),
      url: channel.streamUrl,
      waitForStartup: _waitForStartup,
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
              autofocus: true,
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
class _ChannelPickerSheet extends StatefulWidget {
  const _ChannelPickerSheet({
    required this.title,
    required this.hint,
    required this.closeLabel,
    required this.channels,
    required this.isSelected,
    required this.canAddMore,
    required this.onToggle,
  });

  final String title;
  final String hint;
  final String closeLabel;
  final List<Channel> channels;
  final bool Function(Channel) isSelected;
  final bool Function() canAddMore;
  final void Function(Channel) onToggle;

  @override
  State<_ChannelPickerSheet> createState() => _ChannelPickerSheetState();
}

class _ChannelPickerSheetState extends State<_ChannelPickerSheet> {
  final _controller = TextEditingController();
  final _firstChannelFocus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _firstChannelFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final media = MediaQuery.of(context);
    final height = (media.size.height - media.viewInsets.bottom) * 0.75;
    final query = _controller.text.trim().toLowerCase();
    final channels = query.isEmpty
        ? widget.channels
        : widget.channels
            .where((c) => c.name.toLowerCase().contains(query))
            .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
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
                      widget.title,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TvFocus(
                    onActivate: () => Navigator.of(context).pop(),
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: widget.closeLabel,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DpadSearchField(
                controller: _controller,
                hint: widget.hint,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                onNavigateDown: () {
                  if (channels.isNotEmpty) _firstChannelFocus.requestFocus();
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: channels.isEmpty
                  ? const Center(child: Text('Aucune chaîne trouvée.'))
                  : ListView.builder(
                      itemCount: channels.length,
                      itemBuilder: (context, index) {
                        final channel = channels[index];
                        final selected = widget.isSelected(channel);
                        return TvFocus(
                          key: ValueKey(channel.id),
                          focusNode: index == 0 ? _firstChannelFocus : null,
                          onActivate: () {
                            widget.onToggle(channel);
                            setState(() {});
                          },
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
                                  : (widget.canAddMore()
                                      ? null
                                      : Colors.white24),
                            ),
                            onTap: () {
                              widget.onToggle(channel);
                              setState(() {});
                            },
                          ),
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

/// Tuile vidéo d'un flux.
///
/// Toutes les tuiles **jouent** ; seule la tuile [active] émet du son. Taper une
/// tuile la rend active (son), ce qui répond au besoin « son uniquement sur
/// l'affichage en cours » sans couper l'image des autres flux.
class VideoTile extends StatefulWidget {
  const VideoTile({
    super.key,
    required this.url,
    required this.waitForStartup,
    required this.title,
    required this.active,
    required this.onActivate,
    required this.onRemove,
  });

  final String url;

  final Future<void> Function() waitForStartup;
  final String title;
  final bool active;
  final VoidCallback onActivate;
  final VoidCallback onRemove;

  @override
  State<VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<VideoTile> {
  VideoPlayerController? _controller;
  Future<void>? _pendingDisposal;
  int _generation = 0;
  bool _failed = false;
  bool _focused = false;

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

  /// Applique le volume instantanément sans recharger le flux vidéo.
  void _applyVolume() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    unawaited(
      safeAsync<void>(
        () => controller.setVolume(widget.active ? 1.0 : 0.0),
        context: 'MultiVideoScreen._VideoTileState.volume',
      ),
    );
  }

  Future<void> _load() async {
    final gen = ++_generation;
    _failed = false;
    final old = _controller;
    _controller = null;
    if (old != null) {
      old.removeListener(_onControllerUpdate);
      await old.dispose();
    }
    await _pendingDisposal;
    if (!mounted || gen != _generation) return;

    final startup = await safeAsync<void>(
      widget.waitForStartup,
      context: 'MultiVideoScreen._VideoTileState.configure',
    );

    if (!mounted || gen != _generation) return;
    if (startup.isFailure) {
      setState(() => _failed = true);
      return;
    }

    final uri = safeSync<Uri>(
      () => Uri.parse(widget.url),
      context: 'MultiVideoScreen._VideoTileState.url',
    );
    if (uri.isFailure) {
      setState(() => _failed = true);
      return;
    }

    final controller = VideoPlayerController.networkUrl(uri.getOrThrow());
    _controller = controller;
    controller.addListener(_onControllerUpdate);
    final result = await safeAsync<void>(
      () async {
        await controller.initialize();
        if (!mounted || gen != _generation || controller.value.hasError) {
          return;
        }
        await controller.setVolume(widget.active ? 1.0 : 0.0);
        if (!mounted || gen != _generation) return;
        await controller.play();
      },
      context: 'MultiVideoScreen._VideoTileState.load',
    );
    if (result.isFailure ||
        controller.value.hasError ||
        !mounted ||
        gen != _generation) {
      if (_controller == controller) {
        _controller = null;
        controller.removeListener(_onControllerUpdate);
        await controller.dispose();
      }
      if (mounted && gen == _generation) setState(() => _failed = true);
      return;
    }
    if (mounted) setState(() {});
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    final controller = _controller;
    if (controller == null || !controller.value.hasError) return;
    if (_failed) return;
    setState(() => _failed = true);
    _controller = null;
    controller.removeListener(_onControllerUpdate);
    _pendingDisposal = Future<void>.delayed(Duration.zero, () async {
      await safeAsync<void>(
        controller.dispose,
        context: 'MultiVideoScreen._VideoTileState.disposeFailed',
      );
    });
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
    return Focus(
        onFocusChange: (focused) => setState(() => _focused = focused),
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.select ||
                  event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.gameButtonA ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            widget.onActivate();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onActivate,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: Colors.black, child: _buildVideo()),
              if (widget.active || _focused)
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _focused ? Colors.white : _kAccent,
                        width: _focused ? 5 : 3,
                      ),
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
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
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
        ));
  }

  Widget _buildVideo() {
    final controller = _controller;
    if (_failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Lecture indisponible',
              style: TextStyle(color: Colors.white),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _load();
                });
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
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
    return const Center(child: CircularProgressIndicator());
  }
}
