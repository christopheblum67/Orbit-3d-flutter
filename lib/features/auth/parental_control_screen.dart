import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

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
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);
    final profile = ref.watch(currentProfileProvider);
    final pinController = ref.read(parentalPinControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: GoRouter.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Retour',
                onPressed: () => GoRouter.of(context).pop(),
              )
            : null,
        title: Text(l.sectionParental),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.gpp_good_outlined),
            title: Text(l.enableParentalControl),
            value: prefs.parentalControlEnabled,
            onChanged: (v) => notifier.updateParental(
              enabled: v,
              ageRestriction: v ? prefs.ageRestriction : 0,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: prefs.ageRestriction,
            decoration: const InputDecoration(
              labelText: 'Restriction d\'âge',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: 0, child: Text('Aucune')),
              for (final age in [7, 10, 12, 16, 18])
                DropdownMenuItem(value: age, child: Text(l.plusAgeYears(age))),
            ],
            onChanged: (v) => notifier.updateParental(
              enabled: prefs.parentalControlEnabled,
              ageRestriction: v ?? 0,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),

          SwitchListTile(
            secondary: const Icon(Icons.no_adult_content_outlined),
            title: Text('Masquer le contenu adulte'),
            subtitle: Text('Films/Séries/Chaînes classés 18+ ou érotique'),
            value: profile?.hideAdultContent ?? false,
            onChanged: (v) => _updateContentFilter(
              hideAdultContent: v,
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.no_backpack_outlined),
            title: Text('Masquer la violence'),
            subtitle: Text('Contenus Gore / Horreur / Thriller / Meurtre'),
            value: profile?.hideViolentContent ?? false,
            onChanged: (v) => _updateContentFilter(
              hideViolentContent: v,
            ),
          ),
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
              label: Text(l.deletePin),
              onPressed: () => _clearPin(pinController),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _savePin() async {
    final l = AppLocalizations.of(context);
    final pin = _pinController.text.trim();
    if (pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.pinMustBe4Digits)),
      );
      return;
    }
    await ref.read(parentalPinControllerProvider).setPin(pin);
    _pinController.clear();
    setState(() => _hasPin = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.pinSaved)),
      );
    }
  }

  Future<void> _clearPin(dynamic controller) async {
    final l = AppLocalizations.of(context);
    await controller.clearPin();
    setState(() => _hasPin = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.pinDeleted)),
      );
    }
  }

  Future<void> _updateContentFilter({
    bool? hideAdultContent,
    bool? hideViolentContent,
  }) async {
    final current = ref.read(currentProfileProvider);
    if (current == null) return;
    final updated = current.copyWith(
      hideAdultContent: hideAdultContent ?? current.hideAdultContent,
      hideViolentContent: hideViolentContent ?? current.hideViolentContent,
    );
    await ref.read(storageServiceProvider).saveProfile(updated);
    ref.read(currentProfileProvider.notifier).setUserProfile(updated);
    ref.invalidate(profilesProvider);
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}
