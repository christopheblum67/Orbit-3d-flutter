import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:orbit_3d_flutter/services/player_track_prefs.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Sous-fenêtre « Détails du flux » ouverte depuis la footerbar (icône ⚙️).
///
/// Liste les pistes audio et les qualités vidéo détectées par le lecteur
/// (ExoPlayer) et permet de les sélectionner. Les sous-titres ne sont pas
/// pris en charge par le lecteur embarqué : la section affiche un état
/// « non disponibles ».
Future<void> showStreamDetailsSheet(
  BuildContext context,
  VideoPlayerController controller,
  String mediaKey,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => StreamDetailsSheet(
      controller: controller,
      mediaKey: mediaKey,
    ),
  );
}

class StreamDetailsSheet extends ConsumerStatefulWidget {
  const StreamDetailsSheet({
    super.key,
    required this.controller,
    required this.mediaKey,
  });

  final VideoPlayerController controller;
  final String mediaKey;

  @override
  ConsumerState<StreamDetailsSheet> createState() => _StreamDetailsSheetState();
}

class _StreamDetailsSheetState extends ConsumerState<StreamDetailsSheet> {
  List<VideoAudioTrack> _audioTracks = const [];
  List<VideoTrack> _videoTracks = const [];
  String? _audioSelection;
  String? _videoSelection;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _selectedAudioId => _audioSelection ?? '';
  String get _selectedVideoId => _videoSelection ?? 'auto';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await safeAsync(() async {
      final audio = await widget.controller.getAudioTracks();
      final video = await widget.controller.getVideoTracks();
      return (audio: audio, video: video);
    }, context: 'StreamDetailsSheet _load');
    
    if (!mounted) return;
    
    if (result.isSuccess) {
      final data = result.valueOrNull!;
      setState(() {
        _audioTracks = data.audio;
        _videoTracks = data.video;
        _audioSelection = data.audio.indexWhere((t) => t.isSelected) >= 0
            ? data.audio.firstWhere((t) => t.isSelected).id
            : null;
        _videoSelection = data.video.indexWhere((t) => t.isSelected) >= 0
            ? data.video.firstWhere((t) => t.isSelected).id
            : 'auto';
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = result.errorOrNull?.message ?? 'Unknown error';
      });
    }
  }

  Future<void> _selectAudio(String id) async {
    setState(() => _audioSelection = id);
    // Mémorise la piste pour la prochaine lecture de ce contenu.
    await PlayerTrackPrefs.setAudioTrack(widget.mediaKey, id);
    await safeAsync(
      () => widget.controller.selectAudioTrack(id),
      context: 'StreamDetailsSheet _selectAudio',
    );
  }

  Future<void> _selectVideo(String? id) async {
    setState(() => _videoSelection = id ?? 'auto');
    await safeAsync(
      () => widget.controller.selectVideoTrack(id == null ? null : _videoTrackFor(id)),
      context: 'StreamDetailsSheet _selectVideo',
    );
  }

  VideoTrack? _videoTrackFor(String id) {
    for (final track in _videoTracks) {
      if (track.id == id) return track;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.streamDetails,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _error != null
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sync_problem,
                                size: 32,
                                color: scheme.error,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Impossible de lire les pistes de ce flux.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: _load,
                                child: Text(l.retry),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          children: [
                            _sectionTitle('Audio'),
                            if (_audioTracks.isEmpty)
                              _EmptyRow(label: l.noAudioTrackDetected)
                            else
                              for (final track in _audioTracks)
                                _TrackTile(
                                  title: _audioLabel(track),
                                  subtitle: _audioMeta(track),
                                  selected: _selectedAudioId == track.id,
                                  onTap: () => _selectAudio(track.id),
                                ),
                            const SizedBox(height: 12),
                            _sectionTitle('Vidéo'),
                            _TrackTile(
                              title: 'Automatique',
                              subtitle: l.autoQualityDescription,
                              selected: _selectedVideoId == 'auto',
                              onTap: () => _selectVideo(null),
                            ),
                            if (_videoTracks.isEmpty)
                              _EmptyRow(label: l.noVideoQualityDetected)
                            else
                              for (final track in _videoTracks)
                                _TrackTile(
                                  title: _videoLabel(track),
                                  subtitle: _videoMeta(track),
                                  selected: _selectedVideoId == track.id,
                                  onTap: () => _selectVideo(track.id),
                                ),
                            const SizedBox(height: 12),
                            _sectionTitle('Sous-titres'),
                            _EmptyRow(
                              label: l.subtitlesUnavailable,
                              info:
                                  'Le lecteur embarqué ne gère pas les sous-titres '
                                  'sur ce flux.',
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String label) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.primary,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  static String _audioLabel(VideoAudioTrack track) {
    final label = track.label;
    if (label != null && label.isNotEmpty && label != 'Audio') {
      return label;
    }
    final language = track.language;
    if (language != null && language.isNotEmpty && language != 'und') {
      return language;
    }
    return 'Piste audio';
  }

  static String _audioMeta(VideoAudioTrack track) {
    final parts = <String>[
      if (track.channelCount != null) '${track.channelCount} can.',
      if (track.codec != null && track.codec!.isNotEmpty) track.codec!,
      if (track.bitrate != null && track.bitrate! > 0)
        '${(track.bitrate! / 1000).round()} kbps',
    ];
    return parts.join(' · ');
  }

  static String _videoLabel(VideoTrack track) {
    final label = track.label;
    if (label != null && label.isNotEmpty) return label;
    if (track.width != null && track.height != null) {
      return '${track.width}×${track.height}';
    }
    return 'Qualité vidéo';
  }

  static String _videoMeta(VideoTrack track) {
    final parts = <String>[
      if (track.codec != null && track.codec!.isNotEmpty) track.codec!,
      if (track.frameRate != null && track.frameRate! > 0)
        '${track.frameRate!.round()} fps',
      if (track.bitrate != null && track.bitrate! > 0)
        '${(track.bitrate! / 1000).round()} kbps',
    ];
    return parts.join(' · ');
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(
        selected
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? scheme.primary : scheme.onSurface,
        ),
      ),
      subtitle: subtitle != null && subtitle!.isNotEmpty
          ? Text(subtitle!, style: const TextStyle(fontSize: 11))
          : null,
      onTap: onTap,
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.label, this.info});

  final String label;
  final String? info;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (info != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    info!,
                    style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}