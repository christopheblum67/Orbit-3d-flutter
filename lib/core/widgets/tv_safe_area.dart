import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';

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
/// **Le retrait n'est appliqué qu'en mode TV.** Détecté par [tvModeNotifierProvider]
/// (activé à la première interaction D-pad par [TvModeDetector]), il reste à zéro
/// sur téléphone : pas de marge perdue sur un écran tactile, pas de régression.
class TvSafeArea extends ConsumerWidget {
  const TvSafeArea({
    super.key,
    required this.child,
    this.minimum = tvOverscanInsets,
    this.left = true,
    this.top = true,
    this.right = true,
    this.bottom = true,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tvMode = ref.watch(tvModeNotifierProvider);
    // `tvModeNotifierProvider` est un `ChangeNotifier` : `ListenableBuilder`
    // reconstruit quand l'état TV change, sans dépendre d'une API Riverpod
    // réactive supplémentaire.
    return ListenableBuilder(
      listenable: tvMode,
      builder: (context, _) => SafeArea(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        minimum: tvMode.enabled ? minimum : EdgeInsets.zero,
        child: child,
      ),
    );
  }
}
