import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> {
  List<String> _recommendations = [];
  bool _loading = false;

  Future<void> _loadRecommendations() async {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun profil sélectionné')),
      );
      return;
    }

    setState(() => _loading = true);
    final aiService = ref.read(aiServiceProvider);
    final results = await aiService.getRecommendations(profile);
    setState(() {
      _recommendations = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recommandations IA')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _loading ? null : _loadRecommendations,
              icon: const Icon(Icons.auto_awesome),
              label: Text(_loading ? 'Chargement...' : 'Obtenir des recommandations'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _recommendations.length,
                      itemBuilder: (context, index) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.movie),
                          title: Text(_recommendations[index]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
