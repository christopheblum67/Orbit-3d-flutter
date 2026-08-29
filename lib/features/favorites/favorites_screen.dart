import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  List<String> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final service = ref.read(favoritesServiceProvider);
    final favs = await service.getFavorites('channel'); // type à adapter
    if (mounted) setState(() => _favorites = favs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoris')),
      body: ListView.builder(
        itemCount: _favorites.length,
        itemBuilder: (context, index) => ListTile(
          leading: const Icon(Icons.favorite),
          title: Text(_favorites[index]),
        ),
      ),
    );
  }
}
