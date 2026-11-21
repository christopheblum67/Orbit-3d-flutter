import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/features/subscriptions/subscriptions_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/subscription_provider.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';

class _Subscriptions extends SubscriptionsNotifier {
  _Subscriptions(this.saved, this.activated, this.testResult, this.pending);

  final List<Subscription> saved;
  final List<String> activated;
  final TestResultStatus testResult;
  final Completer<void>? pending;

  @override
  List<Subscription> build() => [];

  @override
  Future<void> addSubscription(Subscription subscription) async {
    saved.add(subscription);
    state = [...state, subscription];
  }

  @override
  Future<void> testConnection(Subscription sub, {ApiService? api}) async {
    if (pending != null) await pending!.future;
    state = [
      for (final item in state)
        if (item.id == sub.id)
          item.copyWith(
            lastTestResult: testResult,
            lastTestError: testResult == TestResultStatus.error
                ? 'invalid credentials'
                : null,
          )
        else
          item,
    ];
  }

  @override
  Future<void> setActive(String id) async {
    activated.add(id);
    state = [for (final item in state) item.copyWith(isActive: item.id == id)];
  }
}

Finder _field(String label) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );

TextField _textField(WidgetTester tester, String label) =>
    tester.widget<TextField>(_field(label));

Future<void> _openForm(
  WidgetTester tester, {
  required bool tv,
  Size size = const Size(1280, 720),
  List<Subscription>? saved,
  List<String>? activated,
  TestResultStatus testResult = TestResultStatus.success,
  Completer<void>? pending,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final mode = TvModeNotifier()..setEnabled(tv);
  addTearDown(mode.dispose);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SubscriptionsScreen()),
      GoRoute(path: '/startup', builder: (_, __) => const Text('Démarrage')),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionsProvider.overrideWith(
          () =>
              _Subscriptions(saved ?? [], activated ?? [], testResult, pending),
        ),
        activeSubscriptionProvider.overrideWithValue(null),
        tvModeNotifierProvider.overrideWithValue(mode),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.add_rounded).first);
  await tester.pumpAndSettle();
}

Future<void> _addSubscription(WidgetTester tester) async {
  for (final (label, text) in [
    ("Nom de l’abonnement", 'Maison'),
    ('URL du serveur (ex: https://provider.com)', 'https://example.test'),
    ('Nom d’utilisateur', 'test-user'),
    ('Mot de passe', 'test-password'),
  ]) {
    await tester.enterText(_field(label), text);
  }
  await tester.tap(find.widgetWithText(FilledButton, 'Ajouter'));
  await tester.pumpAndSettle();
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la télécommande navigue entre les champs et OK ouvre le clavier',
      (tester) async {
    await _openForm(tester, tv: true);
    const name = "Nom de l’abonnement";
    const url = 'URL du serveur (ex: https://provider.com)';
    expect(_textField(tester, name).focusNode!.hasPrimaryFocus, isTrue);
    expect(_textField(tester, name).readOnly, isTrue);
    expect(tester.testTextInput.isVisible, isFalse);

    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_textField(tester, url).focusNode!.hasPrimaryFocus, isTrue);
    expect(_textField(tester, url).readOnly, isTrue);
    expect(_textField(tester, url).decoration!.focusedBorder, isNotNull);
    expect(tester.testTextInput.isVisible, isFalse);

    await _key(tester, LogicalKeyboardKey.select);
    expect(_textField(tester, url).readOnly, isFalse);
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.enterText(_field(url), 'https://example.test');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(_textField(tester, 'Nom d’utilisateur').focusNode!.hasPrimaryFocus,
        isTrue);
    expect(_textField(tester, 'Nom d’utilisateur').readOnly, isTrue);

    await _key(tester, LogicalKeyboardKey.enter);
    await tester.enterText(_field('Nom d’utilisateur'), 'tester');
    await _key(tester, LogicalKeyboardKey.escape);
    expect(_textField(tester, 'Nom d’utilisateur').readOnly, isTrue);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(_textField(tester, 'Nom d’utilisateur').controller!.text, 'tester');

    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(
        _textField(tester, 'Mot de passe').focusNode!.hasPrimaryFocus, isTrue);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    await _key(tester, LogicalKeyboardKey.select);
    expect(_textField(tester, 'Mot de passe').obscureText, isTrue);
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    expect(
        _textField(tester, 'Mot de passe').focusNode!.hasPrimaryFocus, isTrue);
    await _key(tester, LogicalKeyboardKey.select);
    await tester.enterText(_field('Mot de passe'), 'secret');
    await _key(tester, LogicalKeyboardKey.arrowUp);
    expect(_textField(tester, 'Nom d’utilisateur').focusNode!.hasPrimaryFocus,
        isTrue);
    expect(_textField(tester, 'Mot de passe').controller!.text, 'secret');
    expect(tester.testTextInput.isVisible, isFalse);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Ajouter'))
          .focusNode!
          .hasPrimaryFocus,
      isTrue,
    );
  });

  testWidgets('la télécommande permet de sélectionner M3U et son URL',
      (tester) async {
    await _openForm(tester, tv: true);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    await _key(tester, LogicalKeyboardKey.select);
    expect(_field('URL de la playlist M3U'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(
      _textField(tester, 'URL de la playlist M3U').focusNode!.hasPrimaryFocus,
      isTrue,
    );
    await _key(tester, LogicalKeyboardKey.select);
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.enterText(
      _field('URL de la playlist M3U'),
      'https://example.test/list.m3u',
    );
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Ajouter'))
          .focusNode!
          .hasPrimaryFocus,
      isTrue,
    );
  });

  testWidgets('la saisie à la télécommande enregistre les données Xtream',
      (tester) async {
    final saved = <Subscription>[];
    await _openForm(tester, tv: true, saved: saved);
    for (final (label, text) in [
      ("Nom de l’abonnement", 'Maison'),
      ('URL du serveur (ex: https://provider.com)', 'https://example.test'),
      ('Nom d’utilisateur', 'test-user'),
      ('Mot de passe', 'test-password'),
    ]) {
      expect(_textField(tester, label).focusNode!.hasPrimaryFocus, isTrue);
      await _key(tester, LogicalKeyboardKey.select);
      await tester.enterText(_field(label), text);
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
    }
    await _key(tester, LogicalKeyboardKey.select);
    expect(saved, hasLength(1));
    expect(saved.single.name, 'Maison');
    expect(saved.single.baseUrl, 'https://example.test');
    expect(saved.single.username, 'test-user');
    expect(saved.single.password, 'test-password');
    expect(find.text('Nouvel abonnement'), findsNothing);
    expect(find.text('Abonnement ajouté'), findsOneWidget);
  });

  testWidgets('test puis activation au D-pad après ajout', (tester) async {
    final saved = <Subscription>[];
    final activated = <String>[];
    await _openForm(tester, tv: true, saved: saved, activated: activated);
    for (final (label, text) in [
      ("Nom de l’abonnement", 'Maison'),
      ('URL du serveur (ex: https://provider.com)', 'https://example.test'),
      ('Nom d’utilisateur', 'test-user'),
      ('Mot de passe', 'test-password'),
    ]) {
      await _key(tester, LogicalKeyboardKey.select);
      await tester.enterText(_field(label), text);
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
    }
    await _key(tester, LogicalKeyboardKey.select);
    expect(find.text('Abonnement ajouté'), findsOneWidget);
    await _key(tester, LogicalKeyboardKey.select);
    expect(find.text('Test de connexion réussi.'), findsOneWidget);
    expect(activated, isEmpty);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.select);
    expect(activated, [saved.single.id]);
    expect(find.text('Démarrage'), findsOneWidget);
  });

  testWidgets('test en échec, nouvel essai ou activation restent possibles',
      (tester) async {
    final activated = <String>[];
    await _openForm(tester,
        tv: false, activated: activated, testResult: TestResultStatus.error);
    await _addSubscription(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Tester'));
    await tester.pumpAndSettle();
    expect(find.textContaining('refusé par le serveur'), findsOneWidget);
    expect(activated, isEmpty);
    await tester.tap(find.widgetWithText(FilledButton, 'Activer'));
    await tester.pumpAndSettle();
    expect(activated, hasLength(1));
    expect(find.text('Démarrage'), findsOneWidget);
  });

  testWidgets('annuler conserve l’abonnement sans l’activer', (tester) async {
    final saved = <Subscription>[];
    final activated = <String>[];
    await _openForm(tester, tv: false, saved: saved, activated: activated);
    await _addSubscription(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Annuler'));
    await tester.pumpAndSettle();
    expect(saved, hasLength(1));
    expect(activated, isEmpty);
    expect(find.text('Inactif'), findsOneWidget);
  });

  testWidgets('la confirmation est aussi proposée pour un abonnement M3U',
      (tester) async {
    final saved = <Subscription>[];
    await _openForm(tester, tv: false, saved: saved);
    await tester.enterText(_field("Nom de l’abonnement"), 'Playlist');
    await tester.tap(find.text('M3U Playlist'));
    await tester.pumpAndSettle();
    await tester.enterText(
      _field('URL de la playlist M3U'),
      'https://example.test/list.m3u',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Ajouter'));
    await tester.pumpAndSettle();
    expect(saved.single.type, SubscriptionType.m3u);
    expect(find.text('Abonnement ajouté'), findsOneWidget);
    expect(find.text('Tester'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Activer'), findsOneWidget);
  });

  testWidgets('annuler pendant le test laisse l’abonnement inactif',
      (tester) async {
    final pending = Completer<void>();
    final saved = <Subscription>[];
    final activated = <String>[];
    await _openForm(tester,
        tv: false, saved: saved, activated: activated, pending: pending);
    await _addSubscription(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Tester'));
    await tester.pump();
    expect(find.text('Test de connexion en cours…'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Activer'))
            .onPressed,
        isNull);
    await tester.tap(find.widgetWithText(TextButton, 'Annuler'));
    await tester.pumpAndSettle();
    pending.complete();
    await tester.pump();
    expect(saved, hasLength(1));
    expect(activated, isEmpty);
    expect(find.text('Inactif'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le champ focalisé reste visible sur un petit écran',
      (tester) async {
    await _openForm(tester, tv: true, size: const Size(640, 400));
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(
        _textField(tester, 'Mot de passe').focusNode!.hasPrimaryFocus, isTrue);
    final viewport = find
        .ancestor(
          of: _field('Mot de passe'),
          matching: find.byType(SingleChildScrollView),
        )
        .first;
    final fieldRect = tester.getRect(_field('Mot de passe'));
    final viewportRect = tester.getRect(viewport);
    expect(fieldRect.bottom, lessThanOrEqualTo(viewportRect.bottom + 1));
    expect(fieldRect.top, greaterThanOrEqualTo(viewportRect.top - 1));
    await _key(tester, LogicalKeyboardKey.arrowUp);
    await _key(tester, LogicalKeyboardKey.arrowUp);
    await _key(tester, LogicalKeyboardKey.arrowUp);
    final typeRect =
        tester.getRect(find.byType(SegmentedButton<SubscriptionType>));
    expect(typeRect.bottom, lessThanOrEqualTo(viewportRect.bottom + 1));
    expect(typeRect.top, greaterThanOrEqualTo(viewportRect.top - 1));
  });

  for (final (label, size, inset, tv) in [
    ('téléphone portrait', const Size(400, 800), 320.0, false),
    ('téléphone paysage', const Size(720, 400), 220.0, false),
    ('TV', const Size(1280, 720), 400.0, true),
  ]) {
    testWidgets('clavier ouvert : champs visibles sur $label', (tester) async {
      await _openForm(tester, tv: tv, size: size);
      tester.view.viewInsets = FakeViewPadding(bottom: inset);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      for (final field in [
        "Nom de l’abonnement",
        'URL du serveur (ex: https://provider.com)',
        'Nom d’utilisateur',
        'Mot de passe',
      ]) {
        _textField(tester, field).focusNode!.requestFocus();
        await tester.pumpAndSettle();
        final fieldRect = tester.getRect(_field(field));
        final viewport = find
            .ancestor(
              of: _field(field),
              matching: find.byType(SingleChildScrollView),
            )
            .first;
        final visibleRect = tester.getRect(viewport);
        expect(fieldRect.top, greaterThanOrEqualTo(visibleRect.top - 1),
            reason: '$field doit rester visible');
        expect(fieldRect.bottom, lessThanOrEqualTo(visibleRect.bottom + 1),
            reason: '$field doit rester visible');
        expect(fieldRect.bottom, lessThanOrEqualTo(size.height - inset),
            reason: '$field ne doit pas être caché par le clavier');
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('la télécommande garde le champ puis Ajouter visibles au clavier',
      (tester) async {
    const size = Size(1280, 720);
    await _openForm(tester, tv: true, size: size);
    await _key(tester, LogicalKeyboardKey.select);
    tester.view.viewInsets = FakeViewPadding(bottom: 400);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    for (final field in [
      "Nom de l’abonnement",
      'URL du serveur (ex: https://provider.com)',
      'Nom d’utilisateur',
      'Mot de passe',
    ]) {
      expect(_textField(tester, field).focusNode!.hasPrimaryFocus, isTrue);
      final viewport = find
          .ancestor(
            of: _field(field),
            matching: find.byType(SingleChildScrollView),
          )
          .first;
      final rect = tester.getRect(_field(field));
      final visible = tester.getRect(viewport);
      expect(rect.top, greaterThanOrEqualTo(visible.top - 1));
      expect(rect.bottom, lessThanOrEqualTo(visible.bottom + 1));
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      if (field != 'Mot de passe') {
        await _key(tester, LogicalKeyboardKey.select);
      }
    }
    final submit = find.widgetWithText(FilledButton, 'Ajouter');
    final viewport = find
        .ancestor(
          of: submit,
          matching: find.byType(SingleChildScrollView),
        )
        .first;
    expect(tester.getRect(submit).bottom,
        lessThanOrEqualTo(tester.getRect(viewport).bottom + 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('le champ M3U reste visible avec le clavier en paysage',
      (tester) async {
    await _openForm(tester, tv: false, size: const Size(720, 400));
    await tester.tap(find.text('M3U Playlist'));
    await tester.pumpAndSettle();
    _textField(tester, 'URL de la playlist M3U').focusNode!.requestFocus();
    await tester.pumpAndSettle();
    tester.view.viewInsets = FakeViewPadding(bottom: 220);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final field = _field('URL de la playlist M3U');
    final viewport = find
        .ancestor(
          of: field,
          matching: find.byType(SingleChildScrollView),
        )
        .first;
    expect(tester.getRect(field).top,
        greaterThanOrEqualTo(tester.getRect(viewport).top - 1));
    expect(tester.getRect(field).bottom,
        lessThanOrEqualTo(tester.getRect(viewport).bottom + 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('le formulaire reste directement éditable au tactile',
      (tester) async {
    await _openForm(tester, tv: false);
    const url = 'URL du serveur (ex: https://provider.com)';
    await tester.tap(_field(url));
    await tester.pumpAndSettle();
    expect(_textField(tester, url).readOnly, isFalse);
    await tester.enterText(_field(url), 'https://example.test');
    expect(_textField(tester, url).controller!.text, 'https://example.test');
  });

  testWidgets('un appui tactile édite un champ même en mode TV',
      (tester) async {
    await _openForm(tester, tv: true);
    const url = 'URL du serveur (ex: https://provider.com)';
    await tester.tap(_field(url));
    await tester.pumpAndSettle();
    expect(_textField(tester, url).readOnly, isFalse);
    expect(tester.testTextInput.isVisible, isTrue);
  });
}
