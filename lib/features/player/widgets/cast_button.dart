import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cast/cast.dart';
import 'package:orbit_3d_flutter/providers/cast_provider.dart';
import 'package:orbit_3d_flutter/services/cast_playback_service.dart';

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
    final connected = _state == CastSessionState.connected;
    return IconButton(
      tooltip: 'Diffuser sur Chromecast',
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

  CastPlaybackService get _service => ref.read(castServiceProvider);

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
    final scheme = Theme.of(context).colorScheme;
    final connected = _sessionState == CastSessionState.connected;
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
                  const Expanded(
                    child: Text(
                      'Diffuser sur Chromecast',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
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
                child: OutlinedButton.icon(
                  onPressed: _disconnect,
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Arrêter la diffusion'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, bool connected) {
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
            const Text('Aucun appareil Chromecast trouvé.', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _scan, child: const Text('Relancer la recherche')),
          ],
        ),
      );
    }
    return ListView(
      shrinkWrap: true,
      children: [
        for (final device in _devices)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(
              Icons.tv_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(device.name, style: const TextStyle(fontSize: 14)),
            subtitle: Text(device.host, style: const TextStyle(fontSize: 11)),
            trailing: Icon(
              connected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: connected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
            onTap: () => _connect(device),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}