# EPG — grille : 4. la grille 2D

> **Partie 1/5**

> Fiche générée depuis le code source — extraction fidèle, commentaires compris. Chaque bloc est limité à 200 lignes pour rester copiable sans saturer le presse-papier.

Sources : `lib/features/epg/widgets/epg_grid_2d_view.dart`, `lib/features/epg/widgets/epg_row_diagnostics.dart`

### 4.1 `EpgGrid2dView` — la grille — suite 1/5

`lib/features/epg/widgets/epg_grid_2d_view.dart` · lignes 1–400

#### `lib/features/epg/widgets/epg_grid_2d_view.dart` · lignes 1–200 · partie 1/2

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerScaleEvent;
import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/core/utils/epg_day_window.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/features/epg/replay_utils.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_timeline.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_timeline_controller.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_row_diagnostics.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_mini_program_bar.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_scroll_gesture.dart';

/// Grille EPG haute performance avec CustomPainter (canvas unique).
///
/// Règle anti-ANR / anti-crash :
/// - **Aucun `setState` pendant les gestes** : hover, ligne "maintenant" et
///   défilement horizontal repaintent via des `ValueNotifier` écoutés par le
///   painter (`repaint:`), pas via un rebuild du widget (l'ancien code
///   rebuildait grille + en-têtes + cache à CHAQUE `onPointerMove`, saturant
///   le thread UI des box TV → freeze/ANR).
/// - **Cache de rendu recalculé uniquement si les données changent**
///   (signature channels + nombre de programmes + zoom), pas à chaque build.
/// - **Culling** : seules les barres visibles dans le viewport sont dessinées
///   (pas de `TextPainter` pour les programmes hors écran).
/// - Les programmes terminés des chaînes DVR affichent un badge « REPLAY »,
///   et un **appui court** sur une barre émet `onProgramTap(program, channel)`.
/// - Un **appui long** sur le nom de la chaîne émet `onChannelLongPress(channel)`.
class EpgGrid2DView extends StatefulWidget {
  final List<String> channels;
  final Map<String, List<EPGProgram>> epgData;
  final DateTime? gridStartTime;
  final double pixelsPerMinute;
  final Function(EPGProgram, String)? onProgramTap;
  final Function(String)? onChannelTap;
  final Function(String)? onChannelLongPress;
  final EpgTimelineController? timelineController;

  /// Noms des chaînes supportant le replay/DVR : leurs programmes terminés
  /// affichent un badge « REPLAY » dans la grille.
  final Set<String> replayChannels;

  /// Noms des chaînes en cours de chargement EPG : affichent un indicateur
  /// de chargement dans la colonne des noms.
  final Set<String> loadingChannels;

  const EpgGrid2DView({
    super.key,
    required this.channels,
    required this.epgData,
    this.gridStartTime,
    this.pixelsPerMinute = 4.0,
    this.onProgramTap,
    this.onChannelTap,
    this.onChannelLongPress,
    this.timelineController,
    this.replayChannels = const {},
    this.loadingChannels = const {},
  });

  @override
  State<EpgGrid2DView> createState() => EpgGrid2DViewState();
}

class EpgGrid2DViewState extends State<EpgGrid2DView> {
  late Timer _timer;
  final ScrollController _verticalController = ScrollController();

  /// Défilement vertical de la colonne des noms de chaînes.
  ///
  /// Suit [_verticalController] par recopie d'offset : les deux colonnes
  /// doivent rester alignées, mais un `ScrollController` ne peut servir qu'à
  /// une seule vue. [_syncingVertical] empêche la recopie de se reboucle.
  final ScrollController _namesVerticalController = ScrollController();
  bool _syncingVertical = false;
  late EpgTimelineController _timelineController;
  bool _ownsTimelineController = false;

  // Repaints ciblés (pas de rebuild du widget) :
  final ValueNotifier<Offset?> _hoverPosition = ValueNotifier<Offset?>(null);
  final ValueNotifier<double> _horizontalOffset = ValueNotifier<double>(0);
  Offset? _tapDownPos;
  DateTime? _tapDownTime;

  late DateTime _gridStartTime;
  late double _pixelsPerMinute;

  // Cache des programmes rendus (index par channel -> liste de _RenderProgram)
  Map<String, List<_RenderProgram>> _renderCache = {};
  int _dataSignature = -1;

  /// Incrémenté à chaque reconstruction du cache de rendu, et écouté par les
  /// painters pour se repeindre.
  ///
  /// C'est le seul canal qui atteint une ligne déjà construite : `setState`
  /// reconstruirait le `ListView` entier, et le painter seul n'a pas accès au
  /// cycle de vie du widget.
  final ValueNotifier<int> _dataRevision = ValueNotifier<int>(0);

  /// Révision du cache de rendu, exposée pour les tests.
  ///
  /// C'est le mécanisme qui a été corrigé : sans cet incrément, les lignes déjà
  /// construites ne se repeignaient pas et la grille restait vide malgré les
  /// données chargées. Un test qui vérifie qu'il change quand [epgData] change
  /// protège exactement cette correction.
  @visibleForTesting
  int get debugDataRevision => _dataRevision.value;

  /// Nombre de programmes effectivement remis au painter, par chaîne.
  ///
  /// Exposé pour les tests parce que c'est le point de rupture historique :
  /// les données arrivaient bien (les logs le confirmaient) et la révision
  /// changeait, mais le cache handed au painter restait vide — donc aucun bloc.
  /// Vérifier seulement la révision ne prouve pas que les programmes
  /// atteignent l'écran.
  @visibleForTesting
  int debugProgramCount(String channelName) =>
      _renderCache[channelName]?.length ?? 0;

  /// Chaînes pour lesquelles aucun programme n'a été rendu.
  @visibleForTesting
  List<String> get debugChannelsWithoutPrograms => [
        for (final ch in widget.channels)
          if ((_renderCache[ch]?.length ?? 0) == 0) ch,
      ];

  @override
  void initState() {
    super.initState();
    _gridStartTime = widget.gridStartTime ??
        // Repli sur minuit, et plus sur « maintenant moins 1 h » : l'axe doit
        // correspondre à la fenêtre de données servie par `EpgDayWindow`, sinon
        // un programme est placé à deux heures différentes selon l'écran. La grille se
        // replace sur l'heure courante juste après (`_scrollToCurrentTime`).
        EpgDayWindow.ofNow().start;
    _pixelsPerMinute = widget.pixelsPerMinute;

    if (widget.timelineController != null) {
      _timelineController = widget.timelineController!;
      // La grille fait autorite sur l'ORIGINE temporelle et l'ecrit dans le
      // controleur : les programmes sont poses avec `_gridStartTime`, donc la
      // ligne « maintenant » doit lire la meme origine.
      //
      // Le ZOOM n'est en revanche PAS ecrit ici. Le controleur peut porter un
      // zoom deja choisi par l'utilisateur, et le remettre a
      // `widget.pixelsPerMinute` (une constante 4,0 cote ecran EPG) annulerait
      // ce choix des le premier build.
      _timelineController.gridStartTime = _gridStartTime;
      _pixelsPerMinute = _timelineController.pixelsPerMinuteValue;
    } else {
      _timelineController = EpgTimelineController(
        gridStartTime: _gridStartTime,
        pixelsPerMinute: _pixelsPerMinute,
      );
      _ownsTimelineController = true;
    }
    _timelineController.scheduledJump.addListener(_consumeJump);
    // Listener nommé, retiré en symétrie dans `dispose()`.
    //
    // La closure anonyme était irrattrapable : impossible de la retirer, donc
    // elle retenait ce State — donc `_renderCache`, le cache de rendu de
    // TOUTES les chaînes × TOUS les programmes, l'objet le plus lourd de
    // l'écran. Et comme `EpgScreen` recrée la grille à chaque changement de
    // catégorie, la fuite se cumulait à chaque navigation.
    _timelineController.targetedChannel.addListener(_onTargetedChannel);

    // La colonne des noms suit le défilement vertical de la grille. Recopie
    // d'offset, pas partage de controller : Flutter n'autorise qu'une position
    // de défilement par controller, et le partage faisait désynchroniser les
    // deux colonnes.
    _verticalController.addListener(_syncNamesColumn);

    // Mise à jour de la ligne "maintenant" sans rebuild du widget.
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _timelineController.now.value = DateTime.now();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Une position mémorisée (retour d'une autre catégorie) prime sur le
      // recentrage : l'utilisateur revient où il était, au lieu de sauter sur
      // l'heure courante à chaque changement de catégorie.
      if (_timelineController.hasSavedScroll) {
        _restoreScrollOffsets();
      } else {
        _scrollToCurrentTime();
      }
    });
  }

  @override
  void didUpdateWidget(covariant EpgGrid2DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gridStartTime != null &&
        widget.gridStartTime != oldWidget.gridStartTime) {
      _gridStartTime = widget.gridStartTime!;
      _timelineController.gridStartTime = _gridStartTime;
    }
```

#### `lib/features/epg/widgets/epg_grid_2d_view.dart` · lignes 201–400 · partie 2/2

```dart
    // `widget.pixelsPerMinute` n'est PAS relu ici : c'est une valeur
    // INITIALE, pas une source de verite. L'ecran EPG le passe en dur a
    // `defaultPixelsPerMinute`, donc le relire a chaque reconstruction
    // ecrasait le zoom de l'utilisateur : le cache repartait a 4,0 px/min
    // pendant que l'axe et la ligne rouge gardaient l'autre echelle, et le
    // contenu glissait sous le repere horaire.
    //
    // Le controleur est l'unique proprietaire du zoom : `_zoomBy` y ecrit, la
    // grille s'y lit.
    _pixelsPerMinute = _timelineController.pixelsPerMinuteValue;
    _rebuildRenderCache();
  }

  @override
  void dispose() {
    _timer.cancel();
    // Mémorise la position AVANT de libérer `_horizontalOffset`/le contrôleur
    // vertical : c'est ici que le défilement survit au changement de catégorie
    // (la grille est détruite puis recréée).
    _timelineController.saveScrollOffsets(
      horizontal: _horizontalOffset.value,
      vertical:
          _verticalController.hasClients ? _verticalController.offset : 0.0,
    );
    _timelineController.scheduledJump.removeListener(_consumeJump);
    // Symétrique de l'abonnement. Sans cette ligne, chaque changement de
    // catégorie de chaîne empilait un State et son cache de rendu.
    //
    // Le contrôleur, lui, n'est PAS disposé : `EpgScreen` le crée et le
    // partage, donc il survit à cette grille — c'est bien ce qui rendait la
    // fuite silencieuse.
    _timelineController.targetedChannel.removeListener(_onTargetedChannel);
    if (_ownsTimelineController) {
      _timelineController.dispose();
    }
    _hoverPosition.dispose();
    _horizontalOffset.dispose();
    _dataRevision.dispose();
    _verticalController.removeListener(_syncNamesColumn);
    _verticalController.dispose();
    _namesVerticalController.dispose();
    super.dispose();
  }

  /// Recopie l'offset vertical de la grille sur la colonne des noms.
  ///
  /// Le drapeau [_syncingVertical] est indispensable : sans lui, chaque
  /// notification de la colonne déclencherait la recopie inverse, et les deux
  /// colonnes se vérifieraient l'une l'autre indéfiniment.
  void _syncNamesColumn() {
    if (_syncingVertical) return;
    if (!_verticalController.hasClients ||
        !_namesVerticalController.hasClients) {
      return;
    }
    final target = _verticalController.offset;
    if ((_namesVerticalController.offset - target).abs() < 0.5) return;
    _syncingVertical = true;
    _namesVerticalController.jumpTo(target);
    _syncingVertical = false;
  }

  void _consumeJump() {
    final target = _timelineController.scheduledJump.value;
    if (target == null) return;
    _timelineController.clearJump();
    _scrollToTime(target);
  }

  /// Cible demandée par la headbar ou la frise (télécommande).
  ///
  /// Nommé pour pouvoir être retiré dans [dispose] : voir l'abonnement.
  void _onTargetedChannel() {
    final name = _timelineController.targetedChannel.value;
    if (name == null || name.isEmpty) return;
    _revealChannel(name);
  }

  /// Amène la ligne de [channelName] dans la vue si elle est hors écran.
  ///
  /// La grille compte plusieurs centaines de chaînes : sélectionner une chaîne
  /// depuis la headbar ou la frise ne faisait rien à l'écran, la ligne restait
  /// hors du viewport et l'utilisateur ne voyait pas ce qu'il venait
  /// choisir. Le centrage n'a lieu que si la ligne est réellement absente ou
  /// tronquée — sinon un changement de chaîne ferait sauter la liste, ce qui
  /// est pire.
  void _revealChannel(String channelName) {
    if (!_verticalController.hasClients) return;
    final index = widget.channels.indexOf(channelName);
    if (index < 0) return;

    final viewport = _verticalController.position.viewportDimension;
    final top = index * kRowStride;
    final bottom = top + kRowHeight;
    final current = _verticalController.offset;

    if (top >= current && bottom <= current + viewport) return;

    _syncingVertical = true;
    try {
      // Centré quand la ligne est entièrement hors écran, aligné en haut
      // quand elle est seulement tronquée : dans ce cas, la centrer ferait
      // passer le contexte uselessement.
      final target = top < current || bottom > current + viewport
          ? (top - (viewport - kRowHeight) / 2).clamp(0.0, _maxVerticalOffset)
          : top;
      _verticalController.jumpTo(target);
      _namesVerticalController.jumpTo(target);
    } finally {
      _syncingVertical = false;
    }
  }

  /// Hauteur d'une ligne de grille, en px logiques.
  ///
  /// SOURCE UNIQUE de la géométrie verticale. Les deux `ListView` (noms de
  /// chaînes et programmes), le centrage d'une ligne au défilement et l'étendue
  /// de défilement doivent tous en dépendre.
  ///
  /// Le `(60.0 + 2)` en dur de `_maxVerticalOffset` était resté après le
  /// passage des trois autres sites à 48 : l'étendue de défilement était donc
  /// 31 % trop grande, la colonne des noms glissait par rapport aux
  /// programmes, et chaque programme sortait de la case de sa chaîne.
  static const double kRowHeight = 48.0;

  /// Gouttière entre deux lignes.
  static const double kRowGap = 2.0;

  /// Pas vertical réel entre deux lignes (`itemExtent` du `ListView`).
  static const double kRowStride = kRowHeight + kRowGap;

  double get _maxVerticalOffset {
    final content = widget.channels.length * kRowStride;
    final viewport = _verticalController.hasClients
        ? _verticalController.position.viewportDimension
        : 0.0;
    final span = content - viewport;
    return span > 0 ? span : 0.0;
  }

  /// Largeur visible de la zone grille, mesurée par le `LayoutBuilder`.
  ///
  /// Elle dimensionne désormais chaque ligne : c'est ce qui remplace les
  /// 5760 px de largeur totale comme taille de canvas.
  double _viewportWidth = 0;

  /// Dernier X connu du pointeur, pour le défilement par glissement.
  double _pointerX = 0;

  double get _maxHorizontalOffset {
    final span = 24 * 60 * _pixelsPerMinute - _viewportWidth;
    return span > 0 ? span : 0.0;
  }

  /// Positionne la grille sur [value] px, bornée à la journée.
  ///
  /// Le décalage est un simple `ValueNotifier` partagé par toutes les lignes :
  /// il n'y a plus de contrôleur horizontal, donc plus de controller attaché à
  /// plusieurs vues — ce qui était la cause du désynchronisme entre la
  /// colonne des noms et la grille.
  void _setHorizontalOffset(double value) {
    final clamped = value.clamp(0.0, _maxHorizontalOffset);
    if ((_horizontalOffset.value - clamped).abs() < 0.5) return;
    _horizontalOffset.value = clamped;
    _timelineController.onGridScroll(clamped);
  }

  void _scrollToTime(DateTime time) {
    _setHorizontalOffset(_getOffsetForTime(time) - 120);
  }

  void _scrollToCurrentTime() {
    _setHorizontalOffset(_getOffsetForTime(DateTime.now()) - 120);
  }

  /// Restaure le défilement mémorisé par une précédente instance de la grille.
  ///
  /// Les deux offsets sont re-bornés : entre-temps la fenêtre a pu rétrécir
  /// (rotation, clavier), et `jumpTo` hors bornes lève. On teste aussi
  /// `hasClients` avant de toucher à la colonne verticale — le rappel de
  /// `postFrame` s'exécute parfois avant que les `ListView` soient attachés.
  void _restoreScrollOffsets() {
    final c = _timelineController;
    _setHorizontalOffset(c.lastHorizontalOffset);
    if (!_verticalController.hasClients) return;
    final target = c.lastVerticalOffset.clamp(0.0, _maxVerticalOffset);
    if ((_verticalController.offset - target).abs() > 0.5) {
      _verticalController.jumpTo(target);
    }
  }

  /// Bornes du zoom, en px/min.
  ///
  /// Mesuré sur le S20 (1080x2400 en 420 dpi, donc 411 dp) : la grille utile
  /// fait `411 - 140` = 271 dp, et les heures visibles valent `271 / pxParMin`.
  ///
  /// | px/min  | 1,0 | 1,15 | 1,5 | 2,2 | 4,0 (defaut) | 14,0 |
  /// |----------|-----|------|-----|-----|---------------|------|
  /// | visibles | 4 h | 3 h  | 3 h | 2 h | 1 h 07        | 19 m |
  ///
```
