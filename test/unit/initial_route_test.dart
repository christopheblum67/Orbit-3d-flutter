import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/navigation/initial_route.dart';
import 'package:orbit_3d_flutter/core/services/startup_refresh_controller.dart';

void main() {
  test('first launch requires legal notice before onboarding', () {
    expect(
      initialRouteFor(onboardingDone: false, legalNoticeDone: false),
      '/legal?flow=first',
    );
  });

  test('accepted legal notice proceeds to onboarding', () {
    expect(
      initialRouteFor(onboardingDone: false, legalNoticeDone: true),
      '/onboarding',
    );
  });

  test('completed onboarding starts the subscription refresh flow', () {
    expect(
      initialRouteFor(onboardingDone: true, legalNoticeDone: false),
      '/startup',
    );
    expect(
      initialRouteFor(onboardingDone: true, legalNoticeDone: true),
      '/startup',
    );
  });

  test('startup refresh phases load the intended sections in order', () {
    expect(
      StartupRefreshController.initialSteps.toList(),
      [
        StartupStep.live,
        StartupStep.movies,
        StartupStep.series,
        StartupStep.epg,
      ],
    );
    expect(
      StartupRefreshController.remainingSteps.toList(),
      [
        StartupStep.radio,
        StartupStep.replay,
        StartupStep.ai,
      ],
    );
  });
}
