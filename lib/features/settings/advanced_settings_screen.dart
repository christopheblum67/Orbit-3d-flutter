import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/settings_widgets.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/providers/opensubtitles_api_key_provider.dart';
import 'package:orbit_3d_flutter/providers/tmdb_api_key_provider.dart';

/// Code d'accès à l'écran des réglages sensibles.
///
/// ## Ce que ce code protège — et ce qu'il ne protège pas
///
/// Il ne protège **rien** au sens cryptographique : le code est dans le
/// binaire, la vérification est dans l'application, et un appareil rooté ou un
/// `adb shell` contourne les deux en quelques secondes. C'est un **rideau** :
/// il évite qu'un utilisateur ouvre cet écran par hasard et modifie une clé
/// d'API, il n'empêche pas un attaquant de s'en emparer.
///
/// ## Pourquoi les clés sont là plutôt que dans les réglages publics
///
/// Les réglages publics sont destinés à un utilisateur courant. Une clé d'API
/// est un identifiant personnel : la partager engage un quota sur un service
/// tiers, et une clé OpenSubtitles permet de télécharger des sous-titres. Elle
/// mérite un écran séparé, pas une tuile au milieu des préférences de lecture.
const String kAdvancedSettingsCode = '54321';

/// Demande le code et renvoie true s'il est correct.
///
/// Le code n'est jamais journalisé et la saisie est masquée. Aucun compteur
/// d'échecs n'est tenu : sur un appareil personnel, verrouiller au bout de
/// trois essais n'arrête personne et perd l'utilisateur qui a oublié son code.
Future<bool> requestAdvancedAccess(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final controller = TextEditingController();

  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => AlertDialog(
      title: Text(l.advancedAccessTitle),
      content: TextField(
        controller: controller,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 8,
        // Un code temporaire n'a rien à faire dans le Presse-papiers : il ne
        // doit pas pouvoir être copié par accident.
        enableSuggestions: false,
        autocorrect: false,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          hintText: l.advancedAccessHint,
          counterText: '',
        ),
        onSubmitted: (_) => Navigator.of(dialogContext).pop(true),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l.advancedAccessConfirm),
        ),
      ],
    ),
  );

  controller.dispose();
  if (accepted != true) return false;

  if (controller.text.trim() == kAdvancedSettingsCode) return true;

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.advancedAccessWrong)),
    );
  }
  return false;
}

/// Réglages sensibles : identifiants d'API et paramètres réseau.
class AdvancedSettingsScreen extends ConsumerStatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  ConsumerState<AdvancedSettingsScreen> createState() =>
      _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends ConsumerState<AdvancedSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final tmdbKey = ref.watch(tmdbApiKeyOverrideProvider);
    final osKey = ref.watch(openSubtitlesApiKeyProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.canPop() ? context.pop() : context.go('/settings'),
        ),
        title: Text(l.advancedSettingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l.advancedSettingsIntro,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          SettingsSectionTitle(l.sectionTmdb),
          const TmdbApiKeyTile(),
          const SizedBox(height: 24),
          SettingsSectionTitle(l.advancedSubtitlesProvider),
          const OpenSubtitlesApiKeyTile(),
          const SizedBox(height: 24),
          SettingsSectionTitle(l.advancedStatus),
          _KeyStatus(
            label: l.tmdbKeyLabel,
            active: tmdbKey.isNotEmpty,
          ),
          _KeyStatus(
            label: l.opensubtitlesKeyLabel,
            active: osKey.isNotEmpty,
          ),
        ],
      ),
    );
  }
}

/// État d'une clé : présente ou absente, sans jamais la montrer.
class _KeyStatus extends StatelessWidget {
  const _KeyStatus({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        active ? Icons.check_circle_outline : Icons.remove_circle_outline,
        color: active ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(label),
      subtitle: Text(
        active ? '••••••••' : '—',
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
/// Tuile de saisie de la clé TMDB.
///
/// Vibrer avant d'afficher le champ : la clé n'a rien de confidentiel dans un
/// registre de sécurité, mais elle n'a rien à faire dans les réglages publics.
class TmdbApiKeyTile extends ConsumerStatefulWidget {
  const TmdbApiKeyTile();

  @override
  ConsumerState<TmdbApiKeyTile> createState() => _TmdbApiKeyTileState();
}

/// Clé API OpenSubtitles.
///
/// L'API refusant toute requête sans clé, une valeur vide ne rend pas
/// l'application moins fonctionnelle : elle rend la recherche en ligne
/// impossible.
class OpenSubtitlesApiKeyTile extends ConsumerWidget {
  const OpenSubtitlesApiKeyTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final key = ref.watch(openSubtitlesApiKeyProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.opensubtitlesKeyLabel,
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        _ApiKeyField(
          value: key,
          hint: l.opensubtitlesKeyHint,
          onSubmitted: (value) async {
            await ref
                .read(openSubtitlesApiKeyProvider.notifier)
                .setApiKey(value);
          },
        ),
        const SizedBox(height: 8),
        Text(
          key.isEmpty ? l.opensubtitlesKeyAnonymous : l.opensubtitlesKeyActive,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: key.isEmpty ? scheme.onSurfaceVariant : scheme.primary,
              ),
        ),
        if (key.isNotEmpty) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await ref
                  .read(openSubtitlesApiKeyProvider.notifier)
                  .setApiKey('');
            },
            icon: const Icon(Icons.delete_outline),
            label: Text(l.opensubtitlesKeyDelete),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error),
            ),
          ),
        ],
      ],
    );
  }
}

/// Champ de saisie de clé : masqué par défaut, œil pour basculer.
class _ApiKeyField extends StatefulWidget {
  const _ApiKeyField({
    required this.value,
    required this.hint,
    required this.onSubmitted,
  });

  final String value;
  final String hint;
  final ValueChanged<String> onSubmitted;

  @override
  State<_ApiKeyField> createState() => _ApiKeyFieldState();
}

class _ApiKeyFieldState extends State<_ApiKeyField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: const Icon(Icons.vpn_key_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () => widget.onSubmitted(_controller.text.trim()),
          icon: const Icon(Icons.save_rounded),
          label: Text(l.save),
        ),
      ],
    );
  }
}

class _TmdbApiKeyTileState extends ConsumerState<TmdbApiKeyTile> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(tmdbApiKeyOverrideProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final hasOverride = ref.watch(tmdbApiKeyOverrideProvider).isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                obscureText: _obscure,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: l.tmdbKeyLabel,
                  hintText: l.tmdbKeyHint,
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(l.save),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          hasOverride ? l.tmdbKeyActive : l.tmdbKeyShared,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: hasOverride ? scheme.primary : scheme.onSurfaceVariant,
              ),
        ),
        if (hasOverride) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _clear,
            icon: const Icon(Icons.delete_outline),
            label: Text(l.tmdbKeyDelete),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.error,
              side: BorderSide(color: scheme.error),
            ),
          ),
        ],
      ],
    );
  }

  void _save() async {
    final key = _controller.text.trim();
    await ref
        .read(tmdbApiKeyOverrideProvider.notifier)
        .setOverride(key.isEmpty ? '' : key);
    if (mounted) setState(() {});
  }

  void _clear() async {
    await ref.read(tmdbApiKeyOverrideProvider.notifier).setOverride('');
    _controller.clear();
    if (mounted) setState(() {});
  }
}