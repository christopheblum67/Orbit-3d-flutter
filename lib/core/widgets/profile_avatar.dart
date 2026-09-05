import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';

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
  ProfileAvatarOption(
    id: 'account',
    icon: Icons.account_circle_rounded,
    color: AppConstants.primaryColor,
  ),
  ProfileAvatarOption(
    id: 'smart_toy',
    icon: Icons.smart_toy_rounded,
    color: AppConstants.secondaryColor,
  ),
  ProfileAvatarOption(
    id: 'esports',
    icon: Icons.sports_esports_rounded,
    color: AppConstants.tertiaryColor,
  ),
  ProfileAvatarOption(
    id: 'movie_filter',
    icon: Icons.movie_filter_rounded,
    color: AppConstants.secondaryColor,
  ),
  ProfileAvatarOption(
    id: 'psychology',
    icon: Icons.psychology_rounded,
    color: AppConstants.primaryColor,
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

/// Dégradé orbital partagé entre l'édition et la sélection de profil
/// (avatar encodé dans `avatarUrl` sous la forme `orbital:<index>`).
class OrbitGradient {
  const OrbitGradient({required this.start, required this.end});

  final Color start;
  final Color end;
}

const List<OrbitGradient> orbitGradientOptions = [
  OrbitGradient(
    start: Color(0xFF5B5BD6),
    end: Color(0xFF00B8D4),
  ),
  OrbitGradient(
    start: Color(0xFFFF4D8D),
    end: Color(0xFF5B5BD6),
  ),
  OrbitGradient(
    start: Color(0xFF00CFE8),
    end: Color(0xFF4FACFE),
  ),
  OrbitGradient(
    start: Color(0xFF8A72FF),
    end: Color(0xFF5B5BD6),
  ),
  OrbitGradient(
    start: Color(0xFFFF6FA8),
    end: Color(0xFFFF4D8D),
  ),
  OrbitGradient(
    start: Color(0xFFFF9A56),
    end: Color(0xFFFFC24D),
  ),
  OrbitGradient(
    start: Color(0xFF34D399),
    end: Color(0xFF00CFE8),
  ),
  OrbitGradient(
    start: Color(0xFFFF6B6B),
    end: Color(0xFFFF4D8D),
  ),
];

/// Avatar de profil : icône prédéfinie ("icone:<id>"), dégradé orbital
/// ("orbital:<index>"), image distante (URL) ou initiale du prénom en secours.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.profile,
    this.size = 64,
  });

  static const String avatarIconPrefix = 'icone:';
  static const String orbitGradientPrefix = 'orbital:';

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
    final option = isIconAvatar
        ? _optionForId(avatarUrl.substring(avatarIconPrefix.length))
        : null;
    final isOrbital = avatarUrl.startsWith(orbitGradientPrefix);
    final gradientIdx = isOrbital
        ? int.tryParse(avatarUrl.substring(orbitGradientPrefix.length)) ?? -1
        : -1;
    final orbital =
        (gradientIdx >= 0 && gradientIdx < orbitGradientOptions.length)
            ? orbitGradientOptions[gradientIdx]
            : null;
    final isRemote = avatarUrl.isNotEmpty && !isIconAvatar && !isOrbital;

    final Widget content;
    if (option != null) {
      content = Icon(option.icon, size: size * 0.5, color: Colors.white);
    } else if (isRemote) {
      content = CachedNetworkImage(
        imageUrl: avatarUrl,
        fit: BoxFit.cover,
        width: size,
        height: size,
        placeholder: (context, url) => Center(
          child: SizedBox(
            width: size * 0.36,
            height: size * 0.36,
            child: const CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white70,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Text(
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
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          shadows: const [
            Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
      );
    }

    final gradientColors = orbital != null
        ? <Color>[orbital.start, orbital.end]
        : option != null
            ? <Color>[
                option.color,
                Color.lerp(option.color, Colors.white, 0.25)!,
              ]
            : <Color>[scheme.primary, scheme.secondary];
    final glowColor = orbital?.start ?? option?.color ?? scheme.primary;

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
            color: glowColor.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: content,
    );
  }
}
