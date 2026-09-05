import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('should have correct app name', () {
      expect(AppConstants.appName, 'Orbit IPTV');
    });

    test('should have valid API URL', () {
      expect(AppConstants.apiBaseUrl, isNotEmpty);
      expect(AppConstants.apiBaseUrl.startsWith('http'), isTrue);
    });

    test('should have positive dimensions', () {
      expect(AppConstants.defaultPadding, greaterThan(0));
      expect(AppConstants.defaultMargin, greaterThan(0));
      expect(AppConstants.defaultRadius, greaterThan(0));
    });

    test('should have valid pagination', () {
      expect(AppConstants.defaultPageSize, greaterThan(0));
      expect(AppConstants.maxPageSize,
          greaterThanOrEqualTo(AppConstants.defaultPageSize),);
    });
  });
}
