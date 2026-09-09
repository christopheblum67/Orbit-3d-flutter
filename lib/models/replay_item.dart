import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    as stream_helpers;

class ReplayItem {
  final String id;
  final String title;
  final String streamUrl;
  final String startTime;
  final String endTime;
  final String categoryId;

  /// Début du programme en temps réel (tri, regroupement) ; null pour les
  /// replays sans horaire (repli live/M3U).
  final DateTime? startDate;

  ReplayItem({
    required this.id,
    required this.title,
    required this.streamUrl,
    required this.startTime,
    required this.endTime,
    this.categoryId = '',
    this.startDate,
  });

  factory ReplayItem.fromMap(Map<String, dynamic> map) {
    return ReplayItem(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      streamUrl: map['url'] ?? '',
      startTime: map['start'] ?? '',
      endTime: map['end'] ?? '',
      categoryId: map['category_id']?.toString() ?? '',
      startDate: DateTime.tryParse(map['start_date']?.toString() ?? ''),
    );
  }

  ReplayItem copyWith({String? streamUrl}) {
    return ReplayItem(
      id: id,
      title: title,
      streamUrl: streamUrl ?? this.streamUrl,
      startTime: startTime,
      endTime: endTime,
      categoryId: categoryId,
      startDate: startDate,
    );
  }

  String requireStreamUrl() =>
      stream_helpers.requireStreamUrl(streamUrl, label: title);
}
