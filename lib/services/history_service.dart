import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';

class HistoryService {
  static const String _boxName = 'history';

  Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  Future<void> addEntry(String type, String title, String url) async {
    await HiveSync.writeAsync(_boxName, (box) async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      box.put('$type-$timestamp', '$title|$url');
    });
  }

  Future<List<String>> getHistory() async {
    return HiveSync.read(_boxName, (box) {
      final keys = box.keys.toList()
        ..sort((a, b) => b.toString().compareTo(a.toString()));
      return keys.map((key) => box.get(key)! as String).toList();
    });
  }
}