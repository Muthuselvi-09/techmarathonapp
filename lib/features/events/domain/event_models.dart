// Feature models
class Participant {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final String? profileImage;
  final double profileCompletion;

  Participant({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    this.profileImage,
    this.profileCompletion = 0.5,
  });
}

class Speaker {
  final String name;
  final String topic;
  final String company;
  final String photoUrl;

  Speaker({
    required this.name,
    required this.topic,
    required this.company,
    required this.photoUrl,
  });
}

class Sponsor {
  final String name;
  final String company;
  final String jobPosition;
  final String logoUrl;

  Sponsor({
    required this.name,
    required this.company,
    required this.jobPosition,
    required this.logoUrl,
  });
}

class CodingEvent {
  final String name;
  final String location;
  final DateTime date;
  final List<Speaker> speakers;
  final List<Sponsor> sponsors;
  final int participantCount;

  CodingEvent({
    required this.name,
    required this.location,
    required this.date,
    required this.speakers,
    required this.sponsors,
    required this.participantCount,
  });
}

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isMe, required this.timestamp});
}
