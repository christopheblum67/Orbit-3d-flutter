import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/subtitle_parser.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

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
  
  // Focus nodes for TV/D-pad navigation
  final _disableFocus = FocusNode();
  final List<FocusNode> _trackFocusNodes = [];
  final _urlFocus = FocusNode();
  final _labelFocus = FocusNode();
  final _languageFocus = FocusNode();
  final _loadFocus = FocusNode();
  FocusNode? _firstFocusNode;

  @override
  void dispose() {
    _urlController.dispose();
    _labelController.dispose();
    _disableFocus.dispose();
    for (final node in _trackFocusNodes) {
      node.dispose();
    }
    _urlFocus.dispose();
    _labelFocus.dispose();
    _languageFocus.dispose();
    _loadFocus.dispose();
    super.dispose();
  }

  void _requestFocus(FocusNode focus) {
    if (mounted) {
      FocusScope.of(context).requestFocus(focus);
    }
  }

  void _ensureFocusNodes(int trackCount) {
    if (_trackFocusNodes.length != trackCount) {
      // Dispose old nodes
      for (final node in _trackFocusNodes) {
        node.dispose();
      }
      _trackFocusNodes.clear();
      // Create new nodes
      for (int i = 0; i < trackCount; i++) {
        _trackFocusNodes.add(FocusNode());
      }
    }
  }

  Future<void> _loadSubtitle() async {
    final l = AppLocalizations.of(context);
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
          SnackBar(content: Text(l.subtitleLoadError(e))),
        );
      }
    }
  }

  void _selectTrack(SubtitleTrack track) {
    ref.read(subtitleControllerProvider).setActiveTrack(track.label);
  }

  Widget _buildTvListTile({
    required FocusNode focusNode,
    required FocusNode nextFocusNode,
    required FocusNode prevFocusNode,
    required Widget child,
    required VoidCallback onSelect,
  }) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            onSelect();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _requestFocus(nextFocusNode);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _requestFocus(prevFocusNode);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }

  Widget _buildTvTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required FocusNode nextFocusNode,
    required String labelText,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefixIcon,
  }) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          _requestFocus(nextFocusNode);
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _requestFocus(prevFocusNodeFor(focusNode));
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          border: const OutlineInputBorder(),
          prefixIcon: prefixIcon,
        ),
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        onEditingComplete: () => _requestFocus(nextFocusNode),
      ),
    );
  }

  FocusNode prevFocusNodeFor(FocusNode current) {
    // This is a simplified version - in practice you'd track the order
    if (current == _urlFocus) {
      // Check if there are tracks or disable button
      if (_trackFocusNodes.isNotEmpty) return _trackFocusNodes.last;
      if (ref.watch(subtitleControllerProvider).activeTrack != null) return _disableFocus;
      return _loadFocus; // fallback
    }
    if (current == _labelFocus) return _urlFocus;
    if (current == _languageFocus) return _labelFocus;
    if (current == _loadFocus) return _languageFocus;
    return _loadFocus;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final subtitleCtrl = ref.watch(subtitleControllerProvider);
    final activeTrack = subtitleCtrl.activeTrack;
    final availableTracks = subtitleCtrl.availableTracks;
    final scheme = Theme.of(context).colorScheme;
    final hasActiveTrack = activeTrack != null;
    final trackCount = availableTracks.length;

    // Ensure focus nodes match track count
    _ensureFocusNodes(trackCount);

    // Determine focus order for text fields
    final firstTextFieldFocus = hasActiveTrack ? _disableFocus : (trackCount > 0 ? _trackFocusNodes.first : _urlFocus);
    

    // Request initial focus on first interactive element
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _firstFocusNode != null) {
        _requestFocus(_firstFocusNode!);
      } else if (mounted) {
        _firstFocusNode = firstTextFieldFocus;
        _requestFocus(firstTextFieldFocus);
      }
    });

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
              if (hasActiveTrack) ...[
                _buildTvListTile(
                  focusNode: _disableFocus,
                  nextFocusNode: trackCount > 0 ? _trackFocusNodes.first : _urlFocus,
                  prevFocusNode: _loadFocus, // loop to bottom
                  onSelect: () {
                    ref.read(subtitleControllerProvider).disable();
                    Navigator.pop(context);
                  },
                  child: ListTile(
                    leading: const Icon(Icons.subtitles_off),
                    title: Text(l.disableSubtitles),
                    onTap: () {
                      ref.read(subtitleControllerProvider).disable();
                      Navigator.pop(context);
                    },
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
              ],
              // Available tracks
              if (trackCount > 0) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Pistes disponibles',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                ...availableTracks.asMap().entries.map((entry) {
                  final index = entry.key;
                  final track = entry.value;
                  final isActive = activeTrack?.label == track.label;
                  final tileColor = isActive
                      ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : null;
                  final focusNode = _trackFocusNodes[index];
                  final nextFocus = index < trackCount - 1 ? _trackFocusNodes[index + 1] : _urlFocus;
                  final prevFocus = index > 0 ? _trackFocusNodes[index - 1] : (hasActiveTrack ? _disableFocus : _loadFocus);
                  return _buildTvListTile(
                    focusNode: focusNode,
                    nextFocusNode: nextFocus,
                    prevFocusNode: prevFocus,
                    onSelect: () => _selectTrack(track),
                    child: ListTile(
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
                    ),
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
              // URL TextField
              _buildTvTextField(
                controller: _urlController,
                focusNode: _urlFocus,
                nextFocusNode: _labelFocus,
                labelText: l.srtVttUrl,
                hintText: 'https://example.com/subtitle.srt',
                keyboardType: TextInputType.url,
                prefixIcon: const Icon(Icons.link),
              ),
              // Label TextField + Language Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTvTextField(
                        controller: _labelController,
                        focusNode: _labelFocus,
                        nextFocusNode: _languageFocus,
                        labelText: l.nameOptional,
                        hintText: l.languageExample,
                        prefixIcon: const Icon(Icons.label),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Focus(
                      focusNode: _languageFocus,
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent &&
                            (event.logicalKey == LogicalKeyboardKey.enter ||
                                event.logicalKey == LogicalKeyboardKey.select ||
                                event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                          _requestFocus(_loadFocus);
                          return KeyEventResult.handled;
                        }
                        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowUp) {
                          _requestFocus(_labelFocus);
                          return KeyEventResult.handled;
                        }
                        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowDown) {
                          _requestFocus(_loadFocus);
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: DropdownButton<String>(
                        value: _selectedLanguage,
                        items: [
                          DropdownMenuItem(value: 'fr', child: Text(l.langFrench)),
                          DropdownMenuItem(value: 'en', child: const Text('English')),
                          DropdownMenuItem(value: 'es', child: Text(l.langSpanish)),
                          DropdownMenuItem(value: 'de', child: const Text('Deutsch')),
                          DropdownMenuItem(value: 'it', child: const Text('Italiano')),
                          DropdownMenuItem(value: 'pt', child: Text(l.langPortuguese)),
                          DropdownMenuItem(value: 'ar', child: Text(l.langArabic)),
                          DropdownMenuItem(value: 'und', child: Text(l.languageUndetermined)),
                        ],
                        onChanged: (v) => setState(() => _selectedLanguage = v ?? 'fr'),
                      ),
                    ),
                  ],
                ),
              ),
              // Load button
              Focus(
                focusNode: _loadFocus,
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent &&
                      (event.logicalKey == LogicalKeyboardKey.enter ||
                          event.logicalKey == LogicalKeyboardKey.select ||
                          event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                    _loadSubtitle();
                    return KeyEventResult.handled;
                  }
                  if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    _requestFocus(_languageFocus);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('Charger'),
                    onPressed: _loadSubtitle,
                  ),
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