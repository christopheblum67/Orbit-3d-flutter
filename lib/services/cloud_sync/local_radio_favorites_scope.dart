import 'package:orbit_3d_flutter/services/cloud_sync/encrypted_scope_sync.dart';
import 'package:orbit_3d_flutter/services/radio_favorites_store.dart';

class LocalRadioFavoritesScope implements LocalSyncScope {
  LocalRadioFavoritesScope(this.profileId);

  final String profileId;

  @override
  Future<Map<String, String>> read() async => {
        for (final name in await RadioFavoritesStore.read(profileId)) name: '1',
      };

  @override
  void validate(Map<String, String> entries) {
    if (entries.values.any((value) => value != '1')) {
      throw const FormatException('Favoris radio invalides.');
    }
  }

  @override
  Future<void> applyIfUnchanged(
    Map<String, String> expected,
    Map<String, String> merged,
    void Function() checkSession,
  ) {
    validate(merged);
    return RadioFavoritesStore.applyIfUnchanged(
      profileId,
      expected.keys.toSet(),
      merged.keys.toSet(),
      checkSession,
    );
  }
}
