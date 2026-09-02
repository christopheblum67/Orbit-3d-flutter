import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    as stream_helpers;

class ReplayItem {
  final String id;
  final String title;
  final String streamUrl;
  final String startTime;
  final String endTime;

  ReplayItem({
    required this.id,
    required this.title,
    required this.streamUrl,
    required this.startTime,
    required this.endTime,
  });

  factory ReplayItem.fromMap(Map<String, dynamic> map) {
    return ReplayItem(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      streamUrl: map['url'] ?? '',
      startTime: map['start'] ?? '',
      endTime: map['end'] ?? '',
    );
  }

  ReplayItem copyWith({String? streamUrl}) {
    return ReplayItem(
      id: id,
      title: title,
      streamUrl: streamUrl ?? this.streamUrl,
      startTime: startTime,
      endTime: endTime,
    );
  }

  String requireStreamUrl() =>
      stream_helpers.requireStreamUrl(streamUrl, label: title);
}
