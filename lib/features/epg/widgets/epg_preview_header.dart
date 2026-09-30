import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/channel.dart';

class EPGPreviewHeader extends StatelessWidget {
  final Channel? channel;
  final EPGProgram? program;
  final int currentTimeSec;

  const EPGPreviewHeader({
    super.key,
    this.channel,
    this.program,
    required this.currentTimeSec,
  });

  @override
  Widget build(BuildContext context) {
    final program = this.program;
    final channel = this.channel;

    if (program == null || channel == null) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            program.categoryColor.withValues(alpha: 0.25),
            const Color(0xFF18202C),
          ],
        ),
        border: Border.all(
          color: program.categoryColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zone aperçu vidéo
            SizedBox(
              width: 280,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_circle_outline,
                          color: Colors.white54,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'APERÇU FLUX LIVE\n${channel.name}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // Détails programme
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Badge catégorie
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: program.categoryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              program.categoryDisplayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            channel.name,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        program.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        program.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  // Barre de progression si en cours
                  if (program.isLiveNow) ...[
                    LinearProgressIndicator(
                      value: program.progress,
                      color: program.accentColor,
                      backgroundColor: Colors.white10,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'En cours (${(program.progress * 100).toInt()}%)',
                      style: TextStyle(
                        color: program.accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
