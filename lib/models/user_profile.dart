class UserProfile {
  final String id;
  final String firstName;
  final DateTime dateOfBirth;
  final String gender;
  final List<String> favoriteGenres;
  final String avatarUrl;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.dateOfBirth,
    required this.gender,
    required this.favoriteGenres,
    this.avatarUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'favoriteGenres': favoriteGenres,
      'avatarUrl': avatarUrl,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      firstName: map['firstName'] ?? '',
      dateOfBirth: DateTime.parse(map['dateOfBirth']),
      gender: map['gender'] ?? '',
      favoriteGenres: List<String>.from(map['favoriteGenres'] ?? []),
      avatarUrl: map['avatarUrl'] ?? '',
    );
  }
}
