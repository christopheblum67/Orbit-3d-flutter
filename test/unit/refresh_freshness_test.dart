import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/services/refresh_freshness.dart';

void main() {
  test('refresh freshness expires exactly at 8 hours', () {
    final now = DateTime(2026, 11, 8, 10);
    expect(isSubscriptionRefreshFresh(null, now: now), isFalse);
    expect(isSubscriptionRefreshFresh(now, now: now), isTrue);
    expect(
      isSubscriptionRefreshFresh(
        now.subtract(const Duration(hours: 7, minutes: 59, seconds: 59)),
        now: now,
      ),
      isTrue,
    );
    expect(
      isSubscriptionRefreshFresh(
        now.subtract(const Duration(hours: 8)),
        now: now,
      ),
      isFalse,
    );
    expect(
      isSubscriptionRefreshFresh(now.add(const Duration(seconds: 1)), now: now),
      isFalse,
    );
  });
}
