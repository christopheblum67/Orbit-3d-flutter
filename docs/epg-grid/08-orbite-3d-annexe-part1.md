# EPG â€” grille : 8. annexe â€” orbite 3D

> **Partie 1/5**
>
> Fiche gÃ©nÃ©rÃ©e depuis le code source â€” extraction fidÃ¨le, commentaires compris. Chaque bloc est limitÃ© Ã  200 lignes pour rester copiable sans saturer le presse-papier.
>
> âš ï¸ **ARCHIVÃ‰** : les 5 widgets 3D documentÃ©s ici (`constellation_dual_screen`, `favorites_orbit_system_3d`, `gravity_focus_node`, `nebula_search_space`, `orbit_planet_node`) ont Ã©tÃ© **supprimÃ©s** par le commit `4458d6d` (Â« chore(cleanup): code mort, identite visuelle cyan/navy, jetifier desactive Â»). Ce document est conservÃ© pour rÃ©fÃ©rence historique uniquement.
Sources : `lib/features/epg/widgets/constellation_dual_screen.dart`, `lib/features/epg/widgets/favorites_orbit_system_3d.dart`, `lib/features/epg/widgets/gravity_focus_node.dart`, `lib/features/epg/widgets/nebula_search_space.dart`, `lib/features/epg/widgets/orbit_planet_node.dart`

### 8.1 `constellation_dual_screen`

`lib/features/epg/widgets/constellation_dual_screen.dart` Â· lignes 1â€“276

#### `lib/features/epg/widgets/constellation_dual_screen.dart` Â· lignes 1â€“200 Â· partie 1/2

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/features/epg/providers/epg_providers.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_planet_node.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/orbit_planet_node.dart';

/// Ã‰cran de constellation 3D pour la navigation EPG.
///
/// Affiche les programmes sous forme de planÃ¨tes en orbite autour d'un soleil
/// central (le Â« maintenant Â»). Chaque planÃ¨te reprÃ©sente un programme, sa taille
/// indique sa durÃ©e, sa couleur son genre, et sa distance orbitale son horaire.
///
/// L'utilisateur navigue en faisant tourner la constellation (drag / flÃ¨ches /
/// tÃ©lÃ©commande). Le focus suit la planÃ¨te la plus proche du centre de l'Ã©cran.
/// Un tap / OK ouvre la fiche dÃ©tail ou lance la lecture.
class ConstellationDualScreen extends ConsumerStatefulWidget {
  const ConstellationDualScreen({super.key});

  @override
  ConsumerState<ConstellationDualScreen> createState() =>
      _ConstellationDualScreenState();
}

class _ConstellationDualScreenState extends ConsumerState<ConstellationDualScreen>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;
  late final AnimationController _focusController;

  // Configuration de la constellation
  static const double _sunRadius = 28.0;
  static const double _minOrbitRadius = 120.0;
  static const double _maxOrbitRadius = 320.0;
  static const int _maxVisiblePlanets = 50;

  // Ã‰tat
  List<EpgProgram> _programs = [];
  int _focusedIndex = 0;
  double _rotationAngle = 0.0;
  bool _isAnimating = false;
