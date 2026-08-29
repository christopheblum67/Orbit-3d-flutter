import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _vpnEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadVpnState();
  }

  Future<void> _loadVpnState() async {
    final vpnService = ref.read(vpnServiceProvider);
    setState(() => _vpnEnabled = vpnService.isConnected);
  }

  Future<void> _toggleVpn(bool value) async {
    final vpnService = ref.read(vpnServiceProvider);
    if (value) {
      await vpnService.connect('');
    } else {
      await vpnService.disconnect();
    }
    setState(() => _vpnEnabled = value);
  }

  Future<void> _sendTestNotification() async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.showNotification('Orbit 3D', 'Ceci est une notification test');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Activer le VPN'),
            subtitle: const Text('VPN simulé pour le moment'),
            value: _vpnEnabled,
            onChanged: (value) => _toggleVpn(value),
            secondary: const Icon(Icons.vpn_lock),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Tester les notifications'),
            onTap: _sendTestNotification,
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profils'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.subscriptions),
            title: const Text('Abonnements'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
