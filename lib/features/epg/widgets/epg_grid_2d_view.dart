import 'dart:async';
import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';

/// Grille EPG 2D style XCIPTV avec barre temporelle synchronisée et ligne rouge "maintenant"
class EpgGrid2DView extends StatefulWidget {
  final List<String> channels;
  final Map<String, List<EPGProgram>> epgData;
  final DateTime? gridStartTime;
  final double pixelsPerMinute;
  final Function(EPGProgram)? onProgramTap;
  final Function(String)? onChannelTap;

  const EpgGrid2DView({
    super.key,
    required this.channels,
    required this.epgData,
    this.gridStartTime,
    this.pixelsPerMinute = 4.0,
    this.onProgramTap,
    this.onChannelTap,
  });

  @override
  State<EpgGrid2DView> createState() => _EpgGrid2DViewState();
}

class _EpgGrid2DViewState extends State<EpgGrid2DView> {
  late Timer _timer;
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final ScrollController _headerController = ScrollController();

  late DateTime _gridStartTime;
  late double _pixelsPerMinute;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _gridStartTime = widget.gridStartTime ??
        DateTime(now.year, now.month, now.day, now.hour - 1); // 1h avant
    _pixelsPerMinute = widget.pixelsPerMinute;

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });

    // Scroll auto vers "maintenant" au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _horizontalController.dispose();
    _verticalController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  void _scrollToCurrentTime() {
    final offset = _getOffsetForTime(DateTime.now()) - 200; // Centrer
    if (_horizontalController.hasClients) {
      _horizontalController.jumpTo(offset.clamp(0.0, _horizontalController.position.maxScrollExtent));
    }
    if (_headerController.hasClients) {
      _headerController.jumpTo(offset.clamp(0.0, _headerController.position.maxScrollExtent));
    }
  }

  double _getOffsetForTime(DateTime time) {
    final diffInMinutes = time.difference(_gridStartTime).inSeconds / 60.0;
    return diffInMinutes * _pixelsPerMinute;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentTimeOffset = _getOffsetForTime(now);
    final totalWidth = 140 + (6 * 30 * _pixelsPerMinute); // 6h par défaut

    return Container(
      color: const Color(0xFF0D0E12),
      child: Column(
        children: [
          // En-tête temporel synchronisé
          SizedBox(
            height: 40,
            child: Row(
              children: [
                // Coin fixe (label "En Direct")
                Container(
                  width: 140,
                  color: const Color(0xFF16181E),
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
                // Header horizontal scrollable
                Expanded(
                  child: SingleChildScrollView(
                    controller: _headerController,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Stack(
                      children: [
                        // Graduations temporelles
                        Row(
                          children: List.generate(24, (index) {
                            final timeLabel = _gridStartTime.add(Duration(minutes: index * 30));
                            return Container(
                              width: 30 * _pixelsPerMinute,
                              padding: const EdgeInsets.only(left: 8),
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: Colors.white12),
                                ),
                              ),
                              child: Text(
                                '${timeLabel.hour.toString().padLeft(2, '0')}:${timeLabel.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(color: Colors.white38, fontSize: 10),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Grille EPG avec scroll vertical + horizontal synchronisé
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonne fixe des noms de chaînes
                SizedBox(
                  width: 140,
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    child: Column(
                      children: widget.channels.map((ch) {
                        return Container(
                          height: 60,
                          color: const Color(0xFF12141C),
                          margin: const EdgeInsets.only(bottom: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => widget.onChannelTap?.call(ch),
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

                // Grille programmes avec scroll horizontal + vertical
                Expanded(
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    child: SingleChildScrollView(
                      controller: _horizontalController,
                      scrollDirection: Axis.horizontal,
                      child: Stack(
                        children: [
                          // Grille des programmes
                          Column(
                            children: widget.channels.map((ch) {
                              final programs = widget.epgData[ch] ?? [];
                              return SizedBox(
                                height: 60,
                                child: Stack(
                                  children: programs.map((prog) {
                                    final left = _getOffsetForTime(prog.startTime);
                                    final width = (prog.durationMinutes) * _pixelsPerMinute;

                                    return Positioned(
                                      left: left,
                                      width: (width - 2).clamp(40.0, double.infinity),
                                      top: 2,
                                      bottom: 2,
                                      child: GestureDetector(
                                        onTap: () => widget.onProgramTap?.call(prog),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: prog.isLive
                                                ? const Color(0xFF2D224D)
                                                : const Color(0xFF1C1F26),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: prog.isLive
                                                  ? const Color(0xFF8B5CF6)
                                                  : Colors.white10,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                prog.title,
                                                style: TextStyle(
                                                  color: prog.isLive ? Colors.white : Colors.white70,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            }).toList(),
                          ),

                          // Barre temps réel rouge (ligne "maintenant")
                          Positioned(
                            left: currentTimeOffset,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 2,
                              color: Colors.redAccent,
                              child: OverflowBox(
                                alignment: Alignment.topCenter,
                                maxHeight: 14,
                                maxWidth: 14,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  double get currentTimeOffset {
    final now = DateTime.now();
    return _getOffsetForTime(now);
  }
}