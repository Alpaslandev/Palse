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
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
    );
  }
}
