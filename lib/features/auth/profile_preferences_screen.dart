import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

class ProfilePreferencesScreen extends ConsumerWidget {
  const ProfilePreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);

    return Scaffold(
        appBar: AppBar(
          leading: GoRouter.of(context).canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Retour',
                  onPressed: () => GoRouter.of(context).pop(),
                )
              : null,
          title: Text(l.preferences),
        ),
        body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Notifications'),
            subtitle: Text(l.receiveAlertsAndTips),
            value: prefs.notificationsEnabled,
            onChanged: (v) => notifier.setNotifications(v),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.settings_brightness_outlined),
            title: Text(l.theme),
            subtitle: Text(_themeLabel(prefs.theme)),
            trailing: DropdownButton<String>(
              value: prefs.theme,
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(value: 'system', child: Text(l.system)),
                const DropdownMenuItem(value: 'light', child: Text('Clair')),
                const DropdownMenuItem(value: 'dark', child: Text('Sombre')),
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
              items: [
                DropdownMenuItem(value: 'fr', child: Text(l.langFrench)),
                const DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'es', child: Text(l.langSpanish)),
                const DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                const DropdownMenuItem(value: 'it', child: Text('Italiano')),
                DropdownMenuItem(value: 'ar', child: Text(l.langArabic)),
              ],
              onChanged: (v) {
                if (v != null) notifier.setLanguage(v);
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.family_restroom_outlined),
            title: Text(l.sectionParental),
            subtitle: Text(
              prefs.parentalControlEnabled
                  ? 'Activé · Restriction ${prefs.ageRestriction > 0 ? l.plusAgeYears(prefs.ageRestriction) : 'désactivée'}'
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
          SwitchListTile(
            secondary: const Icon(Icons.visibility_outlined),
            title: Text(l.profileVisible),
            subtitle:
                Text(l.appearInSearchAndRecommendations),
            value: prefs.profileVisible,
            onChanged: (v) => notifier.setProfileVisible(v),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.video_camera_back_outlined),
            title: const Text('Autoriser l\'enregistrement'),
            subtitle: const Text(
                'Permettre l\'enregistrement de mes contenus favoris',),
            value: prefs.allowRecording,
            onChanged: (v) => notifier.setAllowRecording(v),
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
    switch (lang) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'de':
        return 'Deutsch';
      case 'it':
        return 'Italiano';
      case 'ar':
        return 'العربية';
      default:
        return 'Français';
    }
  }

  Future<({bool enabled, int ageRestriction})?> _showParentalDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic prefs,
  ) async {
    final l = AppLocalizations.of(context);
    bool enabled = prefs.parentalControlEnabled;
    int ageRestriction = prefs.ageRestriction;

    final cancelFocus = FocusNode();
    final confirmFocus = FocusNode();
    final switchFocus = FocusNode();
    final dropdownFocus = FocusNode();

    void requestFocus(FocusNode focus) {
      if (context.mounted) {
        FocusScope.of(context).requestFocus(focus);
      }
    }

    final result = await showDialog<({bool enabled, int ageRestriction})>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l.sectionParental),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Focus(
                    focusNode: switchFocus,
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.enter ||
                            event.logicalKey == LogicalKeyboardKey.select ||
                            event.logicalKey == LogicalKeyboardKey.gameButtonA ||
                            event.logicalKey == LogicalKeyboardKey.arrowRight ||
                            event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                          setState(() => enabled = !enabled);
                          return KeyEventResult.handled;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                          requestFocus(dropdownFocus);
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: SwitchListTile(
                      title: const Text('Activer'),
                      value: enabled,
                      onChanged: (v) => setState(() => enabled = v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Focus(
                    focusNode: dropdownFocus,
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                          requestFocus(switchFocus);
                          return KeyEventResult.handled;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                          requestFocus(confirmFocus);
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: DropdownButtonFormField<int>(
                      initialValue: ageRestriction,
                      decoration:
                          const InputDecoration(labelText: 'Restriction d\'âge'),
                      items: [
                        const DropdownMenuItem(value: 0, child: Text('Aucune')),
                        for (final age in [7, 10, 12, 16, 18])
                          DropdownMenuItem(value: age, child: Text(l.plusAgeYears(age))),
                      ],
                      onChanged: (v) => setState(() => ageRestriction = v ?? 0),
                    ),
                  ),
                ],
              ),
              actions: [
                Focus(
                  focusNode: cancelFocus,
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent &&
                        (event.logicalKey == LogicalKeyboardKey.enter ||
                            event.logicalKey == LogicalKeyboardKey.select ||
                            event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                      Navigator.pop(dialogContext);
                      return KeyEventResult.handled;
                    }
                    if (event is KeyDownEvent &&
                        (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                            event.logicalKey == LogicalKeyboardKey.arrowLeft)) {
                      requestFocus(confirmFocus);
                      return KeyEventResult.handled;
                    }
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      requestFocus(dropdownFocus);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Annuler'),
                  ),
                ),
                Focus(
                  focusNode: confirmFocus,
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent &&
                        (event.logicalKey == LogicalKeyboardKey.enter ||
                            event.logicalKey == LogicalKeyboardKey.select ||
                            event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                      Navigator.pop(
                        dialogContext,
                        (enabled: enabled, ageRestriction: ageRestriction),
                      );
                      return KeyEventResult.handled;
                    }
                    if (event is KeyDownEvent &&
                        (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                            event.logicalKey == LogicalKeyboardKey.arrowLeft)) {
                      requestFocus(cancelFocus);
                      return KeyEventResult.handled;
                    }
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      requestFocus(dropdownFocus);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      dialogContext,
                      (enabled: enabled, ageRestriction: ageRestriction),
                    ),
                    child: const Text('Valider'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    cancelFocus.dispose();
    confirmFocus.dispose();
    switchFocus.dispose();
    dropdownFocus.dispose();

    return result;
  }
}
