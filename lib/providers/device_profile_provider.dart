import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/hardware/hardware_detector.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// Profil de lecture actif, persisté dans les réglages (clé
/// `device_profile`). Recalculé à chaque invalidation après un diagnostic
/// (lib/features/onboarding/onboarding_screen.dart).
final deviceProfileProvider = Provider<DeviceProfile>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final raw = storage.getSetting('device_profile');
  for (final profile in DeviceProfile.values) {
    if (profile.name == raw) return profile;
  }
  return DeviceProfile.standard;
});

/// Clé de réglage stockée pour [deviceProfileProvider].
const kDeviceProfileKey = 'device_profile';

/// Flag de premier lancement : écran de diagnostic terminé.
const kOnboardingDoneKey = 'onboarding_done';