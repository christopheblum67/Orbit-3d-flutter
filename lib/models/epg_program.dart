class EPGProgram {
  final String channelId;
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;

  EPGProgram({
    required this.channelId,
    required this.title,
    required this.description,
    required this.start,
    required this.end,
  });

  DateTime get startTime => start;
  DateTime get endTime => end;
  int get durationMinutes => end.difference(start).inMinutes;
  bool get isLive {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }
}
