import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/drm/license_manager.dart';
import 'package:orbit_3d_flutter/drm/drm_manager.dart';
import 'package:orbit_3d_flutter/drm/license_cache.dart';
import 'package:orbit_3d_flutter/drm/widevine/widevine_delegate.dart';
import 'package:orbit_3d_flutter/drm/widevine_config_store.dart';

export 'package:orbit_3d_flutter/drm/license_manager.dart';
export 'package:orbit_3d_flutter/drm/drm_manager.dart';
export 'package:orbit_3d_flutter/drm/license_cache.dart';
export 'package:orbit_3d_flutter/drm/widevine/widevine_delegate.dart';

/// Provider global pour le cache de licences.
final licenseCacheProvider = Provider<LicenseCache>((ref) => licenseCache);

/// Provider pour le gestionnaire de licences.
final licenseManagerProvider = Provider<LicenseManager>((ref) {
  return LicenseManager();
});

/// Provider pour le gestionnaire DRM principal.
final drmManagerProvider = Provider<DrmManager>((ref) {
  return DrmManager(licenseManager: ref.watch(licenseManagerProvider));
});

/// Provider pour le délégué Widevine.
final widevineDelegateProvider = Provider<WidevineDelegate>((ref) {
  return WidevineDelegate(licenseManager: ref.watch(licenseManagerProvider));
});

/// Chaque abonnement conserve sa propre configuration de licence.
final widevineConfigProvider = FutureProvider.family<WidevineConfig?, String>(
  (ref, subscriptionId) =>
      WidevineConfigStore.instance.loadForSubscription(subscriptionId),
);

final legacyWidevineConfigProvider = FutureProvider<WidevineConfig?>(
  (ref) => WidevineConfigStore.instance.load(),
);
