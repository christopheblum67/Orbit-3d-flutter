
/// Configuration d'une clé DRM (Widevine/PlayReady).
class DrmKeyConfig {
  final String keyId; // base64
  final String key; // base64
  final String? iv; // base64 (optionnel pour CBC)
  final String? keySystem; // 'com.widevine.alpha' | 'com.microsoft.playready'
  final String? keyIdHex; // hex string alternative

  const DrmKeyConfig({
    required this.keyId,
    required this.key,
    this.iv,
    this.keySystem,
    this.keyIdHex,
  });

  Map<String, dynamic> toJson() => {
        'keyId': keyId,
        'key': key,
        if (iv != null) 'iv': iv,
        if (keySystem != null) 'keySystem': keySystem,
        if (keyIdHex != null) 'keyIdHex': keyIdHex,
      };

  factory DrmKeyConfig.fromJson(Map<String, dynamic> json) => DrmKeyConfig(
        keyId: json['keyId'] as String,
        key: json['key'] as String,
        iv: json['iv'] as String?,
        keySystem: json['keySystem'] as String?,
        keyIdHex: json['keyIdHex'] as String?,
      );
}

/// Configuration complète DRM pour un flux.
class DrmConfig {
  final String licenseUrl;
  final Map<String, String> licenseHeaders;
  final String keySystem; // 'com.widevine.alpha' | 'com.microsoft.playready'
  final List<DrmKeyConfig> keys; // multi-keys support
  final String? certificateUrl; // URL certificat Widevine (optionnel)
  final String? certificateBase64; // Certificat pré-embeddé (base64)
  final Map<String, String>?
      customData; // Données custom pour licence (ex: token utilisateur)
  final Duration? licenseDuration; // Durée de validité licence (si connue)
  final bool offlineEnabled; // Supporte lecture hors-ligne
  final bool keyRotationEnabled; // Rotation de clés pendant lecture

  const DrmConfig({
    required this.licenseUrl,
    this.licenseHeaders = const {},
    required this.keySystem,
    this.keys = const [],
    this.certificateUrl,
    this.certificateBase64,
    this.customData,
    this.licenseDuration,
    this.offlineEnabled = false,
    this.keyRotationEnabled = false,
  });

  /// Crée une config Widevine L1/L3 standard.
  factory DrmConfig.widevine({
    required String licenseUrl,
    Map<String, String> headers = const {},
    List<DrmKeyConfig> keys = const [],
    String? certificateUrl,
    String? certificateBase64,
    Map<String, String>? customData,
    Duration? licenseDuration,
    bool offlineEnabled = false,
    bool keyRotationEnabled = false,
  }) =>
      DrmConfig(
        licenseUrl: licenseUrl,
        licenseHeaders: headers,
        keySystem: 'com.widevine.alpha',
        keys: keys,
        certificateUrl: certificateUrl,
        certificateBase64: certificateBase64,
        customData: customData,
        licenseDuration: licenseDuration,
        offlineEnabled: offlineEnabled,
        keyRotationEnabled: keyRotationEnabled,
      );

  /// Crée une config PlayReady.
  factory DrmConfig.playready({
    required String licenseUrl,
    Map<String, String> headers = const {},
    List<DrmKeyConfig> keys = const [],
    Map<String, String>? customData,
    Duration? licenseDuration,
    bool offlineEnabled = false,
  }) =>
      DrmConfig(
        licenseUrl: licenseUrl,
        licenseHeaders: headers,
        keySystem: 'com.microsoft.playready',
        keys: keys,
        customData: customData,
        licenseDuration: licenseDuration,
        offlineEnabled: offlineEnabled,
      );

  Map<String, dynamic> toJson() => {
        'licenseUrl': licenseUrl,
        'licenseHeaders': licenseHeaders,
        'keySystem': keySystem,
        'keys': keys.map((k) => k.toJson()).toList(),
        if (certificateUrl != null) 'certificateUrl': certificateUrl,
        if (certificateBase64 != null) 'certificateBase64': certificateBase64,
        if (customData != null) 'customData': customData,
        if (licenseDuration != null)
          'licenseDuration': licenseDuration!.inMilliseconds,
        'offlineEnabled': offlineEnabled,
        'keyRotationEnabled': keyRotationEnabled,
      };

  factory DrmConfig.fromJson(Map<String, dynamic> json) => DrmConfig(
        licenseUrl: json['licenseUrl'] as String,
        licenseHeaders: Map<String, String>.from(json['licenseHeaders'] ?? {}),
        keySystem: json['keySystem'] as String,
        keys: (json['keys'] as List<dynamic>?)
                ?.map((k) => DrmKeyConfig.fromJson(k as Map<String, dynamic>))
                .toList() ??
            const [],
        certificateUrl: json['certificateUrl'] as String?,
        certificateBase64: json['certificateBase64'] as String?,
        customData: Map<String, String>.from(json['customData'] ?? {}),
        licenseDuration: json['licenseDuration'] != null
            ? Duration(milliseconds: json['licenseDuration'] as int)
            : null,
        offlineEnabled: json['offlineEnabled'] as bool? ?? false,
        keyRotationEnabled: json['keyRotationEnabled'] as bool? ?? false,
      );

  /// Vérifie si la config est valide pour une requête licence.
  bool get isValid => licenseUrl.isNotEmpty && keySystem.isNotEmpty;

  /// Vérifie si la config supporte le mode offline.
  bool get supportsOffline => offlineEnabled;

  @override
  String toString() =>
      'DrmConfig(keySystem: $keySystem, licenseUrl: $licenseUrl, keys: ${keys.length}, offline: $offlineEnabled)';
}
