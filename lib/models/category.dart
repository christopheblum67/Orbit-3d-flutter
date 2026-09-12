class MediaCategory {
  const MediaCategory({required this.id, required this.name, this.count = 0});

  final String id;
  final String name;

  /// Nombre d'éléments réels rattachés à cette catégorie (0 = non calculé).
  final int count;

  factory MediaCategory.fromMap(Map<String, dynamic> map) {
    return MediaCategory(
      id: map['category_id']?.toString() ?? map['categoryId']?.toString() ?? '',
      name: map['category_name']?.toString() ?? map['categoryName'] ?? '',
      count: map['count'] is num ? (map['count'] as num).toInt() : 0,
    );
  }

  MediaCategory copyWith({String? id, String? name, int? count}) {
    return MediaCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      count: count ?? this.count,
    );
  }
}
