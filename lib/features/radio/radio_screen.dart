import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/channel.dart';
import '../../core/widgets/widgets.dart';

class RadioScreen extends ConsumerStatefulWidget {
  const RadioScreen({super.key});

  @override
  ConsumerState<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends ConsumerState<RadioScreen> {
  String? _currentStationName;
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    final radiosAsync = ref.watch(radioChannelsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Radio')),
      body: radiosAsync.when(
        data: (radios) {
          if (radios.isEmpty) {
            return const EmptyState(
              icon: Icons.radio,
              title: 'Aucune station disponible',
              message: 'Ajoute des stations de radio dans les réglages.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionHeader(
                icon: Icons.graphic_eq,
                title: 'Stations',
                subtitle: '${radios.length} stations',
              ),
              const SizedBox(height: 8),
              for (final radio in radios)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ChannelTile(
                    title: radio.name,
                    subtitle: radio.group,
                    icon: Icons.radio,
                    isActive: _currentStationName == radio.name && _isPlaying,
                    trailing: IconButton(
                      icon: Icon(
                        _currentStationName == radio.name && _isPlaying
                            ? Icons.stop_circle_outlined
                            : Icons.play_circle_outline,
                      ),
                      color: _currentStationName == radio.name && _isPlaying
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      onPressed: () => _toggleStation(radio),
                    ),
                    onTap: () => _toggleStation(radio),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  Future<void> _toggleStation(Channel radio) async {
    final radioService = ref.read(radioServiceProvider);
    if (_currentStationName == radio.name && _isPlaying) {
      await radioService.stop();
      setState(() {
        _isPlaying = false;
        _currentStationName = null;
      });
    } else {
      await radioService.play(radio.streamUrl);
      setState(() {
        _isPlaying = true;
        _currentStationName = radio.name;
      });
    }
  }
}