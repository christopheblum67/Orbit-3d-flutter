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
  /// Le defaut de 4,0 px/min ne montrait donc que 1 h 07 au premier
  /// affichage, ce qui correspond a la plainte « il n'y a qu'une heure ». Les
  /// paliers descendent jusqu'a 1,0 px/min, soit 4 h 30 atteignables en trois
  /// clics sur `-` et toujours reversibles.
  static const double minPixelsPerMinute = 1.0;
  static const double maxPixelsPerMinute = 14.0;

  /// Paliers du zoom, pour que `−` et `+` restent réversibles.
  ///
  /// Invariant verrouille par `test/unit/epg_zoom_range_test.dart` : chaque
  /// palier reste dans `[minPixelsPerMinute, maxPixelsPerMinute]`. Un palier
  /// hors bornes serait propose par `_nextZoomStep` puis ecrete par `_zoomBy`,
  /// et le bouton deviendrait un no-op sans aucun signe visible.
  static const List<double> zoomSteps = [
    1.0,
    1.15,
    1.5,
    2.2,
    3.0,
    4.0,
    5.0,
    6.5,
    8.5,
    11.0,
    14.0,
  ];

  double get _zoomFactor => _pixelsPerMinute / minPixelsPerMinute;

  /// Applique un facteur de zoom en gardant l'heure CIBLE immobile.
  ///
  /// [anchorX] est la position écran à conserver : sans cette correction, un
  /// zoom recentrait simplement sur le bord gauche, et la minute que l'on
  /// regardait disparaissait de l'écran. On reprojette donc le décalage pour
  /// que l'heure sous [anchorX] y reste.
  void _zoomBy(double factor, double anchorX) {
    final target = (_pixelsPerMinute * factor).clamp(
      minPixelsPerMinute,
      maxPixelsPerMinute,
    );
    if (target == _pixelsPerMinute) return;

    // Heure actuellement sous le point d'ancrage, avant le changement.
    final anchoredMinutes =
        (_horizontalOffset.value + anchorX) / _pixelsPerMinute;
    _pixelsPerMinute = target;
    // Le contrôleur est la source de vérité partagée avec la frise.
    _timelineController.pixelsPerMinute = target;
    _setHorizontalOffset(anchoredMinutes * target - anchorX);
    _rebuildRenderCache();
    setState(() {});
  }

  void _zoomIn() => _zoomBy(_nextZoomStep(_pixelsPerMinute, up: true), 140);

  void _zoomOut() => _zoomBy(_nextZoomStep(_pixelsPerMinute, up: false), 140);

  /// Facteur pour passer au palier suivant (ou précédent).
  static double _nextZoomStep(double current, {required bool up}) {
    for (final step in zoomSteps) {
      if (up && step > current + 0.01) return step / current;
      if (!up && step < current - 0.01) return step / current;
    }
    return 1.0;
  }

  double _getOffsetForTime(DateTime time) =>
      programLeftPx(time, _gridStartTime, _pixelsPerMinute);

  /// Signature légère (O(channels)) pour détecter un changement de données
  /// sans comparer des listes entières : suffixée par le zoom et l'origine
  /// temporelle car ils affectent le rendu.
  int _computeSignature() {
    var hash = _gridStartTime.minute * 100003;
    hash = (hash * 31 + (_pixelsPerMinute * 1000).round()) & 0x7fffffff;
    hash = (hash * 31 + widget.channels.length) & 0x7fffffff;
    for (final ch in widget.channels) {
      hash = (hash * 31 + ch.hashCode) & 0x7fffffff;
      final programs = widget.epgData[ch];
      if (programs == null || programs.isEmpty) {
        hash = (hash * 31) & 0x7fffffff;
        continue;
      }
      // L'effectif seul ne suffit pas : un rafraîchissement de l'EPG peut
      // remplacer N programmes par N autres. On inclut donc le premier et le
      // dernier debut, ce qui change des que le contenu change, et on les
      // combine sans allouer (une somme suffit a detecter un changement).
      hash = (hash * 31 + programs.length) & 0x7fffffff;
      var fingerprint = programs.first.start.millisecondsSinceEpoch;
      fingerprint += programs.last.start.millisecondsSinceEpoch;
      fingerprint +=
          programs[programs.length ~/ 2].start.millisecondsSinceEpoch;
      hash = (hash * 31 + fingerprint) & 0x7fffffff;
    }
    for (final ch in widget.replayChannels) {
      hash = (hash * 31 + ch.hashCode) & 0x7fffffff;
    }
    return hash;
  }

  /// Reconstruit le cache uniquement quand les données changent (pas à chaque
  /// build/geste). Les positions sont fiables : les barres débutant AVANT
  /// l'origine de la grille gardent une `left` négative (rendues via le
  /// culling du viewport).
  void _rebuildRenderCache() {
    final signature = _computeSignature();
    if (signature == _dataSignature) return;
    _dataSignature = signature;
    // Notifie les painters déjà à l'écran.
    //
    // Un `ListView.builder` ne rappelle `itemBuilder` que lorsqu'il RECYCLE
    // une ligne. Les lignes déjà affichées — donc presque toutes, la grille
    // étant virtualisée — conservaient le painter construit au premier rendu,
    // avec une `renderCache` encore vide. Les programmes se chargeaient bien
    // (les logs le confirment) mais aucun bloc n'apparaissait : le repeint
    // passait par un état que rien ne signalait.
    _dataRevision.value++;

    final cache = <String, List<_RenderProgram>>{};
    final now = DateTime.now();
    // Échelle lue UNE fois. Les positions et largeurs sont précalculées ici,
    // puis seulement multipliées pendant le `paint` : sur une box Android
    // ancienne, un `DateTime.difference` par programme et par trame saturait
    // le thread UI (le guide saccadait dès qu'on faisait défiler).
    final ppm = _pixelsPerMinute;
    for (final ch in widget.channels) {
      final programs = widget.epgData[ch] ?? const <EPGProgram>[];
      final channelHasReplay = widget.replayChannels.contains(ch);
      cache[ch] = [
        for (final p in programs)
          _RenderProgram(
            program: p,
            left: programLeftPx(p.startTime, _gridStartTime, ppm),
            width: programWidthPx(p.durationMinutes, ppm),
            isLive: p.isLive,
            replayable: isReplayableProgram(
              p,
              now: now,
              channelSupportsReplay: channelHasReplay,
            ),
          ),
      ];
    }
    _renderCache = cache;

    // Mesure de rendu : distingue trois causes pourtant très différentes d'une
    // grille vide.
    //
    // 1. `withPrograms == 0` → les programmes n'arrivent pas jusqu'ici, le
    //    problème est en amont (chargement ou signature).
    // 2. `withPrograms > 0` mais `maxLeft > largeur visible` → les programmes
    //    sont calculés hors du viewport, donc Cullés : le problème est un
    //    décalage horaire, pas une absence de données.
    //
    // Cette mesure n'existait pas, et sans elle les deux cas se ressemblent
    // exactement à l'écran : des lignes vides.
    if (cache.isNotEmpty) {
      var minLeft = double.infinity;
      var maxLeft = double.negativeInfinity;
      for (final rp in cache.values) {
        if (rp.isEmpty) continue;
        for (final p in rp) {
          if (p.left < minLeft) minLeft = p.left;
          if (p.left + p.width > maxLeft) maxLeft = p.left + p.width;
        }
      }
      // Les trois états sont comptés séparément : « comblées seules » et
      // « vides » se ressemblent à l'écran mais n'ont rien à voir comme causes,
      // et l'ancien compteur les confondait avec les lignes ayant de vrais
      // programmes — rendant le bilan incomparable à celui du chargeur.
      final diag = diagnoseEpgRows(widget.epgData);
      LoggerService.instance.info(
        'EPG rendu: $diag, étendue $minLeft..'
        '${maxLeft == double.negativeInfinity ? 0 : maxLeft} '
        'px, origine ${_gridStartTime.toIso8601String()}, '
        'début 1re ligne = ${_firstProgramStart(cache)}',
      );
    }
  }

  /// Heure du premier programme de la première ligne ayant des données.
  ///
  /// Comparée à `_gridStartTime`, elle révèle un décalage de fuseau horaire :
  /// un programme annoncé à 06:00 alors que la grille démarre à 00:00 se
  /// retrouve à 6 h × zoom pixels, donc hors écran.
  String _firstProgramStart(Map<String, List<_RenderProgram>> cache) {
    for (final ch in widget.channels) {
      final rp = cache[ch];
      if (rp == null || rp.isEmpty) continue;
      final earliest = rp.reduce((a, b) => a.left < b.left ? a : b);
      return earliest.program.startTime.toIso8601String();
    }
    return 'aucune';
  }

  /// Appui court (peu de déplacement, < 400 ms) sur la grille : ouvre le
  /// programme sous le doigt. Un appui hors programme sélectionne la chaîne
  /// de la ligne (comme un appui sur la colonne des noms).
  void _consumeGridTap(Offset pos) {
    final down = _tapDownPos;
    final downTime = _tapDownTime;
    if (down == null || downTime == null) return;
    if ((pos - down).distance > 12) return; // c'est un scroll, pas un tap
    if (DateTime.now().difference(downTime).inMilliseconds >= 400) return;

    final channelIndex = (pos.dy / kRowStride).floor();
    if (channelIndex < 0 || channelIndex >= widget.channels.length) return;
    final ch = widget.channels[channelIndex];
    _timelineController.setTargetedChannel(ch);

    final rp = _programAt(pos.dx, ch);
    if (rp != null) {
      widget.onProgramTap?.call(rp.program, ch);
    } else {
      widget.onChannelTap?.call(ch);
    }
  }

  /// Contrôleur partagé — pour les tests.
  @visibleForTesting
  EpgTimelineController get debugTimelineControllerForTest => _timelineController;

  /// Positionne la grille à [value] px — pour les tests.
  @visibleForTesting
  void debugSetHorizontalOffsetForTest(double value) =>
      _setHorizontalOffset(value);

  /// Décalage horizontal courant, en px — pour les tests.
  @visibleForTesting
  double get debugHorizontalOffsetForTest => _horizontalOffset.value;

  /// Titre du programme sous l'abscisse ÉCRAN [screenDx] — pour les tests.
  ///
  /// Expose la conversion screen → position absolue, qui est le cœur du
  /// défaut : sans elle, un tap à mi-journée ouvre un programme décalé de
  /// plusieurs heures.
  @visibleForTesting
  String? debugProgramTitleAt(double screenDx, String channelName) =>
      _programAt(screenDx, channelName)?.program.title;

  /// Programme sous l'abscisse écran [dx] de la grille, pour [channelName].
  ///
  /// [dx] vient de `PointerEvent.localPosition`, donc il est relatif au canvas
  /// de la grille, qui affiche la tranche `[offset, offset + largeur]` de la
  /// journée. Or `rp.left` est une position ABSOLUE depuis minuit : il faut
  /// rendre à [dx] son rang absolu avant de comparer, sans quoi le programme
  /// retourné est décalé de tout le défilement — à mi-journée, l'erreur vaut
  /// la moitié de la largeur visible.
  _RenderProgram? _programAt(double dx, String channelName) {
    final absolute = dx + _horizontalOffset.value;
    for (final rp in _renderCache[channelName] ?? const <_RenderProgram>[]) {
      if (absolute >= rp.left && absolute < rp.left + rp.width) return rp;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    _rebuildRenderCache();
    final l = AppLocalizations.of(context);

    // Largeur de la journée = 24 h × échelle. Elle doit valoir EXACTEMENT ce que
    // valent les positions des programmes (`minutes × pixelsPerMinute`), sinon
    // la fin de journée est peinte hors de la boîte et devient invisible.
    //
    // Le clamp à 2880 px qui était ici tronquait la grille à 12 h : à 4 px/min
    // les programmes allaient jusqu'à 5760 px, et tout ce qui dépassait la
    // demi-journée n'était jamais dessiné. Le défilement horizontal existe
    // précisément pour cela.
    const rowHeight = kRowHeight;

    /// Largeur de la colonne des noms de chaînes.
    ///
    /// C'est aussi l'abscisse de départ de l'axe du temps : la bande de l'axe
    /// et la grille partagent le même `Row` (colonne puis `Expanded`), donc les
    /// deux commencent au MÊME pixel, sans gouttière entre elles.
    ///
    /// La gouttière de 4 px qui figurait ici (`channelWidth + 4`) n'a jamais
    /// existé dans le layout, et était pourtant appliquée à l'axe ET à la
    /// ligne « maintenant ». Résultat : ces deux repères étaient décalés de
    /// 4 px vers la droite par rapport aux programmes qu'ils désignent, soit
    /// 1 min à 4 px/min et 4 min à 1 px/min. L'erreur étant en pixels, elle
    /// grandissait à chaque dézoom.
    const channelWidth = kChannelWidth;

    return Container(
      color: const Color(0xFF0D0E12),
      child: Column(
        children: [
          // Frise temporelle + barre de navigation
          //
          // L'axe doit COMMENCER AU MÊME X QUE LA GRILLE. Les boutons de
          // navigation étaient entre la colonne des noms et la frise : la
          // frise démarrait donc ~150 px plus loin, et chaque libellé d'heure
          // se lisait à ce décalage. La ligne « maintenant », correctement
          // posée sur la grille, tombait alors vers 7 h 35 quand l'axe
          // annonçait l'heure réelle.
          //
          // Les boutons occupent désormais la bande gauche — celle des noms
          // de chaînes, large de `channelWidth` — et l'axe s'ouvre juste
          // après, aligné sur la grille.
          Container(
            height: 44,
            color: const Color(0xFF0D0E12),
            child: Row(
              children: [
                SizedBox(
                  width: channelWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _AxisButton(
                        icon: Icons.zoom_out,
                        tooltip: '${l.epgZoomOut} '
                            '(${_zoomFactor.toStringAsFixed(1)}×)',
                        onPressed: _zoomOut,
                      ),
                      _AxisButton(
                        icon: Icons.access_time,
                        tooltip: l.epgNow,
                        color: const Color(0xFF8B5CF6),
                        onPressed: () =>
                            _timelineController.jumpTo(DateTime.now()),
                      ),
                      _AxisButton(
                        icon: Icons.zoom_in,
                        tooltip: '${l.epgZoomIn} '
                            '(${_zoomFactor.toStringAsFixed(1)}×)',
                        onPressed: _zoomIn,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: EpgTimeline(
                      controller: _timelineController,
                      onScrub: (time) {
                        _timelineController.jumpTo(time);
                      },
                      onTimeSelected: (time) {
                        _timelineController.jumpTo(time);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mini-lecteur programme de la chaîne ciblée
          EpgMiniProgramBar(
            controller: _timelineController,
            epgData: widget.epgData,
          ),

          // Grille EPG avec CustomPainter
          //
          // Le `Stack` permet de poser la ligne « maintenant » AU-DESSUS des
          // deux colonnes (noms + programmes) : c'est un repère temporel unique,
          // il doit traverser toute la grille d'un seul trait. Elle est
          // ignorée au toucher pour ne pas voler les appuis sur les programmes.
          Expanded(
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Colonne fixe noms chaînes
                    SizedBox(
                      width: channelWidth,
                      // Virtualisée comme la grille.
                      //
                      // Un `Column` de 628 `Container` dans un
                      // `SingleChildScrollView` construit TOUS les widgets, même
                      // invisibles : plusieurs secondes de layout à chaque
                      // ouverture, et l'écran paraissait figé. `ListView.builder`
                      // ne construit que les lignes visibles.
                      child: ListView.builder(
                        controller: _namesVerticalController,
                        // Même pas que la grille : c'est la condition pour
                        // que chaque programme reste dans la case de SA chaîne.
                        itemExtent: kRowStride,
                        itemCount: widget.channels.length,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          final ch = widget.channels[index];
                          final isLoading = widget.loadingChannels.contains(ch);
                          final hasPrograms = (widget.epgData[ch]?.isNotEmpty ?? false);
                          final isEmpty = !hasPrograms && !isLoading;
                          return Container(
                            height: rowHeight,
                            color: isLoading
                                ? const Color(0xFF1A1D26)
                                : isEmpty
                                    ? const Color(0xFF1A1518)
                                    : const Color(0xFF12141C),
                            margin: const EdgeInsets.only(bottom: kRowGap),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () {
                                _timelineController.setTargetedChannel(ch);
                                widget.onChannelTap?.call(ch);
                              },
                              onLongPress: () =>
                                  widget.onChannelLongPress?.call(ch),
                              child: Row(
                                children: [
                                  if (isLoading) ...[
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          const Color(0xFF8B5CF6),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: Text(
                                      ch,
                                      style: TextStyle(
                                        color: isLoading
                                            ? Colors.white70
                                            : isEmpty
                                                ? Colors.white30
                                                : Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!hasPrograms && !isLoading)
                                    Icon(
                                      Icons.info_outline,
                                      size: 12,
                                      color: Colors.white30,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Zone grille : LIGNES VIRTUALISÉES.
                    //
                    // Un `ListView.builder` ne construit que les lignes visibles, et
                    // chacune reçoit un canvas de la seule largeur du viewport. On
                    // ne dimensionne donc plus un canvas de 5760 × (chaînes × 60) :
                    // cette taille dépassait la limite de texture de Skia (l'écran
                    // devenait un aplat gris) et représentait à elle seule plusieurs
                    // centaines de mégaoctets de RAM.
                    Expanded(
                      // `Expanded` ici, et non dans le builder : le `LayoutBuilder`
                      // est l'enfant direct du `Row`, donc il reçoit un
                      // `BoxParentData`. Un `Expanded` renvoyé par son builder
                      // était un petit-enfant du `Row`, et le cast vers
                      // `FlexParentData` échouait — la grille entière était
                      // remplacée par l'aplat gris d'un `RenderErrorBox`.
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final viewportWidth = constraints.maxWidth;
                          if (_viewportWidth != viewportWidth) {
                            _viewportWidth = viewportWidth;
                            // La borne de défilement vient de changer : on se
                            // reprojette pour rester dans la journée.
                            _setHorizontalOffset(_horizontalOffset.value);
                          }
                            return HorizontalDragLayer(
                              offset: _horizontalOffset,
                              maxOffset: _maxHorizontalOffset,
                              onOffsetChanged: _setHorizontalOffset,
                              child: Listener(
                            // Pinch : le geste naturel du zoom sur un
                            // téléphone. On ancre sur la position donnée par
                            // l'événement, sinon la minute visée dérive pendant
                            // le geste.
                            onPointerSignal: (event) {
                              if (event is! PointerScaleEvent) return;
                              _zoomBy(event.scale, event.localPosition.dx);
                            },
                            onPointerDown: (event) {
                              _tapDownPos = event.localPosition;
                              _tapDownTime = DateTime.now();
                              _pointerX = event.localPosition.dx;
                              _hoverPosition.value = null;
                            },
                            onPointerMove: (event) {
                              // Le déplacement horizontal est conduit par
                              // `HorizontalDragLayer`, qui participe à l'arène
                              // de gestes et gagne franchement sur un
                              // mouvement horizontal. Ici on ne fait plus que
                              // suivre le doigt, pour le survol et pour
                              // distinguer un glissement d'un appui.
                              //
                              // Déplacer la grille ici était le bug d'origine :
                              // un `Listener` ne réclame rien dans l'arène, donc
                              // il bougeait dès le premier pixel alors que le
                              // `ListView` vertical croyait encore tenir le
                              // geste — les deux se disputaient le pointeur.
                              _pointerX = event.localPosition.dx;
                              _hoverPosition.value = event.localPosition;
                            },
                            onPointerUp: (event) {
                              _hoverPosition.value = null;
                              // Un glissement n'est pas un appui : sans cette
                              // distinction, un simple balayage sélectionnait un
                              // programme au hasard.
                              //
                              // `onPointerDown` a pu être annulé par le système
                              // (centré de dialogue) : dans ce cas aucune
                              // sélection ne doit partir, et surtout le `!`
                              // planterait la zone.
                              final down = _tapDownPos;
                              _tapDownPos = null;
                              if (down == null) return;
                              final moved = (_pointerX - down.dx).abs() > 8;
                              if (!moved) _consumeGridTap(event.localPosition);
                            },
                            onPointerCancel: (_) {
                              _hoverPosition.value = null;
                              _tapDownPos = null;
                            },
                            child: ClipRect(
                              child: ListView.builder(
                                controller: _verticalController,
                                itemExtent: kRowStride,
                                itemCount: widget.channels.length,
                                itemBuilder: (context, index) =>
                                    RepaintBoundary(
                                  child: CustomPaint(
                                    size: Size(viewportWidth, kRowStride),
                                    painter: _EpgGridPainter(
                                      channels: widget.channels,
                                      renderCacheOf: () => _renderCache,
                                      gridStartTime: _gridStartTime,
                                      pixelsPerMinute: _pixelsPerMinute,
                                      rowHeight: rowHeight,
                                      channelWidth: channelWidth,
                                      viewportWidth: viewportWidth,
                                      channelIndex: index,
                                      liveLabel: l.epgLiveNow,
                                      horizontalOffset: _horizontalOffset,
                                      touchPosition: _hoverPosition,
                                      dataRevision: _dataRevision,
                                      repaint: Listenable.merge([
                                        _hoverPosition,
                                        _timelineController.now,
                                        _horizontalOffset,
                                        _dataRevision,
                                      ]),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      ),
                    ),
                  ],
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: _NowLineOverlay(
                      controller: _timelineController,
                      channelWidth: channelWidth,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Largeur de la colonne des noms de chaînes, en px logiques.
///
/// Source unique. C'est aussi l'abscisse de départ de l'axe du temps.
@visibleForTesting
const double kChannelWidth = 140.0;

/// Marge intérieure du titre d'un programme, à gauche comme à droite.
@visibleForTesting
const double kTitlePaddingH = 6.0;

/// Largeur minimale pour écrire un titre, une fois la marge retirée.
///
/// En dessous, `TextPainter` ne produit qu'une colonne de lettres broyées :
/// plus illisible que rien du tout. Le seuil historique (`width > 26`)
/// laissait passer des blocs de 26 à 38 px pour lesquels `maxWidth` tombait
/// sous 14 px. Mesuré au zoom le plus dézoomé (1,0 px/min), un programme de
/// 30 min fait 28 px de bloc, donc 16 px de texte : juste au-dessus, et
/// lisible pour un mot.
@visibleForTesting
const double kTitleMinReadableWidth = 12.0;

/// Marge de culling horizontale, en pixels, pour une densité donnée.
@visibleForTesting
double cullMarginFor(double pixelsPerMinute) => pixelsPerMinute * 60.0;

/// Plancher de largeur d'un bloc, en px.
///
/// Ne sert qu'à garder VISIBLE et cliquable un bloc dont la durée réelle
/// donnerait moins de 4 px (programme très court, ou zoom très dézoomé). Il est
/// volontairement minuscule : l'ancien plancher de 40 px faisait déborder
/// chaque bloc sur ses voisins, et le culling occultait alors la suite de la
/// grille. Sur un appareil Android ancien, où le zoom minimum est atteint
/// souvent, ce plancher borne le recouvrement à 4 px au lieu de plusieurs
/// centaines.
@visibleForTesting
const double kMinProgramBlockWidth = 4.0;

/// Couleur de l'indicateur « en direct ».
///
/// Alignée sur la ligne « maintenant » (`#FF5252`) : les deux désignent le même
/// instant, ils doivent se lire comme un seul repère.
const Color kLiveIndicatorColor = Color(0xFFFF5252);

/// Rayon de la pastille « en direct », en px logiques.
const double kLiveDotRadius = 3.0;

/// Espace entre la pastille, le libellé et le titre, en px logiques.
const double kLiveDotGap = 4.0;

/// Largeur de bloc à partir de laquelle le libellé « en direct » est écrit.
///
/// En dessous, seule la pastille reste : écrire le libellé dans un bloc trop
/// étroit écraserait le titre — c'était exactement le défaut d'origine, où
/// « DIRECT » et le titre partageaient la même abscisse et le titre gagnait
/// toujours.
const double kLiveLabelMinWidth = 72.0;

/// Abscisse du bord gauche d'un bloc, en px, dans le repère [gridStartTime].
///
/// Fonction pure, extraite du `paint` pour être verrouillée par un test : c'est
/// elle qui garantit que deux programmes de la même tranche horaire ne se
/// superposent plus. [start] peut précéder [gridStartTime] (programme à cheval
/// sur minuit) : le résultat est alors négatif, et c'est le culling qui s'en
/// charge.
@visibleForTesting
double programLeftPx(
  DateTime start,
  DateTime gridStartTime,
  double pixelsPerMinute,
) =>
    start.difference(gridStartTime).inSeconds / 60.0 * pixelsPerMinute;

/// Largeur d'un bloc, en px : durée réelle × échelle, plancher
/// [kMinProgramBlockWidth].
///
/// Pas de gouttière soustraite : les tuiles sont volontairement pleine largeur
/// (chaque bloc va jusqu'au début du suivant), ce qui évite les fentes
/// claires qui se lisaient comme des trous d'EPG.
@visibleForTesting
double programWidthPx(int durationMinutes, double pixelsPerMinute) {
  final raw = durationMinutes * pixelsPerMinute;
  return raw < kMinProgramBlockWidth ? kMinProgramBlockWidth : raw;
}

/// Abscisse ÉCRAN (0 = bord gauche du canvas de la ligne) d'une position
/// ABSOLUE de la journée.
///
/// Le canvas de chaque ligne ne montre qu'une tranche de la journée : toute
/// abscisse issue de [programLeftPx] (donc relative à minuit, jusqu'à 5760 px)
/// doit passer par ici avant d'être dessinée.
///
/// Oublier cet appel — le défaut qui touchait le titre et le badge « REPLAY » —
/// peignait le texte à sa position absolue, hors du canvas dès que la grille
/// est défilée : les blocs restaient visibles mais vides de texte, ce qui se
/// lisait comme « aucun programme dans la grille ».
///
/// Source unique : fond, titre et badge appellent cette fonction, donc ils ne
/// peuvent plus diverger.
@visibleForTesting
double screenXFor(double absolutePx, double horizontalOffset) =>
    absolutePx - horizontalOffset;

/// Abscisse de départ de l'axe des heures.
@visibleForTesting
double axisLeftInset() => kChannelWidth;

/// Bouton du bandeau d'axe.
///
/// Les trois boutons occupent la bande des noms de chaînes, 144 px. Un
/// `IconButton` fait 40 px en densité compacte, et ne respecte pas
/// `tightFor` : il faut donc compter 3 × 40 = 120 px et ne rien ajouter à
/// côté. C'est pour cela que le facteur de zoom vit dans les info-bulles
/// plutôt qu'en texte à côté des boutons.
///
/// C'est un vrai `IconButton`, et non un `InkWell` nu : l'info-bulle,
/// l'ondulation et surtout le **focus** en dépendent. Un `InkWell` ne reçoit
/// pas le focus, et les boutons devenaient inatteignables au D-pad — le zoom
/// était alors inutilisable à la télécommande.
class _AxisButton extends StatelessWidget {
  const _AxisButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color = Colors.white70,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      color: color,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
    );
  }
}

/// Programme préparé pour le rendu (positions précalculées une fois).
///
/// [left] et [width] sont calculés à la construction du cache, à partir de
/// l'heure réelle (`startTime`/`durationMinutes`) et de l'origine de la
/// journée. La grille a un temps quantifié les programmes en créneaux de 2 h :
/// tous ceux d'un même créneau recevaient la MÊME abscisse et se masquaient
/// les uns les autres. On revient à un placement exact.
class _RenderProgram {
  final EPGProgram program;

  /// Abscisse du bord gauche, en px, depuis l'origine de la journée.
  /// Négative pour un programme commencé la veille.
  final double left;

  /// Largeur réelle en px : `durée × échelle`, plancher [kMinProgramBlockWidth].
  final double width;

  final bool isLive;
  final bool replayable;

  const _RenderProgram({
    required this.program,
    required this.left,
    required this.width,
    required this.isLive,
    this.replayable = false,
  });
}

/// Ligne « maintenant », peinte en surcouche sur toute la hauteur de la grille.
///
/// ## Pourquoi une surcouche
///
/// La grille est virtualisée : une chaîne = un `CustomPaint`. La ligne était
/// tracée dans chaque canvas, donc 628 fois, et s'arrêtait au bord de chaque
/// ligne — elle se lisait comme une colonne de tirets, pas comme un repère
/// temporel. Une seule instance, au-dessus de tout, donne une vraie ligne
/// verticale continue, et traverse aussi la colonne des noms : c'est le repère
/// qui relie l'heure de la frise aux programmes de toutes les chaînes.
///
/// ## Les deux rouges
///
/// Un rouge clair (`#FF5252`) pour la ligne elle-même et un rouge sombre
/// (`#8E0000`) pour son halo : le halo donne l'épaisseur sans épaissir le trait,
/// et le contraste reste lisible sur un programme en cours (fond violet) comme
/// sur un bloc de trou (fond quasi transparent).
/// Abscisse écran de la ligne « maintenant », en px logiques.
///
/// Fonction pure, extraite du `build` pour être testable : là, aucune
/// assertion ne pouvait l'atteindre.
///
/// La formule est `channelWidth + timePixels - offset`, SANS gouttière.
/// L'overlay est dans un `Positioned.fill` qui commence au bord gauche de
/// l'écran, donc il doit sauter les 140 px de la colonne des noms — et rien
/// d'autre. Les programmes sont dessinés dans un canvas qui démarre lui aussi
/// après les 140 px exacts. Ajouter 4 px ici décalait la ligne vers la droite
/// de 4 px par rapport aux programmes qu'elle marque : 1 min à 4 px/min, et
/// 4 min à 1 px/min.
@visibleForTesting
double nowLineX({
  required double channelWidth,
  required double timePixels,
  required double offset,
}) =>
    channelWidth + timePixels - offset;

class _NowLineOverlay extends StatelessWidget {
  const _NowLineOverlay({
    required this.controller,
    required this.channelWidth,
  });

  /// Source unique de vérité pour l'heure, l'échelle et le décalage.
  ///
  /// L'overlay lisait ses propres champs (`gridStartTime`, `pixelsPerMinute`,
  /// `horizontalOffset`) alors que la frise lit le contrôleur. Les deux
  /// divergeaient : le zoom change `pixelsPerMinute` dans le contrôleur, et le
  /// défilement écrit dans `gridOffset` — donc la ligne rouge n'était plus
  /// alignée sur la pastille de l'heure réelle. En repassant par le contrôleur,
  /// les deux affichages ne peuvent plus diverger.
  final EpgTimelineController controller;

  /// Largeur de la colonne des noms, traversée par la ligne.
  final double channelWidth;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: controller.gridOffset,
      builder: (context, offset, _) {
        return ValueListenableBuilder<DateTime>(
          valueListenable: controller.now,
          builder: (context, now, _) {
            final x = nowLineX(
              channelWidth: channelWidth,
              timePixels: controller.timeToPixels(now),
              offset: offset,
            );

            // Mesure du décalage, et non plus supposition.
            //
            // « La ligne rouge n'est pas à la bonne heure » a resistsé à une
            // correction : la ligne et la frise partageaient déjà le même
            // contrôleur. Reste à savoir de combien elles divergent, et dans
            // quel sens — sans nombre, tout correctif suivant serait une
            // hypothèse de plus.
            //
            // On relit l'heure que la frise affichera à cette position x, via
            // la conversion aller-retour, en retirant la colonne des noms que
            // la ligne franchit. La gouttière n'est ni ajoutée ni retranchée :
            // elle n'existe pas dans le layout, et la prendre ici rendait la
            // mesure incohérente avec le tracé.
            final axisTime = controller.pixelsToTime(
              x - channelWidth + offset,
            );
            final drift = now.difference(axisTime).inSeconds;
            if (drift.abs() >= 30) {
              LoggerService.instance.info(
                'EPG : ligne « maintenant » décalée de ${drift}s — '
                'axe=$axisTime grille=$now '
                '(décalage=$offset, colonne=$channelWidth, '
                'densité=${controller.pixelsPerMinuteValue})',
                tag: 'epg',
              );
            }

            return ExcludeSemantics(
              child: CustomPaint(
                painter: _NowLinePainter(x),
                // La ligne est un repère, jamais une cible : sans `IgnorePointer`
                // elle absorberait les appuis destinés aux programmes.
                size: Size.infinite,
              ),
            );
          },
        );
      },
    );
  }
}

class _NowLinePainter extends CustomPainter {
  _NowLinePainter(this.x);

  final double x;

  /// Rouge du trait, lisible sur fond sombre comme sur fond violet.
  static const Color _core = Color(0xFFFF5252);

  /// Rouge du halo : même teinte, faible luminance.
  static const Color _halo = Color(0xFF8E0000);

  @override
  void paint(Canvas canvas, Size size) {
    if (x < -8 || x > size.width + 8) return;

    // Halo sombre : donne l'épaisseur perçue sans épaissir le trait.
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = _halo
        ..strokeWidth = 5,
    );
    // Trait clair au centre.
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = _core
        ..strokeWidth = 2,
    );
    // Pointe en haut : indique le haut de la grille (l'heure la plus ancienne).
    final tip = Path()
      ..moveTo(x, 0)
      ..lineTo(x - 5, -0)
      ..lineTo(x + 5, 0)
      ..close();
    canvas.drawPath(tip, Paint()..color = _core);
  }

  @override
  bool shouldRepaint(covariant _NowLinePainter old) => old.x != x;
}

/// Peintre haute performance pour la grille EPG (canvas unique).
/// Repeint uniquement sur les notifiers reçus (hover, "now", scroll), pas à
/// chaque build du widget.
class _EpgGridPainter extends CustomPainter {
  final List<String> channels;
  final DateTime gridStartTime;
  final double pixelsPerMinute;
  final double rowHeight;
  final double channelWidth;
  final double viewportWidth;
  final ValueListenable<double>? horizontalOffset;
  final ValueListenable<Offset?>? touchPosition;

  /// Notifié quand le cache de rendu est reconstruit.
  ///
  /// Écouté via `repaint` : c'est lui qui fait repeindre une ligne déjà
  /// construite, donc déjà displayée avec une map périmée.
  final ValueListenable<int>? dataRevision;

  /// Index de la chaîne peinte par CE canvas.
  ///
  /// Une ligne = un canvas. Le peintre ne boucle donc plus sur toutes les
  /// chaînes : c'est la virtualisation qui rend la grille affichable, et c'est
  /// elle qui supprime l'empreinte mémoire délirante.
  final int channelIndex;

  /// Libellé « en direct », résolu par l'écran (`epgLiveNow`).
  ///
  /// Le painter n'a pas de `BuildContext` : le texte est lu dans le `build` puis
  /// passé ici, pour que l'indicateur suive la langue de l'application.
  final String liveLabel;

  /// Lecture différée du cache de rendu.
  ///
  /// Le painter ne reçoit pas la map : il la lit au moment du paint. Capturer
  /// la map à la construction figeait le premier état (vide) dans chaque ligne
  /// déjà displayée, et aucun rebuild ne venait la corriger.
  final Map<String, List<_RenderProgram>> Function() renderCacheOf;

  _EpgGridPainter({
    required this.channels,
    required this.renderCacheOf,
    required this.gridStartTime,
    required this.pixelsPerMinute,
    required this.rowHeight,
    required this.channelWidth,
    required this.viewportWidth,
    required this.channelIndex,
    required this.liveLabel,
    required this.horizontalOffset,
    required this.touchPosition,
    required this.dataRevision,
    super.repaint,
  });

  /// Range de rendu : petit dépassement autour du viewport pour garder les
  /// bordures des barres à cheval sur le bord visible.
  (double, double) get _cullRange {
    final offset = horizontalOffset?.value ?? 0.0;
    // Marge exprimée en TEMPS, pas en pixels.
    //
    // Fixée à 240 px, elle valait 1 h au zoom par défaut (4 px/min) mais 4 h au
    // zoom le plus dézoomé (1 px/min) : le comportement visible changeait avec
    // le zoom. Une heure de marge donne la même garantie partout — 240 px à
    // 4 px/min, 60 px à 1 px/min.
    final margin = cullMarginFor(pixelsPerMinute);
    return (offset - margin, offset + viewportWidth + margin);
  }

  /// Programme sous le pointeur (highlight seul, sans rebuild du widget).
  ///
  /// Le pointeur est exprimé dans le repère de CE canvas (une ligne), donc on
  /// ne cherche que parmi les programmes de cette chaîne.
  _RenderProgram? _resolveHovered(Offset? pos) {
    if (pos == null) return null;
    if (pos.dy < 0 || pos.dy > rowHeight) return null;
    final ch = channels[channelIndex];
    // `pos.dx` est relatif au canvas de la ligne (tranche visible), alors que
    // `rp.left` est ABSOLU depuis minuit : sans cette conversion, la
    // surbrillance suivait le programme situé à la même abscisse près de
    // minuit au lieu de celui sous le pointeur.
    final absolute = pos.dx + (horizontalOffset?.value ?? 0.0);
    for (final rp in renderCacheOf()[ch] ?? const <_RenderProgram>[]) {
      if (absolute >= rp.left && absolute < rp.left + rp.width) {
        return rp;
      }
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0D0E12),
    );

    // Lignes de séparation horizontales (entre chaînes)
    // Séparateur entre deux lignes : sur un canvas par ligne, c'est le bord
    // haut qui sépare celle-ci de la précédente.
    final linePaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), linePaint);

    final (cullMin, cullMax) = _cullRange;
    // Positions absolues dans la journée (0 → 5760 px) : le canvas ne montre
    // que la tranche visible, donc on les ramène à l'écran via `screenXFor`.
    final screenOffset = horizontalOffset?.value ?? 0.0;
    final hovered = _resolveHovered(touchPosition?.value);

    final ch = channels[channelIndex];
    final programs = renderCacheOf()[ch] ?? const <_RenderProgram>[];
    {
      final y = 2.0;
      final h = rowHeight - 4;

      for (final rp in programs) {
        // Culling : on ne dessine/layout que les barres visibles dans le
        // viewport + marge (évite ~des milliers de TextPainter hors écran).
        final left = rp.left;
        final width = rp.width;
        if (left + width < cullMin || left > cullMax) continue;

        // Abscisse ÉCRAN du bord gauche du bloc : partagée par le fond, le
        // titre et le badge REPLAY (source unique `screenXFor`).
        final screenLeft = screenXFor(left, screenOffset);

        final isHovered = rp == hovered;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(screenLeft, y, width, h),
          const Radius.circular(6),
        );

        // Un bloc de trou n'est pas un programme : il doit se lire comme une
        // absence de données, pas comme une émission sans titre. Fond vide,
        // bordure discrète, texte attenué.
        final isDummy = rp.program.isDummy;
        final bgPaint = Paint()
          ..color = isDummy
              ? const Color(0x00000000)
              : rp.isLive
                  ? const Color(0xFF2D224D)
                  : (isHovered
                      ? const Color(0xFF2A2F3A)
                      : const Color(0xFF1C1F26));
        if (isDummy) {
          canvas.drawRRect(
            rect,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.02)
              ..style = PaintingStyle.fill,
          );
        } else {
          canvas.drawRRect(rect, bgPaint);
        }

        final borderPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = isDummy
              ? Colors.white10.withValues(alpha: 0.4)
              : rp.isLive
                  ? const Color(0xFF8B5CF6)
                  : (isHovered
                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.5)
                      : Colors.white10);
        if (isDummy) {
          // Bordure en pointillés : le motif dit « il n'y a rien ici » sans
          // competing avec les programmes voisins.
          _drawDashedRect(canvas, rect, borderPaint);
        } else {
          canvas.drawRRect(rect, borderPaint);
        }

        // Contenu du bloc : pastille « en direct », puis éventuellement son
        // libellé, puis le titre — tous posés SÉQUENTIELLEMENT depuis la
        // gauche. C'est la correction du défaut d'origine : « DIRECT » et le
        // titre partageaient la même abscisse (`rp.left + 6`) et se
        // recouvraient, le titre passant toujours au-dessus.
        var contentLeft = screenLeft + kTitlePaddingH;
        if (rp.isLive && !isDummy) {
          final centerY = y + h / 2;
          canvas.drawCircle(
            Offset(contentLeft + kLiveDotRadius, centerY),
            kLiveDotRadius,
            Paint()..color = kLiveIndicatorColor,
          );
          contentLeft += kLiveDotRadius * 2 + kLiveDotGap;
          // Le libellé n'est écrit que si le bloc peut le porter sans écraser
          // le titre : en dessous de [kLiveLabelMinWidth], la pastille suffit à
          // dire « en direct ».
          if (rp.width >= kLiveLabelMinWidth) {
            final livePainter = TextPainter(
              text: TextSpan(
                text: liveLabel,
                style: const TextStyle(
                  color: kLiveIndicatorColor,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
              textDirection: TextDirection.ltr,
              maxLines: 1,
            )..layout();
            livePainter.paint(
              canvas,
              Offset(contentLeft, centerY - livePainter.height / 2),
            );
            contentLeft += livePainter.width + kLiveDotGap;
          }
        }

        // Titre du programme, adapté à la place restante.
        //
        // Le seuil est dérivé de la marge intérieure : il faut de la place pour
        // au moins quelques caractères, sinon n'écrire rien. L'ancien
        // `width > 26` produisait deux défauts opposés — du texte broyé entre
        // 26 et 38 px, et un bloc totalement vide en dessous, ce qui se lisait
        // comme une description disparue au défilement.
        final textMaxWidth =
            screenLeft + rp.width - kTitlePaddingH - contentLeft;
        if (textMaxWidth >= kTitleMinReadableWidth) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: rp.program.title,
              style: TextStyle(
                color: isDummy ? Colors.white24 : Colors.white70,
                fontWeight: isDummy ? FontWeight.w400 : FontWeight.bold,
                fontSize: 10,
              ),
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
            ellipsis: '…',
          );
          textPainter.layout(maxWidth: textMaxWidth);
          textPainter.paint(
            canvas,
            Offset(contentLeft, y + (h - textPainter.height) / 2),
          );
        }

        // Badge "replay" pour les programmes terminés des chaînes DVR
        if (rp.replayable && rp.width > 34) {
          final replayPainter = TextPainter(
            text: const TextSpan(
              text: '↺ REPLAY',
              style: TextStyle(
                color: Color(0xFF6EE7B7),
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          replayPainter.layout();
          replayPainter.paint(
            canvas,
            Offset(
              screenLeft + rp.width - replayPainter.width - 6,
              y + h - 14,
            ),
          );
        }
      }

      // Chaîne sans aucun programme sur la fenêtre affichée : on l'annonce
      // explicitement.
      //
      // Laissait la ligne entièrement vide, ce qui est ambigu : impossible de
      // distinguer « cette chaîne n'a pas d'EPG » d'un bug d'affichage ou
      // d'un décalage de grille. Un libellé rend l'information lisible et
      // évite au lecteur de croire que l'application est cassée.
      if (programs.isEmpty) {
        final emptyPainter = TextPainter(
          text: const TextSpan(
            text: 'Aucune donnée de programme',
            style: TextStyle(
              color: Color(0xFF5A6273),
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: (cullMax - cullMin).clamp(0.0, size.width));
        if (cullMin <= 8 && emptyPainter.width > 0) {
          emptyPainter.paint(
              canvas, Offset(8, y + (h - emptyPainter.height) / 2),);
        }
      }
    }

    // La ligne « maintenant » n'est PAS tracée ici.
    //
    // Une ligne = un canvas, donc ce tracé était répété 628 fois et s'interrompait
    // aux bords de chaque ligne : elle se lisait comme une suite de tirets sans
    // signification. Elle est désormais peinte une seule fois, par-dessus toute la
    // grille, dans `_NowLineOverlay`.
  }

  /// Rectangle à bordure pointillée, pour les blocs de trou.
  ///
  /// `Paint` n'a pas de style pointillé : on trace donc le chemin segment par
  /// segment. Le motif dit « il n'y a rien ici » sans se confondre avec les
  /// programmes voisins.
  void _drawDashedRect(Canvas canvas, RRect rect, Paint paint) {
    final path = Path()..addRRect(rect.deflate(0.5));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 4).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + 3;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EpgGridPainter old) {
    // La map n'est plus capturée : c'est [dataRevision] qui arbitre, et il est
    // déjà écouté via `repaint`. On ne compare donc plus l'identité d'une map
    // — deux painters successifs lisaient la même instance, et l'égalité
    // disait « rien à repeindre » alors que son contenu venait de changer.
    if (old.dataRevision != dataRevision) return true;
    return old.gridStartTime != gridStartTime ||
        old.pixelsPerMinute != pixelsPerMinute ||
        old.viewportWidth != viewportWidth ||
        old.channelIndex != channelIndex;
  }
}
