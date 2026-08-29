import 'package:flutter/material.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recherche avancée')),
      body: const Center(child: Text('Recherche par titre, réalisateur, année...')),
    );
  }
}
