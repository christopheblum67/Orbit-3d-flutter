import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profils'),
          ),
          ListTile(
            leading: Icon(Icons.subscriptions),
            title: Text('Abonnements'),
          ),
          ListTile(
            leading: Icon(Icons.vpn_lock),
            title: Text('VPN'),
          ),
          ListTile(
            leading: Icon(Icons.search),
            title: Text('Recherche'),
          ),
        ],
      ),
    );
  }
}
