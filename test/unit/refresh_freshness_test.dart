import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/services/refresh_freshness.dart';

void main() {
  test('refresh freshness expires exactly at 30 minutes', () {
    final now = DateTime(2026, 11, 8, 10);
    expect(isSubscriptionRefreshFresh(null, now: now), isFalse);
    expect(isSubscriptionRefreshFresh(now, now: now), isTrue);
    expect(
      isSubscriptionRefreshFresh(
        now.subtract(const Duration(minutes: 29, seconds: 59)),
        now: now,
      ),
      isTrue,
    );
    expect(
      isSubscriptionRefreshFresh(
        now.subtract(const Duration(minutes: 30)),
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
