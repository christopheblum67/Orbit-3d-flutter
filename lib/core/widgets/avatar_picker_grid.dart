import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/widgets/avatar_catalog.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';

/// Filet de sélection d'avatar (30 images DiceBear) avec filtres par
/// catégorie, navigable à la télécommande (d-pad / Entrée) et tactile.
/// Les images sont mises en cache via `CachedNetworkImage`.
class AvatarPickerGrid extends StatefulWidget {
  final String selectedImageUrl;
  final ValueChanged<String> onAvatarSelected;

  const AvatarPickerGrid({
    super.key,
    required this.selectedImageUrl,
    required this.onAvatarSelected,
  });

  @override
  State<AvatarPickerGrid> createState() => _AvatarPickerGridState();
}

class _AvatarPickerGridState extends State<AvatarPickerGrid> {
  String _selectedCategory = 'Tous';

  List<AvatarItem> get _filteredAvatars {
    if (_selectedCategory == 'Tous') return orbit3DAvatars;
    return orbit3DAvatars
        .where((item) => item.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 42,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: avatarCategories.length,
            itemBuilder: (context, index) {
              final cat = avatarCategories[index];
              final isSelected = cat == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TvFocus(
                  onActivate: () => setState(() => _selectedCategory = cat),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? scheme.primary.withValues(alpha: 0.22)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? scheme.primary
                              : Colors.white.withValues(alpha: 0.14),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected
                              ? scheme.primary
                              : Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
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
        ),
      ],
    );
  }
}
