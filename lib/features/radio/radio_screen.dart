import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

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
    final radioService = ref.read(radioServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Radio')),
      body: radiosAsync.when(
        data: (radios) => ListView.builder(
          itemCount: radios.length,
          itemBuilder: (context, index) {
            final radio = radios[index];
            return ListTile(
              leading: const Icon(Icons.radio),
              title: Text(radio.name),
              trailing: _currentStationName == radio.name && _isPlaying
                  ? const Icon(Icons.stop)
                  : const Icon(Icons.play_arrow),
              onTap: () async {
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
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}
