enum ProfileType { adult, child, expert }

class UserProfile {
  final String id;
  final String firstName;
  final DateTime dateOfBirth;
  final String gender;
  final List<String> favoriteGenres;
  final String avatarUrl;
  final ProfileType profileType;
  final String? pinHash;
  final Map<String, dynamic> settings;
  final DateTime? lastActiveAt;
  final List<String> hiddenContentIds;
  final int maxProfilesAllowed;
  final bool hideAdultContent;
  final bool hideViolentContent;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.dateOfBirth,
    required this.gender,
    required this.favoriteGenres,
    this.avatarUrl = '',
    this.profileType = ProfileType.adult,
    this.pinHash,
    this.settings = const {},
    this.lastActiveAt,
    this.hiddenContentIds = const [],
    this.maxProfilesAllowed = 5,
    this.hideAdultContent = false,
    this.hideViolentContent = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isChild => profileType == ProfileType.child;
  bool get isExpert => profileType == ProfileType.expert;
  bool get hasPin => pinHash != null;

  int get age => DateTime.now().difference(dateOfBirth).inDays ~/ 365;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'favoriteGenres': favoriteGenres,
      'avatarUrl': avatarUrl,
      'profileType': profileType.name,
      'pinHash': pinHash,
      'settings': settings,
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'hiddenContentIds': hiddenContentIds,
      'maxProfilesAllowed': maxProfilesAllowed,
      'hideAdultContent': hideAdultContent,
      'hideViolentContent': hideViolentContent,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      firstName: map['firstName'] ?? '',
      dateOfBirth:
          DateTime.tryParse(map['dateOfBirth'] ?? '') ?? DateTime(1970),
      gender: map['gender'] ?? '',
      favoriteGenres: List<String>.from(map['favoriteGenres'] ?? []),
      avatarUrl: map['avatarUrl'] ?? '',
      profileType: ProfileType.values.firstWhere(
        (e) => e.name == map['profileType'],
        orElse: () => ProfileType.adult,
      ),
      pinHash: map['pinHash'],
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
      lastActiveAt: map['lastActiveAt'] != null
          ? DateTime.tryParse(map['lastActiveAt'])
          : null,
      hiddenContentIds: List<String>.from(map['hiddenContentIds'] ?? []),
      maxProfilesAllowed: map['maxProfilesAllowed'] ?? 5,
      hideAdultContent: map['hideAdultContent'] ?? false,
      hideViolentContent: map['hideViolentContent'] ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? id,
    String? firstName,
    DateTime? dateOfBirth,
    String? gender,
    List<String>? favoriteGenres,
    String? avatarUrl,
    ProfileType? profileType,
    String? pinHash,
    Map<String, dynamic>? settings,
    DateTime? lastActiveAt,
    List<String>? hiddenContentIds,
    int? maxProfilesAllowed,
    bool? hideAdultContent,
    bool? hideViolentContent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      profileType: profileType ?? this.profileType,
      pinHash: pinHash ?? this.pinHash,
      settings: settings ?? this.settings,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      hiddenContentIds: hiddenContentIds ?? this.hiddenContentIds,
      maxProfilesAllowed: maxProfilesAllowed ?? this.maxProfilesAllowed,
      hideAdultContent: hideAdultContent ?? this.hideAdultContent,
      hideViolentContent: hideViolentContent ?? this.hideViolentContent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
