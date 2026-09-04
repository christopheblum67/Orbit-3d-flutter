import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';

class RadioScreen extends ConsumerStatefulWidget {
  const RadioScreen({super.key});

  @override
  ConsumerState<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends ConsumerState<RadioScreen> {
  @override
  Widget build(BuildContext context) {
    final radiosAsync = ref.watch(radioChannelsProvider);
    final radioService = ref.watch(radioServiceProvider);
    final stationName = _currentStationName;
    final isPlaying = radioService.isPlaying;
    final isLoading = radioService.isLoading;
    final error = radioService.error;
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
          return Column(
            children: [
              if (isLoading)
                LinearProgressIndicator(
                  minHeight: 3,
                  color: Theme.of(context).colorScheme.primary,
                ),
              if (error != null && !isLoading)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            error,
                            style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: ListView(
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
                          isActive: stationName == radio.name && isPlaying,
                          trailing: _unavailable.contains(radio.name)
                              ? Tooltip(
                                  message:
                                      'Flux radio indisponible sur cette station',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .errorContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.error_outline_rounded,
                                          size: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onErrorContainer,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Indisponible',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onErrorContainer,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: Icon(
                                    stationName == radio.name && isPlaying
                                        ? Icons.stop_circle_outlined
                                        : Icons.play_circle_outline,
                                  ),
                                  color: stationName == radio.name && isPlaying
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                  onPressed: () => _toggleStation(radio),
                                ),
                          onTap: () => _toggleStation(radio),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingState(message: 'Chargement…'),
        error: (err, _) => ErrorState(
          icon: Icons.radio,
          title: 'Stations indisponibles',
          message: userFriendlyError(err),
          onRetry: () => ref.invalidate(radioChannelsProvider),
        ),
      ),
    );
  }

  String? _currentStationName;
  final Set<String> _unavailable = {};

  Future<void> _toggleStation(Channel radio) async {
    final radioService = ref.read(radioServiceProvider);
    if (_currentStationName == radio.name && radioService.isPlaying) {
      await radioService.stop();
      setState(() {
        _currentStationName = null;
        _unavailable.remove(radio.name);
      });
    } else {
      await radioService.play(radio.streamUrl);
      setState(() {
        if (radioService.error != null) {
          _unavailable.add(radio.name);
          _currentStationName = null;
        } else {
          _unavailable.remove(radio.name);
          _currentStationName = radio.name;
        }
      });
    }
  }
}
