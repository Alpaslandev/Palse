class EventModel {
  final String id;
  final String name;
  final String url;
  final String content;
  final DateTime start;
  final DateTime end;
  final String? posterUrl;
  final bool isFree;
  final Map<String, dynamic>? venue;

  EventModel({
    required this.id,
    required this.name,
    required this.url,
    required this.content,
    required this.start,
    required this.end,
    this.posterUrl,
    required this.isFree,
    this.venue,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'].toString(),
      name: json['name'],
      url: json['url'],
      content: json['content'],
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
      posterUrl: json['poster_url'],
      isFree: json['is_free'] ?? false,
      venue: json['venue'] as Map<String, dynamic>?,
    );
  }

  // Mekan adını al
  String? get venueName => venue?['name'] as String?;

  // Mekan adresi
  String? get venueAddress {
    final district = venue?['district']?['name'] as String?;
    final address = venue?['address'] as String?;
    if (district != null && address != null) {
      return '$address, $district';
    }
    return address ?? district;
  }
}
