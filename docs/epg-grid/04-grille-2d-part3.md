# EPG — grille : 4. la grille 2D

> **Partie 3/5**

> Fiche générée depuis le code source — extraction fidèle, commentaires compris. Chaque bloc est limité à 200 lignes pour rester copiable sans saturer le presse-papier.

Sources : `lib/features/epg/widgets/epg_grid_2d_view.dart`, `lib/features/epg/widgets/epg_row_diagnostics.dart`

### 4.1 `EpgGrid2dView` — la grille — suite 3/4

`lib/features/epg/widgets/epg_grid_2d_view.dart` · lignes 801–1200

#### `lib/features/epg/widgets/epg_grid_2d_view.dart` · lignes 801–1000 · partie 1/2

```dart
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
```

#### `lib/features/epg/widgets/epg_grid_2d_view.dart` · lignes 1001–1200 · partie 2/2

```dart
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
```
