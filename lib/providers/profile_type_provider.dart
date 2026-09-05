import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

class ProfileTypeState {
  final ProfileType? currentType;
  final bool isLoading;

  ProfileTypeState({this.currentType, this.isLoading = false});

  ProfileTypeState copyWith({ProfileType? currentType, bool? isLoading}) {
    return ProfileTypeState(
      currentType: currentType ?? this.currentType,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ProfileTypeNotifier extends StateNotifier<ProfileTypeState> {
  final Ref _ref;

  ProfileTypeNotifier(this._ref) : super(ProfileTypeState());

  void loadFromProfile(UserProfile? profile) {
    if (profile != null) {
      state = state.copyWith(currentType: profile.profileType);
    }
  }

  Future<void> setType(ProfileType type, {String? pin}) async {
    state = state.copyWith(isLoading: true);

    final currentProfile = _ref.read(currentProfileProvider);
    if (currentProfile == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    if ((type == ProfileType.child || type == ProfileType.expert) &&
        pin == null) {
      state = state.copyWith(isLoading: false);
      throw ArgumentError('PIN requis pour ce type de profil');
    }

    if (pin != null && !_verifyPin(currentProfile, pin)) {
      state = state.copyWith(isLoading: false);
      throw ArgumentError('PIN incorrect');
    }

    final updatedProfile = currentProfile.copyWith(
      profileType: type,
      updatedAt: DateTime.now(),
    );

    final storage = _ref.read(storageServiceProvider);
    await storage.saveProfile(updatedProfile);

    _ref.read(currentProfileProvider.notifier).state = updatedProfile;
    state = state.copyWith(currentType: type, isLoading: false);
  }

  bool verifyPin(String input) {
    final currentProfile = _ref.read(currentProfileProvider);
    if (currentProfile == null || currentProfile.pinHash == null) {
      return false;
    }
    return _verifyPin(currentProfile, input);
  }

  bool _verifyPin(UserProfile profile, String input) {
    if (profile.pinHash == null) return false;
    return profile.pinHash == input;
  }

  void clear() {
    state = ProfileTypeState();
  }
}

final profileTypeProvider =
    StateNotifierProvider<ProfileTypeNotifier, ProfileTypeState>(
  (ref) => ProfileTypeNotifier(ref),
);