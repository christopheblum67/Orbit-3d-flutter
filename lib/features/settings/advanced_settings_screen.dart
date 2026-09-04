import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/settings_widgets.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/services/cloudflare_bypass_service.dart';

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
    _tabController = TabController(length: 6, vsync: this);
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
            Tab(icon: Icon(Icons.equalizer), text: 'Audio'),
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
          _AudioTab(),
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
        SettingsActionTile(
          title: 'Réinitialiser config lecteur',
          subtitle:
              'Remet TLS Impersonation=OFF, efface cookies Cloudflare, remet UA ExoPlayer par défaut',
          icon: Icons.restore_outlined,
          onTap: () async {
            n.setTlsImpersonation(false);
            CloudflareBypassService.instance.invalidate('draap.online');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Config lecteur réinitialisée'),
                  backgroundColor: Color(0xFF00CFE8),
                ),
              );
            }
          },
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

class _AudioTab extends ConsumerWidget {
  const _AudioTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(advancedSettingsProvider);
    final n = ref.read(advancedSettingsProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SettingsSectionTitle('Night Focus (Mode Nuit)'),
        SettingsSwitchTile(
          title: 'Activer Night Focus',
          subtitle:
              'Traitement audio temps réel : boost dialogues, coupe basses, sync',
          value: s.nightFocusEnabled,
          onChanged: n.setNightFocus,
          icon: Icons.nightlight_round,
        ),
        SettingsSwitchTile(
          title: 'Boost Dialogues (+4 dB)',
          subtitle: 'Amplifie les voix par rapport aux effets/musique',
          value: s.nightFocusDialogueBoost,
          onChanged: n.setNightFocusDialogueBoost,
          icon: Icons.record_voice_over,
        ),
        SettingsSwitchTile(
          title: 'Bass Killer (coupe < 120 Hz)',
          subtitle: 'Atténue les basses fréquences pour éviter les vibrations',
          value: s.nightFocusBassKiller,
          onChanged: n.setNightFocusBassKiller,
          icon: Icons.equalizer,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            'Gain Vocal : ${s.nightFocusVocalGainDb.toStringAsFixed(1)} dB',
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Slider(
          value: s.nightFocusVocalGainDb,
          min: 0,
          max: 12,
          divisions: 24,
          label: '${s.nightFocusVocalGainDb.toStringAsFixed(1)} dB',
          onChanged: (v) => n.setNightFocusVocalGainDb(v),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            'Décalage Audio (Sync) : ${s.nightFocusAudioShiftMs} ms',
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Slider(
          value: s.nightFocusAudioShiftMs.toDouble(),
          min: -500,
          max: 500,
          divisions: 100,
          label: '${s.nightFocusAudioShiftMs} ms',
          onChanged: (v) => n.setNightFocusAudioShiftMs(v.round()),
        ),
        const SettingsSectionTitle('Test de désactivation complète'),
        SettingsActionTile(
          title: 'Désactiver tout Night Focus',
          subtitle:
              'Met tous les paramètres Night Focus à OFF / 0 pour tester la lecture brute',
          icon: Icons.block_outlined,
          onTap: () async {
            n.setNightFocus(false);
            n.setNightFocusDialogueBoost(false);
            n.setNightFocusBassKiller(false);
            n.setNightFocusVocalGainDb(0);
            n.setNightFocusAudioShiftMs(0);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Night Focus désactivé complètement'),
                  backgroundColor: Color(0xFF00CFE8),
                ),
              );
            }
          },
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
