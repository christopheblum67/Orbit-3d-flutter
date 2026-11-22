import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/orbit_cached_image.dart';
import 'package:orbit_3d_flutter/core/widgets/secure_cached_image.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/cloudflare_session_manager.dart';

class _Session extends Fake implements CloudflareSessionManager {
  _Session(this.baseUrl);

  @override
  final String baseUrl;

  @override
  Map<String, String> get videoHeaders => {'X-Test-Session': 'marker'};
}

void main() {
  testWidgets('envoie les en-têtes seulement à la même origine',
      (tester) async {
    Future<void> check(String baseUrl, String imageUrl, bool allowed) async {
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            cloudflareSessionProvider.overrideWith((ref) => _Session(baseUrl)),
          ],
          child: MaterialApp(
            home: SecureCachedImage(imageUrl: imageUrl),
          ),
        ),
      );
      final image = tester.widget<OrbitCachedImage>(
        find.byType(OrbitCachedImage),
      );
      expect(image.httpHeaders != null, allowed && !kIsWeb, reason: imageUrl);
    }

    const origin = 'https://panel.example';
    await check(origin, 'https://PANEL.example:443/poster', true);
    await check(origin, 'https://other.example/poster', false);
    await check(origin, 'https://sub.panel.example/poster', false);
    await check(origin, 'http://panel.example/poster', false);
    await check(origin, 'https://panel.example:8443/poster', false);
    await check(origin, 'https://user@panel.example/poster', false);
    await check(origin, '/poster', false);
    await check('', 'https://panel.example/poster', false);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
