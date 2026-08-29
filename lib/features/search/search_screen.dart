import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/data_providers.dart';
import '../../models/movie.dart';
import '../../models/series.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _titleController = TextEditingController();
  final _directorController = TextEditingController();
  final _yearController = TextEditingController();
  final _genreController = TextEditingController();
  final _minRatingController = TextEditingController();
  List<dynamic> _results = [];

  void _search() {
    final movies = ref.read(moviesProvider).valueOrNull ?? [];
    final series = ref.read(seriesProvider).valueOrNull ?? [];
    final title = _titleController.text.trim().toLowerCase();
    final director = _directorController.text.trim().toLowerCase();
    final year = _yearController.text.trim();
    final genre = _genreController.text.trim().toLowerCase();
    final minRating = double.tryParse(_minRatingController.text.trim());

    final filteredMovies = movies.where((m) {
      final okTitle = title.isEmpty || m.title.toLowerCase().contains(title);
      final okDirector = director.isEmpty || m.director.toLowerCase().contains(director);
      final okYear = year.isEmpty || m.year.toString() == year;
      final okGenre = genre.isEmpty || m.genre.toLowerCase().contains(genre);
      final okRating = minRating == null || m.rating >= minRating;
      return okTitle && okDirector && okYear && okGenre && okRating;
    }).toList();

    final filteredSeries = series.where((s) {
      final okTitle = title.isEmpty || s.title.toLowerCase().contains(title);
      final okDirector = director.isEmpty || s.director.toLowerCase().contains(director);
      final okYear = year.isEmpty || s.year.toString() == year;
      final okGenre = genre.isEmpty || s.genre.toLowerCase().contains(genre);
      final okRating = minRating == null || s.rating >= minRating;
      return okTitle && okDirector && okYear && okGenre && okRating;
    }).toList();

    setState(() {
      _results = [...filteredMovies, ...filteredSeries];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recherche avancée')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titre'),
            ),
            TextField(
              controller: _directorController,
              decoration: const InputDecoration(labelText: 'Réalisateur'),
            ),
            TextField(
              controller: _yearController,
              decoration: const InputDecoration(labelText: 'Année'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _genreController,
              decoration: const InputDecoration(labelText: 'Genre'),
            ),
            TextField(
              controller: _minRatingController,
              decoration: const InputDecoration(labelText: 'Note minimale (0-10)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _search,
              child: const Text('Rechercher'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final item = _results[index];
                  if (item is Movie) {
                    return ListTile(
                      leading: const Icon(Icons.movie),
                      title: Text(item.title),
                      subtitle: Text('${item.year} - ${item.director}'),
                    );
                  } else if (item is Series) {
                    return ListTile(
                      leading: const Icon(Icons.tv),
                      title: Text(item.title),
                      subtitle: Text('${item.year} - ${item.director}'),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
