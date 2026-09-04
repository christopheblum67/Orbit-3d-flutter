import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/settings_widgets.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';

/// Configuration Avancée (Next-Gen) organisée en onglets, conforme à la
/// concurrence XCIPTV. Chaque option est persistée via
/// [advancedSettingsProvider].
class AdvancedSettingsScreen extends ConsumerStatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  ConsumerState<AdvancedSettingsScreen> createState() =>
      _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends ConsumerState<AdvancedSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(advancedSettingsProvider.notifier).load();
    });
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
        title: const Text('Configuration Avancée'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.security), text: 'Réseau'),
            Tab(icon: Icon(Icons.play_circle), text: 'Lecteur'),
            Tab(icon: Icon(Icons.shield), text: 'Sécurité'),
            Tab(icon: Icon(Icons.tv), text: 'Ergonomie'),
            Tab(icon: Icon(Icons.psychology), text: 'IA'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _NetworkTab(),
          _PlayerTab(),
          _SecurityTab(),
          _ErgonomicsTab(),
          _AiTab(),
        ],
      ),
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
        SettingsSwitchTile(
          title: 'DNS over HTTPS (DoH)',
          subtitle: 'Masque les requêtes de nom de domaine au FAI',
          value: s.useCustomDNS,
          onChanged: n.setCustomDNS,
          icon: Icons.dns_outlined,
        ),
        SettingsSwitchTile(
          title: 'Streaming Hybride P2P (WebRTC)',
          subtitle: 'Partage de segments entre utilisateurs pour réduire le buffering',
          value: s.enableP2PHybrid,
          onChanged: n.setP2PHybrid,
          icon: Icons.hub_outlined,
        ),
      ],
    );
  }
}

class _PlayerTab extends ConsumerWidget {
  const _PlayerTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(advancedSettingsProvider);
    final n = ref.read(advancedSettingsProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SettingsSectionTitle('Rendu Vidéo et Zapping'),
        SettingsSwitchTile(
          title: 'Auto Frame Rate (AFR)',
          subtitle: 'Ajuste la fréquence de rafraîchissement de la TV au flux (24/50/60Hz)',
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
          subtitle: 'Améliore la netteté des flux SD/HD vers la 4K en temps réel',
          value: s.enableAiUpscaling,
          onChanged: n.setAiUpscaling,
          icon: Icons.hd_outlined,
        ),
      ],
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
      ],
    );
  }
}

class _ErgonomicsTab extends ConsumerWidget {
  const _ErgonomicsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(advancedSettingsProvider);
    final n = ref.read(advancedSettingsProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SettingsSectionTitle('Expérience Télécommande'),
        SettingsSwitchTile(
          title: 'Lancement Direct au Démarrage',
          subtitle:
              'Ouvre directement la dernière chaîne au lancement de l\'application',
          value: s.directToLive,
          onChanged: n.setDirectToLive,
          icon: Icons.monitor_outlined,
        ),
        const SettingsSectionTitle('Guide TV (EPG)'),
        SettingsDropdownTile<String>(
          title: 'Affichage EPG',
          subtitle: 'Choisir le mode d\'affichage du guide TV',
          value: s.epgDisplayMode.label,
          options: EpgDisplayMode.values.map((e) => e.label).toList(),
          onChanged: (label) {
            final mode = EpgDisplayMode.values.firstWhere(
              (e) => e.label == label,
              orElse: () => EpgDisplayMode.grid2D,
            );
            n.setEpgDisplayMode(mode);
          },
          icon: Icons.tv,
        ),
      ],
    );
  }
}

class _AiTab extends ConsumerWidget {
  const _AiTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(advancedSettingsProvider);
    final n = ref.read(advancedSettingsProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SettingsSectionTitle('Fonctionnalités NPU Embarquées'),
        SettingsSwitchTile(
          title: 'Sous-Titres IA Locaux',
          subtitle: 'Génère des sous-titres à la volée via traitement vocal local',
          value: s.localAiSubtitles,
          onChanged: n.setLocalAiSubtitles,
          icon: Icons.subtitles_outlined,
        ),
        SettingsSwitchTile(
          title: 'Détection des Temps Forts Sportifs',
          subtitle:
              'Marque automatiquement les événements clés sur les replays',
          value: s.sportsHighlightsDetection,
          onChanged: n.setSportsHighlights,
          icon: Icons.sports_soccer_outlined,
        ),
      ],
    );
  }
}
