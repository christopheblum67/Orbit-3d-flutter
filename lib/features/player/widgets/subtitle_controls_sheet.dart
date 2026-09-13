import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/subtitle_parser.dart';

/// Sous-fenêtre « Sous-titres » ouverte depuis le lecteur.
Future<void> showSubtitleControlsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => const SubtitleControlsSheet(),
  );
}

class SubtitleControlsSheet extends ConsumerStatefulWidget {
  const SubtitleControlsSheet({super.key});

  @override
  ConsumerState<SubtitleControlsSheet> createState() => _SubtitleControlsSheetState();
}

class _SubtitleControlsSheetState extends ConsumerState<SubtitleControlsSheet> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  String _selectedLanguage = 'fr';

  @override
  void dispose() {
    _urlController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _loadSubtitle() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    try {
      await ref.read(subtitleControllerProvider).loadAndSetTrack(
        url,
        language: _selectedLanguage,
        label: _labelController.text.trim().isEmpty ? _selectedLanguage : _labelController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement sous-titre: $e')),
        );
      }
    }
  }

  void _selectTrack(SubtitleTrack track) {
    ref.read(subtitleControllerProvider).setActiveTrack(track.label);
  }

  void _disableSubtitles() {
    ref.read(subtitleControllerProvider).disable();
  }

  @override
  Widget build(BuildContext context) {
    final subtitleCtrl = ref.watch(subtitleControllerProvider);
    final activeTrack = subtitleCtrl.activeTrack;
    final availableTracks = subtitleCtrl.availableTracks;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Sous-titres',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(height: 1),
              // Current track / disable
              if (ref.watch(subtitleControllerProvider).activeTrack != null) ...[
                ListTile(
                  leading: const Icon(Icons.subtitles_off),
                  title: const Text('Désactiver les sous-titres'),
                  onTap: () {
                    ref.read(subtitleControllerProvider).disable();
                    Navigator.pop(context);
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
              ],
              // Available tracks
              if (availableTracks.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Pistes disponibles',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                ...availableTracks.map((track) {
                  final isActive = activeTrack?.label == track.label;
                  final tileColor = isActive
                      ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : null;
                  return ListTile(
                    leading: Icon(
                      isActive ? Icons.check_circle : Icons.circle_outlined,
                      color: isActive ? Theme.of(context).colorScheme.primary : null,
                    ),
                    title: Text(track.label),
                    subtitle: Text('${track.language.toUpperCase()} · ${track.cues.length} cues'),
                    trailing: isActive
                        ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () => _selectTrack(track),
                    tileColor: tileColor,
                  );
                  }),
                const Divider(height: 1, indent: 16, endIndent: 16),
              ],
              // Add new subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Ajouter un sous-titre (URL .srt/.vtt)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL .srt / .vtt',
                    hintText: 'https://example.com/subtitle.srt',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _labelController,
                        decoration: const InputDecoration(
                          labelText: 'Nom (optionnel)',
                          hintText: 'Français, English, etc.',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _selectedLanguage,
                      items: const [
                        DropdownMenuItem(value: 'fr', child: Text('Français')),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'es', child: Text('Español')),
                        DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                        DropdownMenuItem(value: 'it', child: Text('Italiano')),
                        DropdownMenuItem(value: 'pt', child: Text('Português')),
                        DropdownMenuItem(value: 'ar', child: Text('العربية')),
                        DropdownMenuItem(value: 'und', child: Text('Indéterminé')),
                      ],
                      onChanged: (v) => setState(() => _selectedLanguage = v ?? 'fr'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  icon: const Icon(Icons.cloud_download),
                  label: const Text('Charger'),
                  onPressed: _loadSubtitle,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}