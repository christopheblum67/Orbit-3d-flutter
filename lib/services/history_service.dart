import 'package:hive_flutter/hive_flutter.dart';
import 'package:orbit_3d_flutter/core/utils/hive_sync.dart';

class HistoryEntry {
  const HistoryEntry({
    required this.type,
    required this.title,
    required this.streamUrl,
    required this.timestamp,
  });

  final String type;
  final String title;
  final String streamUrl;
  final DateTime timestamp;
}

class HistoryService {
  static const String _boxName = 'history';
  static const int maxEntries = 100;

  Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  Future<void> addEntry(String type, String title, String url) async {
    await HiveSync.writeAsync(_boxName, (box) async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await box.add(<String, Object>{
        'type': type,
        'title': title,
        'url': url,
        'timestamp': timestamp,
      });
      final entries = box.toMap().entries.toList()
        ..sort(
          (a, b) => _timestampFor(b.value, b.key)
              .compareTo(_timestampFor(a.value, a.key)),
        );
      for (final entry in entries.skip(maxEntries)) {
        final key = entry.key;
        await box.delete(key);
      }
    });
  }

  Future<List<HistoryEntry>> getHistory() async {
    return HiveSync.read(_boxName, (box) {
      final entries = box
          .toMap()
          .entries
          .map((entry) => _decodeEntry(entry.key, entry.value))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries;
    });
  }

  static HistoryEntry _decodeEntry(Object? key, Object? value) {
    if (value is Map) {
      final timestamp = _timestampFor(value, key);
      return HistoryEntry(
        type: value['type']?.toString() ?? _typeForKey(key),
        title: value['title']?.toString() ?? '',
        streamUrl: value['url']?.toString() ?? '',
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
      );
    }

    // Older releases stored `title|url` and kept the type/timestamp in
    // the Hive key. Read those entries without requiring a migration.
    final parts = value?.toString().split('|') ?? const <String>[];
    return HistoryEntry(
      type: _typeForKey(key),
      title: parts.isEmpty ? '' : parts.first.trim(),
      streamUrl: parts.length < 2 ? '' : parts.sublist(1).join('|').trim(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(_timestampForKey(key)),
    );
  }

  static int _timestampFor(Object? value, Object? key) => value is Map
      ? (value['timestamp'] as num?)?.toInt() ?? _timestampForKey(key)
      : _timestampForKey(key);

  static int _timestampForKey(Object? key) {
    final match = RegExp(r'-(\d+)$').firstMatch(key?.toString() ?? '');
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  static String _typeForKey(Object? key) {
    final value = key?.toString() ?? '';
    final match = RegExp(r'^(.*)-\d+$').firstMatch(value);
    return match?.group(1) ?? 'live';
  }
}
