/// Recommandation renvoyée par le service IA, structurée en objet.
class AIRecommendation {
  final String title;
  final String reason;
  final String category;
  final double? rating;

  const AIRecommendation({
    required this.title,
    required this.reason,
    required this.category,
    this.rating,
  });

  factory AIRecommendation.fromJson(Map<String, dynamic> json) {
    final rawRating = json['rating'];
    final rating = rawRating is num ? rawRating.toDouble() : null;
    return AIRecommendation(
      title: _clean(json['title']),
      reason: _clean(json['reason'] ?? json['synopsis'] ?? json['explanation']),
      category: _clean(json['category'] ?? 'Film / Série'),
      rating: rating,
    );
  }

  static String _clean(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? 'Titre inconnu' : text;
  }
}
