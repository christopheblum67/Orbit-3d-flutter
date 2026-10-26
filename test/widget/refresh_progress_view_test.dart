import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orbit_3d_flutter/core/services/refresh_steps_controller.dart';
import 'package:orbit_3d_flutter/features/startup/widgets/refresh_progress_view.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations_fr.dart';

/// Écran de régénération des flux (démarrage **et** « Mettre à jour »).
///
/// Il ne doit afficher QUE le nom de l'application et la progression des
/// sections d'abonnement. Le carrousel de recommandations (« Pour vous ») a été
/// retiré : ces tests verrouillent son absence et la présence des informations
/// attendues, dans les deux orientations.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    int percent = 40,
    StartupStep? currentStep,
    Set<StartupStep> doneSteps = const {},
    bool isFinished = false,
    bool showBranding = true,
    Size size = const Size(400, 800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: RefreshProgressView(
            percent: percent,
            currentStep: currentStep,
            doneSteps: doneSteps,
            isFinished: isFinished,
            showBranding: showBranding,
          ),
        ),
      ),
    );
  }

  testWidgets('affiche « Orbit IPTV » et le texte de mise à jour',
      (tester) async {
    await pump(tester, percent: 40, currentStep: StartupStep.movies);

    expect(find.text('Orbit IPTV'), findsOneWidget);
    expect(
      find.textContaining(AppLocalizationsFr().updatingMediaContent),
      findsOneWidget,
    );
    expect(find.text('40 %'), findsOneWidget);
  });

  testWidgets('n\'affiche plus « Pour vous »', (tester) async {
    await pump(tester);
    expect(find.text('Pour vous'), findsNothing);
    expect(find.textContaining('Sélection du jour'), findsNothing);
  });

  testWidgets('peut différer le branding sans masquer la progression',
      (tester) async {
    await pump(tester, showBranding: false);

    expect(find.text('Orbit IPTV'), findsNothing);
    expect(find.text('40 %'), findsOneWidget);
  });

  testWidgets('affiche les 4 sections d\'abonnement', (tester) async {
    await pump(tester);
    expect(find.text('Chaînes TV'), findsOneWidget);
    expect(find.text('Films & VOD'), findsOneWidget);
    expect(find.text(AppLocalizationsFr().series), findsOneWidget);
    expect(find.text('EPG'), findsOneWidget);
  });

  testWidgets('affiche « Prêt ! » une fois la mise à jour terminée',
      (tester) async {
    await pump(tester, percent: 100, isFinished: true);
    expect(find.text('Prêt !'), findsOneWidget);
    expect(find.textContaining('Mise à jour du contenu'), findsNothing);
  });

  testWidgets('paysage : pas d\'overflow, nom et sections visibles',
      (tester) async {
    await pump(
      tester,
      currentStep: StartupStep.live,
      size: const Size(1000, 480),
    );
    expect(find.text('Orbit IPTV'), findsOneWidget);
    expect(find.text('Chaînes TV'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('l\'écran de démarrage ne contient plus le carrousel « Pour vous »', () {
    final src = File(
      'lib/features/startup/startup_splash_screen.dart',
    ).readAsStringSync();
    expect(src.contains('Pour vous'), isFalse);
    expect(src.contains('Sélection du jour'), isFalse);
    expect(src.contains('PersonalizedRecommendations'), isFalse);
  });
}
