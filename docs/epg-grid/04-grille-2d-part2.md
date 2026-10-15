# EPG — grille : 4. la grille 2D

> **Partie 2/5**

> Fiche générée depuis le code source — extraction fidèle, commentaires compris. Chaque bloc est limité à 200 lignes pour rester copiable sans saturer le presse-papier.

Sources : `lib/features/epg/widgets/epg_grid_2d_view.dart`, `lib/features/epg/widgets/epg_row_diagnostics.dart`

### 4.1 `EpgGrid2dView` — la grille — suite 2/5

`lib/features/epg/widgets/epg_grid_2d_view.dart` · lignes 401–800

#### `lib/features/epg/widgets/epg_grid_2d_view.dart` · lignes 401–600 · partie 1/2

```dart
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
```

#### `lib/features/epg/widgets/epg_grid_2d_view.dart` · lignes 601–800 · partie 2/2

```dart
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
```
