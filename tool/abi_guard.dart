// Garde-fou ABI : détermine quelle architecture doit être utilisée pour un
// appareil donné, et vérifie que l'APK est bien universel.
//
// Règle d'or du projet : on ne retire JAMAIS une ABI d'un APK de release.
// Un APK doit toujours contenir armeabi-v7a (TV 32 bits, ex. TCL BeyondTV),
// arm64-v8a (téléphones récents) et x86_64 (émulateurs). Un APK allégé casse
// silencieusement l'installation sur une partie du parc (INSTALL_FAILED_NO_MATCHING_ABIS).
//
// Utilisable en CLI par tool/deploy_tv.ps1 :
//   dart tool/abi_guard.dart resolve --device "arm64-v8a,armeabi-v7a" --apk <chemin>
//
// Sortie (une valeur par ligne, parsable par PowerShell) :
//   apk-abis=arm64-v8a,armeabi-v7a,x86_64
//   device-abis=arm64-v8a,armeabi-v7a
//   selected=arm64-v8a
// En cas d'échec : une ligne `error=...` puis code de sortie non nul
// (1 = APK non universel, 2 = aucune ABI commune avec l'appareil).

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// ABIs que tout APK de release doit embarquer.
const List<String> requiredAbis = <String>[
  'armeabi-v7a',
  'arm64-v8a',
  'x86_64',
];

/// ABIs connues d'Android (dossiers `lib/<abi>/`).
const Set<String> knownAbis = <String>{
  'armeabi',
  'armeabi-v7a',
  'arm64-v8a',
  'x86',
  'x86_64',
  'mips',
  'mips64',
  'riscv64',
};

/// Normalise une liste d'ABIs séparées par des virgules (sortie de
/// `getprop ro.product.cpu.abilist`) en liste ordonnée, sans doublon ni vide.
List<String> parseAbiList(String raw) {
  final seen = <String>{};
  final result = <String>[];
  for (final part in raw.split(',')) {
    final abi = part.trim();
    if (abi.isEmpty || !seen.add(abi)) continue;
    result.add(abi);
  }
  return result;
}

/// ABI d'une entrée ZIP de type `lib/armeabi-v7a/libflutter.so`, ou null.
String? abiFromLibEntry(String entryName) {
  if (!entryName.startsWith('lib/')) return null;
  final parts = entryName.split('/');
  if (parts.length < 3) return null;
  return knownAbis.contains(parts[1]) ? parts[1] : null;
}

/// Première ABI de l'appareil (ordre de préférence Android) présente dans
/// l'APK. C'est exactement ce que fait le PackageManager au moment de
/// l'installation : l'ordre de `abilist` est l'ordre de préférence.
String? selectAbi(List<String> deviceAbis, Set<String> apkAbis) {
  for (final abi in deviceAbis) {
    if (apkAbis.contains(abi)) return abi;
  }
  return null;
}

/// ABIs obligatoires absentes de l'APK.
List<String> missingRequiredAbis(Set<String> apkAbis) =>
    requiredAbis.where((abi) => !apkAbis.contains(abi)).toList();

/// Lit la liste des ABIs présentes dans un APK (dossiers `lib/<abi>/`).
///
/// Parse le répertoire central du ZIP plutôt que de chercher des sous-chaînes
/// dans le binaire : une chaîne `lib/armeabi-v7a/` peut apparaître dans des
/// données compressées et donner un faux positif.
Set<String> apkAbis(File apk) {
  if (!apk.existsSync()) {
    throw FileSystemException('APK introuvable', apk.path);
  }
  final bytes = apk.readAsBytesSync();
  return apkAbisFromBytes(bytes);
}

/// Variante testable de [apkAbis] (aucun accès disque).
Set<String> apkAbisFromBytes(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final eocd = _findEndOfCentralDirectory(bytes);
  if (eocd < 0) {
    throw const FormatException(
      'En-tête ZIP (EOCD) introuvable : fichier APK/ZIP invalide.',
    );
  }

  var entryCount = data.getUint16(eocd + 10, Endian.little);
  var centralDirOffset = data.getUint32(eocd + 16, Endian.little);

  // ZIP64 : le champ 16 bits déborde (0xFFFF) sur les gros APK.
  if (entryCount == 0xFFFF || centralDirOffset == 0xFFFFFFFF) {
    final zip64 = _readZip64EndOfCentralDirectory(data, bytes, eocd);
    if (zip64 != null) {
      entryCount = zip64.entryCount;
      centralDirOffset = zip64.centralDirOffset;
    }
  }

  final abis = <String>{};
  var offset = centralDirOffset;
  for (var i = 0; i < entryCount; i++) {
    if (offset + 46 > bytes.length ||
        data.getUint32(offset, Endian.little) != 0x02014b50) {
      throw FormatException(
        'Répertoire central ZIP corrompu à l\'entrée $i (offset $offset).',
      );
    }
    final nameLength = data.getUint16(offset + 28, Endian.little);
    final extraLength = data.getUint16(offset + 30, Endian.little);
    final commentLength = data.getUint16(offset + 32, Endian.little);
    final nameStart = offset + 46;
    final nameEnd = nameStart + nameLength;
    if (nameEnd > bytes.length) {
      throw FormatException('Nom d\'entrée ZIP hors limites (offset $offset).');
    }
    final name = utf8.decode(
      bytes.sublist(nameStart, nameEnd),
      allowMalformed: true,
    );
    final abi = abiFromLibEntry(name);
    if (abi != null) abis.add(abi);
    offset = nameEnd + extraLength + commentLength;
  }
  return abis;
}

int _findEndOfCentralDirectory(Uint8List bytes) {
  const signature = 0x06054b50;
  // L'EOCD fait 22 octets, suivi d'un commentaire de 0 à 65535 octets.
  final last = bytes.length - 22;
  final first = last - 0xFFFF < 0 ? 0 : last - 0xFFFF;
  final data = ByteData.sublistView(bytes);
  for (var i = last; i >= first; i--) {
    if (data.getUint32(i, Endian.little) == signature) return i;
  }
  return -1;
}

({int entryCount, int centralDirOffset})? _readZip64EndOfCentralDirectory(
  ByteData data,
  Uint8List bytes,
  int eocd,
) {
  // Localisateur ZIP64 : signature 0x07064b50, 20 octets, juste avant l'EOCD.
  const locatorSignature = 0x07064b50;
  const recordSignature = 0x06064b50;
  final locator = eocd - 20;
  if (locator < 0 ||
      data.getUint32(locator, Endian.little) != locatorSignature) {
    return null;
  }
  final recordOffset = data.getUint64(locator + 8, Endian.little);
  if (recordOffset + 56 > bytes.length ||
      data.getUint32(recordOffset, Endian.little) != recordSignature) {
    return null;
  }
  return (
    entryCount: data.getUint64(recordOffset + 32, Endian.little),
    centralDirOffset: data.getUint64(recordOffset + 48, Endian.little),
  );
}

/// Vérifie l'APK et choisit l'ABI. Retourne `null` si tout est bon, sinon un
/// message d'erreur prêt à afficher.
String? resolveError({
  required List<String> deviceAbis,
  required Set<String> apkAbis,
  bool allowPartialApk = false,
}) {
  if (!allowPartialApk) {
    final missing = missingRequiredAbis(apkAbis);
    if (missing.isNotEmpty) {
      return 'APK non universel : ABI manquante(s) ${missing.join(', ')}. '
          'Reconstruire avec `flutter build apk --release` (sans '
          '--split-per-abi ni --target-platform restreint).';
    }
  }
  if (selectAbi(deviceAbis, apkAbis) == null) {
    return 'Aucune ABI commune entre l\'appareil (${deviceAbis.join(', ')}) '
        'et l\'APK (${apkAbis.join(', ')}).';
  }
  return null;
}

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.first != 'resolve') {
    stdout.writeln(
      'Usage: dart tool/abi_guard.dart resolve --device <abis> --apk <chemin> '
      '[--allow-partial]',
    );
    exit(64);
  }

  String? device;
  String? apkPath;
  var allowPartial = false;
  for (var i = 1; i < args.length; i++) {
    switch (args[i]) {
      case '--device':
        if (i + 1 < args.length) device = args[++i];
      case '--apk':
        if (i + 1 < args.length) apkPath = args[++i];
      case '--allow-partial':
        allowPartial = true;
    }
  }

  if (device == null || apkPath == null) {
    stdout
        .writeln('error=Arguments manquants : --device et --apk sont requis.');
    exit(64);
  }

  final deviceAbis = parseAbiList(device);
  final Set<String> apkAbiSet;
  try {
    apkAbiSet = apkAbis(File(apkPath));
  } on Object catch (e) {
    stdout.writeln('error=Lecture APK impossible : $e');
    exit(1);
  }

  final orderedApkAbis = <String>[
    ...requiredAbis.where(apkAbiSet.contains),
    ...apkAbiSet.where((abi) => !requiredAbis.contains(abi)),
  ];

  stdout.writeln('apk-abis=${orderedApkAbis.join(',')}');
  stdout.writeln('device-abis=${deviceAbis.join(',')}');

  final error = resolveError(
    deviceAbis: deviceAbis,
    apkAbis: apkAbiSet,
    allowPartialApk: allowPartial,
  );
  if (error != null) {
    stdout.writeln('error=$error');
    final missing = missingRequiredAbis(apkAbiSet);
    exit(missing.isNotEmpty ? 1 : 2);
  }

  stdout.writeln('selected=${selectAbi(deviceAbis, apkAbiSet)}');
}
