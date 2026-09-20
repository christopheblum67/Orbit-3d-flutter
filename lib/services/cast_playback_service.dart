import 'dart:async';
import 'package:cast/cast.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';

/// Service Chromecast / Google Cast (protocole natif v2, découverte mDNS).
///
/// Enchaîne : découverte des appareils → connexion → lancement du Default
/// Media Receiver (app « CC1AD845 ») → chargement du média (LOAD). Le service
/// est volontairement « best-effort » : en l'absence de Chromecast sur le
/// réseau local, aucune erreur n'est propagée ; l'UI masque le bouton.
class CastPlaybackService {
  static const String kDefaultMediaReceiverAppId = 'CC1AD845';

  final CastDiscoveryService _discovery = CastDiscoveryService();

  CastSession? _session;
  StreamSubscription<Map<String, dynamic>>? _messageSub;
  Timer? _heartbeatTimer;
  String? _receiverSessionId;
  bool _disposed = false;

  final _stateController = StreamController<CastSessionState>.broadcast();
  final _messageController = StreamController<String>.broadcast();

  /// État courant de la session Cast (pas de session = `null`).
  CastSessionState? get state => _session?.state;

  /// État de session (mise à jour en direct).
  Stream<CastSessionState> get stateStream => _stateController.stream;

  /// Dernières nouvelles reçues du récepteur (optimisées pour l'affichage).
  Stream<String> get messageStream => _messageController.stream;

  /// Scanne le réseau local à la recherche de Chromecast pendant [timeout].
  ///
  /// S'appuie sur le service mDNS `_googlecast._tcp` (package `bonsoir`).
  Future<List<CastDevice>> scanForDevices({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_disposed) return const [];
    final result = await safeAsync<List<CastDevice>>(
      () => _discovery.search(timeout: timeout),
      context: 'CastPlaybackService.scanForDevices',
      fallbackValue: const [],
    );
    return result.valueOrNull ?? const [];
  }

  /// Connecte [device] et attend la disponibilité du récepteur. Renvoie
  /// `true` une fois la session établie (`connected`).
  Future<bool> connect(CastDevice device) async {
    await disconnect();
    final result = await safeAsync<bool>(
      () async {
        final session = await CastSession.connect(
          'cr-sender-$_sessionCounter',
          device,
        );
        if (_disposed) {
          await session.close();
          return false;
        }
        _session = session;
        _receiverSessionId = null;
        _messageSub?.cancel();
        _messageSub = session.messageStream.listen(_onMessage);
        _stateController.add(session.state);
        _startHeartbeat();
        // Attend jusqu'à `connected` (receiver status reçu + transport établi).
        final connected = await session.stateStream
            .firstWhere((s) => s != CastSessionState.connecting)
            .timeout(const Duration(seconds: 15))
            .then((s) => s == CastSessionState.connected)
            .catchError((_) => false);
        if (!connected) {
          await disconnect();
        }
        return connected;
      },
      context: 'CastPlaybackService.connect',
    );
    if (result.isFailure) {
      await disconnect();
    }
    return result.getOrElse(false);
  }

  int _sessionCounter = 0;

  void _onMessage(Map<String, dynamic> payload) {
    final receiverSessionId = _receiverSessionId;
    if (payload['type'] == 'RECEIVER_STATUS' &&
        payload['status'] is Map<String, dynamic>) {
      final status = payload['status'] as Map<String, dynamic>;
      if (status['sessionId'] != null) {
        _receiverSessionId = status['sessionId'] as String;
      }
      final apps = status['applications'];
      if (apps is List && apps.isNotEmpty) {
        final app = apps.first as Map;
        final displayName = app['displayName'];
        if (displayName is String && displayName.isNotEmpty) {
          _messageController.add(displayName);
        }
      }
    } else {
      final errorCode = payload['error'];
      if (errorCode is Map && errorCode['description'] is String) {
        _messageController.add(errorCode['description'] as String);
      }
    }
    // Premier CONNECT établi : on ne relance pas un LAUNCH spontanément.
    if (!_launched && receiverSessionId == null &&
        _receiverSessionId != null) {
      _launched = true;
    }
  }

  bool _launched = false;

  /// Lance [url] sur l'appareil connecté (Default Media Receiver).
  ///
  /// [isLive] force `streamType: live` (flux IPTV), sinon on détecte le type
  /// depuis l'extension de l'URL. Best-effort : renvoie `false` si aucune
  /// session n'est établie.
  Future<bool> castMedia(String url, {bool isLive = false}) async {
    final session = _session;
    if (session == null || session.state != CastSessionState.connected) {
      return false;
    }
    if (_receiverSessionId == null) {
      _messageController.add('Récepteur pas encore prêt');
      return false;
    }
    final contentType = guessContentType(url, isLive: isLive);
    session.sendMessage(CastSession.kNamespaceReceiver, {
      'type': 'LAUNCH',
      'appId': kDefaultMediaReceiverAppId,
      'launchRequestId': 0,
    });
    // Attend un bref instant pour le statut du récepteur après le LAUNCH.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    session.sendMessage(CastSession.kNamespaceMedia, buildLoadPayload(
      contentId: url,
      contentType: contentType,
      sessionId: _receiverSessionId!,
      streamType: isLive ? 'live' : null,
    ));
    return true;
  }

  /// Coupe la session : fermeture du socket + libération des resources.
  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _messageSub?.cancel();
    _messageSub = null;
    final session = _session;
    _session = null;
    _receiverSessionId = null;
    if (session != null) {
      await safeAsync<void>(
        () => session.close(),
        context: 'CastPlaybackService.disconnect',
      );
    }
    if (!_disposed) {
      _stateController.add(CastSessionState.closed);
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final session = _session;
      if (session != null &&
          session.state == CastSessionState.connected) {
        session.sendMessage(CastSession.kNamespaceHeartbeat, {
          'type': 'PING',
        });
      }
    });
  }

  void dispose() {
    _disposed = true;
    _messageSub?.cancel();
    _heartbeatTimer?.cancel();
    _stateController.close();
    _messageController.close();
  }

  /// Devine le `contentType` Cast d'après l'extension de l'URL.
  static String guessContentType(String url, {bool isLive = false}) {
    if (isLive) return 'application/x-mpegurl';
    final ext = Uri.tryParse(url)?.path.split('.').last.toLowerCase();
    switch (ext) {
      case 'm3u8':
      case 'm3u':
        return 'application/x-mpegurl';
      case 'dash':
      case 'mpd':
        return 'application/dash+xml';
      case 'mp4':
      case 'm4v':
        return 'video/mp4';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      case 'ts':
        return 'video/mp2t';
      default:
        return 'video/mp4';
    }
  }

  /// Construit le payload `LOAD` (namespace media) du Default Media Receiver.
  static Map<String, dynamic> buildLoadPayload({
    required String contentId,
    required String contentType,
    required String sessionId,
    String? streamType,
  }) {
    return <String, dynamic>{
      'autoplay': true,
      'currentTime': 0.0,
      'media': <String, dynamic>{
        'contentId': contentId,
        'contentType': contentType,
        if (streamType != null) 'streamType': streamType,
        'metadata': <String, dynamic>{
          'metadataType': 0,
          'title': 'Orbit 3D',
        },
      },
      'sessionId': sessionId,
      'type': 'LOAD',
    };
  }
}