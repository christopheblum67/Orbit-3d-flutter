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
}
