class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String imageUrl;
  final List<String> speakers;
  final String category;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.imageUrl,
    required this.speakers,
    required this.category,
  });
}

class CourseModel {
  final String id;
  final String title;
  final String level;
  final String duration;
  final double price;
  final String imageUrl;
  final List<String> benefits;

  CourseModel({
    required this.id,
    required this.title,
    required this.level,
    required this.duration,
    required this.price,
    required this.imageUrl,
    required this.benefits,
  });
}
