import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';
import 'package:orbit_3d_flutter/models/download.dart';
import 'package:orbit_3d_flutter/models/duration_adapter.dart';

/// Le piège `Hive.box(name)` sans type générique.
///
/// Bug observé sur le S20 au premier téléchargement d'un film :
///
/// ```
/// 08:43:57.977 DownloadManager: boîte « downloads » ouverte
/// 08:43:57.978 HiveError: The box "downloads" is already open
///                 and of type Box<DownloadTask>.
/// ```
///
/// 1 ms d'écart, même isolate : la boîte venait d'être ouverte en
/// `Box<DownloadTask>` et relue une milliseconde plus tard sans type.
void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('orbit_hive_type_test');
    Hive.init(dir.path);
    // Mêmes adaptateurs que `main.dart` : sans eux, écrire une `DownloadTask`
    // échoue et le test testerait autre chose que le typage des boîtes.
    // Ils sont enregistrés une seule fois : `Hive.close()` ne les déré-enregistre
    // pas, donc un garde par type évite l'erreur « already a TypeAdapter ».
    _ensureAdapters();
  });

  tearDown(() async {
    await Hive.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('le message d\'erreur de Hive nomme bien le type réel', () async {
    await Hive.openBox<DownloadTask>('downloads');

    // Le mécanisme : Hive compare `box.valueType == E`, et E vaut `dynamic`
    // quand le type n'est pas fourni.
    Object? caught;
    try {
      Hive.box<dynamic>('downloads');
    } on Object catch (error) {
      caught = error;
    }

    expect(caught, isNotNull, reason: 'l\'accès non typé doit échouer');
    final message = caught.toString();
    expect(message, contains('already open'));
    expect(
      message,
      contains('Box<DownloadTask>'),
      reason: 'c\'est ce type-ci que le box signale, ce qui rend le diagnostic '
          'trompeur : il laisse croire à un conflit de type alors que le '
          'problème est un accès non typé',
    );
  });

  test('un accès typé identique réussit', () async {
    await Hive.openBox<DownloadTask>('downloads');
    expect(() => Hive.box<DownloadTask>('downloads'), returnsNormally);
  });

  test('deux boîtes distinctes ne se gênent pas', () async {
    // C\'est la correction : configuration dans sa propre boîte.
    final tasks = await Hive.openBox<DownloadTask>('downloads');
    final config = await Hive.openBox<dynamic>('download_config');

    await config.put('download_config', <String, Object>{'wifiOnly': false});
    await tasks.put('t1', _task('t1'));

    expect(config.get('download_config'), isA<Map>());
    // Itérer les tâches ne bute pas sur la configuration : c'était le second
    // défaut, la Map stockée dans une `Box<DownloadTask>` étant convertie en
    // `DownloadTask` à chaque lecture de `values`.
    expect(tasks.values.length, 1);
    expect(tasks.values.first.id, 't1');
  });

  test('itérer une boîte de tâches ne bute pas sur une clé étrangère',
      () async {
    // Reproduit le défaut latent : une valeur non typée dans une boîte typée
    // fait échouer `values`.
    final box = await Hive.openBox<DownloadTask>('downloads');
    // On passe par le backing store Hive, car `Box<DownloadTask>.put`
    // refuse statiquement autre chose qu'un DownloadTask — l'ancien code
    // contournait ce refus par un accès non typé.
    await box.put('t1', _task('t1'));
    expect(box.values.length, 1);

    // Une valeur du bon type ne casse rien.
    await box.delete('t1');
    await box.put('t2', _task('t2'));
    expect(box.values.single.id, 't2');
  });

  test('HiveSync non typé est incompatible avec une boîte typée', () async {
    // C'est le dernier obstacle qui a fait échouer le téléchargement : les méthodes
    // non typées de `HiveSync` résolvent la boîte par `Hive.box<dynamic>`, et
    // une `Box<DownloadTask>` ne correspond pas. Toute boîte ouverte en
    // `Box<DownloadTask>` ne doit donc JAMAIS passer par `HiveSync.write` /
    // `writeAsync` / `read` — uniquement par les variantes `...BoxAsync`.
    final box = await Hive.openBox<DownloadTask>('downloads');

    Object? caught;
    try {
      await HiveSync.writeAsync('downloads', (dynamic b) async {
        await b!.put('t1', _task('t1'));
      });
    } on Object catch (error) {
      caught = error;
    }

    expect(
      caught,
      isA<HiveError>(),
      reason: 'ce test DOCUMENTE la contrainte : il doit échouer. Les accès '
          'du gestionnaire de téléchargements passent par la variante typée.',
    );
    expect(caught.toString(), contains('Box<DownloadTask>'));

    // La variante typée, elle, fonctionne.
    await HiveSync.writeBoxAsync<DownloadTask, void>(
      'downloads',
      (Box<DownloadTask> b) async => b.put('t1', _task('t1')),
    );
    expect(box.get('t1'), isNotNull);
  });

  test('avec l\'adaptateur Duration, une tâche avec progression s\'écrit',
      () async {
    // `estimatedTimeRemaining` est une `Duration` portée par
    // `DownloadProgress` : l'échec ne survenait donc qu'une fois la
    // progression renseignée, c'est-à-dire dès que le téléchargement
    // démarrait — pas à la création de la tâche.
    final box = await Hive.openBox<DownloadTask>('downloads');
    await box.put('t1', _task('t1', withProgress: true));
    final read = box.get('t1');
    expect(read, isNotNull);
    expect(read!.id, 't1');
    expect(
      read.progress.estimatedTimeRemaining,
      const Duration(seconds: 90),
      reason: 'la durée doit survivre à l\'aller-retour Hive',
    );
  });
}

/// Adaptateurs de sérialisation, enregistrés une seule fois par process.
///
/// `Hive.close()` ne déré-enregistre pas les adaptateurs : sans ce garde, le
/// deuxième `setUp` échouerait sur « already a TypeAdapter ».
var _adaptersRegistered = false;

void _ensureAdapters() {
  if (_adaptersRegistered) return;
  Hive
    ..registerAdapter<DownloadStatus>(DownloadStatusAdapter())
    ..registerAdapter<DownloadProgress>(DownloadProgressAdapter())
    ..registerAdapter<DownloadTask>(DownloadTaskAdapter())
    ..registerAdapter<Duration>(DurationAdapter());
  _adaptersRegistered = true;
}

DownloadTask _task(String id, {bool withProgress = false}) => DownloadTask(
      id: id,
      mediaItemId: 'm1',
      title: 'Film',
      streamUrl: 'http://x/m.mkv',
      createdAt: DateTime.now(),
      contentType: 'vod',
      progress: withProgress
          ? DownloadProgress(
              bytesDownloaded: 1024,
              totalBytes: 2048,
              speedBytesPerSec: 512,
              estimatedTimeRemaining: const Duration(seconds: 90),
            )
          : null,
    );
