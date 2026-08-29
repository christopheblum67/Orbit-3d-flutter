import 'package:flutter/material.dart';

class VpnScreen extends StatelessWidget {
  const VpnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VPN')),
      body: const Center(child: Text('Configuration VPN')),
    );
  }
}
