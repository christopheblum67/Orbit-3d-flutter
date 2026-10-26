import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/navigation/initial_route.dart';

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

  test('completed onboarding opens profile selection', () {
    expect(
      initialRouteFor(onboardingDone: true, legalNoticeDone: false),
      '/profiles',
    );
    expect(
      initialRouteFor(onboardingDone: true, legalNoticeDone: true),
      '/profiles',
    );
  });
}
