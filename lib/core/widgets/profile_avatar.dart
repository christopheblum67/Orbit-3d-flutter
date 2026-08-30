import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../../models/user_profile.dart';

const List<ProfileAvatarOption> profileAvatarOptions = [
  ProfileAvatarOption(
    id: 'face',
    icon: Icons.face,
    color: AppConstants.primaryColor,
  ),
  ProfileAvatarOption(
    id: 'rocket',
    icon: Icons.rocket_launch,
    color: AppConstants.tertiaryColor,
  ),
  ProfileAvatarOption(
    id: 'sport',
    icon: Icons.sports_soccer,
    color: AppConstants.secondaryColor,
  ),
  ProfileAvatarOption(
    id: 'film',
    icon: Icons.movie,
    color: Color(0xFF8A72FF),
  ),
  ProfileAvatarOption(
    id: 'music',
    icon: Icons.music_note,
    color: Color(0xFF00CFE8),
  ),
  ProfileAvatarOption(
    id: 'heart',
    icon: Icons.favorite,
    color: Color(0xFFFF6FA8),
  ),
];

class ProfileAvatarOption {
  const ProfileAvatarOption({
    required this.id,
    required this.icon,
    required this.color,
  });

  final String id;
  final IconData icon;
  final Color color;
}

/// Avatar de profil : icône prédéfinie ("icone:<id>"), image distante
/// (URL) ou initiale du prénom en secours.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.profile,
    this.size = 64,
  });

  static const String avatarIconPrefix = 'icone:';

  final UserProfile profile;
  final double size;

  ProfileAvatarOption? _optionForId(String id) {
    for (final option in profileAvatarOptions) {
      if (option.id == id) return option;
    }
    return null;
  }

  String _initial() {
    final name = profile.firstName.trim();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = _initial();
    final avatarUrl = profile.avatarUrl.trim();
    final isIconAvatar = avatarUrl.startsWith(avatarIconPrefix);
    final option =
        isIconAvatar ? _optionForId(avatarUrl.substring(avatarIconPrefix.length)) : null;
    final isRemote = avatarUrl.isNotEmpty && !isIconAvatar;

    final Widget content;
    if (option != null) {
      content = Icon(option.icon, size: size * 0.5, color: Colors.white);
    } else if (isRemote) {
      content = Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        width: size,
        height: size,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: size * 0.36,
              height: size * 0.36,
              child: const CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white70,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Text(
          initial,
          style: TextStyle(
            color: scheme.onPrimary,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    } else {
      content = Text(
        initial,
        style: TextStyle(
          color: scheme.onPrimary,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    final gradientColors = option != null
        ? <Color>[option.color, Color.lerp(option.color, Colors.white, 0.25)!]
        : <Color>[scheme.primary, scheme.secondary];

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (option?.color ?? scheme.primary).withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: content,
    );
  }
}