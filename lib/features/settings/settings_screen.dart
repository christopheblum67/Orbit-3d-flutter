import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/settings_widgets.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/player_engine_config_sheet.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/memory_settings_panel.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/device_profile_provider.dart';
import 'package:orbit_3d_flutter/providers/preferences_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/subscription_provider.dart';
import 'package:orbit_3d_flutter/providers/tmdb_api_key_provider.dart';
import 'package:orbit_3d_flutter/services/settings_backup_service.dart';

/// Menu de configuration organisé en onglets, inspiré de la concurrence
/// (XCIPTV). Réunit les réglages standard (compte, sécurité, notification)
/// et les options avancées persistées via [advancedSettingsProvider].
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        actions: [
          IconButton(
            tooltip: 'Configuration avancée',
            icon: const Icon(Icons.tune),
            onPressed: () => context.go('/settings/advanced'),
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.person_outline), text: 'Compte'),
              Tab(icon: Icon(Icons.network_wifi), text: 'Réseau'),
              Tab(icon: Icon(Icons.play_circle_outline), text: 'Lecture'),
              Tab(icon: Icon(Icons.shield_outlined), text: 'Sécurité'),
              Tab(icon: Icon(Icons.auto_awesome), text: 'Contenu'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _AccountTab(),
                _NetworkTab(),
                _PlaybackTab(),
                _SecurityTab(),
                _ContentTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTab extends ConsumerWidget {
  const _AccountTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final sub = ref.watch(activeSubscriptionProvider).valueOrNull;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SettingsSectionTitle('Compte & Profil'),
        _NavTile(
          icon: Icons.person,
          title: 'Profils',
          subtitle: 'Gérer les profils et le profil actif',
          onTap: () => context.go('/profiles'),
        ),
        _NavTile(
          icon: Icons.subscriptions,
          title: 'Abonnements',
          subtitle: sub == null
              ? 'Aucun abonnement actif'
              : '${sub.name} · ${sub.validityLabel}',
          onTap: () => context.go('/subscriptions'),
        ),
        _NavTile(
          icon: Icons.settings_outlined,
          title: 'Préférences',
          subtitle: 'Langue, thème et restrictions d\'âge',
          onTap: () => context.go('/profile/preferences'),
        ),
        _NavTile(
          icon: Icons.memory_rounded,
          title: 'Configurer l\'appareil',
          subtitle:
              'Profil ${ref.watch(deviceProfileProvider).label} · diagnostic et réglages du lecteur',
          onTap: () => context.go('/onboarding'),
        ),
        const SizedBox(height: 8),
        const SettingsSectionTitle('Notifications'),
        _NavTile(
          icon: Icons.notifications,
          title: 'Tester les notifications',
          subtitle: 'Envoie une notification locale de test',
          onTap: () async {
            final notificationService = ref.read(notificationServiceProvider);
            await notificationService.showNotification(
              'Orbit IPTV',
              'Ceci est une notification test',
            );
          },
          trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        const SettingsSectionTitle('Sauvegarde'),
        _NavTile(
          icon: Icons.upload_outlined,
          title: 'Exporter les réglages',
          subtitle: 'Copie la config (réseau, lecteur, audio, accessibilité) dans le presse-papiers',
          onTap: () => _exportSettings(context, ref),
          trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ),
        _NavTile(
          icon: Icons.download_outlined,
          title: 'Importer les réglages',
          subtitle: 'Restaure depuis le presse-papiers (JSON)',
          onTap: () => _importSettings(context, ref),
          trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _NetworkTab extends ConsumerWidget {
  const _NetworkTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(advancedSettingsProvider);
    final n = ref.read(advancedSettingsProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SettingsSectionTitle('Protection contre le bridage FAI'),
        SettingsSwitchTile(
          title: 'TLS Impersonation (Proxy Local)',
          subtitle:
              'Simule l\'empreinte d\'un navigateur moderne pour contourner Cloudflare',
          value: s.useTlsImpersonation,
          onChanged: n.setTlsImpersonation,
          icon: Icons.shield_outlined,
        ),
        const _DnsProviderTile(),
      ],
    );
  }
}

class _DnsProviderTile extends ConsumerWidget {
  const _DnsProviderTile();

  static const _options = <String>[
    '1.1.1.1 (Cloudflare DoH)',
    '8.8.8.8 (Google DoH)',
    '9.9.9.9 (Quad9 DoH)',
    'Automatique (Système)',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(advancedSettingsProvider);
    final n = ref.read(advancedSettingsProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.dns_outlined,
              color: Theme.of(context).colorScheme.primary),
          title: const Text('Fournisseur DNS', style: TextStyle(fontSize: 14)),
          subtitle: const Text(
            'Serveur utilisé pour les requêtes DoH',
            style: TextStyle(fontSize: 11),
          ),
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _options.contains(s.dnsProvider)
                  ? s.dnsProvider
                  : _options.last,
              isDense: true,
              items: [
                for (final o in _options)
                  DropdownMenuItem(value: o, child: Text(o)),
              ],
              onChanged: (v) {
                if (v != null) n.setDnsProvider(v);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaybackTab extends ConsumerWidget {
  const _PlaybackTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(advancedSettingsProvider);
    final n = ref.read(advancedSettingsProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SettingsSectionTitle('Moteur de lecture'),
        const _PlayerEngineTile(),
        const SettingsSectionTitle('Rendu Vidéo et Zapping'),
        SettingsSwitchTile(
          title: 'Zapping Instantané (Prefetching)',
          subtitle: 'Précharge les chaînes adjacentes en mémoire tampon',
          value: s.zeroLagPrefetch,
          onChanged: n.setZeroLagPrefetch,
          icon: Icons.fast_forward_outlined,
        ),
        const SizedBox(height: 8),
        const SettingsSectionTitle('Mémoire & Cache'),
        const MemorySettingsPanel(),
      ],
    );
  }
}

class _PlayerEngineTile extends ConsumerWidget {
  const _PlayerEngineTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(advancedSettingsProvider);
    return SettingsNavTile(
      icon: Icons.play_circle_outline,
      title: 'Moteurs de lecture',
      subtitle:
          'Live : ${s.playerLive.primary.label} · VOD : ${s.playerVod.primary.label}',
      onTap: () => showPlayerEngineConfigSheet(context),
    );
  }
}

class _SecurityTab extends ConsumerWidget {
  const _SecurityTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SettingsSectionTitle('Contrôle parental'),
        _NavTile(
          icon: Icons.gpp_good_outlined,
          title: 'Contrôle parental',
          subtitle: 'Ajouter un code PIN et restreindre le contenu',
          onTap: () => context.go('/parental'),
        ),
        const SizedBox(height: 8),
        const SettingsSectionTitle('Informations légales'),
        _NavTile(
          icon: Icons.balance_outlined,
          title: 'Lisez-moi · Mentions légales',
          subtitle:
              'Usage de l\'application, ayants droit et confidentialité',
          onTap: () => context.go('/legal?flow=settings'),
        ),
      ],
    );
  }
}

class _ContentTab extends ConsumerWidget {
  const _ContentTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SettingsSectionTitle('Classements (TMDB)'),
        const _TmdbApiKeyTile(),
        const SizedBox(height: 8),
        const SettingsSectionTitle('Recommandations'),
        _NavTile(
          icon: Icons.recommend,
          title: 'Pour vous (recommandations)',
          subtitle: 'Gérer l\'appariement et les suggestions',
          onTap: () => context.go('/matchmaking'),
        ),
      ],
    );
  }
}

/// Saisie de la clé API TMDB optionnelle (override utilisateur).
/// La clé partagée embarquée sert de valeur par défaut ; la saisie d'une clé
/// personnelle la remplace pour cet utilisateur (validée via /configuration).
class _TmdbApiKeyTile extends ConsumerStatefulWidget {
  const _TmdbApiKeyTile();

  @override
  ConsumerState<_TmdbApiKeyTile> createState() => _TmdbApiKeyTileState();
}

class _TmdbApiKeyTileState extends ConsumerState<_TmdbApiKeyTile> {
  final TextEditingController _controller = TextEditingController();
  bool _validating = false;
  bool? _valid;

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

  Future<void> _validate() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      setState(() => _valid = null);
      return;
    }
    setState(() {
      _validating = true;
      _valid = null;
    });
    final service = ref.read(tmdbServiceProvider);
    final ok = await service.validateApiKey(key);
    if (!mounted) return;
    setState(() {
      _validating = false;
      _valid = ok;
    });
    if (ok) {
      await ref.read(tmdbApiKeyOverrideProvider.notifier).setOverride(key);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Clé API TMDB validée et enregistrée'),
              backgroundColor: Color(0xFF00CFE8),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.key_outlined, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Clé API TMDB (optionnelle)',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              if (_validating)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (_valid == true)
                const Icon(Icons.check_circle,
                    color: Colors.green, size: 20)
              else if (_valid == false)
                const Icon(Icons.cancel,
                    color: Colors.redAccent, size: 20),
            ],
          ),
          TextField(
            controller: _controller,
            onChanged: (_) => setState(() => _valid = null),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Laisser vide pour utiliser la clé intégrée',
              hintStyle: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
              isDense: true,
              filled: true,
              fillColor: scheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: TextButton.icon(
              onPressed: _validating ? null : _validate,
              icon: const Icon(Icons.verified_outlined, size: 18),
              label: const Text('Valider la clé'),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _exportSettings(BuildContext context, WidgetRef ref) async {
  final backupService = SettingsBackupService();
  final advancedSettings = ref.read(advancedSettingsProvider);
  final userPreferences = ref.read(preferencesProvider);
  final json = await backupService.exportToJson(
    advancedSettings: advancedSettings,
    userPreferences: userPreferences,
  );
  await backupService.copyToClipboard(json);
  await backupService.writeToFile(json);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Réglages exportés (presse-papiers + Documents/orbit_settings_backup.json)'),
        backgroundColor: Color(0xFF00CFE8),
      ),
    );
  }
}

Future<void> _importSettings(BuildContext context, WidgetRef ref) async {
  final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
  if (clipboard?.text == null || clipboard!.text!.trim().isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Presse-papiers vide'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
    return;
  }

  final backupService = SettingsBackupService();
  final result = await backupService.importFromJson(
    clipboard.text!,
    ref.read(advancedSettingsProvider.notifier),
    ref.read(preferencesProvider.notifier),
  );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? const Color(0xFF00CFE8) : Colors.redAccent,
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: scheme.primary),
          title: Text(title, style: const TextStyle(fontSize: 14)),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
          trailing: trailing ??
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          onTap: onTap,
        ),
      ),
    );
  }
}
