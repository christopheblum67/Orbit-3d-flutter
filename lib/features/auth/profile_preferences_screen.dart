import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

class ProfilePreferencesScreen extends ConsumerWidget {
  const ProfilePreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);
    final profile = ref.watch(currentProfileProvider);

    Future<void> setMultiTv(bool enabled) async {
      try {
        await ref
            .read(currentProfileProvider.notifier)
            .setMultiTvEnabled(enabled);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.preferenceMultiTvFailed),
            ),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        // Retour toujours visible : en route racine (accès direct par les
        // réglages), `canPop()` est false et l'icône disparaissait.
        leading: TvFocus(
          autofocus: true,
          onActivate: () {
            final router = GoRouter.of(context);
            if (router.canPop()) {
              router.pop();
            } else {
              router.go('/settings');
            }
          },
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () {
              final router = GoRouter.of(context);
              if (router.canPop()) {
                router.pop();
              } else {
                router.go('/settings');
              }
            },
          ),
        ),
        title: Text(l.preferences),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.settings_brightness_outlined),
            title: Text(l.theme),
            subtitle: Text(_themeLabel(prefs.theme, l)),
            trailing: DropdownButton<String>(
              value: prefs.theme,
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(value: 'system', child: Text(l.system)),
                DropdownMenuItem(
                    value: 'light', child: Text(l.preferenceLight)),
                DropdownMenuItem(value: 'dark', child: Text(l.preferenceDark)),
              ],
              onChanged: (v) {
                if (v != null) notifier.setTheme(v);
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(l.language),
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
          Focus(
            canRequestFocus: profile != null,
            onKeyEvent: (node, event) {
              if (profile != null &&
                  event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.select ||
                      event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                setMultiTv(!profile.multiTvEnabled);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: SwitchListTile(
              secondary: const Icon(Icons.grid_view_rounded),
              title: const Text('Multi TV'),
              subtitle: Text(l.preferenceMultiTvHelp),
              value: profile?.multiTvEnabled ?? true,
              onChanged: profile == null ? null : setMultiTv,
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.video_camera_back_outlined),
            title: Text(l.preferenceAllowRecording),
            subtitle: Text(l.preferenceRecordingHelp),
            value: prefs.allowRecording,
            onChanged: (v) => notifier.setAllowRecording(v),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.live_tv_outlined),
            title: Text(l.preferenceLivePreview),
            subtitle: Text(l.preferenceLivePreviewHelp),
            value: ref.watch(advancedSettingsProvider).livePreviewVideo ?? true,
            onChanged:
                ref.read(advancedSettingsProvider.notifier).setLivePreviewVideo,
          ),
          const Divider(height: 1),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                l.preferenceProfileHelp,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _themeLabel(String theme, AppLocalizations l) {
    switch (theme) {
      case 'light':
        return l.preferenceLight;
      case 'dark':
        return l.preferenceDark;
      default:
        return l.system;
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
}
