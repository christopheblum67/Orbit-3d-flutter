import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';
import 'package:orbit_3d_flutter/models/download.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';

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
  final String? localPath;
  final bool headersReceived;
  final String? validator;

  DownloadWorkerResponse({
    required this.taskId,
    required this.status,
    this.progress,
    this.errorMessage,
    this.isComplete = false,
    this.localPath,
    this.headersReceived = false,
    this.validator,
  });
}

class _DownloadWorker {
  final ReceivePort receivePort = ReceivePort();
  final Completer<void> finished = Completer<void>();
  Isolate? isolate;
  SendPort? commandPort;
  DownloadWorkerCommand? pendingCommand;
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
  /// « The box "downloads" is already open and of type `Box<DownloadTask>` ».
  Future<void>? _initFuture;
  DownloadManagerConfig _config = const DownloadManagerConfig();
  final Map<String, _DownloadWorker> _workers = {};
  int _activeDownloads = 0;

  /// Flux des tâches, alimenté une fois pour toutes à l'ouverture de la boîte.
  ///
  /// ## Pourquoi un contrôleur plutôt que `_box.watch()`
  ///
  /// `DownloadsScreen.initState()` lit `tasksStream` **avant** d'appeler `init()`,
  /// qui est asynchrone. Le getter construisait alors son stream sur une boîte
  /// encore fermée et renvoyait `Stream.value([])` : un flux *mort*, qui émetait
  /// une liste vide puis se terminait, sans jamais_plus être relié à Hive.
  ///
  /// Conséquence mesurée : la tâche était bien créée et persistée (log
  /// « Download task created »), et l'onglet Téléchargements restait vide — au
  /// premier lancement comme après redémarrage, puisque `initState()` précède
  /// toujours l'ouverture asynchrone. Le rattrapage au démarrage ne pouvait
  /// pas aider : le stream n'était plus réabonnable.
  ///
  /// Un contrôleur *broadcast* alimenté à l'ouverture puis à chaque écriture
  /// Hive supprime la fenêtre : un abonné qui s'abonne avant l'ouverture reçoit
  /// bien le premier instantané, parce que l'émission a lieu après son
  /// abonnement.
  final StreamController<List<DownloadTask>> _tasksController =
      StreamController<List<DownloadTask>>.broadcast();

  /// Boîte actuellement câblée au contrôleur.
  ///
  /// On suit l'**instance**, pas un booléen : une boîte fermée puis rouverte
  /// donne un nouvel objet `Box`, dont l'écouteur précédent est mort. Un
  /// garde booléen aurait alors laissé le contrôleur muet pour toujours — le
  /// même symptôme que le bug d'origine, réapparu à la réinitialisation
  /// d'usine ou à une déconnexion.
  Box<DownloadTask>? _wiredBox;

  StreamSubscription<BoxEvent>? _tasksSubscription;

  /// Configuration actuelle.
  DownloadManagerConfig get config => _config;

  /// Liste de toutes les tâches (réactive via Hive).
  ///
  /// Ne renvoie plus `_watchTasks()` : ce getter construisait un stream
  /// *à l'instant de l'appel*, donc figé sur l'état de la boîte à cet instant.
  Stream<List<DownloadTask>> get tasksStream => _tasksController.stream;

  /// Tâches actuellement stockées, la plus récente d'abord.
  ///
  /// Public parce qu'un abonné du flux peut arriver APRÈS l'émission
  /// initiale : un contrôleur *broadcast* ne rattrape pas un événement passé,
  /// donc le flux seul ne peut pas garantir un premier instantané. LaFenêtre
  /// est réelle — un `StreamProvider` fait `await init()` avant de
  /// s'abonner, donc après le câblage.
  List<DownloadTask> get currentTasks => _snapshotTasks();

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
    if (box != null && box.isOpen) {
      // Chemin de sortie rapide : on câble quand même, car c'est le cas
      // courant lors d'une reconstruction d'écran, et qu'un contrôleur jamais
      // câblé se traduit par une liste vide.
      _wireTasksStream();
      return Future<void>.value();
    }

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
    }).whenComplete(() {
      // Libération aussi en cas de SUCCÈS. Sans elle, `_initFuture` restait
      // renseigné pour toute la vie du singleton : après une fermeture de
      // boîte, `init()`court-circuitait sur ce future déjà accompli et
      // n'ouvrait plus rien — la liste des tâches restait muette pour le
      // reste de la session.
      if (identical(_initFuture, future)) _initFuture = null;
    });
    _initFuture = future;
    return future;
  }

  Future<void> _doInit() async {
    await _openBoxOnce();
    _wireTasksStream();
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
    _startNextQueued();
    notifyListeners();
  }

  /// Instantané trié des tâches, la plus récente d'abord.
  List<DownloadTask> _snapshotTasks() {
    final box = _box;
    if (box == null) return const [];
    return box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Relie le contrôleur à Hive : première émission puis suivi des écritures.
  ///
  /// Idempotent. Appelé après l'ouverture de la boîte, jamais avant : émettre
  /// sur un contrôleur *broadcast* ne rattrape pas un abonné ultérieur, alors
  /// que le Watch de Hive, lui, est attaché à la boîte déjà ouverte.
  void _wireTasksStream() {
    final box = _box;
    if (box == null || identical(_wiredBox, box)) return;
    // Boîte précédente encore vivante : on lâche son écouteur avant d'en
    // créer un autre, sinon chaque réouverture empile une notification.
    _tasksSubscription?.cancel();
    _wiredBox = box;
    _tasksController.add(_snapshotTasks());
    _logger.info('DownloadManager: flux tâches câblé, '
        '${_snapshotTasks().length} tâche(s) présente(s)');
    _tasksSubscription = box.watch().listen((_) {
      if (_tasksController.isClosed) return;
      _tasksController.add(_snapshotTasks());
    });
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

    _startNextQueued();

    notifyListeners();
    return task;
  }

  /// Démarre un téléchargement (crée le worker isolate).
  Future<void> _startWorker(String taskId) async {
    if (_workers.containsKey(taskId)) return;

    final task = _box?.get(taskId);
    if (task == null ||
        task.status != DownloadStatus.queued ||
        _activeDownloads >= _config.maxConcurrentDownloads) {
      return;
    }

    final worker = _DownloadWorker();
    _workers[taskId] = worker;
    _activeDownloads++;
    task.status = DownloadStatus.preparing;
    unawaited(task.save());
    notifyListeners();
    worker.receivePort.listen((message) {
      if (message is SendPort) {
        worker.commandPort = message;
        final pending = worker.pendingCommand;
        if (pending != null) {
          message.send(DownloadWorkerMessage(pending, taskId));
        }
      } else if (message is DownloadWorkerResponse) {
        _handleWorkerResponse(message);
      } else if (message is List && message.length == 2) {
        _handleWorkerError(taskId, message.first.toString());
      } else if (message == null && identical(_workers[taskId], worker)) {
        _handleWorkerError(
            taskId, 'Le téléchargement s’est arrêté sans résultat.');
      }
    });

    try {
      final localPath = task.localPath.isNotEmpty
          ? task.localPath
          : await _getLocalPath(taskId);
      if (task.status != DownloadStatus.preparing) {
        _finishWorker(taskId);
        return;
      }
      task.localPath = localPath;
      await task.save();
      if (task.status != DownloadStatus.preparing) {
        _finishWorker(taskId);
        return;
      }
      final isolate = await Isolate.spawn(
        _downloadWorkerEntry,
        _DownloadWorkerParams(
          taskId: taskId,
          sendPort: worker.receivePort.sendPort,
          streamUrl: task.streamUrl,
          headers: _getFreshHeaders(task),
          drmToken: task.drmToken,
          localPath: localPath,
          validator: task.downloadValidator,
        ),
        onError: worker.receivePort.sendPort,
        onExit: worker.receivePort.sendPort,
        errorsAreFatal: true,
      );
      if (identical(_workers[taskId], worker)) {
        worker.isolate = isolate;
      } else {
        isolate.kill(priority: Isolate.immediate);
      }
    } catch (error, stack) {
      _logger.error('Failed to start download worker for $taskId',
          error: error, stackTrace: stack);
      _handleWorkerError(taskId, error.toString());
    }
  }

  /// Gère les réponses du worker.
  void _handleWorkerResponse(DownloadWorkerResponse response) {
    final task = _box?.get(response.taskId);
    if (task != null && task.status != DownloadStatus.cancelled) {
      if (response.headersReceived) {
        task.downloadValidator = response.validator;
      }
      if (response.progress != null) {
        task.progress = response.progress!;
      }
      if (response.status == DownloadStatus.completed ||
          (task.status != DownloadStatus.paused &&
              task.status != DownloadStatus.queued)) {
        task.status = response.status;
        task.errorMessage = response.errorMessage;
        if (response.status == DownloadStatus.completed) {
          task.completedAt = DateTime.now();
        }
      }
      task.updatedAt = DateTime.now();
      unawaited(task.save());
    }
    if (response.isComplete) _finishWorker(response.taskId);
    notifyListeners();
  }

  void _handleWorkerError(String taskId, String error) {
    final task = _box?.get(taskId);
    if (task != null &&
        task.status != DownloadStatus.cancelled &&
        task.status != DownloadStatus.paused &&
        task.status != DownloadStatus.queued) {
      task.fail(error);
    }
    _finishWorker(taskId);
    notifyListeners();
  }

  void _finishWorker(String taskId) {
    final worker = _workers.remove(taskId);
    if (worker == null) return;
    worker.isolate?.kill(priority: Isolate.immediate);
    worker.receivePort.close();
    _activeDownloads--;
    worker.finished.complete();
    _startNextQueued();
  }

  /// Démarre le prochain téléchargement en attente.
  void _startNextQueued() {
    if (_box == null) return;
    final queued = _box!.values
        .where((t) => t.status == DownloadStatus.queued)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    for (final task in queued) {
      if (_workers.containsKey(task.id)) continue;
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
    }
    _startNextQueued();
  }

  /// Envoie une commande au worker.
  void _sendCommand(
    String taskId,
    DownloadWorkerCommand command, {
    dynamic payload,
  }) {
    final worker = _workers[taskId];
    if (worker == null) return;
    worker.pendingCommand = command;
    worker.commandPort?.send(
      DownloadWorkerMessage(command, taskId, payload: payload),
    );
  }

  /// Met en pause un téléchargement.
  Future<void> pause(String taskId) async {
    final task = _box?.get(taskId);
    if (task == null) return;

    if (task.status == DownloadStatus.downloading ||
        task.status == DownloadStatus.preparing) {
      final worker = _workers[taskId];
      task.status = DownloadStatus.paused;
      _sendCommand(taskId, DownloadWorkerCommand.pause);
      await task.save();
      notifyListeners();
      if (worker != null) await worker.finished.future;
    }
  }

  /// Reprend un téléchargement.
  Future<void> resume(String taskId) async {
    final task = _box?.get(taskId);
    if (task == null) return;

    if (task.status == DownloadStatus.paused) {
      task.resume();
      _startNextQueued();
      notifyListeners();
    }
  }

  /// Annule un téléchargement.
  Future<void> cancel(String taskId) async {
    final task = _box?.get(taskId);
    if (task == null) return;

    final worker = _workers[taskId];
    task.cancel();
    _sendCommand(taskId, DownloadWorkerCommand.cancel);
    notifyListeners();
    if (worker != null) await worker.finished.future;
  }

  /// Supprime un téléchargement (fichier + entrée Hive).
  Future<void> delete(String taskId) async {
    final task = _box?.get(taskId);
    if (task == null) return;

    if (_workers.containsKey(taskId)) {
      await cancel(taskId);
    }

    // Supprimer le fichier local
    if (task.isFileExists) {
      await File(task.localPath).delete();
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

    _startNextQueued();
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
    if (!path.isAbsolute(base)) {
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

  /// Récupère les en-têtes fournis avec la tâche de téléchargement.
  Map<String, String> _getFreshHeaders(DownloadTask task) {
    final headers = <String, String>{};
    if (task.headers != null) {
      headers.addAll(task.headers!);
    }
    return headers;
  }

  /// Chemin du répertoire racine des téléchargements (pour l'affichage UI).
  String? get downloadsDirectoryPath => _downloadsDirectory;

  /// Met à jour la configuration.
  Future<void> setConfig(DownloadManagerConfig config) async {
    _config = config;
    _downloadsDirectory = null;
    await _saveConfig();
    _startNextQueued();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final worker in _workers.values) {
      worker.isolate?.kill(priority: Isolate.immediate);
      worker.receivePort.close();
      if (!worker.finished.isCompleted) worker.finished.complete();
    }
    _workers.clear();
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
  final String? validator;

  _DownloadWorkerParams({
    required this.taskId,
    required this.sendPort,
    required this.streamUrl,
    required this.headers,
    required this.drmToken,
    required this.localPath,
    required this.validator,
  });
}

/// Point d'entrée du worker isolate.
Future<void> _downloadWorkerEntry(_DownloadWorkerParams params) async {
  final receivePort = ReceivePort();
  params.sendPort.send(receivePort.sendPort);

  final httpClient = HttpClient()..autoUncompress = false;
  DownloadStatus? stopped;
  receivePort.listen((dynamic message) {
    if (message is DownloadWorkerMessage) {
      switch (message.command) {
        case DownloadWorkerCommand.cancel:
          stopped = DownloadStatus.cancelled;
          httpClient.close(force: true);
          break;
        case DownloadWorkerCommand.pause:
          stopped = DownloadStatus.paused;
          httpClient.close(force: true);
          break;
        default:
          break;
      }
    }
  });

  try {
    await _runDownload(params, httpClient, () => stopped);
  } finally {
    httpClient.close(force: true);
    receivePort.close();
  }
}

Future<void> _runDownload(
  _DownloadWorkerParams params,
  HttpClient httpClient,
  DownloadStatus? Function() stopped,
) async {
  final file = File(params.localPath);
  RandomAccessFile? output;
  var bytesDownloaded = 0;
  var totalBytes = 0;
  var status = DownloadStatus.failed;
  String? failure;
  var discardPartial = false;
  try {
    final existingBytes = await file.exists() ? await file.length() : 0;
    var offset = params.validator == null ? 0 : existingBytes;
    Future<HttpClientResponse> getResponse(int from) async {
      final request =
          await httpClient.openUrl('GET', Uri.parse(params.streamUrl));
      params.headers?.forEach((key, value) => request.headers.set(key, value));
      request.headers.removeAll(HttpHeaders.rangeHeader);
      request.headers.removeAll(HttpHeaders.ifRangeHeader);
      request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      if (params.drmToken != null) {
        request.headers.add(HttpHeaders.cookieHeader, params.drmToken!);
      }
      if (from > 0) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$from-');
        request.headers.set(HttpHeaders.ifRangeHeader, params.validator!);
      }
      return request.close();
    }

    var response = await getResponse(offset);
    if (offset > 0 &&
        response.statusCode == HttpStatus.requestedRangeNotSatisfiable) {
      await response.drain<void>();
      offset = 0;
      response = await getResponse(0);
    }
    if (response.statusCode != HttpStatus.ok &&
        response.statusCode != HttpStatus.partialContent) {
      throw HttpException('HTTP ${response.statusCode}');
    }

    var start = 0;
    if (response.statusCode == HttpStatus.partialContent) {
      final range = response.headers.value(HttpHeaders.contentRangeHeader);
      final match = range == null
          ? null
          : RegExp(r'^bytes (\d+)-(\d+)/(\d+)$').firstMatch(range);
      if (offset == 0 || match == null || int.parse(match[1]!) != offset) {
        throw const FormatException('Réponse Range invalide');
      }
      start = offset;
      totalBytes = int.parse(match[3]!);
      if (int.parse(match[2]!) != totalBytes - 1 || start >= totalBytes) {
        throw const FormatException('Taille Range invalide');
      }
    } else {
      totalBytes = response.contentLength > 0 ? response.contentLength : 0;
    }

    final etag = response.headers.value(HttpHeaders.etagHeader);
    final validator = etag != null && !etag.startsWith('W/')
        ? etag
        : response.headers.value(HttpHeaders.lastModifiedHeader);
    if (start > 0 && validator != null && validator != params.validator) {
      throw const FormatException('Le contenu a changé pendant la reprise');
    }
    output =
        await file.open(mode: start > 0 ? FileMode.append : FileMode.write);
    bytesDownloaded = start;
    params.sendPort.send(DownloadWorkerResponse(
      taskId: params.taskId,
      status: DownloadStatus.downloading,
      headersReceived: true,
      validator: validator,
      progress: DownloadProgress(
        totalBytes: totalBytes,
        bytesDownloaded: bytesDownloaded,
      ),
    ));

    final stopwatch = Stopwatch()..start();
    final head = <int>[];
    await for (final chunk in response) {
      if (stopped() != null) break;
      if (start == 0 && head.length < _manifestHeadLimit) {
        head.addAll(chunk.take(_manifestHeadLimit - head.length));
        if (head.length >= _manifestHeadLimit && _isPlaylistManifest(head)) {
          discardPartial = true;
          throw const FormatException(
            'Ce flux est une playlist HLS/DASH : téléchargement direct non supporté.',
          );
        }
      }
      await output.writeFrom(chunk);
      bytesDownloaded += chunk.length;
      final elapsed = stopwatch.elapsedMilliseconds;
      final speed =
          elapsed > 0 ? (bytesDownloaded - start) * 1000 / elapsed : 0.0;
      final remaining = speed > 0 && totalBytes > bytesDownloaded
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
    if (stopped() != null) return;
    if (start == 0 && _isPlaylistManifest(head)) {
      discardPartial = true;
      throw const FormatException(
        'Ce flux est une playlist HLS/DASH : téléchargement direct non supporté.',
      );
    }
    if (totalBytes > 0 && bytesDownloaded != totalBytes) {
      throw const FormatException('Téléchargement incomplet');
    }
    status = DownloadStatus.completed;
  } catch (error) {
    if (stopped() == null) {
      failure = error.toString();
    }
  } finally {
    if (output != null) {
      try {
        await output.close();
      } catch (error) {
        status = DownloadStatus.failed;
        failure = error.toString();
      }
    }
    if (discardPartial && await file.exists()) {
      try {
        await file.delete();
        bytesDownloaded = 0;
      } catch (error) {
        failure = '$failure; suppression du fichier temporaire : $error';
      }
    }
    status = stopped() ?? status;
    params.sendPort.send(DownloadWorkerResponse(
      taskId: params.taskId,
      status: status,
      errorMessage: failure,
      headersReceived: discardPartial,
      progress: DownloadProgress(
        bytesDownloaded: bytesDownloaded,
        totalBytes: status == DownloadStatus.completed && totalBytes == 0
            ? bytesDownloaded
            : totalBytes,
      ),
      isComplete: true,
      localPath: params.localPath,
    ));
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
