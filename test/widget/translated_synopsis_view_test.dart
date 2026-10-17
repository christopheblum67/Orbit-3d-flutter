import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/widgets/translated_synopsis_view.dart';
import 'package:orbit_3d_flutter/providers/synopsis_translation_provider.dart';
import 'package:orbit_3d_flutter/services/synopsis_translation_service.dart';

/// Feuille « Synopsis » utilisée à l'identique par le détail film et le détail
/// série.
///
/// Contrat visuel : un synopsis **traduit** (TMDB fr ou Google) doit
/// s'afficher en rouge pour signaler qu'il ne s'agit pas du texte d'origine du
/// fournisseur. Un synopsis déjà en français (ou d'origine) reste dans la
/// couleur normale du thème.
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
  testWidgets('synopsis traduit (Google) → texte en rouge', (tester) async {
    await tester.pumpWidget(
      _app(
        const TranslatedSynopsis(
          text: 'Synopsis traduit automatiquement.',
          source: SynopsisSource.googleTranslate,
          detectedLanguage: 'en',
        ),
        raw: 'English synopsis that is not French at all.',
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      _textColor(tester, 'Synopsis traduit automatiquement.'),
      TranslatedSynopsisView.translatedTextColor,
    );
    // La source du traducteur reste affichée sous le texte.
    expect(find.text('Traduit automatiquement (Google)'), findsOneWidget);
  });

  testWidgets('synopsis TMDB français → texte en rouge aussi', (tester) async {
    await tester.pumpWidget(
      _app(
        const TranslatedSynopsis(
          text: 'Un synopsis TMDB en français.',
          source: SynopsisSource.tmdb,
          detectedLanguage: 'fr',
        ),
        raw: 'Original English text.',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      _textColor(tester, 'Un synopsis TMDB en français.'),
      TranslatedSynopsisView.translatedTextColor,
    );
    expect(find.text('Synopsis TMDB'), findsOneWidget);
  });

  testWidgets('synopsis d\'origine (déjà français) → couleur normale', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const TranslatedSynopsis(
          text: 'Un synopsis déjà en français.',
          source: SynopsisSource.original,
          detectedLanguage: 'fr',
        ),
        raw: 'Un synopsis déjà en français.',
      ),
    );
    await tester.pumpAndSettle();

    final color = _textColor(tester, 'Un synopsis déjà en français.');
    expect(color, isNot(TranslatedSynopsisView.translatedTextColor));
    expect(find.text('Traduit automatiquement (Google)'), findsNothing);
    expect(find.text('Synopsis TMDB'), findsNothing);
  });
}
