import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:orbit_3d_flutter/core/theme/app_theme.dart';
import 'package:orbit_3d_flutter/core/widgets/cast_carousel.dart';
import 'package:orbit_3d_flutter/core/widgets/home_clock.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/memory_settings_panel.dart';
import 'package:orbit_3d_flutter/features/vod/widgets/crew_section.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/cast.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  for (final brightness in Brightness.values) {
    testWidgets('text adapts to $brightness surfaces', (tester) async {
      final theme = brightness == Brightness.light
          ? AppTheme.lightTheme()
          : AppTheme.darkTheme();
      final actor = Actor(
        id: '1',
        name: 'Actor name',
        character: 'Character name',
        profilePath: '',
      );
      final member = CrewMember(
        id: '2',
        name: 'Crew name',
        job: 'Director',
        department: 'Directing',
        profilePath: '',
      );
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: theme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const HomeClock(),
                  CastCarousel(actors: [actor], itemWidth: 180),
                  CrewSection(crew: [member]),
                  const MemorySettingsPanel(),
                ],
              ),
            ),
          ),
        ),
      ));

      Color? textColor(Finder finder) =>
          tester.widget<Text>(finder).style?.color;
      final clockTexts = find.descendant(
        of: find.byType(HomeClock),
        matching: find.byType(Text),
      );
      expect(textColor(clockTexts.at(0)), theme.colorScheme.onSurface);
      expect(textColor(clockTexts.at(1)), theme.colorScheme.onSurfaceVariant);
      expect(textColor(find.text('Actor name')), theme.colorScheme.onSurface);
      expect(textColor(find.text('Character name')),
          theme.colorScheme.onSurfaceVariant);
      expect(textColor(find.text('Crew name')), theme.colorScheme.onSurface);
      expect(
          textColor(find.text('Director')), theme.colorScheme.onSurfaceVariant);
      expect(textColor(find.textContaining('global history')),
          theme.colorScheme.onSurfaceVariant);
      expect(textColor(find.textContaining('cached files on disk are kept')),
          theme.colorScheme.onSurfaceVariant);
    });
  }
}
