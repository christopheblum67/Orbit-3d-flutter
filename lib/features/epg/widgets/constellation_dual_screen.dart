import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/models/epg_models.dart';

/// Vue dual-screen / multi-flux (Picture-in-Picture ou split)
class ConstellationDualScreenView extends StatefulWidget {
  final String primaryStreamUrl;
  final String secondaryStreamUrl;
  final String? primaryTitle;
  final String? secondaryTitle;

  const ConstellationDualScreenView({
    Key? key,
    required this.primaryStreamUrl,
    required this.secondaryStreamUrl,
    this.primaryTitle,
    this.secondaryTitle,
  }) : super(key: key);

  @override
  State<ConstellationDualScreenView> createState() => _ConstellationDualScreenViewState();
}

class _ConstellationDualScreenViewState extends State<ConstellationDualScreenView> {
  int _focusedPlayer = 0;
  DualScreenLayout _layout = DualScreenLayout.splitEqual;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Zone des joueurs vidéo
          Row(
            children: [
              Expanded(
                flex: (_layout == DualScreenLayout.mainWithPip && _focusedPlayer == 1) ? 1 : 2,
                child: _buildPlayerSlot(
                  index: 0,
                  title: widget.primaryTitle ?? 'Flux Principal',
                  isFocused: _focusedPlayer == 0,
                  isMain: _layout == DualScreenLayout.splitEqual ||
                      (_layout == DualScreenLayout.mainWithPip && _focusedPlayer == 0),
                ),
              ),
              Expanded(
                flex: 2,
                child: _buildPlayerSlot(
                  index: 1,
                  title: widget.secondaryTitle ?? 'Flux Secondaire',
                  isFocused: _focusedPlayer == 1,
                  isMain: _layout == DualScreenLayout.mainWithPip && _focusedPlayer == 1,
                ),
              ),
            ],
          ),

          // Contrôles PiP en overlay
          if (_layout == DualScreenLayout.mainWithPip)
            Positioned(
              top: 16,
              right: 16,
              child: _buildPipControls(),
            ),

          // Barre de contrôle en bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSlot({
    required int index,
    required String title,
    required bool isFocused,
    required bool isMain,
  }) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _focusedPlayer = index),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(
            color: isFocused ? const Color(0xFF8B5CF6) : Colors.transparent,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(isMain ? 12 : 8),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Placeholder pour le lecteur vidéo
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tv,
                    size: isMain ? 64 : 48,
                    color: isFocused ? const Color(0xFF8B5CF6) : Colors.white38,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: isFocused ? Colors.white : Colors.white70,
                      fontSize: isMain ? 16 : 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Audio ${isFocused ? "Actif" : "Muet"}',
                    style: TextStyle(
                      color: isFocused ? Colors.amber : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Badge focus
            if (isFocused)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'FOCUS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPipControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _pipButton(Icons.swap_horiz, 'Inverser', () {
          setState(() => _focusedPlayer = _focusedPlayer == 0 ? 1 : 0);
        }),
        const SizedBox(width: 8),
        _pipButton(Icons.aspect_ratio, 'Layout', () {
          setState(() => _layout = _layout == DualScreenLayout.splitEqual
              ? DualScreenLayout.mainWithPip
              : DualScreenLayout.splitEqual);
        }),
      ],
    );
  }

  Widget _pipButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Material(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0C10),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _controlButton(Icons.volume_up, 'Audio 1', () => setState(() => _focusedPlayer = 0)),
            _controlButton(Icons.volume_off, 'Audio 2', () => setState(() => _focusedPlayer = 1)),
            _controlButton(Icons.swap_horiz, 'Swap', () => setState(() => _focusedPlayer = _focusedPlayer == 0 ? 1 : 0)),
            _controlButton(Icons.aspect_ratio, 'Layout', () => setState(() => _layout = _layout == DualScreenLayout.splitEqual ? DualScreenLayout.mainWithPip : DualScreenLayout.splitEqual)),
            _controlButton(Icons.fullscreen, 'Plein écran', () {}),
          ],
        ),
      ),
    );
  }

  Widget _controlButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: const Color(0xFF1C1F26),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}