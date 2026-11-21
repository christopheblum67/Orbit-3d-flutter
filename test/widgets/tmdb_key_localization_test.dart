import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/settings/advanced_settings_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/metadata_providers.dart';
import 'package:orbit_3d_flutter/providers/tmdb_api_key_provider.dart';
import 'package:orbit_3d_flutter/services/tmdb_service.dart';

class _FakeKeyNotifier extends TmdbApiKeyOverrideNotifier {
  @override
  Future<void> setOverride(String value) async => state = value;
}

class _FakeTmdbService implements TmdbService {
  _FakeTmdbService(this.valid);

  final bool valid;

  @override
  Future<bool> validateApiKey(String key) async => valid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final valid in [true, false]) {
    testWidgets('TMDB key result is localized when valid=$valid',
        (tester) async {
      final service = _FakeTmdbService(valid);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          tmdbApiKeyOverrideProvider.overrideWith(_FakeKeyNotifier.new),
          tmdbServiceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TmdbApiKeyTile()),
        ),
      ));
      await tester.enterText(find.byType(TextField), 'test-key');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(
        find.text(valid
            ? 'TMDB key is valid'
            : 'TMDB rejected the key or the network is unavailable: check the key'),
        findsOneWidget,
      );
    });
  }
}
