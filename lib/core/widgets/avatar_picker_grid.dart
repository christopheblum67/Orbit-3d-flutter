import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/widgets/avatar_catalog.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Grille des avatars locaux, filtrable par catégorie et
/// navigable au D-pad comme au tactile. Fonctionne hors ligne.
class AvatarPickerGrid extends StatefulWidget {
  final String selectedImageUrl;
  final ValueChanged<String> onAvatarSelected;
  final String? categoryId;

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
  String _selectedCategoryId = 'all';

  List<AvatarItem> get _filteredAvatars {
    final categoryId = widget.categoryId ?? _selectedCategoryId;
    if (categoryId == 'all') return selectableOrbit3DAvatars;
    return selectableOrbit3DAvatars
        .where((item) => item.category == categoryId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final avatars = _filteredAvatars;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.categoryId == null) ...[
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: avatarCategoryIds.length,
              itemBuilder: (context, index) {
                final catId = avatarCategoryIds[index];
                final isSelected = catId == _selectedCategoryId;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TvFocus(
                    onActivate: () =>
                        setState(() => _selectedCategoryId = catId),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategoryId = catId),
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
                          avatarCategoryLabel(l, catId),
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
        ],
        FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width < 420 ? 4 : (width < 720 ? 6 : 8);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: avatars.length,
              itemBuilder: (context, index) {
                final avatar = avatars[index];
                final isCurrent = avatar.imageUrl == widget.selectedImageUrl;
                return TvFocus(
                  circular: true,
                  onActivate: () => widget.onAvatarSelected(avatar.imageUrl),
                  child: GestureDetector(
                    onTap: () => widget.onAvatarSelected(avatar.imageUrl),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
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
                      child: ClipOval(
                        child: Image.asset(
                          avatar.imageUrl.substring(avatarAssetPrefix.length),
                          fit: BoxFit.cover,
                          semanticLabel: avatar.imageUrl.contains(
                            '/avatar_collection/',
                          )
                              ? '${avatarCategoryLabel(l, avatar.category)} ${avatar.id.split('_').last}'
                              : avatar.name,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (context, error, stack) => Container(
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
          }),
        ),
      ],
    );
  }
}
