import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/download.dart';
import 'package:orbit_3d_flutter/providers/subscription_provider.dart';
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
    Provider.autoDispose<AsyncValue<List<DownloadTask>>>((ref) {
  final subscription = ref.watch(activeSubscriptionProvider);
  if (subscription == null || subscription.id.isEmpty) {
    return const AsyncData([]);
  }
  return ref.watch(downloadTasksForSubscriptionProvider(subscription.id));
});

final downloadTasksForSubscriptionProvider = StreamProvider.autoDispose
    .family<List<DownloadTask>, String>((ref, subscriptionId) async* {
  final manager = ref.watch(downloadManagerProvider);
  final subscriptions = ref.watch(subscriptionsProvider);
  await manager.init();
  if (!ref.mounted) return;
  if (subscriptions.length == 1 && subscriptions.single.id == subscriptionId) {
    await manager.assignLegacyTasks(subscriptionId, () {
      if (!ref.mounted) return false;
      final current = ref.read(subscriptionsProvider);
      return current.length == 1 &&
          current.single.id == subscriptionId &&
          ref.read(activeSubscriptionProvider)?.id == subscriptionId;
    });
  }
  if (!ref.mounted) return;
  List<DownloadTask> scoped(List<DownloadTask> tasks) =>
      tasks.where((task) => task.subscriptionId == subscriptionId).toList();
  yield* Stream<List<DownloadTask>>.multi((controller) {
    final subscription = manager.tasksStream.listen(
      (tasks) => controller.add(scoped(tasks)),
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
    controller.add(scoped(manager.currentTasks));
  });
});
