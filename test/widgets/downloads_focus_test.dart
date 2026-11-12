import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/downloads/downloads_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/download.dart';

void main() {
  testWidgets('la télécommande atteint les actions du téléchargement échoué',
      (tester) async {
    var opened = 0;
    var retried = 0;
    var deleted = 0;
    final task = DownloadTask(
      id: '1',
      mediaItemId: 'film',
      title: 'Film',
      streamUrl: 'https://example.test/film',
      contentType: 'vod',
      status: DownloadStatus.failed,
      errorMessage: 'Certificat non valide',
      createdAt: DateTime(2026),
    );

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DownloadTile(
            task: task,
            onTap: () => opened++,
            onRetry: () => retried++,
            onDelete: () => deleted++,
            onPause: () {},
            onResume: () {},
            onCancel: () {},
          ),
        ),
      ),
    ));
    expect(find.text('Certificat non valide'), findsOneWidget);

    Focus.of(tester.element(find.text('Film'))).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(opened, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Réessayer'))).hasPrimaryFocus,
        isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(retried, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Supprimer'))).hasPrimaryFocus,
        isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(deleted, 1);
  });
}
