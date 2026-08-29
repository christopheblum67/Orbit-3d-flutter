import 'package:hive_flutter/hive_flutter.dart';

class HistoryService {
  static const String _boxName = 'history';

  Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  Future<void> addEntry(String type, String title, String url) async {
    final box = Hive.box<String>(_boxName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await box.put('$type-$timestamp', '$title|$url');
  }

  Future<List<String>> getHistory() async {
    final box = Hive.box<String>(_boxName);
    final keys = box.keys.toList()
      ..sort((a, b) => b.toString().compareTo(a.toString()));
    return keys.map((key) => box.get(key)!).toList();
  }
}
