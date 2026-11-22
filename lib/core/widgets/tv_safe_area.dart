import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/providers/tv_mode_provider.dart';

/// Marge de sécurité « overscan » des téléviseurs.
///
/// Sur Android TV / Fire TV / box, la dalle affiche en général hors du cadre :
/// 5 à 10 % de l'image peuvent être rognés sur les bords (le « dépassement » /
/// overscan). Le [SafeArea] standard ne traite que les barres système et
/// laisserait donc des logos, textes ou boutons collés — voire coupés — au bord.
///
/// Ces valeurs viennent des recommandations de conception Google TV :
/// https://developer.android.com/tv/get-started/layouts#overscan
/// - 48 dp horizontal ≈ 5 % en 1080p, ≈ 3 % en 4K
/// - 27 dp vertical   ≈ 5 % en 1080p, ≈ 3 % en 4K
const EdgeInsets tvOverscanInsets =
    EdgeInsets.symmetric(horizontal: 48, vertical: 27);

/// [SafeArea] avec protection contre le dépassement des téléviseurs.
///
/// **Le retrait n'est appliqué qu'en mode TV ET sur une vraie TV.** Le mode TV
/// n'est pas une preuve de télévision : il s'active à la première touche
/// ressemblant à une télécommande, or un téléphone tactile en produit aussi
/// (Entrée du clavier virtuel, Retour système). Exiger en plus qu'une TV ait
/// réellement été détectée garantit qu'un écran tactile ne perd jamais de marge.
class TvSafeArea extends ConsumerWidget {
  const TvSafeArea({
    super.key,
    required this.child,
    this.minimum = tvOverscanInsets,
    this.left = true,
    this.top = true,
    this.right = true,
    this.bottom = true,
    this.backgroundColor,
  });

  /// Le contenu à protéger.
  final Widget child;

  /// Marge minimale appliquée en mode TV, en plus des barres système.
  final EdgeInsets minimum;

  /// Appliquer la marge minimale de chaque côté.
  final bool left;
  final bool top;
  final bool right;
  final bool bottom;

  /// Couleur de fond qui s'étend derrière l'overscan (pour éviter les bandes
  /// blanches/visibles sur les TV). Par défaut : `Theme.of(context).scaffoldBackgroundColor`.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(tvModeControllerProvider);
    final bgColor = backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;
    final applyOverscan = controller.enabled && controller.isRealTv;

    return ColoredBox(
      color: bgColor,
      child: SafeArea(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        // La marge d'overscan est une contrainte de dalle de télévision : elle
        // ne doit JAMAIS s'appliquer sur un écran tactile, même si le mode TV a
        // été activé par une touche (Entrée du clavier virtuel, Retour).
        minimum: applyOverscan ? minimum : EdgeInsets.zero,
        child: child,
      ),
    );
  }
}
