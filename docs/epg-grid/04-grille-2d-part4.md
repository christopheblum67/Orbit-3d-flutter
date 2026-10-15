# EPG — grille : 4. la grille 2D

> **Partie 4/5**

> Fiche générée depuis le code source — extraction fidèle, commentaires compris. Chaque bloc est limité à 200 lignes pour rester copiable sans saturer le presse-papier.

Sources : `lib/features/epg/widgets/epg_grid_2d_view.dart`, `lib/features/epg/widgets/epg_row_diagnostics.dart`

### 4.1 `EpgGrid2dView` — la grille — suite 4/5

`lib/features/epg/widgets/epg_grid_2d_view.dart` · lignes 1201–1600

#### `lib/features/epg/widgets/epg_grid_2d_view.dart` · lignes 1201–1400 · partie 1/2

```dart
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
```

#### `lib/features/epg/widgets/epg_grid_2d_view.dart` · lignes 1401–1600 · partie 2/2

```dart
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
```
