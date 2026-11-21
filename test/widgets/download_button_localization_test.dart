import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/downloads/widgets/download_button.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/download.dart';
import 'package:orbit_3d_flutter/providers/download_providers.dart';

void main() {
  testWidgets('download tooltips follow the locale and task state',
      (tester) async {
    Future<void> showTasks(List<DownloadTask> tasks) => tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              downloadTasksStreamProvider
                  .overrideWith((ref) => AsyncData(tasks)),
            ],
            child: MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: DownloadButton(
                  mediaItemId: 'film',
                  title: 'Film',
                  streamUrl: 'https://example.test/film',
                ),
              ),
            ),
          ),
        );

    await showTasks([]);
    expect(find.byTooltip('Download for offline use'), findsOneWidget);

    final task = DownloadTask(
      id: '1',
      mediaItemId: 'film',
      title: 'Film',
      streamUrl: 'https://example.test/film',
      status: DownloadStatus.downloading,
      createdAt: DateTime(2026),
      contentType: 'vod',
    );
    await showTasks([task]);
    expect(find.byTooltip('Download in progress'), findsOneWidget);
    task.status = DownloadStatus.completed;
    await showTasks([task]);
    expect(find.byTooltip('Downloaded'), findsOneWidget);
  });
}
