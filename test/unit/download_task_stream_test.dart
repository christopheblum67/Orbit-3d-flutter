import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orbit_3d_flutter/models/download.dart';
import 'package:orbit_3d_flutter/models/duration_adapter.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/download_manager.dart';

/// L'onglet Téléchargements vide malgré une tâche persistée.
///
/// Bug observé sur le S20 : la tâche était bien créée et écrite sur le disque
/// (log « Download task created: dl_952629_1791347096260 », puis échec réseau),
/// et l'onglet affichait « aucun téléchargement » — au premier lancement comme
/// après redémarrage.
///
/// Cause : `DownloadsScreen.initState()` lit `tasksStream` *avant* d'appeler
/// `init()`, qui est asynchrone. Le getter construisait son stream sur une
/// boîte encore fermée et renvoyait `Stream.value([])` : un flux mort, qui
/// émetait une liste vide puis se terminait. Il n'était plus jamais relié à
/// Hive, donc aucune écriture ultérieure n'y parvenait.
void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('orbit_dl_stream_test');
    Hive.init(dir.path);
    _ensureAdapters();
  });

  tearDown(() async {
    await Hive.close();
    // La boîte peut rester verrouillée le temps que les handles se ferment :
    // le répertoire est jeté sans faire échouer le test sur un détail de
    // système de fichiers Windows sans rapport avec l'assertion.
    try {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    } on FileSystemException {
      // ignoré : le temporary est nettoyé par l'OS.
    }
  });

  test('un abonné pris avant l\'ouverture voit les tâches persistées',
      () async {
    // Session précédente : la tâche existe sur le disque, personne ne l'a
    // encore lue dans ce process.
    final seeded = await Hive.openBox<DownloadTask>('downloads');
    await seeded.put('prev-session', _task('prev-session'));

    final manager = DownloadManager();

    // Exactement l'ordre de `DownloadsScreen.initState()` : abonnement d'abord,
    // `init()` ensuite.
    final seen = <List<DownloadTask>>[];
    final sub = manager.tasksStream.listen(seen.add);
    addTearDown(sub.cancel);

    await manager.init();
    await _pump();

    expect(
      seen,
      isNotEmpty,
      reason: 'l\'abonné doit recevoir au moins l\'instantané initial : '
          'sans lui, l\'écran reste vide quoi qu\'il y ait dans la boîte',
    );
    expect(
      seen.last.map((t) => t.id),
      contains('prev-session'),
      reason: 'la tâche écrite par la session précédente doit être visible',
    );
  });

  test('le flux suit les écritures postérieures à l\'ouverture', () async {
    final manager = DownloadManager();
    final seen = <List<DownloadTask>>[];
    final sub = manager.tasksStream.listen(seen.add);
    addTearDown(sub.cancel);

    await manager.init();
    await _pump();
    expect(seen, isNotEmpty, reason: 'précondition : l\'instantané initial');

    final box = Hive.box<DownloadTask>('downloads');
    await box.put('added-later', _task('added-later'));
    await _pump();

    expect(
      seen.last.map((t) => t.id),
      contains('added-later'),
      reason: 'une tâche créée après coup doit apparaître sans rouvrir l\'écran',
    );
  });

  test('le provider ouvre la boîte et rend la tâche déjà persistée', () async {
    // La tâche est écrite AVANT toute initialisation du gestionnaire.
    final seeded = await Hive.openBox<DownloadTask>('downloads');
    await seeded.put('orpheline', _task('orpheline'));

    final container = ProviderContainer();
    addTearDown(container.dispose);

    // `autoDispose` : sans écouteur, le provider est détruit dès la fin du
    // `read`, donc son futur se complète sur un provider déjà mort
    // (« disposed during loading state »). L'écouteur le garde en vie.
    final sub = container.listen(downloadTasksStreamProvider, (_, __) {});
    addTearDown(sub.close);

    // Aucun appel à `DownloadManager().init()` : c'est le provider qui doit le
    // faire. C'est exactement le chemin de `DownloadsSection`, seul lecteur de
    // la liste, et il n'initialisait rien.
    final tasks = await container.read(downloadTasksStreamProvider.future);

    expect(
      tasks.map((t) => t.id),
      contains('orpheline'),
      reason: 'le provider doit initialiser le gestionnaire et rendre l\'état '
          'courant, pas une liste vide',
    );
  });
}

/// Laisse tourner la boucle d\'événements le temps que Hive notifie ses
/// observateurs. `Duration.zero` ne suffit pas : la notification part dans un
/// tour de boucle ultérieur.
Future<void> _pump() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

/// `Hive.close()` ne déré-enregistre pas les adaptateurs : un garde par process.
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

DownloadTask _task(String id) => DownloadTask(
      id: id,
      mediaItemId: 'm1',
      title: 'Film',
      streamUrl: 'http://x/m.mkv',
      createdAt: DateTime.now(),
      contentType: 'vod',
    );