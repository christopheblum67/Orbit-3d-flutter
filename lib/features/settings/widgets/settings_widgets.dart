import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';

/// Titre de section dans les écrans de configuration.
class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: scheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Liste déroulante sur fond de carte, pour les choix de configuration.
class SettingsDropdownTile<T> extends StatelessWidget {
  const SettingsDropdownTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.options,
    required this.onChanged,
    this.icon,
  });

  final String title;
  final String subtitle;
  final T value;
  final List<T> options;
  final ValueChanged<T> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labels = options.map(_label).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: icon == null
              ? null
              : Icon(icon!, color: scheme.primary),
          title: Text(title, style: const TextStyle(fontSize: 14)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ),
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isDense: true,
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              items: [
                for (var i = 0; i < options.length; i++)
                  DropdownMenuItem(value: options[i], child: Text(labels[i])),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ),
    );
  }

  String _label(T value) => value.toString();
}

/// Interrupteur sur fond de carte, stylé pour la configuration.
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: icon == null
              ? null
              : Icon(icon, color: scheme.primary),
          activeThumbColor: scheme.primary,
          activeTrackColor: scheme.primary.withValues(alpha: 0.4),
          title: Text(title, style: const TextStyle(fontSize: 14)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Tuile de navigation sur fond de carte (avec chevron), utilisée pour
/// ouvrir une sous-fenêtre ou une page de configuration.
class SettingsNavTile extends StatelessWidget {
  const SettingsNavTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: icon == null
              ? null
              : Icon(icon!, color: scheme.primary),
          title: Text(title, style: const TextStyle(fontSize: 14)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ),
          trailing: trailing ??
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          onTap: onTap,
        ),
      ),
    );
  }
}
