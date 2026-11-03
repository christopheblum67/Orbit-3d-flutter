// Garde-fou « règle d'or ABI ».
//
// 1. Vérifie la logique de sélection d'ABI (celle qu'utilise le déploiement).
// 2. Vérifie que la configuration du dépôt ne peut pas produire un APK
//    amputé d'une architecture (le cas qui casserait la TCL BeyondTV,
//    armeabi-v7a uniquement).
//
// Ces tests échouent si quelqu'un réintroduit :
//   - une liste `abiFilters` incomplète dans android/app/build.gradle ;
//   - `--split-per-abi` ou `-Pdisable-abi-filtering` dans un script/CI ;
//   - un `--target-platform` restreint ;
//   - la suppression du script de déploiement (le garde-fou lui-même).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/abi_guard.dart';

/// Dossiers/fichiers d'automatisation inspectés par la politique ABI.
const List<String> _automationGlobs = <String>[
  '.github/workflows',
  'tool',
];

void main() {
  group('sélection ABI', () {
    test('préfère l’ABI de l’appareil quand elle est dans l’APK', () {
      expect(
        selectAbi(
          <String>['arm64-v8a', 'armeabi-v7a'],
          <String>{'arm64-v8a', 'armeabi-v7a', 'x86_64'},
        ),
        'arm64-v8a',
      );
    });

    test('respecte l’ordre de abilist (préférence Android)', () {
      expect(
        selectAbi(
          <String>['armeabi-v7a', 'arm64-v8a'],
          <String>{'arm64-v8a', 'armeabi-v7a'},
        ),
        'armeabi-v7a',
      );
    });

    test('échoue sur une TV 32 bits face à un APK arm64-only', () {
      // C'est la régression exacte à empêcher : TCL BeyondTV = armeabi-v7a.
      expect(
        selectAbi(
          <String>['armeabi-v7a'],
          <String>{'arm64-v8a', 'x86_64'},
        ),
        isNull,
      );
    });

    test('parseAbiList nettoie virgules, espaces et doublons', () {
      expect(
        parseAbiList('arm64-v8a, armeabi-v7a,armeabi-v7a,,x86_64'),
        <String>['arm64-v8a', 'armeabi-v7a', 'x86_64'],
      );
    });

    test('abiFromLibEntry ne reconnaît que les vraies ABIs', () {
      expect(abiFromLibEntry('lib/armeabi-v7a/libflutter.so'), 'armeabi-v7a');
      expect(abiFromLibEntry('lib/arm64-v8a/libapp.so'), 'arm64-v8a');
      expect(abiFromLibEntry('lib/not-an-abi/libfoo.so'), isNull);
      expect(abiFromLibEntry('assets/lib/armeabi-v7a/foo'), isNull);
    });

    test('missingRequiredAbis signale l’ABI absente', () {
      expect(
        missingRequiredAbis(<String>{'arm64-v8a', 'x86_64'}),
        <String>['armeabi-v7a'],
      );
      expect(
        missingRequiredAbis(<String>{'armeabi-v7a', 'arm64-v8a', 'x86_64'}),
        isEmpty,
      );
    });

    test('resolveError refuse un APK non universel', () {
      final error = resolveError(
        deviceAbis: <String>['armeabi-v7a'],
        apkAbis: <String>{'arm64-v8a', 'x86_64'},
      );
      expect(error, isNotNull);
      expect(error, contains('armeabi-v7a'));
    });

    test('resolveError accepte un APK universel', () {
      expect(
        resolveError(
          deviceAbis: <String>['armeabi-v7a'],
          apkAbis: <String>{'armeabi-v7a', 'arm64-v8a', 'x86_64'},
        ),
        isNull,
      );
    });
  });

  group('APK réellement construit', () {
    final apk = File('build/app/outputs/flutter-apk/app-release.apk');

    test(
      'contient les 3 architectures',
      () {
        final abis = apkAbis(apk);
        expect(missingRequiredAbis(abis), isEmpty,
            reason: 'APK construit sans une ABI : $abis');
      },
      skip: apk.existsSync()
          ? false
          : 'APK absent (lancer `flutter build apk --release` d’abord)',
    );
  });

  group('politique du dépôt', () {
    test('android/app/build.gradle : abiFilters doit lister les 3 ABIs', () {
      final gradle = File('android/app/build.gradle');
      expect(gradle.existsSync(), isTrue);

      final matches = RegExp(r'abiFilters\s*(.+)')
          .allMatches(_stripGradleComments(gradle.readAsStringSync()))
          .toList();
      // Aucun abiFilters est acceptable (Flutter applique alors les 3 par
      // défaut) ; s'il y en a un, il doit être complet.
      for (final match in matches) {
        final declared = RegExp(r"'([\w-]+)'")
            .allMatches(match.group(1) ?? '')
            .map((m) => m.group(1))
            .whereType<String>()
            .toSet();
        expect(
          requiredAbis.every(declared.contains),
          isTrue,
          reason: 'abiFilters incomplet (${declared.join(', ')}) : il doit '
              'contenir ${requiredAbis.join(', ')}. Une ABI retirée casse '
              'l’installation sur une partie du parc (TCL BeyondTV = '
              'armeabi-v7a).',
        );
      }
    });

    test('android/ : aucun split ABI ni désactivation du filtrage', () {
      final files = <File>[
        File('android/app/build.gradle'),
        File('android/build.gradle'),
        File('android/gradle.properties'),
        ...Directory('android/app')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.gradle')),
      ];

      for (final file in files) {
        final content =
            _stripGradleComments(file.readAsStringSync()).toLowerCase();
        for (final forbidden in <String>[
          'split-per-abi',
          'splits.abi',
          'isuniversalapk = false',
          'isuniversalapk=false',
          'disable-abi-filtering',
        ]) {
          expect(
            content.contains(forbidden),
            isFalse,
            reason: '${file.path} contient « $forbidden » : un APK de release '
                'doit rester universel.',
          );
        }
      }
    });

    test('scripts et CI : pas de build restreint en ABI', () {
      final files = _automationFiles();
      expect(files, isNotEmpty,
          reason: 'Aucun script/CI trouvé : la politique serait inopérante.');

      for (final file in files) {
        final content = file.readAsStringSync();
        final lower = content.toLowerCase();
        expect(lower.contains('--split-per-abi'), isFalse,
            reason: '${file.path} utilise --split-per-abi : plus d’APK '
                'universel, déploiement TV impossible.');
        expect(lower.contains('disable-abi-filtering'), isFalse,
            reason: '${file.path} désactive le filtrage ABI de Flutter : les '
                'abiFilters du projet prendraient le dessus.');

        for (final match in RegExp(r'--target-platform[=\s]+([A-Za-z0-9_,.-]+)')
            .allMatches(content)) {
          final platforms =
              (match.group(1) ?? '').split(',').map((p) => p.trim()).toSet();
          expect(
            platforms.containsAll(<String>{
              'android-arm',
              'android-arm64',
              'android-x64',
            }),
            isTrue,
            reason: '${file.path} restreint --target-platform à '
                '${platforms.join(', ')} : doivent rester '
                'android-arm, android-arm64, android-x64.',
          );
        }
      }
    });

    test('le garde-fou de déploiement existe et détecte l’ABI', () {
      final script = File('tool/deploy_tv.ps1');
      expect(script.existsSync(), isTrue,
          reason: 'tool/deploy_tv.ps1 manquant : plus de garde-fou au '
              'déploiement.');
      final content = script.readAsStringSync();
      expect(content, contains('ro.product.cpu.abilist'),
          reason: 'Le script doit lire l’ABI réelle de l’appareil.');
      expect(content, contains('abi_guard.dart'),
          reason: 'Le script doit déléguer la décision à tool/abi_guard.dart.');
      expect(content, contains('install -r'));
    });
  });
}

/// Tous les fichiers d'automatisation (.ps1, .yml, .yaml) du dépôt, hors
/// dépendances tierces et artefacts de build.
List<File> _automationFiles() {
  final files = <File>[];
  final roots = <Directory>[
    for (final path in _automationGlobs) Directory(path),
    Directory('.'),
  ];
  for (final root in roots) {
    if (!root.existsSync()) continue;
    for (final entity in root.listSync(recursive: root.path == '.')) {
      if (entity is! File) continue;
      final path = entity.path.replaceAll('\\', '/');
      if (path.startsWith('third_party/') ||
          path.startsWith('build/') ||
          path.startsWith('.gradle/') ||
          path.startsWith('.git/') ||
          path.startsWith('.fvm/') ||
          path.startsWith('.dart_tool/') ||
          path.startsWith('test/')) {
        continue;
      }
      if (path.endsWith('.ps1') ||
          path.endsWith('.yml') ||
          path.endsWith('.yaml')) {
        files.add(entity);
      }
    }
  }
  return files;
}

/// Retire les commentaires Groovy/`.properties` : la politique ABI ne doit pas
/// se déclencher sur un simple commentaire documentaire.
String _stripGradleComments(String source) {
  final withoutBlock = source.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
  final lines = <String>[];
  for (final line in withoutBlock.split('\n')) {
    final slash = line.indexOf('//');
    var code = slash >= 0 ? line.substring(0, slash) : line;
    if (code.trimLeft().startsWith('#')) code = '';
    lines.add(code);
  }
  return lines.join('\n');
}
