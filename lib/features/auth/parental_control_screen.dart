import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';

class ParentalControlScreen extends ConsumerStatefulWidget {
  const ParentalControlScreen({super.key});

  @override
  ConsumerState<ParentalControlScreen> createState() =>
      _ParentalControlScreenState();
}

class _ParentalControlScreenState extends ConsumerState<ParentalControlScreen> {
  final _pinController = TextEditingController();
  bool _hasPin = false;
  bool _obscurePin = true;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final pin = await ref.read(parentalPinControllerProvider).getPin();
    if (mounted) {
      setState(() => _hasPin = pin != null && pin.isNotEmpty);
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);
    final pinController = ref.read(parentalPinControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Contrôle parental')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.gpp_good_outlined),
            title: const Text('Activer le contrôle parental'),
            value: prefs.parentalControlEnabled,
            onChanged: (v) => notifier.updateParental(
              enabled: v,
              ageRestriction: v ? prefs.ageRestriction : 0,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: prefs.ageRestriction,
            decoration: const InputDecoration(
              labelText: 'Restriction d\'âge',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: 0, child: Text('Aucune')),
              for (final age in [7, 10, 12, 16, 18])
                DropdownMenuItem(value: age, child: Text('+$age ans')),
            ],
            onChanged: (v) => notifier.updateParental(
              enabled: prefs.parentalControlEnabled,
              ageRestriction: v ?? 0,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            _hasPin ? 'PIN actuel : ${'•' * 4}' : 'Définir un code PIN',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: _obscurePin,
            maxLength: 4,
            decoration: InputDecoration(
              labelText:
                  _hasPin ? 'Nouveau PIN (4 chiffres)' : 'PIN (4 chiffres)',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _obscurePin ? 'Afficher le PIN' : 'Masquer le PIN',
                icon:
                    Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.lock_outline),
            label: Text(_hasPin ? 'Mettre à jour le PIN' : 'Définir le PIN'),
            onPressed: _savePin,
          ),
          if (_hasPin) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.lock_open_outlined),
              label: const Text('Supprimer le PIN'),
              onPressed: () => _clearPin(pinController),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _savePin() async {
    final pin = _pinController.text.trim();
    if (pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Le PIN doit contenir exactement 4 chiffres'),),
      );
      return;
    }
    final pinController = ref.read(parentalPinControllerProvider);
    await pinController.setPin(pin);
    _pinController.clear();
    setState(() => _hasPin = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN enregistré')),
      );
    }
  }

  Future<void> _clearPin(ParentalPinController controller) async {
    await controller.clearPin();
    setState(() => _hasPin = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN supprimé')),
      );
    }
  }
}
