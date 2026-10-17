class UserPreferences {
  final bool parentalControlEnabled;
  final int ageRestriction;
  final String language;
  final String theme;
  final String palette;
  final bool profileVisible;
  final bool allowRecording;
  final double fontScale;

  const UserPreferences({
    this.parentalControlEnabled = false,
    this.ageRestriction = 0,
    this.language = 'fr',
    this.theme = 'system',
    this.palette = 'cyan',
    this.profileVisible = true,
    this.allowRecording = true,
    this.fontScale = 1.0,
  });

  UserPreferences copyWith({
    bool? parentalControlEnabled,
    int? ageRestriction,
    String? language,
    String? theme,
    String? palette,
    bool? profileVisible,
    bool? allowRecording,
    double? fontScale,
  }) {
    return UserPreferences(
      parentalControlEnabled:
          parentalControlEnabled ?? this.parentalControlEnabled,
      ageRestriction: ageRestriction ?? this.ageRestriction,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      palette: palette ?? this.palette,
      profileVisible: profileVisible ?? this.profileVisible,
      allowRecording: allowRecording ?? this.allowRecording,
      fontScale: fontScale ?? this.fontScale,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parentalControlEnabled': parentalControlEnabled,
      'ageRestriction': ageRestriction,
      'language': language,
      'theme': theme,
      'palette': palette,
      'profileVisible': profileVisible,
      'allowRecording': allowRecording,
      'fontScale': fontScale,
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      parentalControlEnabled: map['parentalControlEnabled'] ?? false,
      ageRestriction: map['ageRestriction'] ?? 0,
      language: map['language'] ?? 'fr',
      theme: map['theme'] ?? 'system',
      profileVisible: map['profileVisible'] ?? true,
      allowRecording: map['allowRecording'] ?? true,
      fontScale: (map['fontScale'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
