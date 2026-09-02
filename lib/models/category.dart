class MediaCategory {
  const MediaCategory({required this.id, required this.name});

  final String id;
  final String name;

  factory MediaCategory.fromMap(Map<String, dynamic> map) {
    return MediaCategory(
      id: map['category_id']?.toString() ?? map['categoryId']?.toString() ?? '',
      name: map['category_name']?.toString() ?? map['categoryName'] ?? '',
    );
  }

  MediaCategory copyWith({String? id, String? name}) {
    return MediaCategory(id: id ?? this.id, name: name ?? this.name);
  }
}
