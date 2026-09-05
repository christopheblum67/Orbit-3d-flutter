import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum SolarOrbit {
  sun,
  innerPlanets,
  outerPlanets,
  asteroidBelt,
  comets,
}

enum SolarBody {
  sun,
  mercury,
  venus,
  earth,
  mars,
  jupiter,
  saturn,
  uranus,
  neptune,
  ceres,
  vesta,
  pallas,
  halley,
  encke,
  favorites,
}

class SolarSystemController extends ChangeNotifier {
  SolarOrbit _currentOrbit = SolarOrbit.sun;
  int _focusedIndex = 0;
  bool _isZoomedIn = false;

  SolarOrbit get currentOrbit => _currentOrbit;
  int get focusedIndex => _focusedIndex;
  bool get isZoomedIn => _isZoomedIn;
  SolarBody get focusedBody => _getBodyAt(_currentOrbit, _focusedIndex);

  int get maxIndexForOrbit => _maxIndexForOrbit(_currentOrbit);

  SolarBody _getBodyAt(SolarOrbit orbit, int index) {
    switch (orbit) {
      case SolarOrbit.sun:
        return SolarBody.sun;
      case SolarOrbit.innerPlanets:
        return SolarBody.values[1 + index];
      case SolarOrbit.outerPlanets:
        return SolarBody.values[5 + index];
      case SolarOrbit.asteroidBelt:
        return SolarBody.values[9 + index];
      case SolarOrbit.comets:
        return SolarBody.values[12 + index];
    }
  }

  int _maxIndexForOrbit(SolarOrbit orbit) {
    switch (orbit) {
      case SolarOrbit.sun:
        return 0;
      case SolarOrbit.innerPlanets:
        return 3;
      case SolarOrbit.outerPlanets:
        return 3;
      case SolarOrbit.asteroidBelt:
        return 2;
      case SolarOrbit.comets:
        return 2;
    }
  }

  void handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        _moveOrbitUp();
        break;
      case LogicalKeyboardKey.arrowDown:
        _moveOrbitDown();
        break;
      case LogicalKeyboardKey.arrowLeft:
        _rotateLeft();
        break;
      case LogicalKeyboardKey.arrowRight:
        _rotateRight();
        break;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
      case LogicalKeyboardKey.select:
        _onSelect();
        break;
      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.goBack:
        _onBack();
        break;
      default:
        return;
    }
    notifyListeners();
  }

  void _moveOrbitUp() {
    if (_isZoomedIn) return;

    const orbits = SolarOrbit.values;
    final currentIdx = orbits.indexOf(_currentOrbit);
    if (currentIdx > 0) {
      _currentOrbit = orbits[currentIdx - 1];
      _focusedIndex = 0;
    }
  }

  void _moveOrbitDown() {
    if (_isZoomedIn) return;

    const orbits = SolarOrbit.values;
    final currentIdx = orbits.indexOf(_currentOrbit);
    if (currentIdx < orbits.length - 1) {
      _currentOrbit = orbits[currentIdx + 1];
      _focusedIndex = 0;
    }
  }

  void _rotateLeft() {
    if (!_isZoomedIn) return;

    _focusedIndex = (_focusedIndex - 1).clamp(0, maxIndexForOrbit);
  }

  void _rotateRight() {
    if (!_isZoomedIn) return;

    _focusedIndex = (_focusedIndex + 1).clamp(0, maxIndexForOrbit);
  }

  void _onSelect() {
    if (_currentOrbit == SolarOrbit.sun) {
      _isZoomedIn = true;
      _focusedIndex = 0;
    }
  }

  void _onBack() {
    if (_isZoomedIn) {
      _isZoomedIn = false;
    }
  }

  void setOrbit(SolarOrbit orbit) {
    _currentOrbit = orbit;
    _focusedIndex = 0;
    _isZoomedIn = orbit != SolarOrbit.sun;
    notifyListeners();
  }

  void setFocusedIndex(int index) {
    _focusedIndex = index.clamp(0, maxIndexForOrbit);
    notifyListeners();
  }

  String getRouteForBody(SolarBody body) {
    switch (body) {
      case SolarBody.sun:
        return '/live';
      case SolarBody.mercury:
      case SolarBody.venus:
        return '/vod';
      case SolarBody.earth:
      case SolarBody.mars:
        return '/series';
      case SolarBody.ceres:
      case SolarBody.vesta:
      case SolarBody.pallas:
        return '/replay';
      case SolarBody.halley:
      case SolarBody.encke:
        return '/radio';
      case SolarBody.favorites:
        return '/favorites';
      default:
        return '/home';
    }
  }

  String getLabelForBody(SolarBody body) {
    switch (body) {
      case SolarBody.sun:
        return 'Live TV';
      case SolarBody.mercury:
        return 'Films Récents';
      case SolarBody.venus:
        return 'Films 4K';
      case SolarBody.earth:
        return 'Séries Populaires';
      case SolarBody.mars:
        return 'Nouvelles Saisons';
      case SolarBody.jupiter:
        return 'Action & Aventure';
      case SolarBody.saturn:
        return 'Sci-Fi & Fantasy';
      case SolarBody.uranus:
        return 'Drame & Thriller';
      case SolarBody.neptune:
        return 'Comédie & Famille';
      case SolarBody.ceres:
        return 'Replay 7 Jours';
      case SolarBody.vesta:
        return 'Replay 30 Jours';
      case SolarBody.pallas:
        return 'Catch-up Intégral';
      case SolarBody.halley:
        return 'Radio Music';
      case SolarBody.encke:
        return 'Radio Talk';
      case SolarBody.favorites:
        return 'Mes Favoris';
    }
  }

  Color getColorForBody(SolarBody body) {
    switch (body) {
      case SolarBody.sun:
        return const Color(0xFFFFD700);
      case SolarBody.mercury:
        return const Color(0xFF8A72FF);
      case SolarBody.venus:
        return const Color(0xFFB388FF);
      case SolarBody.earth:
        return const Color(0xFF4CAF50);
      case SolarBody.mars:
        return const Color(0xFFFF6FA8);
      case SolarBody.jupiter:
        return const Color(0xFFFFB300);
      case SolarBody.saturn:
        return const Color(0xFF26A69A);
      case SolarBody.uranus:
        return const Color(0xFF00CFE8);
      case SolarBody.neptune:
        return const Color(0xFF8B5CF6);
      case SolarBody.ceres:
        return const Color(0xFFFFB300);
      case SolarBody.vesta:
        return const Color(0xFFFFA726);
      case SolarBody.pallas:
        return const Color(0xFFFF8C00);
      case SolarBody.halley:
        return const Color(0xFF8B5CF6);
      case SolarBody.encke:
        return const Color(0xFFB388FF);
      case SolarBody.favorites:
        return const Color(0xFFFF6FA8);
    }
  }

  IconData getIconForBody(SolarBody body) {
    switch (body) {
      case SolarBody.sun:
        return Icons.tv_rounded;
      case SolarBody.mercury:
      case SolarBody.venus:
        return Icons.movie_outlined;
      case SolarBody.earth:
      case SolarBody.mars:
      case SolarBody.jupiter:
      case SolarBody.saturn:
      case SolarBody.uranus:
      case SolarBody.neptune:
        return Icons.video_library_rounded;
      case SolarBody.ceres:
      case SolarBody.vesta:
      case SolarBody.pallas:
        return Icons.replay_rounded;
      case SolarBody.halley:
      case SolarBody.encke:
        return Icons.radio_rounded;
      case SolarBody.favorites:
        return Icons.favorite_rounded;
    }
  }

  double getOrbitRadius(SolarOrbit orbit) {
    switch (orbit) {
      case SolarOrbit.sun:
        return 0;
      case SolarOrbit.innerPlanets:
        return 180;
      case SolarOrbit.outerPlanets:
        return 300;
      case SolarOrbit.asteroidBelt:
        return 400;
      case SolarOrbit.comets:
        return 500;
    }
  }

  int getBodyCountForOrbit(SolarOrbit orbit) {
    return maxIndexForOrbit + 1;
  }
}