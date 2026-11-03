import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/widgets/translated_synopsis_view.dart';
import 'package:orbit_3d_flutter/providers/synopsis_translation_provider.dart';
import 'package:orbit_3d_flutter/services/synopsis_translation_service.dart';

Widget _app(TranslatedSynopsis result, {required String raw}) => ProviderScope(
      overrides: [
        translatedSynopsisProvider.overrideWith((ref, arg) async => result),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: TranslatedSynopsisView(title: 'Un titre', rawSynopsis: raw),
        ),
      ),
    );

Color? _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  testWidgets('Google-translated synopsis is red and attributed',
      (tester) async {
    await tester.pumpWidget(
      _app(
        const TranslatedSynopsis(
          text: 'Synopsis traduit automatiquement.',
          source: SynopsisSource.googleTranslate,
          detectedLanguage: 'en',
        ),
        raw: 'English synopsis.',
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      _textColor(tester, 'Synopsis traduit automatiquement.'),
      TranslatedSynopsisView.translatedTextColor,
    );
    expect(find.text('Traduit par Google'), findsOneWidget);
  });

  testWidgets('TMDB-localized synopsis is also indicated as translated',
      (tester) async {
    await tester.pumpWidget(
      _app(
        const TranslatedSynopsis(
          text: 'Un synopsis fourni par TMDB.',
          source: SynopsisSource.tmdb,
          detectedLanguage: 'fr',
        ),
        raw: 'Original English text.',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      _textColor(tester, 'Un synopsis fourni par TMDB.'),
      TranslatedSynopsisView.translatedTextColor,
    );
    expect(find.text('Synopsis TMDB'), findsOneWidget);
  });

  testWidgets('original synopsis keeps the normal theme color', (tester) async {
    await tester.pumpWidget(
      _app(
        const TranslatedSynopsis(
          text: 'Un synopsis original.',
          source: SynopsisSource.original,
          detectedLanguage: 'fr',
        ),
        raw: 'Un synopsis original.',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      _textColor(tester, 'Un synopsis original.'),
      isNot(TranslatedSynopsisView.translatedTextColor),
    );
    expect(find.text('Traduit par Google'), findsNothing);
    expect(find.text('Synopsis TMDB'), findsNothing);
  });
}
