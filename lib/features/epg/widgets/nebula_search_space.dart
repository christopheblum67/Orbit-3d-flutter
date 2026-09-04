import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/models/epg_models.dart';

class NebulaSearchSpace extends StatefulWidget {
  final String searchQuery;
  final List<NebulaSearchResult> results;
  final Function(NebulaSearchResult)? onResultTap;

  const NebulaSearchSpace({
    super.key,
    required this.searchQuery,
    required this.results,
    this.onResultTap,
  });

  @override
  State<NebulaSearchSpace> createState() => _NebulaSearchSpaceState();
}

class _NebulaSearchSpaceState extends State<NebulaSearchSpace>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat(reverse: false);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07080A),
      body: Stack(
        alignment: Alignment.center,
        children: [
          _buildNebulaParticles(),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.05),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search, color: Colors.white, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        '"${widget.searchQuery}"',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
),
                ),
              );
            },
          ),
      if (widget.results.isNotEmpty)
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: List.generate(widget.results.length, (index) {
                    final item = widget.results[index];
                    final angle = (2 * math.pi / widget.results.length) * index +
                        (_rotationController.value * 2 * math.pi);
                    const radius = 180.0;
                    final x = radius * math.cos(angle);
                    final y = radius * math.sin(angle);

                    return Transform.translate(
                      offset: Offset(x, y),
                      child: _buildResultChip(item),
                    );
                  }),
                );
              },
            ),
          if (widget.results.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text('Aucun résultat pour "${widget.searchQuery}"', style: const TextStyle(color: Colors.white38, fontSize: 16)),
                ],
              ),
            ),
          Positioned(
            bottom: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.keyboard_arrow_left, color: Colors.white38),
                  SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_right, color: Colors.white38),
                  SizedBox(width: 16),
                  Text('Naviguer · OK pour sélectionner', style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNebulaParticles() {
    return Stack(
      children: List.generate(15, (index) {
        final angle = (2 * math.pi / 15) * index;
        final radius = 100.0 + (index % 3) * 50.0;
        final x = radius * math.cos(angle);
        final y = radius * math.sin(angle);

        return Positioned(
          left: x + 200,
          top: y + 200,
          child: Container(
            width: 4 + (index % 3) * 2.0,
            height: 4 + (index % 3) * 2.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: [
                const Color(0xFF8B5CF6),
                const Color(0xFF00CFE8),
                const Color(0xFFFF6FA8),
              ][index % 3].withValues(alpha: 0.4),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildResultChip(NebulaSearchResult item) {
    final color = _getTypeColor(item.type);

    return GestureDetector(
      onTap: () => widget.onResultTap?.call(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getTypeIcon(item.type), color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              '${item.title} (${item.type})',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(item.relevanceScore * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'live':
      case 'channel':
        return Colors.redAccent;
      case 'vod':
      case 'movie':
        return const Color(0xFF8A72FF);
      case 'series':
        return const Color(0xFFB388FF);
      case 'replay':
        return const Color(0xFFFFB300);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'live':
      case 'channel':
        return Icons.live_tv;
      case 'vod':
      case 'movie':
        return Icons.movie;
      case 'series':
        return Icons.video_library;
      case 'replay':
        return Icons.replay;
      default:
        return Icons.search;
    }
  }
}