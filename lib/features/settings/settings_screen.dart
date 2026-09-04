import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/settings_widgets.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/player_engine_config_sheet.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/memory_settings_panel.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/subscription_provider.dart';

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
        const SizedBox(height: 8),
        const SettingsSectionTitle('Notifications'),
        _NavTile(
          icon: Icons.notifications,
          title: 'Tester les notifications',
          subtitle: 'Envoie une notification locale de test',
          onTap: () async {
            final notificationService = ref.read(notificationServiceProvider);
            await notificationService.showNotification(
              'Orbit 3D',
              'Ceci est une notification test',
            );
          },
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
    final vpn = ref.watch(vpnServiceProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SettingsSectionTitle('VPN'),
        SettingsSwitchTile(
          title: 'VPN',
          subtitle: vpn.isConnected
              ? 'Connecté — contourne le bridage réseau'
              : 'VPN simulé pour le moment',
          value: vpn.isConnected,
          onChanged: (value) async {
            if (value) {
              await vpn.connect('');
            } else {
              await vpn.disconnect();
            }
          },
          icon: Icons.vpn_lock,
        ),
        const SettingsSectionTitle('Protection contre le bridage FAI'),
        SettingsSwitchTile(
          title: 'TLS Impersonation (Proxy Local)',
          subtitle:
              'Simule l\'empreinte d\'un navigateur moderne pour contourner Cloudflare',
          value: s.useTlsImpersonation,
          onChanged: n.setTlsImpersonation,
          icon: Icons.shield_outlined,
        ),
        SettingsSwitchTile(
          title: 'DNS over HTTPS (DoH)',
          subtitle: 'Masque les requêtes DNS au FAI',
          value: s.useCustomDNS,
          onChanged: n.setCustomDNS,
          icon: Icons.dns_outlined,
        ),
        const _DnsProviderTile(),
        SettingsSwitchTile(
          title: 'Streaming Hybride P2P (WebRTC)',
          subtitle: 'Partage de segments pour réduire le buffering',
          value: s.enableP2PHybrid,
          onChanged: n.setP2PHybrid,
          icon: Icons.hub_outlined,
        ),
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
          leading: Icon(Icons.dns_outlined, color: Theme.of(context).colorScheme.primary),
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
          title: 'Auto Frame Rate (AFR)',
          subtitle:
              'Ajuste la fréquence de rafraîchissement de la TV au flux (24/50/60Hz)',
          value: s.autoFrameRate,
          onChanged: n.setAutoFrameRate,
          icon: Icons.highlight_outlined,
        ),
        SettingsSwitchTile(
          title: 'Zapping Instantané (Prefetching)',
          subtitle: 'Précharge les chaînes adjacentes en mémoire tampon',
          value: s.zeroLagPrefetch,
          onChanged: n.setZeroLagPrefetch,
          icon: Icons.fast_forward_outlined,
        ),
        SettingsSwitchTile(
          title: 'Super-Résolution IA (NPU Upscaling)',
          subtitle:
              'Améliore la netteté des flux SD/HD vers la 4K en temps réel',
          value: s.enableAiUpscaling,
          onChanged: n.setAiUpscaling,
          icon: Icons.hd_outlined,
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
    final s = ref.watch(advancedSettingsProvider);
    final n = ref.read(advancedSettingsProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SettingsSectionTitle('Résilience du Service'),
        SettingsSwitchTile(
          title: 'Smart Failover (Serveur de secours)',
          subtitle:
              'Bascule automatiquement sur un serveur alternatif si le flux coupe',
          value: s.smartFailover,
          onChanged: n.setSmartFailover,
          icon: Icons.sync_problem_outlined,
        ),
        SettingsSwitchTile(
          title: 'Masquer les identifiants',
          subtitle:
              'Chiffre et masque les liens d\'accès Xtream dans l\'interface',
          value: s.hideCredentials,
          onChanged: n.setHideCredentials,
          icon: Icons.lock_outline,
        ),
        const SizedBox(height: 8),
        const SettingsSectionTitle('Contrôle parental'),
        _NavTile(
          icon: Icons.gpp_good_outlined,
          title: 'Contrôle parental',
          subtitle: 'Ajouter un code PIN et restreindre le contenu',
          onTap: () => context.go('/parental'),
        ),
      ],
    );
  }
}

class _ContentTab extends ConsumerWidget {
  const _ContentTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(advancedSettingsProvider);
    final n = ref.read(advancedSettingsProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SettingsSectionTitle('Recommandations'),
        _NavTile(
          icon: Icons.recommend,
          title: 'Pour vous (recommandations)',
          subtitle: 'Gérer l\'appariement et les suggestions',
          onTap: () => context.go('/matchmaking'),
        ),
        const SizedBox(height: 8),
        const SettingsSectionTitle('Fonctionnalités IA'),
        SettingsSwitchTile(
          title: 'Sous-Titres IA Locaux',
          subtitle: 'Génère des sous-titres via traitement vocal local',
          value: s.localAiSubtitles,
          onChanged: n.setLocalAiSubtitles,
          icon: Icons.subtitles_outlined,
        ),
        SettingsSwitchTile(
          title: 'Détection des Temps Forts Sportifs',
          subtitle: 'Marque les événements clés sur les replays',
          value: s.sportsHighlightsDetection,
          onChanged: n.setSportsHighlights,
          icon: Icons.sports_soccer_outlined,
        ),
      ],
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
