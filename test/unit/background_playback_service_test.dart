import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/services/background_playback_service.dart';

/// Contrat du pont « orbit/playback_service » (foreground service +
/// MediaSession native).
///
/// Le canal est simulé : on fixe (1) les arguments envoyés au natif au
/// démarrage / à la mise à jour, et (2) la remontée des commandes distantes
/// (`play`/`pause`/`next`…) vers le flux Dart consommé par l'écran lecteur.
/// Une faute sur une clé d'argument (`playing` oublié) ou sur le nom de la
/// commande ne se voit qu'à l'exécution sur un vrai appareil ; ces tests la
/// rendent visible hors device.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('orbit/playback_service');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  /// Simule un appel natif -> Dart sur le canal (MediaSession native).
  Future<void> emitFromNative(String command) {
    final data =
        const StandardMethodCodec().encodeMethodCall(MethodCall('command', command));
    return messenger.handlePlatformMessage('orbit/playback_service', data, (_) {});
  }

  test('start transmet titre, sous-titre et état de lecture', () async {
    final service = BackgroundPlaybackService();

    final ok = await service.start(
      title: 'TF1',
      subtitle: 'Direct',
      playing: true,
    );

    expect(ok, isTrue);
    expect(calls, hasLength(1));
    expect(calls.single.method, 'start');
    expect(calls.single.arguments, <String, dynamic>{
      'title': 'TF1',
      'subtitle': 'Direct',
      'playing': true,
    });
  });

  test('start par défaut annonce une lecture en cours', () async {
    final service = BackgroundPlaybackService();

    await service.start();

    expect(calls.single.arguments, <String, dynamic>{
      'title': 'Orbit',
      'subtitle': 'Lecture en cours',
      'playing': true,
    });
  });

  test('updateSession transmet les métadonnées sans action de service', () async {
    final service = BackgroundPlaybackService();

    await service.updateSession(
      title: 'M6',
      subtitle: 'Film',
      playing: false,
    );

    expect(calls.single.method, 'update');
    expect(calls.single.arguments, <String, dynamic>{
      'title': 'M6',
      'subtitle': 'Film',
      'playing': false,
    });
  });

  test('stop demande l\'arrêt du foreground service', () async {
    final service = BackgroundPlaybackService();

    await service.stop();

    expect(calls.single.method, 'stop');
  });

  test('les commandes natives remontent sur le flux commands', () async {
    final service = BackgroundPlaybackService();
    final received = <String>[];
    final sub = service.commands.listen(received.add);

    await emitFromNative('pause');
    await emitFromNative('next');
    await emitFromNative('previous');
    // Laisse le flux broadcast distribuer les événements.
    await Future<void>.delayed(Duration.zero);

    expect(received, <String>['pause', 'next', 'previous']);

    await sub.cancel();
  });

  test('une commande native vide est ignorée', () async {
    final service = BackgroundPlaybackService();
    final received = <String>[];
    final sub = service.commands.listen(received.add);

    await emitFromNative('');
    await Future<void>.delayed(Duration.zero);

    expect(received, isEmpty);

    await sub.cancel();
  });
}
