import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/subscription_manager.dart';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _m3uUrlController = TextEditingController();
  String _sourceType = 'xtream'; // 'xtream' ou 'm3u'

  @override
  void dispose() {
    _baseUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _m3uUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des abonnements')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'xtream', label: Text('Xtream Codes')),
                  ButtonSegment(value: 'm3u', label: Text('M3U Playlist')),
                ],
                selected: {_sourceType},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _sourceType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 20),
              if (_sourceType == 'xtream') ...[
                TextFormField(
                  controller: _baseUrlController,
                  decoration: const InputDecoration(labelText: 'URL du serveur (ex: http://provider.com)'),
                  validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                ),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                ),
              ] else ...[
                TextFormField(
                  controller: _m3uUrlController,
                  decoration: const InputDecoration(labelText: 'URL de la playlist M3U'),
                  validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                ),
              ],
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final manager = SubscriptionManager();
                    if (_sourceType == 'xtream') {
                      await manager.saveXtream(
                        baseUrl: _baseUrlController.text.trim(),
                        username: _usernameController.text.trim(),
                        password: _passwordController.text.trim(),
                      );
                    } else {
                      await manager.saveM3u(_m3uUrlController.text.trim());
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Abonnement sauvegardé')),
                      );
                      Navigator.of(context).pop();
                    }
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
