import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cast/cast.dart';
import 'package:orbit_3d_flutter/providers/cast_provider.dart';
import 'package:orbit_3d_flutter/services/cast_playback_service.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Bouton Cast de la footerbar du lecteur : ouvre le sélecteur d'appareils
/// Chromecast du réseau local, puis lance le flux en cours sur le récepteur.
///
/// L'icône bascule sur « connecté » tant qu'une session est active.
class CastButton extends ConsumerStatefulWidget {
  const CastButton({
    super.key,
    required this.streamUrl,
    required this.isLive,
  });

  final String streamUrl;
  final bool isLive;

  @override
  ConsumerState<CastButton> createState() => _CastButtonState();
}

class _CastButtonState extends ConsumerState<CastButton> {
  CastSessionState? _state;

  @override
  void initState() {
    super.initState();
    final service = ref.read(castServiceProvider);
    _state = service.state;
    service.stateStream.listen((s) {
      if (mounted) setState(() => _state = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final connected = _state == CastSessionState.connected;
    return IconButton(
      tooltip: l.castToChromecast,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
      onPressed: () => showCastSheet(
        context,
        ref: ref,
        streamUrl: widget.streamUrl,
        isLive: widget.isLive,
      ),
      icon: Icon(
        connected ? Icons.cast_connected : Icons.cast,
        color: connected ? const Color(0xFFFFC107) : Colors.white,
        size: 22,
      ),
    );
  }
}

/// Ouvre le panneau de sélection Chromecast (scan → connexion → lecture).
Future<void> showCastSheet(
  BuildContext context, {
  required WidgetRef ref,
  required String streamUrl,
  required bool isLive,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => _CastSheet(
      ref: ref,
      streamUrl: streamUrl,
      isLive: isLive,
    ),
  );
}

class _CastSheet extends ConsumerStatefulWidget {
  const _CastSheet({
    required this.ref,
    required this.streamUrl,
    required this.isLive,
  });

  final WidgetRef ref;
  final String streamUrl;
  final bool isLive;

  @override
  ConsumerState<_CastSheet> createState() => _CastSheetState();
}

class _CastSheetState extends ConsumerState<_CastSheet> {
  final List<CastDevice> _devices = [];
  bool _scanning = true;
  bool _connecting = false;
  String? _feedback;
  CastSessionState? _sessionState;

  // Focus nodes for TV/D-pad navigation
  final _closeFocus = FocusNode();
  final _retryFocus = FocusNode();
  final _disconnectFocus = FocusNode();
  final List<FocusNode> _deviceFocusNodes = [];

  CastPlaybackService get _service => ref.read(castServiceProvider);

  @override
  void dispose() {
    _closeFocus.dispose();
    _retryFocus.dispose();
    _disconnectFocus.dispose();
    for (final node in _deviceFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _sessionState = _service.state;
    _service.stateStream.listen((s) {
      if (mounted) setState(() => _sessionState = s);
    });
    _service.messageStream.listen((msg) {
      if (mounted) setState(() => _feedback = msg);
    });
    _scan();
  }

  void _ensureDeviceFocusNodes(int count) {
    if (_deviceFocusNodes.length != count) {
      for (final node in _deviceFocusNodes) {
        node.dispose();
      }
      _deviceFocusNodes.clear();
      for (int i = 0; i < count; i++) {
        _deviceFocusNodes.add(FocusNode());
      }
    }
  }

  void _requestFocus(FocusNode focus) {
    if (mounted) {
      FocusScope.of(context).requestFocus(focus);
    }
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _feedback = null;
    });
    final found = await _service.scanForDevices();
    if (!mounted) return;
    setState(() {
      _devices
        ..clear()
        ..addAll(found);
      _scanning = false;
      if (found.isEmpty && _feedback == null) {
        _feedback = 'Aucun Chromecast détecté sur le réseau.';
      }
    });
  }

  Future<void> _connect(CastDevice device) async {
    setState(() => _connecting = true);
    final connected = await _service.connect(device);
    if (!mounted) return;
    setState(() => _connecting = false);
    if (connected) {
      setState(() => _feedback = 'Connecté à ${device.name}');
      await _service.castMedia(widget.streamUrl, isLive: widget.isLive);
    } else {
      setState(() => _feedback = 'Connexion à ${device.name} impossible.');
    }
  }

  Future<void> _disconnect() async {
    await _service.disconnect();
    if (mounted) setState(() => _feedback = null);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final connected = _sessionState == CastSessionState.connected;

    // Request initial focus on close button
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _requestFocus(_closeFocus);
      }
    });

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Row(
                children: [
                  Icon(Icons.cast, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.castToChromecast,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Focus(
                    focusNode: _closeFocus,
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent &&
                          (event.logicalKey == LogicalKeyboardKey.enter ||
                              event.logicalKey == LogicalKeyboardKey.select ||
                              event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                        Navigator.of(context).pop();
                        return KeyEventResult.handled;
                      }
                      if (event is KeyDownEvent &&
                          (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                              event.logicalKey == LogicalKeyboardKey.arrowUp)) {
                        // Move focus to first device or retry button
                        if (_deviceFocusNodes.isNotEmpty) {
                          _requestFocus(_deviceFocusNodes.first);
                        } else if (!_devices.isEmpty) {
                          // fallback
                        } else if (_retryFocus.hasFocus == false) {
                          _requestFocus(_retryFocus);
                        }
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: IconButton(
                      tooltip: 'Fermer',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
            ),
            if (_feedback != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _feedback!,
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ),
            const SizedBox(height: 8),
            Flexible(
              child: _body(context, connected),
            ),
            if (connected)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Focus(
                  focusNode: _disconnectFocus,
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent &&
                        (event.logicalKey == LogicalKeyboardKey.enter ||
                            event.logicalKey == LogicalKeyboardKey.select ||
                            event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                      _disconnect();
                      return KeyEventResult.handled;
                    }
                    if (event is KeyDownEvent &&
                        (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                            event.logicalKey == LogicalKeyboardKey.arrowDown)) {
                      // Move focus back to last device
                      if (_deviceFocusNodes.isNotEmpty) {
                        _requestFocus(_deviceFocusNodes.last);
                      }
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: OutlinedButton.icon(
                    onPressed: _disconnect,
                    icon: const Icon(Icons.stop_rounded),
                    label: Text(l.stopCasting),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, bool connected) {
    final l = AppLocalizations.of(context);
    if (_connecting) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_scanning) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              'Recherche d\'appareils Cast…',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    if (_devices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cast_connected, size: 32, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(l.noChromecastDeviceFound, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Focus(
              focusNode: _retryFocus,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    (event.logicalKey == LogicalKeyboardKey.enter ||
                        event.logicalKey == LogicalKeyboardKey.select ||
                        event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                  _scan();
                  return KeyEventResult.handled;
                }
                if (event is KeyDownEvent &&
                    (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                        event.logicalKey == LogicalKeyboardKey.arrowDown)) {
                  // Loop to close button
                  _requestFocus(_closeFocus);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: OutlinedButton(onPressed: _scan, child: Text(l.retrySearch)),
            ),
          ],
        ),
      );
    }

    // Ensure device focus nodes match device count
    _ensureDeviceFocusNodes(_devices.length);

    return ListView(
      shrinkWrap: true,
      children: [
        for (int i = 0; i < _devices.length; i++)
          Focus(
            focusNode: _deviceFocusNodes[i],
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.select ||
                    event.logicalKey == LogicalKeyboardKey.gameButtonA) {
                  _connect(_devices[i]);
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  if (i + 1 < _devices.length) {
                    _requestFocus(_deviceFocusNodes[i + 1]);
                  } else if (connected) {
                    _requestFocus(_disconnectFocus);
                  } else {
                    _requestFocus(_closeFocus);
                  }
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  if (i > 0) {
                    _requestFocus(_deviceFocusNodes[i - 1]);
                  } else {
                    _requestFocus(_closeFocus);
                  }
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: Icon(
                Icons.tv_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(_devices[i].name, style: const TextStyle(fontSize: 14)),
              subtitle: Text(_devices[i].host, style: const TextStyle(fontSize: 11)),
              trailing: Icon(
                connected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: connected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              onTap: () => _connect(_devices[i]),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}