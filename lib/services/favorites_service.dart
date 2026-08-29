import 'package:hive_flutter/hive_flutter.dart';

class FavoritesService {
  static const String _boxName = 'favorites';

  Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  Future<void> addFavorite(String type, String id) async {
    final box = Hive.box<String>(_boxName);
    await box.put('$type-$id', id);
  }

  Future<void> removeFavorite(String type, String id) async {
    final box = Hive.box<String>(_boxName);
    await box.delete('$type-$id');
  }

  Future<bool> isFavorite(String type, String id) async {
    final box = Hive.box<String>(_boxName);
    return box.containsKey('$type-$id');
  }

  Future<List<String>> getFavorites(String type) async {
    final box = Hive.box<String>(_boxName);
    return box.keys
        .where((key) => key.toString().startsWith('$type-'))
        .map((e) => box.get(e)!)
        .toList();
  }
}
