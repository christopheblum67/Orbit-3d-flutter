import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/core/services/media_library_manager.dart';

part 'download.g.dart';

/// État d'un téléchargement.
@HiveType(typeId: 50)
enum DownloadStatus {
  @HiveField(0)
  queued,
  @HiveField(1)
  preparing,
  @HiveField(2)
  downloading,
  @HiveField(3)
  paused,
  @HiveField(4)
  completed,
  @HiveField(5)
  failed,
  @HiveField(6)
  cancelled,
}

/// Progression d'un téléchargement (sérialisable pour Hive).
@HiveType(typeId: 51)
class DownloadProgress extends HiveObject {
  @HiveField(0)
  final int bytesDownloaded;

  @HiveField(1)
  final int totalBytes;

  @HiveField(2)
  final double speedBytesPerSec;

  @HiveField(3)
  final Duration estimatedTimeRemaining;

  DownloadProgress({
    this.bytesDownloaded = 0,
    this.totalBytes = 0,
    this.speedBytesPerSec = 0.0,
    this.estimatedTimeRemaining = Duration.zero,
  });

  double get fraction => totalBytes > 0 ? bytesDownloaded / totalBytes : 0.0;

  String get formattedSpeed {
    if (speedBytesPerSec < 1024) return '${speedBytesPerSec.toStringAsFixed(1)} B/s';
    if (speedBytesPerSec < 1024 * 1024) return '${(speedBytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    return '${(speedBytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  String get formattedRemaining {
    if (estimatedTimeRemaining.inHours > 0) {
      return '${estimatedTimeRemaining.inHours}h ${estimatedTimeRemaining.inMinutes % 60}min';
    }
    if (estimatedTimeRemaining.inMinutes > 0) {
      return '${estimatedTimeRemaining.inMinutes}min ${estimatedTimeRemaining.inSeconds % 60}s';
    }
    return '${estimatedTimeRemaining.inSeconds}s';
  }

  DownloadProgress copyWith({
    int? bytesDownloaded,
    int? totalBytes,
    double? speedBytesPerSec,
    Duration? estimatedTimeRemaining,
  }) {
    return DownloadProgress(
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      totalBytes: totalBytes ?? this.totalBytes,
      speedBytesPerSec: speedBytesPerSec ?? this.speedBytesPerSec,
      estimatedTimeRemaining: estimatedTimeRemaining ?? this.estimatedTimeRemaining,
    );
  }
}

/// Configuration d'un téléchargement (qualité, wifi-only, etc.).
@HiveType(typeId: 52)
class DownloadConfig extends HiveObject {
  @HiveField(0)
  final bool wifiOnly;

  @HiveField(1)
  final int maxConcurrentDownloads;

  @HiveField(2)
  final int retryAttempts;

  @HiveField(3)
  final Duration retryDelay;

  @HiveField(4)
  final bool deleteAfterWatch;

  @HiveField(5)
  final String preferredQuality; // 'auto', '1080p', '720p', '480p'

  DownloadConfig({
    this.wifiOnly = true,
    this.maxConcurrentDownloads = 2,
    this.retryAttempts = 3,
    this.retryDelay = const Duration(seconds: 10),
    this.deleteAfterWatch = false,
    this.preferredQuality = 'auto',
  });

  DownloadConfig copyWith({
    bool? wifiOnly,
    int? maxConcurrentDownloads,
    int? retryAttempts,
    Duration? retryDelay,
    bool? deleteAfterWatch,
    String? preferredQuality,
  }) {
    return DownloadConfig(
      wifiOnly: wifiOnly ?? this.wifiOnly,
      maxConcurrentDownloads: maxConcurrentDownloads ?? this.maxConcurrentDownloads,
      retryAttempts: retryAttempts ?? this.retryAttempts,
      retryDelay: retryDelay ?? this.retryDelay,
      deleteAfterWatch: deleteAfterWatch ?? this.deleteAfterWatch,
      preferredQuality: preferredQuality ?? this.preferredQuality,
    );
  }
}

/// Tâche de téléchargement principale (persistée dans Hive).
@HiveType(typeId: 53)
class DownloadTask extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String mediaItemId;

  @HiveField(2)
  String title;

  @HiveField(3)
  String? posterUrl;

  @HiveField(4)
  String streamUrl;

  @HiveField(5)
  String? drmToken;

  @HiveField(6)
  String localPath;

  @HiveField(7)
  DownloadStatus status;

  @HiveField(8)
  DownloadProgress progress;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime? updatedAt;

  @HiveField(11)
  DateTime? completedAt;

  @HiveField(12)
  String? errorMessage;

  @HiveField(13)
  int retryCount;

  @HiveField(14)
  String contentType; // 'vod', 'series', 'live', 'replay'

  @HiveField(15)
  String? seriesId;

  @HiveField(16)
  int? seasonNumber;

  @HiveField(17)
  int? episodeNumber;

  @HiveField(18)
  String? episodeTitle;

  @HiveField(19)
  Map<String, String>? headers; // Headers HTTP personnalisés (Cloudflare, etc.)

  DownloadTask({
    required this.id,
    required this.mediaItemId,
    required this.title,
    this.posterUrl,
    required this.streamUrl,
    this.drmToken,
    this.localPath = '',
    this.status = DownloadStatus.queued,
    DownloadProgress? progress,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.errorMessage,
    this.retryCount = 0,
    required this.contentType,
    this.seriesId,
    this.seasonNumber,
    this.episodeNumber,
    this.episodeTitle,
    this.headers,
  }) : progress = progress ?? DownloadProgress();

  /// Crée une tâche depuis un MediaItem.
  factory DownloadTask.fromMediaItem(MediaItem item, {String? preferredQuality}) {
    return DownloadTask(
      id: 'dl_${item.id}_${DateTime.now().millisecondsSinceEpoch}',
      mediaItemId: item.id,
      title: item.title,
      posterUrl: item.posterUrl,
      streamUrl: item.streamUrl,
      contentType: _inferContentType(item),
      createdAt: DateTime.now(),
    );
  }

  static String _inferContentType(MediaItem item) {
    // À affiner selon le type réel de l'item
    return 'vod';
  }

  /// Chemin local complet du fichier téléchargé.
  String get fullLocalPath => localPath.isNotEmpty ? localPath : '';

  /// Vérifie si le fichier existe localement.
  bool get isFileExists => localPath.isNotEmpty && File(localPath).existsSync();

  /// Taille du fichier local (octets).
  int get localFileSize {
    if (!isFileExists) return 0;
    return File(localPath).lengthSync();
  }

  /// Met à jour la progression.
  void updateProgress(DownloadProgress newProgress) {
    progress = newProgress;
    updatedAt = DateTime.now();
    save();
  }

  /// Marque comme en cours de téléchargement.
  void markDownloading() {
    status = DownloadStatus.downloading;
    updatedAt = DateTime.now();
    save();
  }

  /// Met en pause.
  void pause() {
    if (status == DownloadStatus.downloading) {
      status = DownloadStatus.paused;
      updatedAt = DateTime.now();
      save();
    }
  }

  /// Reprend le téléchargement.
  void resume() {
    if (status == DownloadStatus.paused) {
      status = DownloadStatus.queued;
      updatedAt = DateTime.now();
      save();
    }
  }

  /// Marque comme terminé.
  void complete(String finalPath) {
    status = DownloadStatus.completed;
    localPath = finalPath;
    progress = progress.copyWith(bytesDownloaded: progress.totalBytes);
    completedAt = DateTime.now();
    updatedAt = DateTime.now();
    save();
  }

  /// Marque comme échoué.
  void fail(String error) {
    status = DownloadStatus.failed;
    errorMessage = error;
    updatedAt = DateTime.now();
    save();
  }

  /// Incrémente le compteur de retry.
  void incrementRetry() {
    retryCount++;
    updatedAt = DateTime.now();
    save();
  }

  /// Annule le téléchargement.
  void cancel() {
    status = DownloadStatus.cancelled;
    updatedAt = DateTime.now();
    save();
  }

  /// Vérifie si le téléchargement peut être repris.
  bool get canResume => status == DownloadStatus.paused || status == DownloadStatus.failed;

  /// Vérifie si le téléchargement est actif.
  bool get isActive => status == DownloadStatus.downloading || status == DownloadStatus.preparing;

  /// Vérifie si le téléchargement est terminé avec succès.
  bool get isCompleted => status == DownloadStatus.completed;

  /// Vérifie si le téléchargement a échoué.
  bool get isFailed => status == DownloadStatus.failed;
}