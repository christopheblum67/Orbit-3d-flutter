import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_timeline.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_timeline_controller.dart';
import 'package:orbit_3d_flutter/features/epg/widgets/epg_mini_program_bar.dart';

/// Grille EPG haute performance avec CustomPainter (canvas unique).
///
/// Règles anti-ANR / anti-crash :
/// - **Aucun `setState` pendant les gestes** : hover, ligne "maintenant" et
///   défilement horizontal repaintent via des `ValueNotifier` écoutés par le
///   painter (`repaint:`), pas via un rebuild du widget (l'ancien code
///   rebuildait grille + en-têtes + cache à CHAQUE `onPointerMove`, saturant
///   le thread UI des box TV → freeze/ANR).
/// - **Cache de rendu recalculé uniquement si les données changent**
///   (signature channels + nombre de programmes + zoom), pas à chaque build.
/// - **Culling** : seules les barres visibles dans le viewport sont dessinées
///   (pas de `TextPainter` pour les programmes hors écran).
class EpgGrid2DView extends StatefulWidget {
  final List<String> channels;
  final Map<String, List<EPGProgram>> epgData;
  final DateTime? gridStartTime;
  final double pixelsPerMinute;
  final Function(EPGProgram)? onProgramTap;
  final Function(String)? onChannelTap;
  final EpgTimelineController? timelineController;

  const EpgGrid2DView({
    super.key,
    required this.channels,
    required this.epgData,
    this.gridStartTime,
    this.pixelsPerMinute = 4.0,
    this.onProgramTap,
    this.onChannelTap,
    this.timelineController,
  });

  @override
  State<EpgGrid2DView> createState() => _EpgGrid2DViewState();
}

class _EpgGrid2DViewState extends State<EpgGrid2DView> {
  late Timer _timer;
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  late EpgTimelineController _timelineController;
  bool _ownsTimelineController = false;

  // Repaints ciblés (pas de rebuild du widget) :
  final ValueNotifier<Offset?> _hoverPosition = ValueNotifier<Offset?>(null);
  final ValueNotifier<double> _horizontalOffset = ValueNotifier<double>(0);

  late DateTime _gridStartTime;
  late double _pixelsPerMinute;

  // Cache des programmes rendus (index par channel -> liste de _RenderProgram)
  Map<String, List<_RenderProgram>> _renderCache = {};
  int _dataSignature = -1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _gridStartTime = widget.gridStartTime ??
        DateTime(now.year, now.month, now.day, now.hour - 1);
    _pixelsPerMinute = widget.pixelsPerMinute;

    if (widget.timelineController != null) {
      _timelineController = widget.timelineController!;
    } else {
      _timelineController = EpgTimelineController(
        gridStartTime: _gridStartTime,
        pixelsPerMinute: _pixelsPerMinute,
      );
      _ownsTimelineController = true;
    }
    _timelineController.scheduledJump.addListener(_consumeJump);

    // Mise à jour de la ligne "maintenant" sans rebuild du widget.
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _timelineController.now.value = DateTime.now();
    });

    _horizontalController.addListener(() {
      if (_horizontalController.hasClients) {
        _horizontalOffset.value = _horizontalController.offset;
        _timelineController.onGridScroll(_horizontalController.offset);
      }
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
    if (_ownsTimelineController) {
      _timelineController.dispose();
    }
    _hoverPosition.dispose();
    _horizontalOffset.dispose();
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  void _consumeJump() {
    final target = _timelineController.scheduledJump.value;
    if (target == null) return;
    _timelineController.clearJump();
    _scrollToTime(target);
  }

  void _scrollToTime(DateTime time) {
    final offset = _getOffsetForTime(time) - 120;
    if (_horizontalController.hasClients) {
      _horizontalController.jumpTo(
        offset.clamp(0.0, _horizontalController.position.maxScrollExtent),
      );
    }
  }

  void _scrollToCurrentTime() {
    final offset = _getOffsetForTime(DateTime.now()) - 120;
    if (_horizontalController.hasClients) {
      _horizontalController.jumpTo(
        offset.clamp(0.0, _horizontalController.position.maxScrollExtent),
      );
    }
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
      hash = (hash * 31 + (widget.epgData[ch]?.length ?? 0)) & 0x7fffffff;
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

    final cache = <String, List<_RenderProgram>>{};
    final ppm = _pixelsPerMinute;
    for (final ch in widget.channels) {
      final programs = widget.epgData[ch] ?? const <EPGProgram>[];
      cache[ch] = [
        for (final p in programs)
          _RenderProgram(
            program: p,
            left: _getOffsetForTime(p.startTime),
            width: _clampWidth(p.durationMinutes * ppm - 2.0),
            isLive: p.isLive,
          ),
      ];
    }
    _renderCache = cache;
  }

  static double _clampWidth(double raw) => raw < 40.0 ? 40.0 : raw;

  @override
  Widget build(BuildContext context) {
    _rebuildRenderCache();

    final totalWidth = (24 * 60 * _pixelsPerMinute).clamp(1440.0, 2880.0);
    const rowHeight = 60.0;
    const channelWidth = 140.0;
    final totalHeight = widget.channels.length * rowHeight;

    return Container(
      color: const Color(0xFF0D0E12),
      child: Column(
        children: [
          // Frise temporelle + barre de navigation
          Container(
            height: 44,
            color: const Color(0xFF0D0E12),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: channelWidth,
                  alignment: Alignment.center,
                  child: const Text(
                    'En Direct',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  tooltip: '-1h',
                  color: Colors.white70,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    final t = _timelineController
                        .pixelsToTime(_timelineController.gridOffset.value)
                        .add(const Duration(hours: -1));
                    _timelineController.jumpTo(t);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.access_time, size: 18),
                  tooltip: 'Maintenant',
                  color: const Color(0xFF8B5CF6),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    _timelineController.jumpTo(DateTime.now());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  tooltip: '+1h',
                  color: Colors.white70,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    final t = _timelineController
                        .pixelsToTime(_timelineController.gridOffset.value)
                        .add(const Duration(hours: 1));
                    _timelineController.jumpTo(t);
                  },
                ),
                const SizedBox(width: 4),
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
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonne fixe noms chaînes
                SizedBox(
                  width: channelWidth,
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    child: Column(
                      children: widget.channels.map((ch) {
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
                      }).toList(),
                    ),
                  ),
                ),

                // Zone grille : repeignable ciblée, culling viewport
                LayoutBuilder(
                  builder: (context, constraints) {
                    final viewportWidth = constraints.maxWidth;
                    return Expanded(
                      child: SingleChildScrollView(
                        controller: _verticalController,
                        child: SingleChildScrollView(
                          controller: _horizontalController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: totalWidth,
                            height: totalHeight,
                            child: Listener(
                              onPointerMove: (event) {
                                // Repaint ciblé uniquement (aucun rebuild).
                                _hoverPosition.value = event.localPosition;
                              },
                              onPointerUp: (_) => _hoverPosition.value = null,
                              onPointerCancel: (_) =>
                                  _hoverPosition.value = null,
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  size: Size(totalWidth, totalHeight),
                                  painter: _EpgGridPainter(
                                    channels: widget.channels,
                                    renderCache: _renderCache,
                                    gridStartTime: _gridStartTime,
                                    pixelsPerMinute: _pixelsPerMinute,
                                    rowHeight: rowHeight,
                                    channelWidth: channelWidth,
                                    viewportWidth: viewportWidth,
                                    horizontalOffset: _horizontalOffset,
                                    touchPosition: _hoverPosition,
                                    repaint: Listenable.merge([
                                      _hoverPosition,
                                      _timelineController.now,
                                      _horizontalOffset,
                                    ]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Programme préparé pour le rendu (positions précalculées).
class _RenderProgram {
  final EPGProgram program;
  final double left;
  final double width;
  final bool isLive;

  const _RenderProgram({
    required this.program,
    required this.left,
    required this.width,
    required this.isLive,
  });
}

/// Peintre haute performance pour la grille EPG (canvas unique).
/// Repeint uniquement sur les notifiers reçus (hover, "now", scroll), pas à
/// chaque build du widget.
class _EpgGridPainter extends CustomPainter {
  final List<String> channels;
  final Map<String, List<_RenderProgram>> renderCache;
  final DateTime gridStartTime;
  final double pixelsPerMinute;
  final double rowHeight;
  final double channelWidth;
  final double viewportWidth;
  final ValueListenable<double>? horizontalOffset;
  final ValueListenable<Offset?>? touchPosition;

  _EpgGridPainter({
    required this.channels,
    required this.renderCache,
    required this.gridStartTime,
    required this.pixelsPerMinute,
    required this.rowHeight,
    required this.channelWidth,
    required this.viewportWidth,
    required this.horizontalOffset,
    required this.touchPosition,
    super.repaint,
  });

  double get _currentTimeOffset {
    final diff = DateTime.now().difference(gridStartTime).inSeconds / 60.0;
    return diff * pixelsPerMinute;
  }

  /// Range de rendu : petit dépassement autour du viewport pour garder les
  /// bordures des barres à cheval sur le bord visible.
  (double, double) get _cullRange {
    final offset = horizontalOffset?.value ?? 0.0;
    return (offset - rowHeight, offset + viewportWidth + rowHeight);
  }

  /// Programme sous le pointeur (highlight seul, sans rebuild du widget).
  _RenderProgram? _resolveHovered(Offset? pos) {
    if (pos == null) return null;
    final channelIndex = (pos.dy / rowHeight).floor();
    if (channelIndex < 0 || channelIndex >= channels.length) return null;
    final ch = channels[channelIndex];
    for (final rp in renderCache[ch] ?? const <_RenderProgram>[]) {
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
    final linePaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1;
    for (int i = 1; i < channels.length; i++) {
      final y = i * rowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final (cullMin, cullMax) = _cullRange;
    final hovered = _resolveHovered(touchPosition?.value);

    for (int chIndex = 0; chIndex < channels.length; chIndex++) {
      final ch = channels[chIndex];
      final programs = renderCache[ch] ?? const <_RenderProgram>[];
      final yBase = chIndex * rowHeight;
      final y = yBase + 2;
      final h = rowHeight - 4;

      for (final rp in programs) {
        // Culling : on ne dessine/layout que les barres visibles dans le
        // viewport + marge (évite ~des milliers de TextPainter hors écran).
        if (rp.left + rp.width < cullMin || rp.left > cullMax) continue;

        final isHovered = rp == hovered;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(rp.left, y, rp.width, h),
          const Radius.circular(6),
        );

        final bgPaint = Paint()
          ..color = rp.isLive
              ? const Color(0xFF2D224D)
              : (isHovered ? const Color(0xFF2A2F3A) : const Color(0xFF1C1F26));
        canvas.drawRRect(rect, bgPaint);

        final borderPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = rp.isLive
              ? const Color(0xFF8B5CF6)
              : (isHovered
                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.5)
                  : Colors.white10);
        canvas.drawRRect(rect, borderPaint);

        // Texte titre (clippé dans la barre, seulement si assez de largeur)
        if (rp.width > 26) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: rp.program.title,
              style: TextStyle(
                color: rp.isLive ? Colors.white : Colors.white70,
                fontWeight: FontWeight.bold,
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
      }
    }

    // Ligne rouge "MAINTENANT"
    final nowOffset = _currentTimeOffset;
    final nowPaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(nowOffset, 0),
      Offset(nowOffset, size.height),
      nowPaint,
    );
    canvas.drawCircle(
      Offset(nowOffset, 7),
      7,
      Paint()..color = Colors.redAccent,
    );
  }

  @override
  bool shouldRepaint(covariant _EpgGridPainter old) {
    return old.renderCache != renderCache ||
        old.gridStartTime != gridStartTime ||
        old.pixelsPerMinute != pixelsPerMinute ||
        old.viewportWidth != viewportWidth;
  }
}
