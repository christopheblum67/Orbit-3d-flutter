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

class _Subscriptions extends SubscriptionsNotifier {
  _Subscriptions(this.saved);

  final List<Subscription> saved;

  @override
  List<Subscription> build() => [];

  @override
  Future<void> addSubscription(Subscription subscription) async {
    saved.add(subscription);
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
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionsProvider.overrideWith(() => _Subscriptions(saved ?? [])),
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

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la télécommande navigue entre les champs et OK ouvre le clavier',
      (tester) async {
    await _openForm(tester, tv: true);
    const name = "Nom de l'abonnement";
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
    expect(_textField(tester, 'Username').focusNode!.hasPrimaryFocus, isTrue);
    expect(_textField(tester, 'Username').readOnly, isTrue);

    await _key(tester, LogicalKeyboardKey.enter);
    await tester.enterText(_field('Username'), 'tester');
    await _key(tester, LogicalKeyboardKey.escape);
    expect(_textField(tester, 'Username').readOnly, isTrue);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(_textField(tester, 'Username').controller!.text, 'tester');

    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_textField(tester, 'Password').focusNode!.hasPrimaryFocus, isTrue);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    await _key(tester, LogicalKeyboardKey.select);
    expect(_textField(tester, 'Password').obscureText, isTrue);
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    expect(_textField(tester, 'Password').focusNode!.hasPrimaryFocus, isTrue);
    await _key(tester, LogicalKeyboardKey.select);
    await tester.enterText(_field('Password'), 'secret');
    await _key(tester, LogicalKeyboardKey.arrowUp);
    expect(_textField(tester, 'Username').focusNode!.hasPrimaryFocus, isTrue);
    expect(_textField(tester, 'Password').controller!.text, 'secret');
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
      ("Nom de l'abonnement", 'Maison'),
      ('URL du serveur (ex: https://provider.com)', 'https://example.test'),
      ('Username', 'test-user'),
      ('Password', 'test-password'),
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
  });

  testWidgets('le champ focalisé reste visible sur un petit écran',
      (tester) async {
    await _openForm(tester, tv: true, size: const Size(640, 400));
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_textField(tester, 'Password').focusNode!.hasPrimaryFocus, isTrue);
    final viewport = find
        .ancestor(
          of: _field('Password'),
          matching: find.byType(SingleChildScrollView),
        )
        .first;
    final fieldRect = tester.getRect(_field('Password'));
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
