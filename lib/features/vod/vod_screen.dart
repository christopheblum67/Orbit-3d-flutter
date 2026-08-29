import 'package:flutter/material.dart';

class VodScreen extends StatelessWidget {
  const VodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Films (VOD)')),
      body: const Center(child: Text('Liste des films')),
    );
  }
}
