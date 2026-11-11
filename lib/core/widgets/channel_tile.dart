import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orbit_3d_flutter/core/widgets/orbit_cached_image.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';

/// Ligne de contenu (chaîne / série / radio) avec artwork dégradé.
class ChannelTile extends StatelessWidget {
  const ChannelTile({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.imageUrl,
    this.trailing,
    this.isActive = false,
    this.onTap,
    this.onLongPress,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String? imageUrl;
  final Widget? trailing;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color:
            isActive ? scheme.secondaryContainer : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: isActive
              ? scheme.primary.withValues(alpha: 0.5)
              : scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: _LongSelect(
          onTap: onTap,
          onLongPress: onLongPress,
          child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                _Artwork(
                  icon: icon,
                  imageUrl: imageUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

/// Appui long sur la touche OK de la télécommande : tap au relâchement,
/// [onLongPress] si la touche reste enfoncée.
class _LongSelect extends StatefulWidget {
  const _LongSelect({
    required this.child,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<_LongSelect> createState() => _LongSelectState();
}

class _LongSelectState extends State<_LongSelect> {
  bool _held = false;
  bool _fired = false;

  static bool _isSelect(LogicalKeyboardKey k) =>
      k == LogicalKeyboardKey.enter ||
      k == LogicalKeyboardKey.select ||
      k == LogicalKeyboardKey.numpadEnter ||
      k == LogicalKeyboardKey.gameButtonA;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (widget.onLongPress == null || !_isSelect(event.logicalKey)) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent) {
      _held = true;
      _fired = false;
      return KeyEventResult.handled;
    }
    if (event is KeyRepeatEvent && _held) {
      if (!_fired) {
        _fired = true;
        HapticFeedback.heavyImpact();
        widget.onLongPress!();
      }
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent && _held) {
      _held = false;
      if (!_fired) widget.onTap?.call();
      _fired = false;
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: widget.child,
      );
}

class _Artwork  extends StatelessWidget {
  const _Artwork({
    required this.icon,
    this.imageUrl,
  });

  final IconData icon;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _placeholder(scheme);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: OrbitCachedImage(
        imageUrl: imageUrl!,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        placeholder: (context, url) => _placeholder(scheme),
        errorWidget: (context, url, error) => _placeholder(scheme),
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [scheme.primaryContainer, scheme.tertiaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(icon, color: scheme.primary, size: 24),
    );
  }
}
