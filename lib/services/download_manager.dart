import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';
import 'package:orbit_3d_flutter/models/download.dart';
import 'package:orbit_3d_flutter/services/cloudflare_session_manager.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';

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
      maxConcurrentDownloads:
          maxConcurrentDownloads ?? this.maxConcurrentDownloads,
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

  /// Boîte de la configuration, SÉPARÉE de celle des tâches.
  ///
  /// Le config était stocké dans `downloads`, une `Box<DownloadTask>`, via un
  /// accès non typé qui « marchait » — jusqu'à ce qu'Hive compare
  /// `box.valueType` et refuse. Pire : la valeur stockée n'est pas un
  /// `DownloadTask`, donc `box.values` de la boîte des tâches trying de la
  /// convertir lèverait à son tour une erreur de cast.
  ///
  /// Deux boîtes, deux responsabilités : des tâches typées d'un côté, une
  /// configuration en Map de l'autre.
  static const String _configBoxName = 'download_config';
  static const String _configKey = 'download_config';

  final LoggerService _logger = LoggerService.instance;

  Box<DownloadTask>? _box;

  /// Future d'initialisation en cours : `init()` est rappelé depuis l'écran
  /// Téléchargements, le bouton de téléchargement de chaque fiche et le
  /// démarrage. Sans cette garde, deux appels simultanés passaient tous deux
  /// le test `isBoxOpen` (toujours faux avant l'ouverture) et le second
  /// `openBox` échouait avec
  /// « The box "downloads" is already open and of type Box<DownloadTask> ».
  Future<void>? _initFuture;
  DownloadManagerConfig _config = const DownloadManagerConfig();
  final Map<String, Isolate> _workers = {};
  final Map<String, SendPort> _workerPorts = {};
  final Map<String, StreamController<DownloadWorkerResponse>>
      _responseControllers = {};
  int _activeDownloads = 0;

  /// Configuration actuelle.
  DownloadManagerConfig get config => _config;

  /// Liste de toutes les tâches (réactive via Hive).
  Stream<List<DownloadTask>> get tasksStream => _watchTasks();

  /// Tâches en cours de téléchargement.
  List<DownloadTask> get activeTasks {
    if (_box == null) return [];
    return _box!.values
        .where(
          (t) =>
              t.status == DownloadStatus.downloading ||
              t.status == DownloadStatus.preparing,
        )
        .toList();
  }

  /// Nombre de téléchargements actifs.
  int get activeCount => _activeDownloads;

  /// Initialise le gestionnaire. Idempotent et concurrent-safe : les appels
  /// suivants partagent la première initialisation au lieu d'ouvrir la boîte
  /// une seconde fois.
  Future<void> init() {
    // La boîte peut avoir été fermée depuis la dernière initialisation : par
    // le chemin « reset usine », qui l'ouvre en `Box<dynamic>`, ou par un
    // démontage de provider. Mémoriser un succès périmé faisait ensuite
    // ré-ouvrir une boîte déjà ouverte, d'où « already open and of type
    // Box<DownloadTask> » au premier téléchargement.
    final box = _box;
    if (box != null && box.isOpen) return Future<void>.value();

    final existing = _initFuture;
    if (existing != null) return existing;
    late final Future<void> future;
    future = _doInit().catchError((Object error, StackTrace stack) {
      // On libère le future en cas d'échec : sinon la boîte resterait
      // « cassée » pour toute la session et chaque nouvel essai de
      // téléchargement rejouerait la même erreur sans jamais retentir
      // l'ouverture de la boîte.
      if (identical(_initFuture, future)) _initFuture = null;
      Error.throwWithStackTrace(error, stack);
    });
    _initFuture = future;
    return future;
  }

  Future<void> _doInit() async {
    await _openBoxOnce();
    await _loadConfig();
    _recoverInterruptedDownloads();
    _logger.info('DownloadManager initialized');
  }

  /// Sérialise l'ouverture de la boîte.
  ///
  /// `init()` sérialise déjà les initialisations, mais une réinitialisation
  /// d'usine ouvre la boîte par un chemin parallèle : sans ce verrou, deux
  /// appels se franchissent mutuellement et l'un d'eux reçoit « already
  /// open ». Le verrou rend l'opération réellement unique.
  Future<void>? _boxOpFuture;

  Future<void> _openBoxOnce() {
    return _boxOpFuture ??= _initBox().whenComplete(() {
      _boxOpFuture = null;
    });
  }

  Future<void> _initBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      // La boîte est DÉJÀ ouverte : on l'adopte.
      //
      // Le code la refermait pour la rouvrir au bon type. Cette fermeture puis
      // réouverture est une fenêtre : entre les deux, un second appel voit
      // `isBoxOpen` à faux, ouvre la boîte, et le premier reçoit alors
      // « already open and of type Box<DownloadTask> ». C'est exactement
      // l'erreur constatée au téléchargement d'un film.
      //
      // Si la boîte a été ouverte avec un AUTRE type — le chemin « reset
      // usine » l'ouvre en `Box<dynamic>` — l'adoption échoue et il faut
      // vraiment la refermer pour la rouvrir au bon type.
      try {
        _box = Hive.box<DownloadTask>(_boxName);
        _logger.info('DownloadManager: boîte « $_boxName » déjà ouverte, '
            'adoptée');
        return;
      } on Object catch (error) {
        _logger.info('DownloadManager: boîte « $_boxName » ouverte avec un '
            'autre type ($error), réouverture au bon type');
        // `Hive.box<dynamic>` fonctionne ici PARCE QUE la boîte a été ouverte
        // en `Box<dynamic>` (le seul cas qui mène dans ce catch, c'est le
        // chemin « reset usine »). Mais s'il était d'un autre type encore, cet
        // appel échouerait à son tour et masquerait le message d'origine par
        // une seconde erreur Hive : on la remonte donc explicitement.
        Box<dynamic> existing;
        try {
          existing = Hive.box<dynamic>(_boxName);
        } on Object catch (nested) {
          throw StateError(
            'DownloadManager: boîte « $_boxName » ouverte avec un type '
            'incompatible ($error), et sa fermeture a échoué ($nested). '
            'Fermer la boîte puis relancer.',
          );
        }
        if (existing.isOpen) await existing.close();
      }
    }
    _box = await Hive.openBox<DownloadTask>(_boxName);
    _logger.info('DownloadManager: boîte « $_boxName » ouverte');
  }

  /// Boîte de configuration, ouverte sans type générique.
  ///
  /// Le séparateur `async` est nécessaire : `_loadConfig` et `_saveConfig`
  /// doivent attendre l'ouverture.
  Future<Box<dynamic>> _configBox() async {
    if (Hive.isBoxOpen(_configBoxName)) {
      return Hive.box<dynamic>(_configBoxName);
    }
    return Hive.openBox<dynamic>(_configBoxName);
  }

  Future<void> _loadConfig() async {
    // Ne JAMAIS relire la boîte des tâches sans type : `Hive.box(name)`
    // infère `E = dynamic`, et Hive compare `box.valueType == E`. Une boîte
    // ouverte en `Box<DownloadTask>` ne correspond donc pas à `Box<dynamic>`,
    // et Hive lève « already open and of type Box<DownloadTask> ». C'était la
    // cause exacte de l'échec au téléchargement d'un film, 1 ms après
    // l'ouverture — visible dans le logcat.
    final box = await _configBox();
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
    final box = await _configBox();
    await box.put(_configKey, <String, Object>{
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
    return _box!.watch().map(
          (_) => _box!.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
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
    // Passe par `init()` plutôt que par `_initBox()` : `init()` re-vérifie que
    // la boîte est ouverte ET sérialise les ouvertures concurrentes. Appeler
    // `_initBox()` ici, hors de cette sérialisation, laissait deux requêtes
    // se franchir mutuellement : la seconde voyait la boîte fermée, la
    /// première l'ouvrait, et la seconde obtenait « already open ».
    await init();

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

    // Variante TYPÉE obligatoire : `HiveSync.writeAsync` résout la boîte par
    // `Hive.box<dynamic>`, et Hive compare `box.valueType == dynamic`. Sur une
    // `Box<DownloadTask>` la comparaison échoue et Hive lève « already open and
    // of type Box<DownloadTask> » — c'est ce qui faisait échouer le
    // téléchargement d'un film, bien après que `_loadConfig` ait été corrigé.
    await HiveSync.writeBoxAsync<DownloadTask, void>(
      _boxName,
      (box) async => box.put(task.id, task),
    );
    _logger.info('Download task created: ${task.id}');

    // Auto-start si place disponible
    if (_activeDownloads < _config.maxConcurrentDownloads) {
      _startWorker(task.id);
    }

    notifyListeners();
    return task;
  }

  /// Démarre un téléchargement (crée le worker isolate).
  Future<void> _startWorker(String taskId) async {
    if (_workers.containsKey(taskId)) return;

    final task = _box?.get(taskId);
    if (task == null ||
        (task.status != DownloadStatus.queued &&
            task.status != DownloadStatus.paused)) {
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

    final localPath = await _getLocalPath(taskId);
    Isolate.spawn(
      _downloadWorkerEntry,
      _DownloadWorkerParams(
        taskId: taskId,
        sendPort: receivePort.sendPort,
        streamUrl: _box!.get(taskId)!.streamUrl,
        headers: _getFreshHeaders(_box!.get(taskId)!),
        drmToken: _box!.get(taskId)!.drmToken,
        localPath: localPath,
        config: _config,
      ),
    ).then((isolate) {
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
        .where(
          (t) =>
              t.status == DownloadStatus.downloading ||
              t.status == DownloadStatus.preparing,
        )
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
  void _sendCommand(
    String taskId,
    DownloadWorkerCommand command, {
    dynamic payload,
  }) {
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
      await safeAsync<void>(
        () => File(task.localPath).delete(),
        context: 'DownloadManager.delete',
      );
    }

    // Typée, pour la même raison que `createTask`.
    await HiveSync.writeBoxAsync<DownloadTask, void>(
      _boxName,
      (box) async => box.delete(taskId),
    );
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

  String? _downloadsDirectory;

  /// Répertoire racine des téléchargements.
  ///
  /// `Directory.current` vaut `/` sur Android : l'y écrire échoue (permission
  /// refusée) ou dispersionne les fichiers hors du sandbox de l'app. On
  /// utilise donc le répertoire privé de l'application, et on retombe sur le
  /// répertoire courant si `path_provider` est indisponible.
  Future<String> resolveDownloadsDirectory() async {
    if (_downloadsDirectory != null) return _downloadsDirectory!;
    var base = _config.downloadDirectory;
    if (!base.startsWith('/')) {
      try {
        base = '${(await getApplicationDocumentsDirectory()).path}/$base';
      } on Object catch (e) {
        LoggerService.instance
            .warning('DownloadManager: path_provider indisponible ($e)');
        base = '${Directory.current.path}/${_config.downloadDirectory}';
      }
    }
    return _downloadsDirectory = base;
  }

  /// Chemin local pour un téléchargement.
  Future<String> _getLocalPath(String taskId) async {
    final root = await resolveDownloadsDirectory();
    final dir = Directory('$root/$_boxName');
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

  /// Chemin du répertoire racine des téléchargements (pour l'affichage UI).
  String? get downloadsDirectoryPath => _downloadsDirectory;

  /// Met à jour la configuration.
  Future<void> setConfig(DownloadManagerConfig config) async {
    _config = config;
    _downloadsDirectory = null;
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
  httpClient.badCertificateCallback =
      (X509Certificate cert, String host, int port) => true;

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
  _runDownload(
    params,
    httpClient,
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
      params.sendPort.send(
        DownloadWorkerResponse(
          taskId: params.taskId,
          status: DownloadStatus.cancelled,
          isComplete: true,
        ),
      );
      return;
    }

    final result = await safeAsync<void>(
      () async {
        // Construire la requête
        final request =
            await httpClient.openUrl('GET', Uri.parse(params.streamUrl));
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

        int totalBytes = response.contentLength;
        if (response.statusCode == 206 &&
            response.headers.value('content-range') != null) {
          final contentRange = response.headers.value('content-range')!;
          final parts = contentRange.split('/');
          if (parts.length == 2) {
            totalBytes = int.tryParse(parts[1]) ?? 0;
          }
        }

        int bytesDownloaded = getPausedBytes();
        final stopwatch = Stopwatch()..start();
        final head = <int>[];

        params.sendPort.send(
          DownloadWorkerResponse(
            taskId: params.taskId,
            status: DownloadStatus.downloading,
            progress: DownloadProgress(
              totalBytes: totalBytes,
              bytesDownloaded: bytesDownloaded,
            ),
          ),
        );

        await for (final chunk in response) {
          // Détection, au tout début d'un téléchargement (jamais en reprise),
          // d'une playlist HLS/DASH SAVAIT réponse : un simple GET sur un flux
          // .m3u8/.mpd sauverait la playlist (quelques Ko) et marquerait la
          // tâche « terminée » à tort.
          if (getPausedBytes() == 0 && head.length < _manifestHeadLimit) {
            head.addAll(chunk);
            if (head.length >= _manifestHeadLimit &&
                _isPlaylistManifest(head)) {
              throw Exception(
                'Ce flux est une playlist HLS/DASH (m3u8/mpd) : le '
                'téléchargement direct n\'est pas supporté.',
              );
            }
          }

          while (getPaused() && !getCancelled()) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          if (getCancelled()) {
            await sink.flush();
            await sink.close();
            params.sendPort.send(
              DownloadWorkerResponse(
                taskId: params.taskId,
                status: DownloadStatus.cancelled,
                isComplete: true,
              ),
            );
            return;
          }

          sink.add(chunk);
          bytesDownloaded += chunk.length;

          final elapsed = stopwatch.elapsed;
          final speed = elapsed.inMilliseconds > 0
              ? bytesDownloaded / (elapsed.inMilliseconds / 1000)
              : 0.0;
          final remaining = speed > 0 && totalBytes > 0
              ? Duration(
                  seconds: ((totalBytes - bytesDownloaded) / speed).round(),
                )
              : Duration.zero;

          params.sendPort.send(
            DownloadWorkerResponse(
              taskId: params.taskId,
              status: DownloadStatus.downloading,
              progress: DownloadProgress(
                bytesDownloaded: bytesDownloaded,
                totalBytes: totalBytes,
                speedBytesPerSec: speed,
                estimatedTimeRemaining: remaining,
              ),
            ),
          );
        }

        await sink.flush();
        await sink.close();

        params.sendPort.send(
          DownloadWorkerResponse(
            taskId: params.taskId,
            status: DownloadStatus.completed,
            progress: DownloadProgress(
              bytesDownloaded: totalBytes,
              totalBytes: totalBytes,
            ),
            isComplete: true,
          ),
        );
      },
      context: 'DownloadManager._runDownload',
    );
    if (result.isFailure) {
      params.sendPort.send(
        DownloadWorkerResponse(
          taskId: params.taskId,
          status: DownloadStatus.failed,
          errorMessage: result.errorOrNull?.message,
        ),
      );
      return;
    }
    return;
  }
}

/// Nombre d'octets à inspecter au début d'un téléchargement pour détecter un
/// manifest HLS/DASH et refuser la tâche avec un message explicite.
const int _manifestHeadLimit = 16;

/// Détecte une playlist HLS/DASH (m3u8/mpd) depuis ses premiers octets.
bool _isPlaylistManifest(List<int> bytes) {
  final preview = String.fromCharCodes(bytes).trimLeft();
  return preview.startsWith('#EXTM3U') ||
      preview.startsWith('#EXT-X') ||
      preview.startsWith('<?xml');
}
