import 'package:flutter/material.dart';

class SeriesScreen extends StatelessWidget {
  const SeriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Séries')),
      body: const Center(child: Text('Liste des séries')),
    );
  }
}
