import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';

/// Carte arrondie moderne, réutilisable sur tous les écrans.
///
/// Par défaut : fond noir charbon (0xFF12141C) pour harmoniser
/// toutes les cartes (chaînes, films, séries).
/// Titre en texte blanc doux (white70) pour lisibilité.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.onLongPress,
    this.color,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final BorderRadius? borderRadius;

  /// Dernière signature de couleur journalisée (diagnostic).
  ///
  /// `AppCard` est construit des milliers de fois par les grilles : journaliser
  /// chaque build noierait logcat. On ne journalise donc que les TRANSITIONS de
  /// couleur demandées par le parent — c'est le seul moyen pour une carte
  /// stateless de changer d'aspect à l'exécution.
  static String? _lastLoggedColorSignature;

  // Couleur de fond par défaut : rouge sombre désaturé. Assez sombre pour ne
  // pas éblouir ni concurrencer les logos, assez rouge pour être perceptible.
  static const Color _defaultCardColor = Color(0xFF33181C);

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppConstants.radiusLg);
    // Quand la carte est transparente (ex. MediaCard dans les grilles
    // films/séries), on supprime la bordure et l'ombre qui dessinent un
    // encadré visible autour de chaque tuile.
    final transparent = color == Colors.transparent;
    // Diagnostic : « APPCARD » n'apparaît que lorsqu'un parent change la
    // couleur demandée d'une carte (ex. transparent ↔ défaut). Si l'encadré
    // d'une tuile apparaît sans log, la cause n'est PAS AppCard.
    final signature = color == null
        ? 'default(#33181C)'
        : color == Colors.transparent
            ? 'transparent'
            : '$color';
    if (signature != _lastLoggedColorSignature) {
      _lastLoggedColorSignature = signature;
      LoggerService.instance
          .info('APPCARD color=$signature transparent=$transparent');
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: color ?? _defaultCardColor,
        borderRadius: radius,
        border: transparent
            ? null
            : Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
        boxShadow: transparent
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
