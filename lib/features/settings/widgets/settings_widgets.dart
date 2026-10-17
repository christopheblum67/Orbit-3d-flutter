import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Séparateur de groupe **distinctif** : un double trait horizontal encadrant
/// un libellé en majuscules espacées, teinté par la couleur tertiaire du thème.
///
/// Utilisé pour marquer la frontière entre deux menus historiquement séparés
/// que l'on a fusionnés dans un même onglet (ex. « Réseau » + « Sécurité ») :
/// l'œil identifie immédiatement où commence le second groupe, là où le
/// [SettingsSectionTitle] classique (couleur primaire, sans trait) ne sert
/// qu'à nommer une sous-catégorie interne.
class SettingsGroupDivider extends StatelessWidget {
  const SettingsGroupDivider(this.label, {super.key, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.tertiary;
    final line = Expanded(
      child: Divider(color: accent.withValues(alpha: 0.45), thickness: 1.5),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 4),
      child: Row(
        children: [
          line,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: accent),
                  const SizedBox(width: 6),
                ],
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
          line,
        ],
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
        child: Focus(
          // Le nœud de focus est porté par le `DropdownButton` (voir plus bas).
          // Le donner aussi au `Focus` parent levait « FocusNode._reparent:
          // assert(child != this) » à chaque frame (rendu en échec en debug).
          // Ce parent ne sert qu'à exposer `hasFocus` (visuel) ; il ne doit
          // donc pas être une cible de focus lui-même.
          canRequestFocus: false,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.select ||
                    event.logicalKey == LogicalKeyboardKey.space ||
                    event.logicalKey == LogicalKeyboardKey.gameButtonA ||
                    event.logicalKey == LogicalKeyboardKey.arrowDown)) {
              return KeyEventResult.ignored;
            }
            return KeyEventResult.ignored;
          },
          child: Builder(
            builder: (context) {
              final focused = Focus.of(context).hasFocus;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: icon == null
                    ? null
                    : Icon(
                        icon!,
                        color:
                            focused ? scheme.primary : scheme.onSurfaceVariant,
                      ),
                title: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: focused ? FontWeight.w700 : FontWeight.w400,
                    color: focused ? scheme.primary : null,
                  ),
                ),
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
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    isDense: true,
                    borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                    items: [
                      for (var i = 0; i < options.length; i++)
                        DropdownMenuItem(
                          value: options[i],
                          child: Text(labels[i]),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) onChanged(v);
                    },
                  ),
                ),
              );
            },
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
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.space ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          onChanged(!value);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: icon == null
                    ? null
                    : Icon(
                        icon,
                        color:
                            focused ? scheme.primary : scheme.onSurfaceVariant,
                      ),
                activeThumbColor: scheme.primary,
                activeTrackColor: scheme.primary.withValues(alpha: 0.4),
                title: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: focused ? FontWeight.w700 : FontWeight.w400,
                    color: focused ? scheme.primary : null,
                  ),
                ),
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
        },
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
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.space ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: icon == null
                    ? null
                    : Icon(
                        icon!,
                        color:
                            focused ? scheme.primary : scheme.onSurfaceVariant,
                      ),
                title: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: focused ? FontWeight.w700 : FontWeight.w400,
                    color: focused ? scheme.primary : null,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle,
                    style:
                        TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                ),
                trailing: trailing ??
                    Icon(
                      Icons.chevron_right,
                      color: focused ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                onTap: onTap,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Tuile d'action sur fond de carte (bouton avec label + icône),
/// utilisée pour déclencher une action immédiate (reset, clear, etc.).
class SettingsActionTile extends StatelessWidget {
  const SettingsActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.space ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: icon == null
                    ? null
                    : Icon(
                        icon!,
                        color:
                            focused ? scheme.primary : scheme.onSurfaceVariant,
                      ),
                title: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: focused ? FontWeight.w700 : FontWeight.w400,
                    color: focused ? scheme.primary : null,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle,
                    style:
                        TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: focused ? scheme.primary : scheme.onSurfaceVariant,
                ),
                onTap: onTap,
              ),
            ),
          );
        },
      ),
    );
  }
}
