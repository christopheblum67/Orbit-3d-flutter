import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';

class ProfilePreferencesScreen extends ConsumerWidget {
  const ProfilePreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Préférences')),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Notifications'),
            subtitle: const Text('Recevoir les alertes et conseils'),
            value: prefs.notificationsEnabled,
            onChanged: (v) => notifier.setNotifications(v),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.settings_brightness_outlined),
            title: const Text('Thème'),
            subtitle: Text(_themeLabel(prefs.theme)),
            trailing: DropdownButton<String>(
              value: prefs.theme,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'system', child: Text('Système')),
                DropdownMenuItem(value: 'light', child: Text('Clair')),
                DropdownMenuItem(value: 'dark', child: Text('Sombre')),
              ],
              onChanged: (v) {
                if (v != null) notifier.setTheme(v);
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Langue'),
            subtitle: Text(_langLabel(prefs.language)),
            trailing: DropdownButton<String>(
              value: prefs.language,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'fr', child: Text('Français')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (v) {
                if (v != null) notifier.setLanguage(v);
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.family_restroom_outlined),
            title: const Text('Contrôle parental'),
            subtitle: Text(
              prefs.parentalControlEnabled
                  ? 'Activé · Restriction ${prefs.ageRestriction > 0 ? '+${prefs.ageRestriction} ans' : 'désactivée'}'
                  : 'Désactivé',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final result = await _showParentalDialog(context, ref, prefs);
              if (result != null) {
                await notifier.updateParental(
                  enabled: result.enabled,
                  ageRestriction: result.ageRestriction,
                );
              }
            },
          ),
          const Divider(height: 1),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'Vos préférences sont appliquées à votre profil.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _themeLabel(String theme) {
    switch (theme) {
      case 'light':
        return 'Clair';
      case 'dark':
        return 'Sombre';
      default:
        return 'Système';
    }
  }

  String _langLabel(String lang) {
    return lang == 'en' ? 'English' : 'Français';
  }

  Future<({bool enabled, int ageRestriction})?> _showParentalDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic prefs,
  ) async {
    bool enabled = prefs.parentalControlEnabled;
    int ageRestriction = prefs.ageRestriction;
    return await showDialog<({bool enabled, int ageRestriction})>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Contrôle parental'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Activer'),
                    value: enabled,
                    onChanged: (v) => setState(() => enabled = v),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: ageRestriction,
                    decoration:
                        const InputDecoration(labelText: 'Restriction d\'âge'),
                    items: [
                      const DropdownMenuItem(value: 0, child: Text('Aucune')),
                      for (final age in [7, 10, 12, 16, 18])
                        DropdownMenuItem(value: age, child: Text('+$age ans')),
                    ],
                    onChanged: (v) => setState(() => ageRestriction = v ?? 0),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context,
                      (enabled: enabled, ageRestriction: ageRestriction),),
                  child: const Text('Valider'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
