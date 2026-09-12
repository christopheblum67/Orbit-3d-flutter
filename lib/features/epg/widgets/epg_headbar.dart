import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';

/// Type de contenu affiché dans la headbar
enum EpgHeadbarType { live, movie, series, replay }

/// Barre d'en-tête EPG unifiée pour Live / Films / Séries / Replay
///
/// Affiche : programme en cours, programme suivant, barre de progression temporelle,
/// infos chaîne/contenu, actions rapides (favori, enregistrement, rappel).
class EpgHeadbar extends StatelessWidget {
  final EpgHeadbarType type;
  final Channel? channel;
  final EPGProgram? currentProgram;
  final EPGProgram? nextProgram;
  final Movie? movie;
  final Series? series;
  final ReplayItem? replay;
  final Duration? playbackPosition;
  final Duration? totalDuration;
  final bool isLive;
  final bool isFavorite;
  final bool isRecording;
  final bool hasReminder;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onRecordToggle;
  final VoidCallback? onReminderToggle;
  final VoidCallback? onPlay;
  final VoidCallback? onInfo;

  const EpgHeadbar({
    super.key,
    required this.type,
    this.channel,
    this.currentProgram,
    this.nextProgram,
    this.movie,
    this.series,
    this.replay,
    this.playbackPosition,
    this.totalDuration,
    this.isLive = false,
    this.isFavorite = false,
    this.isRecording = false,
    this.hasReminder = false,
    this.onFavoriteToggle,
    this.onRecordToggle,
    this.onReminderToggle,
    this.onPlay,
    this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16181E) : Colors.white,
        border: Border(
          bottom:
              BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.2)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ligne 1 : Infos principales + progression
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Logo / Image
                  _buildLeadingImage(context),
                  const SizedBox(width: 12),
                  // Infos texte
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getTitle(),
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isLive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2,),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'EN DIRECT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getSubtitle(),
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Barre de progression temporelle
                  if (totalDuration != null && totalDuration!.inSeconds > 0)
                    SizedBox(
                      width: 120,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LinearProgressIndicator(
                            value: _getProgress(),
                            minHeight: 4,
                            backgroundColor:
                                scheme.outlineVariant.withValues(alpha: 0.3),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(scheme.primary),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTimeProgress(),
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 10,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Ligne 2 : Programme suivant + Actions
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.1),),),
            ),
            child: Row(
              children: [
                // Programme suivant
                if (_hasNextProgram())
                  Expanded(
                    child: _NextProgramWidget(
                      nextProgram: _getNextProgram(),
                      isLive: isLive,
                    ),
                  ),
                // Actions rapides
                _ActionButtonsWidget(
                  isFavorite: isFavorite,
                  isRecording: isRecording,
                  hasReminder: hasReminder,
                  onFavoriteToggle: onFavoriteToggle,
                  onRecordToggle: onRecordToggle,
                  onReminderToggle: onReminderToggle,
                  onInfo: onInfo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadingImage(BuildContext context) {
    String? imageUrl;
    const size = 56.0;

    if (channel?.logoUrl.isNotEmpty == true) {
      imageUrl = channel!.logoUrl;
    } else if (movie?.posterUrl.isNotEmpty == true) {
      imageUrl = movie!.posterUrl;
    } else if (series?.coverUrl.isNotEmpty == true) {
      imageUrl = series!.coverUrl;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: imageUrl != null
          ? Image.network(
              imageUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(context),
            )
          : _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primaryContainer, scheme.tertiaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        type == EpgHeadbarType.live
            ? Icons.live_tv
            : type == EpgHeadbarType.movie
                ? Icons.movie
                : Icons.video_library,
        size: 28,
        color: scheme.primary,
      ),
    );
  }

  String _getTitle() {
    switch (type) {
      case EpgHeadbarType.live:
        return channel?.name ?? currentProgram?.title ?? 'Live TV';
      case EpgHeadbarType.movie:
        return movie?.title ?? 'Film';
      case EpgHeadbarType.series:
        return series?.title ?? 'Série';
      case EpgHeadbarType.replay:
        return replay?.title ?? 'Replay';
    }
  }

  String _getSubtitle() {
    switch (type) {
      case EpgHeadbarType.live:
        if (currentProgram != null) {
          final start = _formatTime(currentProgram!.start);
          final end = _formatTime(currentProgram!.end);
          return '$start - $end  •  ${currentProgram!.title}';
        }
        return channel?.groupLabel ?? 'Live TV';
      case EpgHeadbarType.movie:
        final parts = <String>[];
        if (movie?.year != null && movie!.year > 0) parts.add('${movie!.year}');
        if (movie?.genre.isNotEmpty == true) parts.add(movie!.genre);
        if (movie?.rating != null && movie!.rating > 0) {
          parts.add('★ ${movie!.rating.toStringAsFixed(1)}');
        }
        return parts.join('  •  ');
      case EpgHeadbarType.series:
        final parts = <String>[];
        if (series?.year != null && series!.year > 0) {
          parts.add('${series!.year}');
        }
        if (series?.genre.isNotEmpty == true) parts.add(series!.genre);
        if (series?.rating != null && series!.rating > 0) {
          parts.add('★ ${series!.rating.toStringAsFixed(1)}');
        }
        return parts.join('  •  ');
      case EpgHeadbarType.replay:
        final parts = <String>[];
        if (replay?.startTime.isNotEmpty == true) parts.add(replay!.startTime);
        if (replay?.endTime.isNotEmpty == true) parts.add(replay!.endTime);
        return parts.join(' - ');
    }
  }

  bool _hasNextProgram() {
    return nextProgram != null || (type != EpgHeadbarType.live && false);
  }

  EPGProgram? _getNextProgram() => nextProgram;

  double _getProgress() {
    if (playbackPosition == null ||
        totalDuration == null ||
        totalDuration!.inSeconds == 0) {
      return 0.0;
    }
    return (playbackPosition!.inSeconds / totalDuration!.inSeconds)
        .clamp(0.0, 1.0);
  }

  String _formatTimeProgress() {
    final pos = playbackPosition ?? Duration.zero;
    final tot = totalDuration ?? Duration.zero;
    return '${_formatDuration(pos)} / ${_formatDuration(tot)}';
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }
}

/// Widget programme suivant
class _NextProgramWidget extends StatelessWidget {
  final EPGProgram? nextProgram;
  final bool isLive;

  const _NextProgramWidget({required this.nextProgram, required this.isLive});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (nextProgram == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: scheme.primary),
              const SizedBox(width: 4),
              Text(
                'SUIVANT',
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${_formatTime(nextProgram!.start)} - ${_formatTime(nextProgram!.end)}',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
          ),
          Text(
            nextProgram!.title,
            style: TextStyle(
                color: scheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

/// Boutons d'action rapides (Favori, Enregistrement, Rappel, Info)
class _ActionButtonsWidget extends StatelessWidget {
  final bool isFavorite;
  final bool isRecording;
  final bool hasReminder;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onRecordToggle;
  final VoidCallback? onReminderToggle;
  final VoidCallback? onInfo;

  const _ActionButtonsWidget({
    required this.isFavorite,
    required this.isRecording,
    required this.hasReminder,
    this.onFavoriteToggle,
    this.onRecordToggle,
    this.onReminderToggle,
    this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: isFavorite ? Icons.favorite : Icons.favorite_border,
          activeColor: Colors.redAccent,
          label: 'Favori',
          isActive: isFavorite,
          onTap: onFavoriteToggle,
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: Icons.fiber_manual_record,
          activeColor: Colors.redAccent,
          label: 'Enreg.',
          isActive: isRecording,
          onTap: onRecordToggle,
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: hasReminder
              ? Icons.notifications_active
              : Icons.notifications_none,
          activeColor: scheme.tertiary,
          label: 'Rappel',
          isActive: hasReminder,
          onTap: onReminderToggle,
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: Icons.info_outline,
          activeColor: scheme.primary,
          label: 'Info',
          isActive: false,
          onTap: onInfo,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color activeColor;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.activeColor,
    required this.label,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.15)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? activeColor
                : scheme.outlineVariant.withValues(alpha: 0.3),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: isActive ? activeColor : scheme.onSurfaceVariant,),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : scheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
