import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/download.dart';
import 'package:orbit_3d_flutter/services/download_manager.dart';

/// Provider singleton pour le gestionnaire de téléchargements.
final downloadManagerProvider = Provider<DownloadManager>((ref) {
  final manager = DownloadManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});

/// Provider du stream des tâches de téléchargement.
final downloadTasksStreamProvider = StreamProvider<List<DownloadTask>>((ref) {
  final manager = ref.watch(downloadManagerProvider);
  return manager.tasksStream;
});

/// Provider du nombre de téléchargements actifs.
final activeDownloadsCountProvider = StreamProvider<int>((ref) {
  final manager = ref.watch(downloadManagerProvider);
  return manager.tasksStream.map((tasks) => tasks.where((t) => t.isActive).length);
});