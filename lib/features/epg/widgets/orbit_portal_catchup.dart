import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/models/epg_models.dart';

/// Navigation temporelle 3D "Orbit Portal" pour le Catch-up / Replay
class OrbitPortalCatchUpView extends StatefulWidget {
  final String channelName;
  final List<DateTime> availableDays;
  final int initialDayIndex;
  final Function(DateTime)? onDaySelected;
  final Function(DateTime)? onPlayLive;

  const OrbitPortalCatchUpView({
    Key? key,
    required this.channelName,
    required this.availableDays,
    this.initialDayIndex = 0,
    this.onDaySelected,
    this.onPlayLive,
  }) : super(key: key);

  @override
  State<OrbitPortalCatchUpView> createState() => _OrbitPortalCatchUpViewState();
}

class _OrbitPortalCatchUpViewState extends State<OrbitPortalCatchUpView> {
  late int _selectedDayIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = widget.initialDayIndex.clamp(0, widget.availableDays.length - 1);
    _pageController = PageController(initialPage: _selectedDayIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.availableDays.isEmpty) {
      return const Center(
        child: Text(
          'Aucun replay disponible',
          style: TextStyle(color: Colors.white38, fontSize: 16),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Arrière-plan avec profondeur
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Color(0xFF16181E),
                  Color(0xFF0B0C10),
                  Colors.black,
                ],
              ),
            ),
          ),

          // Carrousel 3D des jours
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _selectedDayIndex = index);
            },
            itemCount: widget.availableDays.length,
            itemBuilder: (context, index) {
              final day = widget.availableDays[index];
              final isSelected = index == _selectedDayIndex;
              final isLive = index == 0;

              return _buildDayPortal(
                index: index,
                day: day,
                isSelected: isSelected,
                isLive: isSelected,
              );
            },
          ),

          // UI de contrôle en bas
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Indicateurs de page
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.availableDays.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: index == _selectedDayIndex ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == _selectedDayIndex
                            ? const Color(0xFF8B5CF6)
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                // Contrôles
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_left, color: Colors.white70, size: 28),
                      onPressed: _selectedDayIndex > 0
                          ? () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                            )
                          : null,
                    ),
                    const SizedBox(width: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: Text(
                        widget.availableDays[_selectedDayIndex] == widget.availableDays.first
                            ? 'EN DIRECT'
                            : 'REPLAY J-${_selectedDayIndex}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final day = widget.availableDays[_selectedDayIndex];
                        if (_selectedDayIndex == 0) {
                          widget.onPlayLive?.call(day);
                        } else {
                          widget.onDaySelected?.call(day);
                        }
                      },
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_right, color: Colors.white70, size: 28),
                      onPressed: _selectedDayIndex < widget.availableDays.length - 1
                          ? () => _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                            )
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Info chaîne en haut
          Positioned(
            top: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFF8B5CF6), width: 2),
              ),
              child: Text(
                widget.channelName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayPortal({
    required int index,
    required DateTime day,
    required bool isSelected,
    required bool isLive,
  }) {
    final zOffset = (index - _selectedDayIndex) * -250.0;
    final opacity = (1.0 - ((index - _selectedDayIndex).abs() * 0.25)).clamp(0.15, 1.0);
    final scale = (1.0 - ((index - _selectedDayIndex).abs() * 0.15)).clamp(0.5, 1.2);

    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // Perspective
        ..translate(0.0, 0.0, zOffset)
        ..scale(scale),
      alignment: Alignment.center,
      child: Opacity(
        opacity: opacity,
        child: GestureDetector(
          onTap: () {
            if (index != _selectedDayIndex) {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
              );
            }
          },
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isSelected
                    ? [const Color(0xFF8B5CF6).withOpacity(0.3), Colors.transparent]
                    : [Colors.white10, Colors.transparent],
              ),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : Colors.white12,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLive ? 'EN DIRECT' : 'REPLAY J-$index',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.bold,
                      fontSize: isSelected ? 20 : 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${day.day}/${day.month}/${day.year}',
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.white24,
                      fontSize: 14,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF8B5CF6), width: 1),
                      ),
                      child: Text(
                        isLive ? 'Appuyez pour regarder en direct' : 'Appuyez pour ouvrir le replay',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}