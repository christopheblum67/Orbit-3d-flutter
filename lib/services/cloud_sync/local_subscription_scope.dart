import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_sync.dart';
import 'package:orbit_3d_flutter/services/cloud_sync/subscription_cloud_record.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';

class LocalSubscriptionScope implements LocalSyncScope {
  LocalSubscriptionScope(this.storage);

  final StorageService storage;

  @override
  Future<Map<String, String>> read() => storage.readCloudSubscriptions();

  @override
  void validate(Map<String, String> entries) {
    for (final entry in entries.entries) {
      SubscriptionCloudRecord.decode(entry.key, entry.value);
    }
  }

  @override
  Future<void> applyIfUnchanged(
    Map<String, String> expected,
    Map<String, String> merged,
    void Function() checkSession,
  ) =>
      storage.applyCloudSubscriptionsIfUnchanged(
          expected, merged, checkSession);
}
