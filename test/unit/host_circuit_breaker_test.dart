import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/host_circuit_breaker.dart';

void main() {
  group('HostCircuitBreaker', () {
    late HostCircuitBreaker breaker;

    setUp(() {
      breaker = HostCircuitBreaker.instance;
      breaker.resetAll();
    });

    test('initial state: not in cooldown', () {
      expect(breaker.isInCooldown('example.com'), isFalse);
      expect(breaker.remainingCooldown('example.com'), Duration.zero);
      expect(breaker.cooldownMessage('example.com'), isNull);
    });

    test('records failure and enters cooldown after 2 failures', () {
      breaker.recordFailure('example.com');
      expect(breaker.isInCooldown('example.com'), isFalse);
      expect(breaker.remainingCooldown('example.com'), Duration.zero);

      breaker.recordFailure('example.com');
      expect(breaker.isInCooldown('example.com'), isTrue);
      expect(breaker.remainingCooldown('example.com').inSeconds, greaterThan(0));
      expect(breaker.cooldownMessage('example.com'), contains('Serveur protégé'));
    });

    test('records success resets failure count', () {
      breaker.recordFailure('example.com');
      breaker.recordFailure('example.com');
      expect(breaker.isInCooldown('example.com'), isTrue);

      breaker.recordSuccess('example.com');
      expect(breaker.isInCooldown('example.com'), isFalse);
      expect(breaker.remainingCooldown('example.com'), Duration.zero);
    });

    test('resetHost clears state for specific host', () {
      breaker.recordFailure('example.com');
      breaker.recordFailure('example.com');
      expect(breaker.isInCooldown('example.com'), isTrue);

      breaker.resetHost('example.com');
      expect(breaker.isInCooldown('example.com'), isFalse);
    });

    test('resetAll clears all hosts', () {
      breaker.recordFailure('example.com');
      breaker.recordFailure('example.com');
      breaker.recordFailure('other.com');
      breaker.recordFailure('other.com');

      breaker.resetAll();
      expect(breaker.isInCooldown('example.com'), isFalse);
      expect(breaker.isInCooldown('other.com'), isFalse);
    });

    test('custom cooldown duration', () {
      breaker.recordFailure('example.com', cooldown: const Duration(seconds: 30));
      breaker.recordFailure('example.com', cooldown: const Duration(seconds: 30));
      expect(breaker.isInCooldown('example.com'), isTrue);
      expect(breaker.remainingCooldown('example.com').inSeconds, lessThanOrEqualTo(30));
    });

    test('different hosts have independent state', () {
      breaker.recordFailure('host1.com');
      breaker.recordFailure('host1.com');
      breaker.recordFailure('host2.com');

      expect(breaker.isInCooldown('host1.com'), isTrue);
      expect(breaker.isInCooldown('host2.com'), isFalse);
    });
  });
}