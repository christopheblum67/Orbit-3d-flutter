import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

/// Profil de lecture appliqué selon la capacité de l'appareil.
enum DeviceProfile {
  eco,
  standard,
  ultra;

  String get label => switch (this) {
        DeviceProfile.eco => 'Économique',
        DeviceProfile.standard => 'Standard',
        DeviceProfile.ultra => 'Ultra',
      };

  /// Nombre maximal de flux simultanés en multi-vue (0 = désactivé).
  int get maxMultiView => switch (this) {
        DeviceProfile.eco => 0,
        DeviceProfile.standard => 2,
        DeviceProfile.ultra => 4,
      };

  /// Les grilles 3D (EPG, effervescences) sont désactivées en Eco.
  bool get disable3D => this == DeviceProfile.eco;

  DeviceProfile? fromStoredName(String? name) {
    for (final p in DeviceProfile.values) {
      if (p.name == name) return p;
    }
    return null;
  }
}

/// Nature de la connexion réseau au moment du diagnostic.
enum ConnectionKind { ethernet, wifi, mobile, other, none }

/// Bilan matériel collecté par [HardwareDetectorService].
class HardwareSpecs {
  const HardwareSpecs({
    required this.deviceName,
    required this.brand,
    required this.isTv,
    required this.isPhysicalDevice,
    required this.totalRamMb,
    required this.lowRam,
    required this.sdkInt,
    required this.connection,
    required this.recommendedProfile,
  });

  final String deviceName;
  final String brand;
  final bool isTv;
  final bool isPhysicalDevice;
  final int totalRamMb;
  final bool lowRam;
  final int sdkInt;
  final ConnectionKind connection;
  final DeviceProfile recommendedProfile;

  String get memoryLabel => totalRamMb > 0
      ? (totalRamMb >= 1024 ? '${(totalRamMb / 1024).toStringAsFixed(1)} Go' : '$totalRamMb Mo')
      : 'Inconnue';

  String get connectionLabel => switch (connection) {
        ConnectionKind.ethernet => 'Ethernet',
        ConnectionKind.wifi => 'Wi-Fi',
        ConnectionKind.mobile => 'Réseau mobile',
        ConnectionKind.other => 'Autre',
        ConnectionKind.none => 'Hors ligne',
      };
}

/// Détecte la configuration matérielle de l'appareil et recommande un
/// profil de lecture parmi Eco / Standard / Ultra.
///
/// La mémoire totale provient du canal natif « orbit/hardware »
/// (ActivityManager.MemoryInfo) : device_info_plus n'expose pas la RAM totale.
class HardwareDetectorService {
  HardwareDetectorService._();

  static const MethodChannel _memoryChannel = MethodChannel('orbit/hardware');

  static Future<HardwareSpecs> analyze() async {
    final android = DeviceInfoPlugin().androidInfo;
    String deviceName = 'Appareil Android';
    String brand = '';
    var isTv = false;
    var isPhysical = true;
    var sdkInt = 0;
    var totalRamMb = 0;
    var lowRam = false;

    try {
      final info = await android;
      deviceName = '${info.brand} ${info.model}'.trim();
      brand = info.brand;
      isTv = info.systemFeatures.contains('android.software.leanback');
      isPhysical = info.isPhysicalDevice;
      sdkInt = info.version.sdkInt;
    } catch (_) {
      // Diagnostic non bloquant : valeurs par défaut conservées.
    }

    try {
      final memory = await _memoryChannel.invokeMethod<Map<Object?, Object?>>('getMemory');
      if (memory != null) {
        totalRamMb = (memory['totalMb'] as num?)?.toInt() ?? 0;
        lowRam = memory['lowRam'] as bool? ?? false;
      }
    } catch (_) {
      // Canal natif indisponible (émulateur/tests) : on gère sans.
    }

    var connection = ConnectionKind.none;
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.isNotEmpty) {
        connection = switch (results.first) {
          ConnectivityResult.ethernet => ConnectionKind.ethernet,
          ConnectivityResult.wifi => ConnectionKind.wifi,
          ConnectivityResult.mobile => ConnectionKind.mobile,
          _ => ConnectionKind.other,
        };
      }
    } catch (_) {
      // Pas de connexion mesurable : type « none » conservé.
    }

    return HardwareSpecs(
      deviceName: deviceName,
      brand: brand,
      isTv: isTv,
      isPhysicalDevice: isPhysical,
      totalRamMb: totalRamMb,
      lowRam: lowRam,
      sdkInt: sdkInt,
      connection: connection,
      recommendedProfile: _recommend(
        totalRamMb: totalRamMb,
        lowRam: lowRam,
        isTv: isTv,
        connection: connection,
      ),
    );
  }

  /// Règle de recommandation :
  /// - RAM < 3 Go ou appareil « low RAM » -> Eco ;
  /// - RAM >= 6 Go + connexion filaire/formidable (Wi-Fi) -> Ultra ;
  /// - sinon -> Standard.
  static DeviceProfile _recommend({
    required int totalRamMb,
    required bool lowRam,
    required bool isTv,
    required ConnectionKind connection,
  }) {
    if (lowRam || (totalRamMb > 0 && totalRamMb < 3072)) {
      return DeviceProfile.eco;
    }
    if (totalRamMb >= 6144 &&
        (connection == ConnectionKind.ethernet ||
            connection == ConnectionKind.wifi)) {
      return DeviceProfile.ultra;
    }
    return DeviceProfile.standard;
  }
}