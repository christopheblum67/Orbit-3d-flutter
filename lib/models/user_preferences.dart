class UserPreferences {
  final bool parentalControlEnabled;
  final int ageRestriction;
  final bool notificationsEnabled;
  final String language;
  final String theme;

  const UserPreferences({
    this.parentalControlEnabled = false,
    this.ageRestriction = 0,
    this.notificationsEnabled = true,
    this.language = 'fr',
    this.theme = 'system',
  });

  UserPreferences copyWith({
    bool? parentalControlEnabled,
    int? ageRestriction,
    bool? notificationsEnabled,
    String? language,
    String? theme,
  }) {
    return UserPreferences(
      parentalControlEnabled:
          parentalControlEnabled ?? this.parentalControlEnabled,
      ageRestriction: ageRestriction ?? this.ageRestriction,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
      theme: theme ?? this.theme,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parentalControlEnabled': parentalControlEnabled,
      'ageRestriction': ageRestriction,
      'notificationsEnabled': notificationsEnabled,
      'language': language,
      'theme': theme,
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      parentalControlEnabled: map['parentalControlEnabled'] ?? false,
      ageRestriction: map['ageRestriction'] ?? 0,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      language: map['language'] ?? 'fr',
      theme: map['theme'] ?? 'system',
    );
  }
}
