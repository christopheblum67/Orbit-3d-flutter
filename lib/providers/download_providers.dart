import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/download.dart';
import 'package:orbit_3d_flutter/services/download_manager.dart';

/// Le gestionnaire singleton survit au démontage de ses providers.
final downloadManagerProvider = Provider<DownloadManager>((ref) {
  return DownloadManager();
});

/// Initialise la boîte avant de fournir l'instantané puis les mises à jour.
///
/// Le flux est autoDispose, mais le gestionnaire reste partagé. L'instantané
/// est nécessaire car l'émission initiale du flux broadcast précède l'écoute.
final downloadTasksStreamProvider =
    StreamProvider.autoDispose<List<DownloadTask>>((ref) async* {
  final manager = ref.watch(downloadManagerProvider);
  await manager.init();
  yield manager.currentTasks;
  yield* manager.tasksStream;
});
