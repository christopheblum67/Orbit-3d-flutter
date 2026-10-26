import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/widgets/avatar_catalog.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Grille d'avatars DiceBear (72 modèles) filtrée par thème.
/// Navigation TV (D-pad) + tactile. Images mises en cache via CachedNetworkImage.
class AvatarPickerGrid extends StatefulWidget {
  final String selectedImageUrl;
  final ValueChanged<String> onAvatarSelected;
  final String? categoryId; // Filtre thème (characters, smileys, blackWhite, pixels, all)

  const AvatarPickerGrid({
    super.key,
    required this.selectedImageUrl,
    required this.onAvatarSelected,
    this.categoryId,
  });

  @override
  State<AvatarPickerGrid> createState() => _AvatarPickerGridState();
}

class _AvatarPickerGridState extends State<AvatarPickerGrid> {
  List<AvatarItem> get _filteredAvatars {
    final catId = widget.categoryId ?? 'all';
    if (catId == 'all') return orbit3DAvatars;
    return orbit3DAvatars
        .where((item) => item.category == catId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _filteredAvatars.length,
      itemBuilder: (context, index) {
        final avatar = _filteredAvatars[index];
        final isCurrent = avatar.imageUrl == widget.selectedImageUrl;
        return TvFocus(
          onActivate: () => widget.onAvatarSelected(avatar.imageUrl),
          child: GestureDetector(
            onTap: () => widget.onAvatarSelected(avatar.imageUrl),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCurrent
                      ? Colors.amberAccent
                      : Colors.white.withValues(alpha: 0.18),
                  width: isCurrent ? 3 : 1,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.45),
                          blurRadius: 10,
                        ),
                      ]
                    : const [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: CachedNetworkImage(
                  imageUrl: avatar.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, _) => Container(
                    color: Colors.white.withValues(alpha: 0.06),
                    child: Icon(
                      Icons.person,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 28,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.white.withValues(alpha: 0.06),
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
