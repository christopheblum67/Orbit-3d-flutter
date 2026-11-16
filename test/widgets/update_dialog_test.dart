import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/update_dialog.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/services/github_update_service.dart';

class _Updates extends GithubUpdateService {
  final downloaded = Completer<void>();
  int downloadCalls = 0;
  int installCalls = 0;

  @override
  Future<UpdateRelease?> check() async => UpdateRelease(
        version: 'v1.1.0',
        notes: 'Nouveautés',
        url: Uri.parse('https://github.com/file'),
        sha256: 'unused',
        size: 1,
      );

  @override
  Future<void> download(UpdateRelease release, void Function(double) progress) {
    downloadCalls++;
    progress(1);
    return downloaded.future;
  }

  @override
  Future<bool> install(UpdateRelease release) async => ++installCalls > 1;
}

class _NoRelease extends GithubUpdateService {
  @override
  Future<UpdateRelease?> check() async =>
      throw const UpdateException('no_release');
}

void main() {
  testWidgets(
      'remote selection waits for download and permits installation retry',
      (tester) async {
    final service = _Updates();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Builder(
            builder: (context) => FilledButton(
                  onPressed: () => showUpdateDialog(context, service: service),
                  child: const Text('Ouvrir'),
                )),
      ),
    ));
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    expect(find.textContaining('v1.1.0'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(service.downloadCalls, 1);
    expect(service.installCalls, 0);
    expect(find.text('100 %'), findsOneWidget);
    service.downloaded.complete();
    await tester.pumpAndSettle();
    expect(service.installCalls, 1);
    expect(find.textContaining('applications inconnues'), findsOneWidget);
    await tester.tap(find.text('Réessayer l’installation'));
    await tester.pumpAndSettle();
    expect(service.installCalls, 2);
    expect(find.text('Ouvrir'), findsOneWidget);
  });

  testWidgets('a missing stable release is reported explicitly',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: UpdateDialog(service: _NoRelease())),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Aucune release stable'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });
}
