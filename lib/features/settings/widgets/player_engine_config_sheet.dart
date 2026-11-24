import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
import 'package:orbit_3d_flutter/core/hardware/player_config.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/services/video_decoder_prefs.dart';

/// Sous-fenêtre de configuration des moteurs de lecture par type de contenu
/// (Live, VOD, Séries, Replays), en grille compacte.
///
/// Pour chaque type on choisit un **Moteur Principal** (par défaut) et un
/// **Moteur de Secours (Fallback)**. Les choix ne sont appliqués qu'à
/// l'appui sur **Sauvegarder** ; **Annuler** referme sans rien persister.
Future<void> showPlayerEngineConfigSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    constraints: const BoxConstraints(maxWidth: 600),
    builder: (_) => const PlayerEngineConfigSheet(),
  );
}

class PlayerEngineConfigSheet extends ConsumerStatefulWidget {
  const PlayerEngineConfigSheet({super.key});

  @override
  ConsumerState<PlayerEngineConfigSheet> createState() =>
      _PlayerEngineConfigSheetState();
}

class _PlayerEngineConfigSheetState
    extends ConsumerState<PlayerEngineConfigSheet> {
  /// Copie locale non persistée : modifiée dans la sous-fenêtre, puis
  /// appliquée au provider uniquement au moment de « Sauvegarder ».
  late Map<PlaybackContentType, PlayerPerTypeConfig> _draft;

  // Focus nodes for TV/D-pad navigation
  final _closeFocus = FocusNode();
  final _externalInfoFocus = FocusNode();
  final _cancelFocus = FocusNode();
  final _saveFocus = FocusNode();
  final _decoderFocusNodes = List.generate(3, (_) => FocusNode());
  final _subtitleFocusNodes = List.generate(3, (_) => FocusNode());
  final _zappingFocus = FocusNode();
  final _scrollController = ScrollController();
  final Map<PlaybackContentType, FocusNode> _primaryFocusNodes = {};
  final Map<PlaybackContentType, FocusNode> _fallbackFocusNodes = {};

  late VodSubtitleMode _vodSubtitleModeDraft;
  bool _vodSubtitleModeChanged = false;
  late bool _zeroLagPrefetchDraft;
  bool _zeroLagPrefetchChanged = false;
  VideoDecoderMode _decoderModeDraft = VideoDecoderMode.auto;
  bool _decoderLoaded = false;

  @override
  void dispose() {
    _closeFocus.dispose();
    _externalInfoFocus.dispose();
    _cancelFocus.dispose();
    _saveFocus.dispose();
    for (final node in [..._decoderFocusNodes, ..._subtitleFocusNodes]) {
      node.dispose();
    }
    _zappingFocus.dispose();
    _scrollController.dispose();
    for (final node in _primaryFocusNodes.values) {
      node.dispose();
    }
    for (final node in _fallbackFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final s = ref.read(advancedSettingsProvider);
    _draft = {
      for (final t in PlaybackContentType.values) t: s.configFor(t),
    };
    _vodSubtitleModeDraft =
        s.subtitlesDisabled ? VodSubtitleMode.disabled : s.vodSubtitleMode;
    _zeroLagPrefetchDraft = s.zeroLagPrefetch;
    VideoDecoderPrefs.ensureLoaded().then((_) {
      if (!mounted) return;
      setState(() {
        _decoderModeDraft = VideoDecoderPrefs.mode;
        _decoderLoaded = true;
      });
    });
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _requestFocus(_closeFocus));
    // Initialize focus nodes for each content type
    for (final type in PlaybackContentType.values) {
      _primaryFocusNodes[type] = FocusNode();
      _fallbackFocusNodes[type] = FocusNode();
    }
  }

  void _setPrimary(PlaybackContentType type, PlayerEngine engine) {
    setState(() {
      _draft[type] = _draft[type]!.copyWith(primary: engine);
    });
  }

  void _setFallback(PlaybackContentType type, PlayerEngine engine) {
    setState(() {
      _draft[type] = _draft[type]!.copyWith(fallback: engine);
    });
  }

  void _setVodSubtitleMode(VodSubtitleMode mode) {
    setState(() {
      _vodSubtitleModeDraft = mode;
      _vodSubtitleModeChanged = true;
    });
  }

  void _showExternalPlayerInfo() {
    final l = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.externalPlayerLimitationsTitle),
        content: SingleChildScrollView(
          child: Text(l.externalPlayerLimitationsDescription),
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.close),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_decoderLoaded) return;
    final n = ref.read(advancedSettingsProvider.notifier);
    for (final entry in _draft.entries) {
      await n.setPlayerPrimary(entry.key, entry.value.primary);
      await n.setPlayerFallback(entry.key, entry.value.fallback);
    }
    if (_vodSubtitleModeChanged) {
      await n.setVodSubtitleMode(_vodSubtitleModeDraft);
      await n.setForceNoSubtitles(false);
    }
    if (_zeroLagPrefetchChanged) {
      await n.setZeroLagPrefetch(_zeroLagPrefetchDraft);
    }
    if (_decoderModeDraft != VideoDecoderPrefs.mode) {
      await VideoDecoderPrefs.setMode(_decoderModeDraft);
      PlayerProfileService.invalidate();
    }
    if (mounted) Navigator.of(context).pop();
  }

  Widget _buildPlayerCheckbox({
    required FocusNode focusNode,
    required FocusNode previous,
    required FocusNode next,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool sideBySide,
    required FocusNode gridFocus,
  }) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        final towardsGrid = Directionality.of(context) == TextDirection.rtl
            ? LogicalKeyboardKey.arrowRight
            : LogicalKeyboardKey.arrowLeft;
        if (sideBySide && event.logicalKey == towardsGrid) {
          _requestFocus(gridFocus);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
            (!sideBySide && event.logicalKey == LogicalKeyboardKey.arrowLeft)) {
          _requestFocus(previous);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
            (!sideBySide &&
                event.logicalKey == LogicalKeyboardKey.arrowRight)) {
          _requestFocus(next);
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          onChanged(!value);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      onFocusChange: (focused) {
        if (focused && focusNode.context != null) {
          Scrollable.ensureVisible(focusNode.context!);
        }
      },
      child: _FocusHalo(
        focusNode: focusNode,
        child: ExcludeFocus(
          child: CheckboxListTile(
            value: value,
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
            title: Text(title, style: const TextStyle(fontSize: 12)),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    );
  }

  void _requestFocus(FocusNode focus) {
    if (mounted) {
      FocusScope.of(context).requestFocus(focus);
      if ((focus == _primaryFocusNodes[PlaybackContentType.live] ||
              focus == _fallbackFocusNodes[PlaybackContentType.live]) &&
          _scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.minScrollExtent);
        return;
      }
      final target = focus.context;
      if (target != null) {
        Scrollable.ensureVisible(target);
      }
    }
  }

  Widget _buildTvDropdownButton({
    required FocusNode focusNode,
    required FocusNode nextFocusNode,
    required FocusNode prevFocusNode,
    required FocusNode? leftFocusNode,
    required FocusNode? rightFocusNode,
    required PlayerEngine value,
    required ValueChanged<PlayerEngine> onChanged,
    required List<DropdownMenuItem<PlayerEngine>> items,
  }) {
    final l = AppLocalizations.of(context);
    final labels = [
      l.engineInternal('ExoPlayer'),
      l.engineExternal('libVLC'),
      l.engineExternal('MX Player'),
    ];
    var menuWidth = 240.0;
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      menuWidth = math.max(menuWidth, painter.width + 48);
      painter.dispose();
    }
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            return KeyEventResult.ignored;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _requestFocus(nextFocusNode);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            if (rightFocusNode != null) {
              _requestFocus(rightFocusNode);
              return KeyEventResult.handled;
            }
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            if (leftFocusNode != null) {
              _requestFocus(leftFocusNode);
              return KeyEventResult.handled;
            }
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _requestFocus(prevFocusNode);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: _FocusHalo(
        focusNode: focusNode,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<PlayerEngine>(
            value: value,
            isDense: true,
            isExpanded: true,
            menuWidth:
                math.min(menuWidth, MediaQuery.sizeOf(context).width - 24),
            focusNode: focusNode,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            items: items,
            selectedItemBuilder: (context) => [
              for (final engine in PlayerEngine.values)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      switch (engine) {
                        PlayerEngine.exoPlayer => 'ExoPlayer',
                        PlayerEngine.vlc => 'libVLC',
                        PlayerEngine.mxPlayer => 'MX Player',
                      },
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // Build dropdown items once
    final dropdownItems = [
      for (final e in PlayerEngine.values)
        DropdownMenuItem(
          value: e,
          child: Text(
            switch (e) {
              PlayerEngine.exoPlayer => l.engineInternal('ExoPlayer'),
              PlayerEngine.vlc => l.engineExternal('libVLC'),
              PlayerEngine.mxPlayer => l.engineExternal('MX Player'),
            },
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: e.isExternal ? null : scheme.primary,
              fontWeight: e.isExternal ? FontWeight.normal : FontWeight.w600,
            ),
          ),
        ),
    ];
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_input_component,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.settingsPlaybackEngines,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Focus(
                      canRequestFocus: false,
                      skipTraversal: true,
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent || event is KeyRepeatEvent) {
                          if (event.logicalKey ==
                                  (isRtl
                                      ? LogicalKeyboardKey.arrowLeft
                                      : LogicalKeyboardKey.arrowRight) ||
                              event.logicalKey == LogicalKeyboardKey.arrowUp) {
                            _requestFocus(_closeFocus);
                            return KeyEventResult.handled;
                          }
                          if (event.logicalKey ==
                              LogicalKeyboardKey.arrowDown) {
                            _requestFocus(
                              _primaryFocusNodes[PlaybackContentType.live]!,
                            );
                            return KeyEventResult.handled;
                          }
                        }
                        return KeyEventResult.ignored;
                      },
                      child: IconButton(
                        focusNode: _externalInfoFocus,
                        tooltip: l.externalPlayerLimitationsTitle,
                        onPressed: _showExternalPlayerInfo,
                        icon: const Icon(Icons.info_outline),
                      ),
                    ),
                    Focus(
                      canRequestFocus: false,
                      skipTraversal: true,
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent &&
                            (event.logicalKey == LogicalKeyboardKey.enter ||
                                event.logicalKey == LogicalKeyboardKey.select ||
                                event.logicalKey ==
                                    LogicalKeyboardKey.gameButtonA)) {
                          Navigator.of(context).pop();
                          return KeyEventResult.handled;
                        }
                        if (event is KeyDownEvent &&
                            event.logicalKey ==
                                (isRtl
                                    ? LogicalKeyboardKey.arrowRight
                                    : LogicalKeyboardKey.arrowLeft)) {
                          _requestFocus(_externalInfoFocus);
                          return KeyEventResult.handled;
                        }
                        if (event is KeyDownEvent &&
                            (event.logicalKey ==
                                LogicalKeyboardKey.arrowDown)) {
                          // Move to first primary dropdown (Live)
                          if (_primaryFocusNodes[PlaybackContentType.live] !=
                              null) {
                            _requestFocus(
                              _primaryFocusNodes[PlaybackContentType.live]!,
                            );
                          }
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: IconButton(
                        focusNode: _closeFocus,
                        tooltip: l.cancel,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
                        child: Text(
                          l.engineSelectionHelp,
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final sideBySide = constraints.maxWidth >= 500;
                          final gridWidth = sideBySide
                              ? (constraints.maxWidth - 12) * 0.60
                              : constraints.maxWidth;
                          final grid = Wrap(
                            key: const ValueKey('engine-grid'),
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final type in PlaybackContentType.values)
                                SizedBox(
                                  width: (gridWidth - 8) / 2,
                                  child: _TypeSection(
                                    type: type,
                                    config: _draft[type]!,
                                    onPrimary: (e) => _setPrimary(type, e),
                                    onFallback: (e) => _setFallback(type, e),
                                    primaryFocusNode: _primaryFocusNodes[type]!,
                                    fallbackFocusNode:
                                        _fallbackFocusNodes[type]!,
                                    dropdownItems: dropdownItems,
                                    buildTvDropdown: _buildTvDropdownButton,
                                    sidePanelFocus: sideBySide
                                        ? (type == PlaybackContentType.vod
                                            ? _decoderFocusNodes.first
                                            : _subtitleFocusNodes.first)
                                        : null,
                                    getNextPrimaryFocus: (type) =>
                                        _fallbackFocusNodes[type]!,
                                    getPrevPrimaryFocus: (type) {
                                      final types = PlaybackContentType.values;
                                      final index = types.indexOf(type);
                                      return index > 0
                                          ? _fallbackFocusNodes[
                                              types[index - 1]]!
                                          : _closeFocus;
                                    },
                                    getNextFallbackFocus: (type) {
                                      final types = PlaybackContentType.values;
                                      final index = types.indexOf(type);
                                      return index + 1 < types.length
                                          ? _primaryFocusNodes[
                                              types[index + 1]]!
                                          : _decoderFocusNodes.first;
                                    },
                                    getPrevFallbackFocus: (type) =>
                                        _primaryFocusNodes[type]!,
                                    getHorizontalFocus: (type, isFallback) {
                                      final types = PlaybackContentType.values;
                                      final index = types.indexOf(type);
                                      final other = types[
                                          index.isEven ? index + 1 : index - 1];
                                      return isFallback
                                          ? _fallbackFocusNodes[other]!
                                          : _primaryFocusNodes[other]!;
                                    },
                                  ),
                                ),
                            ],
                          );
                          final options = Column(
                            key: const ValueKey('engine-side-options'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppCard(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radiusLg),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l.engineVideoDecoding),
                                    for (var i = 0;
                                        i < VideoDecoderMode.values.length;
                                        i++)
                                      _buildPlayerCheckbox(
                                        focusNode: _decoderFocusNodes[i],
                                        previous: i == 0
                                            ? _fallbackFocusNodes[
                                                PlaybackContentType.replay]!
                                            : _decoderFocusNodes[i - 1],
                                        next: i ==
                                                VideoDecoderMode.values.length -
                                                    1
                                            ? _subtitleFocusNodes.first
                                            : _decoderFocusNodes[i + 1],
                                        sideBySide: sideBySide,
                                        gridFocus: _fallbackFocusNodes[
                                            PlaybackContentType.vod]!,
                                        title: switch (
                                            VideoDecoderMode.values[i]) {
                                          VideoDecoderMode.auto =>
                                            l.engineAutoRecommended,
                                          VideoDecoderMode.hardware =>
                                            l.engineHardware,
                                          VideoDecoderMode.software =>
                                            l.engineSoftware,
                                        },
                                        value: _decoderModeDraft ==
                                            VideoDecoderMode.values[i],
                                        onChanged: (_) {
                                          if (_decoderLoaded) {
                                            setState(() => _decoderModeDraft =
                                                VideoDecoderMode.values[i]);
                                          }
                                        },
                                      ),
                                  ],
                                ),
                              ),
                              if (_decoderLoaded &&
                                  _decoderModeDraft == VideoDecoderMode.auto &&
                                  VideoDecoderPrefs.learnedSoftware)
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 4, 8, 0),
                                  child: Text(l.engineAutoSoftware,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: scheme.onSurfaceVariant)),
                                ),
                              const SizedBox(height: 8),
                              Text(l.tabPlayer,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                              Text(l.engineVodSubtitles,
                                  style: const TextStyle(fontSize: 12)),
                              for (var i = 0; i < 3; i++)
                                _buildPlayerCheckbox(
                                  focusNode: _subtitleFocusNodes[i],
                                  previous: i == 0
                                      ? _decoderFocusNodes.last
                                      : _subtitleFocusNodes[i - 1],
                                  next: i == 2
                                      ? _zappingFocus
                                      : _subtitleFocusNodes[i + 1],
                                  sideBySide: sideBySide,
                                  gridFocus: _fallbackFocusNodes[
                                      PlaybackContentType.replay]!,
                                  title: switch (i) {
                                    0 => l.engineSubtitleDefault,
                                    1 => l.engineSubtitleForced,
                                    _ => l.engineSubtitleDisabled,
                                  },
                                  value: _vodSubtitleModeDraft ==
                                      [
                                        VodSubtitleMode.defaultSelection,
                                        VodSubtitleMode.forcedOnly,
                                        VodSubtitleMode.disabled,
                                      ][i],
                                  onChanged: (_) => _setVodSubtitleMode([
                                    VodSubtitleMode.defaultSelection,
                                    VodSubtitleMode.forcedOnly,
                                    VodSubtitleMode.disabled,
                                  ][i]),
                                ),
                              _buildPlayerCheckbox(
                                focusNode: _zappingFocus,
                                previous: _subtitleFocusNodes.last,
                                next: _cancelFocus,
                                sideBySide: sideBySide,
                                gridFocus: _fallbackFocusNodes[
                                    PlaybackContentType.replay]!,
                                title: l.instantZapping,
                                value: _zeroLagPrefetchDraft,
                                onChanged: (value) => setState(() {
                                  _zeroLagPrefetchDraft = value;
                                  _zeroLagPrefetchChanged = true;
                                }),
                              ),
                            ],
                          );
                          if (!sideBySide) {
                            return Column(children: [
                              grid,
                              const SizedBox(height: 8),
                              options,
                            ]);
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: gridWidth, child: grid),
                              const SizedBox(width: 12),
                              Expanded(child: options),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Focus(
                        canRequestFocus: false,
                        skipTraversal: true,
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent &&
                              (event.logicalKey == LogicalKeyboardKey.enter ||
                                  event.logicalKey ==
                                      LogicalKeyboardKey.select ||
                                  event.logicalKey ==
                                      LogicalKeyboardKey.gameButtonA)) {
                            Navigator.of(context).pop();
                            return KeyEventResult.handled;
                          }
                          if (event is KeyDownEvent &&
                              (event.logicalKey ==
                                  LogicalKeyboardKey.arrowUp)) {
                            _requestFocus(_zappingFocus);
                            return KeyEventResult.handled;
                          }
                          if (event is KeyDownEvent &&
                              (event.logicalKey ==
                                  LogicalKeyboardKey.arrowRight)) {
                            _requestFocus(_saveFocus);
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: OutlinedButton.icon(
                          focusNode: _cancelFocus,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          label: Text(l.cancel),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Focus(
                        canRequestFocus: false,
                        skipTraversal: true,
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent &&
                              (event.logicalKey == LogicalKeyboardKey.enter ||
                                  event.logicalKey ==
                                      LogicalKeyboardKey.select ||
                                  event.logicalKey ==
                                      LogicalKeyboardKey.gameButtonA)) {
                            _save();
                            return KeyEventResult.handled;
                          }
                          if (event is KeyDownEvent &&
                              (event.logicalKey ==
                                  LogicalKeyboardKey.arrowLeft)) {
                            _requestFocus(_cancelFocus);
                            return KeyEventResult.handled;
                          }
                          if (event is KeyDownEvent &&
                              (event.logicalKey ==
                                  LogicalKeyboardKey.arrowUp)) {
                            _requestFocus(_zappingFocus);
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: FilledButton.icon(
                          focusNode: _saveFocus,
                          onPressed: _save,
                          icon: const Icon(Icons.save_outlined),
                          label: Text(l.save),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeSection extends StatelessWidget {
  const _TypeSection({
    required this.type,
    required this.config,
    required this.onPrimary,
    required this.onFallback,
    required this.primaryFocusNode,
    required this.fallbackFocusNode,
    required this.dropdownItems,
    required this.buildTvDropdown,
    required this.getNextPrimaryFocus,
    required this.getPrevPrimaryFocus,
    required this.getNextFallbackFocus,
    required this.getPrevFallbackFocus,
    required this.getHorizontalFocus,
    required this.sidePanelFocus,
  });

  final PlaybackContentType type;
  final PlayerPerTypeConfig config;
  final ValueChanged<PlayerEngine> onPrimary;
  final ValueChanged<PlayerEngine> onFallback;
  final FocusNode primaryFocusNode;
  final FocusNode fallbackFocusNode;
  final List<DropdownMenuItem<PlayerEngine>> dropdownItems;
  final Widget Function({
    required FocusNode focusNode,
    required FocusNode nextFocusNode,
    required FocusNode prevFocusNode,
    required FocusNode? leftFocusNode,
    required FocusNode? rightFocusNode,
    required PlayerEngine value,
    required ValueChanged<PlayerEngine> onChanged,
    required List<DropdownMenuItem<PlayerEngine>> items,
  }) buildTvDropdown;
  final FocusNode Function(PlaybackContentType) getNextPrimaryFocus;
  final FocusNode Function(PlaybackContentType) getPrevPrimaryFocus;
  final FocusNode Function(PlaybackContentType) getNextFallbackFocus;
  final FocusNode Function(PlaybackContentType) getPrevFallbackFocus;
  final FocusNode Function(PlaybackContentType, bool) getHorizontalFocus;
  final FocusNode? sidePanelFocus;
  IconData get _icon => switch (type) {
        PlaybackContentType.live => Icons.live_tv,
        PlaybackContentType.vod => Icons.movie_outlined,
        PlaybackContentType.series => Icons.tv_outlined,
        PlaybackContentType.replay => Icons.replay,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isFirstColumn = PlaybackContentType.values.indexOf(type).isEven;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final neighborOnLeft = isFirstColumn == isRtl;
    final outsideFocus = isFirstColumn ? null : sidePanelFocus;
    final blue = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF64B5F6)
        : const Color(0xFF1565C0);
    final orange = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFFB74D)
        : const Color(0xFFA64E00);
    return Container(
      key: ValueKey('engine-type-${type.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: blue.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: blue),
                    ),
                    child: Icon(_icon, size: 16, color: blue),
                  ),
                  PositionedDirectional(
                    top: -1,
                    end: 1,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                switch (type) {
                  PlaybackContentType.live => 'Live',
                  PlaybackContentType.vod => 'VOD',
                  PlaybackContentType.series => l.series,
                  PlaybackContentType.replay => l.replay,
                },
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )),
            ],
          ),
          const SizedBox(height: 6),
          _EngineRow(
            label: l.primaryEngine,
            value: config.primary,
            onChanged: onPrimary,
            focusNode: primaryFocusNode,
            nextFocusNode: getNextPrimaryFocus(type),
            prevFocusNode: getPrevPrimaryFocus(type),
            leftFocusNode:
                neighborOnLeft ? getHorizontalFocus(type, false) : outsideFocus,
            rightFocusNode:
                neighborOnLeft ? outsideFocus : getHorizontalFocus(type, false),
            dropdownItems: dropdownItems,
            buildTvDropdown: buildTvDropdown,
          ),
          _EngineRow(
            label: l.fallbackEngine,
            value: config.fallback,
            onChanged: onFallback,
            focusNode: fallbackFocusNode,
            nextFocusNode: getNextFallbackFocus(type),
            prevFocusNode: getPrevFallbackFocus(type),
            leftFocusNode:
                neighborOnLeft ? getHorizontalFocus(type, true) : outsideFocus,
            rightFocusNode:
                neighborOnLeft ? outsideFocus : getHorizontalFocus(type, true),
            dropdownItems: dropdownItems,
            buildTvDropdown: buildTvDropdown,
          ),
        ],
      ),
    );
  }
}

class _EngineRow extends StatelessWidget {
  const _EngineRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.focusNode,
    required this.nextFocusNode,
    required this.prevFocusNode,
    required this.leftFocusNode,
    required this.rightFocusNode,
    required this.dropdownItems,
    required this.buildTvDropdown,
  });

  final String label;
  final PlayerEngine value;
  final ValueChanged<PlayerEngine> onChanged;
  final FocusNode focusNode;
  final FocusNode nextFocusNode;
  final FocusNode prevFocusNode;
  final FocusNode? leftFocusNode;
  final FocusNode? rightFocusNode;
  final List<DropdownMenuItem<PlayerEngine>> dropdownItems;
  final Widget Function({
    required FocusNode focusNode,
    required FocusNode nextFocusNode,
    required FocusNode prevFocusNode,
    required FocusNode? leftFocusNode,
    required FocusNode? rightFocusNode,
    required PlayerEngine value,
    required ValueChanged<PlayerEngine> onChanged,
    required List<DropdownMenuItem<PlayerEngine>> items,
  }) buildTvDropdown;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 132),
              child: buildTvDropdown(
                focusNode: focusNode,
                nextFocusNode: nextFocusNode,
                prevFocusNode: prevFocusNode,
                leftFocusNode: leftFocusNode,
                rightFocusNode: rightFocusNode,
                value: value,
                onChanged: onChanged,
                items: dropdownItems,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusHalo extends StatelessWidget {
  const _FocusHalo({required this.focusNode, required this.child});

  final FocusNode focusNode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: focusNode,
      child: child,
      builder: (context, child) {
        final focused = focusNode.hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: focused ? color : Colors.transparent,
              width: 2,
            ),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
    );
  }
}
