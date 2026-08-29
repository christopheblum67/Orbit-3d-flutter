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
}
