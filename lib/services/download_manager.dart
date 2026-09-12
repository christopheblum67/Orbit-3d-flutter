import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';
import 'package:orbit_3d_flutter/models/download.dart';
import 'package:orbit_3d_flutter/services/cloudflare_session_manager.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    as stream_helpers;

/// Commandes envoyées au worker isolate.
enum DownloadWorkerCommand {
  start,
  pause,
  resume,
  cancel,
  retry,
  updateConfig,
}

/// Message envoyé au worker.
class DownloadWorkerMessage {
  final DownloadWorkerCommand command;
  final String taskId;
  final dynamic payload;

  DownloadWorkerMessage(this.command, this.taskId, {this.payload});
}

/// Réponse du worker.
class DownloadWorkerResponse {
  final String taskId;
  final DownloadStatus status;
  final DownloadProgress? progress;
  final String? errorMessage;
  final bool isComplete;

  DownloadWorkerResponse({
    required this.taskId,
    required this.status,
    this.progress,
    this.errorMessage,
    this.isComplete = false,
  });
}

/// Configuration globale des téléchargements.
class DownloadManagerConfig {
  final bool wifiOnly;
  final int maxConcurrentDownloads;
  final int retryAttempts;
  final Duration retryDelay;
  final bool deleteAfterWatch;
  final String preferredQuality;
  final String downloadDirectory;

  const DownloadManagerConfig({
    this.wifiOnly = true,
    this.maxConcurrentDownloads = 2,
    this.retryAttempts = 3,
    this.retryDelay = const Duration(seconds: 10),
    this.deleteAfterWatch = false,
    this.preferredQuality = 'auto',
    this.downloadDirectory = 'Orbit/downloads',
  });

  DownloadManagerConfig copyWith({
    bool? wifiOnly,
    int? maxConcurrentDownloads,
    int? retryAttempts,
    Duration? retryDelay,
    bool? deleteAfterWatch,
    String? preferredQuality,
    String? downloadDirectory,
  }) {
    return DownloadManagerConfig(
      wifiOnly: wifiOnly ?? this.wifiOnly,
      maxConcurrentDownloads: maxConcurrentDownloads ?? this.maxConcurrentDownloads,
      retryAttempts: retryAttempts ?? this.retryAttempts,
      retryDelay: retryDelay ?? this.retryDelay,
      deleteAfterWatch: deleteAfterWatch ?? this.deleteAfterWatch,
      preferredQuality: preferredQuality ?? this.preferredQuality,
      downloadDirectory: downloadDirectory ?? this.downloadDirectory,
    );
  }
}

/// Gestionnaire centralisé des téléchargements hors-ligne.
///
/// Utilise des isolates pour le téléchargement réel (I/O lourd) et
/// maintient l'état dans Hive via [HiveSync].
class DownloadManager extends ChangeNotifier {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  static const String _boxName = 'downloads';
  static const String _configKey = 'download_config';

  final LoggerService _logger = LoggerService.instance;

  Box<DownloadTask>? _box;
  DownloadManagerConfig _config = const DownloadManagerConfig();
  final Map<String, Isolate> _workers = {};
  final Map<String, SendPort> _workerPorts = {};
  final Map<String, StreamController<DownloadWorkerResponse>> _responseControllers = {};
  int _activeDownloads = 0;

  /// Configuration actuelle.
  DownloadManagerConfig get config => _config;

  /// Liste de toutes les tâches (réactive via Hive).
  Stream<List<DownloadTask>> get tasksStream => _watchTasks();

  /// Tâches en cours de téléchargement.
  List<DownloadTask> get activeTasks {
    if (_box == null) return [];
    return _box!.values
        .where((t) => t.status == DownloadStatus.downloading || t.status == DownloadStatus.preparing)
        .toList();
  }

  /// Nombre de téléchargements actifs.
  int get activeCount => _activeDownloads;

  /// Initialise le gestionnaire.
  Future<void> init() async {
    await _initBox();
    await _loadConfig();
    _recoverInterruptedDownloads();
    _logger.info('DownloadManager initialized');
  }

  Future<void> _initBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<DownloadTask>(_boxName);
    } else {
      _box = Hive.box<DownloadTask>(_boxName);
    }
  }

  Future<void> _loadConfig() async {
    final box = Hive.box(_boxName);
    final configMap = box.get(_configKey);
    if (configMap is Map) {
      _config = DownloadManagerConfig(
        wifiOnly: configMap['wifiOnly'] ?? true,
        maxConcurrentDownloads: configMap['maxConcurrentDownloads'] ?? 2,
        retryAttempts: configMap['retryAttempts'] ?? 3,
        retryDelay: Duration(seconds: configMap['retryDelaySeconds'] ?? 10),
        deleteAfterWatch: configMap['deleteAfterWatch'] ?? false,
        preferredQuality: configMap['preferredQuality'] ?? 'auto',
        downloadDirectory: configMap['downloadDirectory'] ?? 'Orbit/downloads',
      );
    }
  }

  Future<void> _saveConfig() async {
    final box = Hive.box(_boxName);
    await box.put(_configKey, {
      'wifiOnly': _config.wifiOnly,
      'maxConcurrentDownloads': _config.maxConcurrentDownloads,
      'retryAttempts': _config.retryAttempts,
      'retryDelaySeconds': _config.retryDelay.inSeconds,
      'deleteAfterWatch': _config.deleteAfterWatch,
      'preferredQuality': _config.preferredQuality,
      'downloadDirectory': _config.downloadDirectory,
    });
  }

  /// Met à jour la configuration globale.
  Future<void> updateConfig(DownloadManagerConfig newConfig) async {
    _config = newConfig;
    await _saveConfig();
    notifyListeners();
  }

  Stream<List<DownloadTask>> _watchTasks() {
    if (_box == null) return Stream.value([]);
    return _box!.watch().map((_) => _box!.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  /// Récupère une tâche par son ID.
  DownloadTask? getTask(String id) => _box?.get(id);

  /// Crée une nouvelle tâche de téléchargement.
  Future<DownloadTask> createTask({
    required String mediaItemId,
    required String title,
    required String streamUrl,
    String? posterUrl,
    String? drmToken,
    required String contentType,
    String? seriesId,
    int? seasonNumber,
    int? episodeNumber,
    String? episodeTitle,
    Map<String, String>? headers,
  }) async {
    if (_box == null) await _initBox();

    final task = DownloadTask(
      id: 'dl_${mediaItemId}_${DateTime.now().millisecondsSinceEpoch}',
      mediaItemId: mediaItemId,
      title: title,
      posterUrl: posterUrl,
      streamUrl: streamUrl,
      drmToken: drmToken,
      contentType: contentType,
      seriesId: seriesId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      episodeTitle: episodeTitle,
      headers: headers,
      createdAt: DateTime.now(),
    );

    await HiveSync.write(_boxName, (box) => box.put(task.id, task));
    _logger.info('Download task created: ${task.id}');

    // Auto-start si place disponible
    if (_activeDownloads < _config.maxConcurrentDownloads) {
      _startWorker(task.id);
    }

    notifyListeners();
    return task;
  }

  /// Démarre un téléchargement (crée le worker isolate).
  void _startWorker(String taskId) {
    if (_workers.containsKey(taskId)) return;

    final task = _box?.get(taskId);
    if (task == null || (task.status != DownloadStatus.queued && task.status != DownloadStatus.paused)) {
      return;
    }

    if (_activeDownloads >= _config.maxConcurrentDownloads) {
      return;
    }

    final receivePort = ReceivePort();
    final controller = StreamController<DownloadWorkerResponse>.broadcast();
    _responseControllers[taskId] = controller;

    // Écouter les réponses du worker
    receivePort.listen((message) {
      if (message is DownloadWorkerResponse) {
        controller.add(message);
        _handleWorkerResponse(message);
      }
    });

    Isolate.spawn(_downloadWorkerEntry, _DownloadWorkerParams(
      taskId: taskId,
      sendPort: receivePort.sendPort,
      streamUrl: _box!.get(taskId)!.streamUrl,
      headers: _getFreshHeaders(_box!.get(taskId)!),
      drmToken: _box!.get(taskId)!.drmToken,
      localPath: _getLocalPath(taskId),
      config: _config,
    )).then((isolate) {
      _workers[taskId] = isolate;
      _workerPorts[taskId] = receivePort.sendPort;
      _activeDownloads++;
      notifyListeners();
    }).catchError((e) {
      _logger.error('Failed to spawn download worker for $taskId: $e');
      _handleWorkerError(taskId, e.toString());
    });
  }

  /// Gère les réponses du worker.
  void _handleWorkerResponse(DownloadWorkerResponse response) {
    final task = _box?.get(response.taskId);
    if (task == null) return;

    if (response.progress != null) {
      task.updateProgress(response.progress!);
    }

    if (response.status != task.status) {
      task.status = response.status;
      task.save();
    }

    if (response.errorMessage != null) {
      task.errorMessage = response.errorMessage;
      task.save();
    }

    if (response.isComplete) {
      _cleanupWorker(response.taskId);
      _activeDownloads--;
      notifyListeners();
      // Démarrer le suivant en queue
      _startNextQueued();
    } else {
      notifyListeners();
    }
  }

  void _handleWorkerError(String taskId, String error) {
    final task = _box?.get(taskId);
    if (task != null) {
      task.fail(error);
      task.save();
    }
    _cleanupWorker(taskId);
    _activeDownloads--;
    notifyListeners();
    _startNextQueued();
  }

  void _cleanupWorker(String taskId) {
    _workers[taskId]?.kill(priority: Isolate.immediate);
    _workers.remove(taskId);
    _workerPorts.remove(taskId);
    _responseControllers[taskId]?.close();
    _responseControllers.remove(taskId);
  }

  /// Démarre le prochain téléchargement en attente.
  void _startNextQueued() {
    if (_box == null) return;
    final queued = _box!.values
        .where((t) => t.status == DownloadStatus.queued)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (final task in queued) {
      if (_activeDownloads < _config.maxConcurrentDownloads) {
        _startWorker(task.id);
      } else {
        break;
      }
    }
  }

  /// Récupère les téléchargements interrompus au redémarrage.
  void _recoverInterruptedDownloads() {
    if (_box == null) return;
    final interrupted = _box!.values
        .where((t) => t.status == DownloadStatus.downloading || t.status == DownloadStatus.preparing)
        .toList();

    for (final task in interrupted) {
      task.status = DownloadStatus.queued;
      task.save();
    }
    if (interrupted.isNotEmpty) {
      _logger.info('Recovered ${interrupted.length} interrupted downloads');
      _startNextQueued();
    }
  }

  /// Envoie une commande au worker.
  void _sendCommand(String taskId, DownloadWorkerCommand command, {dynamic payload}) {
    final port = _workerPorts[taskId];
    if (port != null) {
      port.send(DownloadWorkerMessage(command, taskId, payload: payload));
    }
  }

  /// Met en pause un téléchargement.
  Future<void> pause(String taskId) async {
    final task = _box?.get(taskId);
    if (task == null) return;

    if (task.status == DownloadStatus.downloading) {
      _sendCommand(taskId, DownloadWorkerCommand.pause);
      task.pause();
      notifyListeners();
    }
  }

  /// Reprend un téléchargement.
  Future<void> resume(String taskId) async {
    final task = _box?.get(taskId);
    if (task == null) return;

    if (task.status == DownloadStatus.paused) {
      if (_activeDownloads < _config.maxConcurrentDownloads) {
        _startWorker(taskId);
      } else {
        task.resume();
      }
      notifyListeners();
    }
  }

  /// Annule un téléchargement.
  Future<void> cancel(String taskId) async {
    final task = _box?.get(taskId);
    if (task == null) return;

    _sendCommand(taskId, DownloadWorkerCommand.cancel);
    task.cancel();
    _cleanupWorker(taskId);
    if (task.isActive) _activeDownloads--;
    notifyListeners();
  }

  /// Supprime un téléchargement (fichier + entrée Hive).
  Future<void> delete(String taskId) async {
    final task = _box?.get(taskId);
    if (task == null) return;

    if (task.isActive) {
      await cancel(taskId);
    }

    // Supprimer le fichier local
    if (task.isFileExists) {
      try {
        await File(task.localPath).delete();
      } catch (e) {
        _logger.warning('Failed to delete file ${task.localPath}: $e');
      }
    }

    await HiveSync.write(_boxName, (box) => box.delete(taskId));
    notifyListeners();
  }

  /// Réessaie un téléchargement échoué.
  Future<void> retry(String taskId) async {
    final task = _box?.get(taskId);
    if (task == null || task.status != DownloadStatus.failed) return;

    task.retryCount = 0;
    task.errorMessage = null;
    task.status = DownloadStatus.queued;
    task.save();

    if (_activeDownloads < _config.maxConcurrentDownloads) {
      _startWorker(taskId);
    }
    notifyListeners();
  }

  /// Chemin local pour un téléchargement.
  String _getLocalPath(String taskId) {
    final dir = Directory('${_getDownloadsDirectory()}/$_boxName');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return '${dir.path}/$taskId.mp4';
  }

  /// Récupère les headers frais (incluant cookies Cloudflare) pour un téléchargement.
  Map<String, String> _getFreshHeaders(DownloadTask task) {
    final headers = <String, String>{};
    if (task.headers != null) {
      headers.addAll(task.headers!);
    }
    // Ajouter les headers Cloudflare (cookies + User-Agent) via le singleton
    final cfHeaders = CloudflareSessionManager().getFreshHeaders();
    headers.addAll(cfHeaders);
    return headers;
  }

  String _getDownloadsDirectory() {
    return '${Directory.current.path}/${_config.downloadDirectory}';
  }

  /// Met à jour la configuration.
  Future<void> setConfig(DownloadManagerConfig config) async {
    _config = config;
    await _saveConfig();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final taskId in _workers.keys) {
      _cleanupWorker(taskId);
    }
    super.dispose();
  }
}

/// Paramètres passés au worker isolate.
class _DownloadWorkerParams {
  final String taskId;
  final SendPort sendPort;
  final String streamUrl;
  final Map<String, String>? headers;
  final String? drmToken;
  final String localPath;
  final DownloadManagerConfig config;

  _DownloadWorkerParams({
    required this.taskId,
    required this.sendPort,
    required this.streamUrl,
    required this.headers,
    required this.drmToken,
    required this.localPath,
    required this.config,
  });
}

/// Point d'entrée du worker isolate.
void _downloadWorkerEntry(_DownloadWorkerParams params) {
  final receivePort = ReceivePort();
  params.sendPort.send(receivePort.sendPort);

  final httpClient = HttpClient();
  httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) => true;

  HttpClientRequest? currentRequest;
  IOSink? currentSink;
  bool isPaused = false;
  bool isCancelled = false;
  int pausedBytes = 0;

  // Écouter les commandes du thread principal
  final streamSubscription = receivePort.listen((dynamic message) {
    if (message is DownloadWorkerMessage) {
      switch (message.command) {
        case DownloadWorkerCommand.cancel:
          isCancelled = true;
          currentRequest?.close();
          currentSink?.close();
          break;
        case DownloadWorkerCommand.pause:
          isPaused = true;
          currentRequest?.close();
          currentSink?.close();
          break;
        case DownloadWorkerCommand.resume:
          isPaused = false;
          // Le resume relancera _runDownload avec le bon offset
          break;
        default:
          break;
      }
    }
  });

  // Démarrer le téléchargement
  _runDownload(params, httpClient, 
    onRequestCreated: (req) => currentRequest = req,
    onSinkCreated: (sink) => currentSink = sink,
    getPaused: () => isPaused,
    getCancelled: () => isCancelled,
    getPausedBytes: () => pausedBytes,
    setPausedBytes: (bytes) => pausedBytes = bytes,
  );
  streamSubscription.cancel();
}

Future<void> _runDownload(
  _DownloadWorkerParams params, 
  HttpClient httpClient, {
    required Function(HttpClientRequest) onRequestCreated,
    required Function(IOSink) onSinkCreated,
    required bool Function() getPaused,
    required bool Function() getCancelled,
    required int Function() getPausedBytes,
    required void Function(int) setPausedBytes,
  }) async {
  httpClient.badCertificateCallback = (cert, host, port) => true;

  while (true) {
    if (getCancelled()) {
      params.sendPort.send(DownloadWorkerResponse(
        taskId: params.taskId,
        status: DownloadStatus.cancelled,
        isComplete: true,
      ));
      return;
    }

    try {
      // Construire la requête
      final request = await httpClient.openUrl('GET', Uri.parse(params.streamUrl));
      onRequestCreated(request);
      
      // Ajouter les headers
      if (params.headers != null) {
        params.headers!.forEach((key, value) {
          request.headers.add(key, value);
        });
      }
      if (params.drmToken != null) {
        request.headers.add('Cookie', params.drmToken!);
      }
      
      // Support Range pour resume
      final resumeFromBytes = getPausedBytes();
      if (resumeFromBytes > 0) {
        request.headers.add('Range', 'bytes=$resumeFromBytes-');
      }

      final response = await request.close();
      
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('HTTP ${response.statusCode}');
      }

      // Fichier de sortie
      final file = File(params.localPath);
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      final mode = getPausedBytes() > 0 ? FileMode.append : FileMode.write;
      final sink = file.openWrite(mode: mode);
      onSinkCreated(sink);
      
      int totalBytes = response.contentLength ?? 0;
      if (response.statusCode == 206 && response.headers.value('content-range') != null) {
        final contentRange = response.headers.value('content-range');
        if (contentRange != null) {
          final parts = contentRange.split('/');
          if (parts.length == 2) {
            totalBytes = int.tryParse(parts[1]) ?? 0;
          }
        }
      }
      
      int bytesDownloaded = getPausedBytes();
      final stopwatch = Stopwatch()..start();

      params.sendPort.send(DownloadWorkerResponse(
        taskId: params.taskId,
        status: DownloadStatus.downloading,
        progress: DownloadProgress(totalBytes: totalBytes, bytesDownloaded: bytesDownloaded),
      ));

      await for (final chunk in response) {
        while (getPaused() && !getCancelled()) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        if (getCancelled()) {
          await sink.flush();
          await sink.close();
          params.sendPort.send(DownloadWorkerResponse(
            taskId: params.taskId,
            status: DownloadStatus.cancelled,
            isComplete: true,
          ));
          return;
        }

        sink.add(chunk);
        bytesDownloaded += chunk.length;
        
        final elapsed = stopwatch.elapsed;
        final speed = elapsed.inMilliseconds > 0 
            ? bytesDownloaded / (elapsed.inMilliseconds / 1000) 
            : 0.0;
        final remaining = speed > 0 && totalBytes > 0
            ? Duration(seconds: ((totalBytes - bytesDownloaded) / speed).round())
            : Duration.zero;

        params.sendPort.send(DownloadWorkerResponse(
          taskId: params.taskId,
          status: DownloadStatus.downloading,
          progress: DownloadProgress(
            bytesDownloaded: bytesDownloaded,
            totalBytes: totalBytes,
            speedBytesPerSec: speed,
            estimatedTimeRemaining: remaining,
          ),
        ));
      }

      await sink.flush();
      await sink.close();

      params.sendPort.send(DownloadWorkerResponse(
        taskId: params.taskId,
        status: DownloadStatus.completed,
        progress: DownloadProgress(bytesDownloaded: totalBytes, totalBytes: totalBytes),
        isComplete: true,
      ));
      return;

    } catch (e) {
      params.sendPort.send(DownloadWorkerResponse(
        taskId: params.taskId,
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      ));
      return;
    }
  }
}