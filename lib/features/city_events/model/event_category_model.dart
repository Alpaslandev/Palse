// Etkinlik kategorileri için model sınıfı
class EventCategoryModel {
  final int id;
  final String name;
  final String slug;

  EventCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory EventCategoryModel.fromJson(Map<String, dynamic> json) {
    return EventCategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }
}
