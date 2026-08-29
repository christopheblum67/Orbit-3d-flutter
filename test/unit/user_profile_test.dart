import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';

void main() {
  test('UserProfile toMap and fromMap', () {
    final profile = UserProfile(
      id: '1',
      firstName: 'Alice',
      dateOfBirth: DateTime(1990, 5, 20),
      gender: 'Femme',
      favoriteGenres: ['Action', 'Sci-Fi'],
    );
    final map = profile.toMap();
    final restored = UserProfile.fromMap(map);
    expect(restored.id, profile.id);
    expect(restored.firstName, profile.firstName);
    expect(restored.favoriteGenres, profile.favoriteGenres);
  });
}
