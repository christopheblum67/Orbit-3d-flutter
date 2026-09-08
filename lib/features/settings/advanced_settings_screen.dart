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
    _tabController = TabController(length: 4, vsync: this);
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
            Tab(icon: Icon(Icons.equalizer), text: 'Audio'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _NetworkTab(),
          _PlayerTab(),
          _SecurityTab(),
          _AudioTab(),
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
          title: 'Zapping Instantané (Prefetching)',
          subtitle: 'Précharge les chaînes adjacentes en mémoire tampon',
          value: s.zeroLagPrefetch,
          onChanged: n.setZeroLagPrefetch,
          icon: Icons.fast_forward_outlined,
        ),
      ],
    );
  }
}

class _SecurityTab extends ConsumerWidget {
  const _SecurityTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SettingsSectionTitle('Résilience du Service'),
        // Options déplacées (smartFailover, hideCredentials) : non consommées par le code métier
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
