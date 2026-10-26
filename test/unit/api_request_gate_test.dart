import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/api_request_gate.dart';

void main() {
  late DateTime now;
  late List<Duration> waits;
  late ApiRequestGate gate;

  setUp(() {
    now = DateTime(2026);
    waits = [];
    gate = ApiRequestGate(
      clock: () => now,
      sleep: (duration) async {
        waits.add(duration);
        now = now.add(duration);
        if (duration == const Duration(milliseconds: 25)) gate.release();
      },
    );
  });

  test('spaces requests and waits when all concurrent slots are occupied',
      () async {
    await gate.acquire();
    await gate.acquire();
    await gate.acquire();
    await gate.acquire();

    expect(
      waits,
      [
        const Duration(milliseconds: 120),
        const Duration(milliseconds: 120),
        const Duration(milliseconds: 25),
        const Duration(milliseconds: 95),
      ],
    );
  });

  test('increases spacing after rate limits and recovers after success',
      () async {
    gate.onRateLimited();
    expect(gate.consecutiveRateLimits, 1);

    await gate.acquire();
    expect(waits, [const Duration(milliseconds: 240)]);

    gate.onSuccess();
    expect(gate.consecutiveRateLimits, 0);
    now = now.add(const Duration(milliseconds: 240));
    await gate.acquire();
    await gate.acquire();
    expect(waits.last, const Duration(milliseconds: 120));
  });
}
