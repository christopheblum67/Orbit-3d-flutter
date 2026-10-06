import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerScaleEvent;
import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/core/utils/epg_day_window.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/features/epg/replay_utils.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_timeline.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_timeline_controller.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_mini_program_bar.dart';

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
      // La grille fait autorité sur la géométrie, et l'écrit dans le
      // contrôleur. Sans cela, les programmes étaient posés avec
      // `_gridStartTime` / `_pixelsPerMinute` tandis que la ligne « maintenant »
      // et la frise lisaient les valeurs du contrôleur : deux référentiels
      // cohabitant, la ligne rouge ne tombait plus sur l'heure annoncée par
      // l'axe, et l'écart grandissait avec la distance au début de la journée.
      _timelineController.gridStartTime = _gridStartTime;
      _timelineController.pixelsPerMinute = _pixelsPerMinute;
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
      _scrollToCurrentTime();
    });
  }

  @override
  void didUpdateWidget(covariant EpgGrid2DView old) {
    super.didUpdateWidget(old);
    _pixelsPerMinute = widget.pixelsPerMinute;
    if (widget.gridStartTime != null &&
        widget.gridStartTime != old.gridStartTime) {
      _gridStartTime = widget.gridStartTime!;
      _timelineController.gridStartTime = _gridStartTime;
    }
    _timelineController.pixelsPerMinute = _pixelsPerMinute;
    _rebuildRenderCache();
  }

  @override
  void dispose() {
    _timer.cancel();
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

    const rowHeight = 60.0;
    const rowStride = rowHeight + 2;
    final viewport = _verticalController.position.viewportDimension;
    final top = index * rowStride;
    final bottom = top + rowHeight;
    final current = _verticalController.offset;

    if (top >= current && bottom <= current + viewport) return;

    _syncingVertical = true;
    try {
      // Centré quand la ligne est entièrement hors écran, aligné en haut
      // quand elle est seulement tronquée : dans ce cas, la centrer ferait
      // passer le contexte uselessement.
      final target = top < current || bottom > current + viewport
          ? (top - (viewport - rowHeight) / 2).clamp(0.0, _maxVerticalOffset)
          : top;
      _verticalController.jumpTo(target);
      _namesVerticalController.jumpTo(target);
    } finally {
      _syncingVertical = false;
    }
  }

  double get _maxVerticalOffset {
    final content = widget.channels.length * (60.0 + 2);
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

  /// Bornes du zoom, en px/min.
  ///
  /// En bas, 2,2 px/min : la grille montre alors environ 7 heures dans la
  /// largeur de l'écran. Un programme de 30 min occupe 66 px — son titre tient
  /// sur un mot ou deux, ce qui suffit à l'identifier. En haut, 14 px/min :
  /// au-delà, une heure dépasse largement l'écran et le défilement devient le
  /// seul moyen de lire l'axe, ce qui n'apporte rien sur un téléphone.
  static const double _minPixelsPerMinute = 2.2;
  static const double _maxPixelsPerMinute = 14.0;

  /// Paliers du zoom, pour que les boutons `−` et `+` restent réversibles.
  ///
  /// Les deux premiers paliers sont plus serrés qu'avant : à 2,2 px/min une
  /// heure occupe 132 px, ce qui fait tenir environ 7 heures dans la largeur
  /// utile d'un téléphone au lieu de 3 h 45. Presque le double : c'est ce qui
  /// permet de lire une soirée entière d'un coup d'œil, et d'afficher plus de
  /// chaînes en même temps qu'on zoome pour voir le détail.
  static const List<double> _zoomSteps = [
    2.2,
    3.0,
    4.0,
    5.0,
    6.5,
    8.5,
    11.0,
    14.0,
  ];

  double get _zoomFactor => _pixelsPerMinute / _minPixelsPerMinute;

  /// Applique un facteur de zoom en gardant l'heure CIBLE immobile.
  ///
  /// [anchorX] est la position écran à conserver : sans cette correction, un
  /// zoom recentrait simplement sur le bord gauche, et la minute que l'on
  /// regardait disparaissait de l'écran. On reprojette donc le décalage pour
  /// que l'heure sous [anchorX] y reste.
  void _zoomBy(double factor, double anchorX) {
    final target = (_pixelsPerMinute * factor).clamp(
      _minPixelsPerMinute,
      _maxPixelsPerMinute,
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
    for (final step in _zoomSteps) {
      if (up && step > current + 0.01) return step / current;
      if (!up && step < current - 0.01) return step / current;
    }
    return 1.0;
  }

  double _getOffsetForTime(DateTime time) {
    final diffInMinutes = time.difference(_gridStartTime).inSeconds / 60.0;
    return diffInMinutes * _pixelsPerMinute;
  }

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
    final ppm = _pixelsPerMinute;
    final now = DateTime.now();
    for (final ch in widget.channels) {
      final programs = widget.epgData[ch] ?? const <EPGProgram>[];
      final channelHasReplay = widget.replayChannels.contains(ch);
      cache[ch] = [
        for (final p in programs)
          _RenderProgram(
            program: p,
            left: _getOffsetForTime(p.startTime),
            width: _clampWidth(p.durationMinutes * ppm - 2.0),
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
      var withPrograms = 0;
      var minLeft = double.infinity;
      var maxLeft = double.negativeInfinity;
      for (final rp in cache.values) {
        if (rp.isEmpty) continue;
        withPrograms++;
        for (final p in rp) {
          if (p.left < minLeft) minLeft = p.left;
          if (p.left + p.width > maxLeft) maxLeft = p.left + p.width;
        }
      }
      LoggerService.instance.info(
        'EPG rendu: ${cache.length} lignes, $withPrograms avec programmes, '
        'étendue $minLeft..${maxLeft == double.negativeInfinity ? 0 : maxLeft} '
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

  static double _clampWidth(double raw) => raw < 40.0 ? 40.0 : raw;

  /// Appui court (peu de déplacement, < 400 ms) sur la grille : ouvre le
  /// programme sous le doigt. Un appui hors programme sélectionne la chaîne
  /// de la ligne (comme un appui sur la colonne des noms).
  void _consumeGridTap(Offset pos) {
    final down = _tapDownPos;
    final downTime = _tapDownTime;
    if (down == null || downTime == null) return;
    if ((pos - down).distance > 12) return; // c'est un scroll, pas un tap
    if (DateTime.now().difference(downTime).inMilliseconds >= 400) return;

    const rowHeight = 60.0;
    final channelIndex = (pos.dy / rowHeight).floor();
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

  _RenderProgram? _programAt(double dx, String channelName) {
    for (final rp in _renderCache[channelName] ?? const <_RenderProgram>[]) {
      if (dx >= rp.left && dx <= rp.left + rp.width) return rp;
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
    const rowHeight = 60.0;
    const channelWidth = 140.0;

    /// Abscisse à laquelle commence l'axe du temps, en pixels depuis la
    /// gauche de la grille.
    ///
    /// Colonnes des noms (140) plus gouttière (4). Cette valeur doit servir
    /// aux TROIS emplacements qui partagent le même repère : la bande de
    /// l'axe, la position de la ligne « maintenant », et la lecture d'une
    /// abscisse en heure. C'était la duplication de `channelWidth` partout,
    /// sans la gouttière, qui produisait un décalage de quelques pixels —
    /// et l'axe, plus loin encore, un décalage de dizaines de minutes.
    const gridLeftInset = channelWidth + 4.0;

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
          // de chaînes, large de `gridLeftInset` — et l'axe s'ouvre juste
          // après, aligné sur la grille.
          Container(
            height: 44,
            color: const Color(0xFF0D0E12),
            child: Row(
              children: [
                SizedBox(
                  width: gridLeftInset,
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
                        itemExtent: rowHeight,
                        itemCount: widget.channels.length,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          final ch = widget.channels[index];
                          return Container(
                            height: rowHeight,
                            color: const Color(0xFF12141C),
                            margin: const EdgeInsets.only(bottom: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () {
                                _timelineController.setTargetedChannel(ch);
                                widget.onChannelTap?.call(ch);
                              },
                              onLongPress: () =>
                                  widget.onChannelLongPress?.call(ch),
                              child: Text(
                                ch,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                          return Listener(
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
                              // Glissement horizontal : déplace la journée au lieu
                              // de la faire défiler. Le contrôleur n'est plus
                              // nécessaire, et il ne pouvait pas être partagé.
                              final dx = event.localPosition.dx - _pointerX;
                              if (dx.abs() >= 1) {
                                _setHorizontalOffset(
                                    _horizontalOffset.value - dx);
                                _pointerX = event.localPosition.dx;
                              }
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
                                itemExtent: rowHeight,
                                itemCount: widget.channels.length,
                                itemBuilder: (context, index) =>
                                    RepaintBoundary(
                                  child: CustomPaint(
                                    size: Size(viewportWidth, rowHeight),
                                    painter: _EpgGridPainter(
                                      channels: widget.channels,
                                      renderCacheOf: () => _renderCache,
                                      gridStartTime: _gridStartTime,
                                      pixelsPerMinute: _pixelsPerMinute,
                                      rowHeight: rowHeight,
                                      channelWidth: channelWidth,
                                      viewportWidth: viewportWidth,
                                      channelIndex: index,
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

/// Gouttière entre la colonne des noms et la grille, en pixels.
///
/// C'est cette valeur qui manquait dans le calcul de la position de la ligne
/// « maintenant » et dans la lecture inverse de l'abscisse. Elle est déclarée
/// une fois et réutilisée : jamais recalculée à la main.
const double kGridLeftInset = 4.0;

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

/// Programme préparé pour le rendu (positions précalculées).
class _RenderProgram {
  final EPGProgram program;
  final double left;
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
            final x = channelWidth +
                kGridLeftInset +
                controller.timeToPixels(now) -
                offset;

            // Mesure du décalage, et non plus supposition.
            //
            // « La ligne rouge n'est pas à la bonne heure » a resistsé à une
            // correction : la ligne et la frise partageaient déjà le même
            // contrôleur. Reste à savoir de combien elles divergent, et dans
            // quel sens — sans nombre, tout correctif suivant serait une
            // hypothèse de plus.
            //
            // On relit l'heure que la frise affichera à cette position x, via
            // la même conversion aller-retour, en retirant la colonne des noms
            // que la ligne franchit en plus.
            final axisTime = controller.pixelsToTime(
              x - channelWidth - kGridLeftInset + offset,
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
    required this.horizontalOffset,
    required this.touchPosition,
    required this.dataRevision,
    super.repaint,
  });

  /// Range de rendu : petit dépassement autour du viewport pour garder les
  /// bordures des barres à cheval sur le bord visible.
  (double, double) get _cullRange {
    final offset = horizontalOffset?.value ?? 0.0;
    // Marge HORIZONTALE. La valeur utilisée auparavant était `rowHeight`, soit
    // une grandeur verticale (60 px), utilisée comme marge horizontale : sans
    // conséquence visible à l'arrêt, mais pendant un défilement les programmes
    // qui entraient dans le viewport étaient écartés puis Drawing, donc rien
    // n'apparaissait tant qu'on ne s'arrêtait pas pile.
    const margin = 240.0;
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
    for (final rp in renderCacheOf()[ch] ?? const <_RenderProgram>[]) {
      if (pos.dx >= rp.left && pos.dx <= rp.left + rp.width) {
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
    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), linePaint);

    final (cullMin, cullMax) = _cullRange;
    // Translation : les positions sont absolues dans la journée (0 → 5760 px),
    // le canvas ne montre que la tranche visible.
    final shift = -(horizontalOffset?.value ?? 0.0);
    final hovered = _resolveHovered(touchPosition?.value);

    final ch = channels[channelIndex];
    final programs = renderCacheOf()[ch] ?? const <_RenderProgram>[];
    {
      final y = 2.0;
      final h = rowHeight - 4;

      for (final rp in programs) {
        // Culling : on ne dessine/layout que les barres visibles dans le
        // viewport + marge (évite ~des milliers de TextPainter hors écran).
        if (rp.left + rp.width < cullMin || rp.left > cullMax) continue;

        final isHovered = rp == hovered;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(rp.left + shift, y, rp.width, h),
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

        // Texte titre (clippé dans la barre, seulement si assez de largeur)
        if (rp.width > 26) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: rp.program.title,
              style: TextStyle(
                color: isDummy
                    ? Colors.white24
                    : rp.isLive
                        ? Colors.white
                        : Colors.white70,
                fontWeight: isDummy ? FontWeight.w400 : FontWeight.bold,
                fontSize: 10,
              ),
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
            ellipsis: '…',
          );
          textPainter.layout(maxWidth: rp.width - 12);
          textPainter.paint(
            canvas,
            Offset(rp.left + 6, y + (h - textPainter.height) / 2),
          );
        }

        // Indicateur "EN DIRECT"
        if (rp.isLive) {
          final livePainter = TextPainter(
            text: const TextSpan(
              text: '● DIRECT',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          livePainter.layout();
          livePainter.paint(canvas, Offset(rp.left + 6, y + h - 14));
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
              rp.left + rp.width - replayPainter.width - 6,
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
              canvas, Offset(8, y + (h - emptyPainter.height) / 2));
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
