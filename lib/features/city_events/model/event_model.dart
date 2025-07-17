class EventModel {
  final String id;
  final String name;
  final String url;
  final String content;
  final DateTime start;
  final DateTime end;

  EventModel({
    required this.id,
    required this.name,
    required this.url,
    required this.content,
    required this.start,
    required this.end,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      content: json['content'],
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
    );
  }
}
