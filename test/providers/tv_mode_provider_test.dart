import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/providers/tv_mode_provider.dart';
import 'package:orbit_3d_flutter/core/utils/device_info.dart';

void main() {
  group('TvModeController - garde-fou centralisé', () {
    test('état initial inactif', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(tvModeProvider), false);
      expect(container.read(tvModeControllerProvider).enabled, false);
    });

    test('enable() active le mode TV', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(tvModeControllerProvider);
      controller.enable();
      expect(controller.enabled, true);
      expect(container.read(tvModeProvider), true);
    });

    test('disable() désactive le mode TV', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(tvModeControllerProvider);
      controller.enable();
      controller.disable();
      expect(controller.enabled, false);
    });

    test('setEnabled modifie l\'état', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(tvModeControllerProvider);
      controller.setEnabled(true);
      expect(controller.enabled, true);
      controller.setEnabled(false);
      expect(controller.enabled, false);
    });

    test('updateFromDetection active automatiquement si TV détecté', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(tvModeControllerProvider);
      final result = const DeviceDetectionResult(
        deviceType: DeviceType.tv,
        isTv: true,
        confidence: 0.8,
        details: {},
      );
      await controller.updateFromDetection(result);
      expect(controller.enabled, true);
      expect(controller.autoDetected, true);
      expect(controller.detectionResult, result);
    });

    test('updateFromDetection ne force pas la désactivation si détection mobile', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(tvModeControllerProvider);
      // Activer manuellement d'abord
      controller.enable();
      final result = const DeviceDetectionResult(
        deviceType: DeviceType.phone,
        isTv: false,
        confidence: 0.9,
        details: {},
      );
      await controller.updateFromDetection(result);
      // Ne doit pas désactiver si activé manuellement
      expect(controller.enabled, true);
    });

    test('reset réinitialise l\'état', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(tvModeControllerProvider);
      controller.enable();
      controller.reset();
      expect(controller.enabled, false);
      expect(controller.autoDetected, false);
      expect(controller.detectionResult, null);
    });
  });

  group('DeviceInfoUtils - détection multi-méthodes', () {
    test('DeviceDetectionResult structure correcte', () {
      const result = DeviceDetectionResult(
        deviceType: DeviceType.tv,
        isTv: true,
        confidence: 0.9,
        details: {'test': 'value'},
      );
      expect(result.isTv, true);
      expect(result.deviceType, DeviceType.tv);
      expect(result.confidence, 0.9);
      expect(result.details['test'], 'value');
    });

    test('DeviceType enum valeurs correctes', () {
      expect(DeviceType.values.length, 3);
      expect(DeviceType.tv, DeviceType.tv);
      expect(DeviceType.phone, DeviceType.phone);
      expect(DeviceType.unknown, DeviceType.unknown);
    });
  });
}
