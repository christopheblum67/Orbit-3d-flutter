import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

class VpnScreen extends ConsumerStatefulWidget {
  const VpnScreen({super.key});

  @override
  ConsumerState<VpnScreen> createState() => _VpnScreenState();
}

class _VpnScreenState extends ConsumerState<VpnScreen> {
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final vpnService = ref.read(vpnServiceProvider);
    setState(() => _isConnected = vpnService.isConnected);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vpnService = ref.read(vpnServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('VPN')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.vpn_lock,
              size: 100,
              color: _isConnected ? scheme.tertiary : scheme.outline,
            ),
            const SizedBox(height: 20),
            Text(
              _isConnected ? 'VPN connecté (simulé)' : 'VPN déconnecté',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () async {
                if (_isConnected) {
                  await vpnService.disconnect();
                } else {
                  await vpnService.connect('');
                }
                setState(() => _isConnected = vpnService.isConnected);
              },
              icon: Icon(_isConnected ? Icons.power_settings_new : Icons.power),
              label: Text(_isConnected ? 'Déconnecter' : 'Connecter'),
            ),
          ],
        ),
      ),
    );
  }
}
