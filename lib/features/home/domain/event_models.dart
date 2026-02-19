import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final bool isEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Category({
    required this.id,
    required this.name,
    this.isEnabled = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromMap(Map<String, dynamic> data, String id) {
    return Category(
      id: id,
      name: data['name'] ?? '',
      isEnabled: data['isEnabled'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isEnabled': isEnabled,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Category copyWith({
    String? id,
    String? name,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CodingEvent {
  final String id;
  final String name;
  final String description;
  final DateTime date;
  final String location;
  final double? latitude;
  final double? longitude;
  final String imageUrl;
  final List<String> speakerIds;
  final String category; // Preserving for backward compatibility
  final String? categoryId; // New field
  final bool isFree;
  final double entryFee;
  final String currency;
  final List<Speaker> speakers;
  final List<Sponsor> sponsors;
  final int participantCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final String? entryTiming;
  final List<String> rules;
  final bool isEntryScanEnabled;
  final int totalSeats;
  final int bookedSeats;
  // VIP & Discount Fields
  final bool isVipEnabled;
  final double vipPrice;
  final double vipDiscountPercentage;
  final double earlyBirdDiscount;

  int get availableSeats => totalSeats - bookedSeats;

  CodingEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.location,
    this.latitude,
    this.longitude,
    required this.imageUrl,
    required this.speakerIds,
    required this.category,
    this.categoryId,
    this.isFree = true,
    this.entryFee = 0.0,
    this.currency = '₹',
    this.speakers = const [],
    this.sponsors = const [],
    this.participantCount = 0,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.entryTiming,
    this.rules = const [],
    this.isEntryScanEnabled = false,
    this.totalSeats = 0,
    this.bookedSeats = 0,
    this.isVipEnabled = false,
    this.vipPrice = 0.0,
    this.vipDiscountPercentage = 0.0,
    this.earlyBirdDiscount = 0.0,
  });

  factory CodingEvent.fromMap(Map<String, dynamic> data, String id) {
    return CodingEvent(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['locationName'] ?? '',
      latitude: (data['location'] is Map ? (data['location']['lat'] ?? 0.0).toDouble() : 0.0),
      longitude: (data['location'] is Map ? (data['location']['lng'] ?? 0.0).toDouble() : 0.0),
      imageUrl: data['imageUrl'] ?? '',
      speakerIds: List<String>.from(data['speakerIds'] ?? []),
      category: data['category'] ?? '',
      categoryId: data['categoryId'],
      isFree: data['isFree'] ?? true,
      entryFee: (data['entryFee'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? '₹',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      entryTiming: data['entryTiming'],
      rules: List<String>.from(data['rules'] ?? []),
      isEntryScanEnabled: data['isEntryScanEnabled'] ?? false,
      totalSeats: data['totalSeats'] ?? 0,
      bookedSeats: data['bookedSeats'] ?? 0,
      isVipEnabled: data['isVipEnabled'] ?? false,
      vipPrice: (data['vipPrice'] ?? 0.0).toDouble(),
      vipDiscountPercentage: (data['vipDiscountPercentage'] ?? 0.0).toDouble(),
      earlyBirdDiscount: (data['earlyBirdDiscount'] ?? 0.0).toDouble(),
    );
  }

  factory CodingEvent.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CodingEvent.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'date': Timestamp.fromDate(date),
      'locationName': location,
      'location': {
        'lat': latitude,
        'lng': longitude,
      },
      'imageUrl': imageUrl,
      'speakerIds': speakerIds,
      'category': category,
      'categoryId': categoryId,
      'isFree': isFree,
      'entryFee': entryFee,
      'currency': currency,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': isActive,
      'entryTiming': entryTiming,
      'rules': rules,
      'isEntryScanEnabled': isEntryScanEnabled,
      'totalSeats': totalSeats,
      'bookedSeats': bookedSeats,
      'isVipEnabled': isVipEnabled,
      'vipPrice': vipPrice,
      'vipDiscountPercentage': vipDiscountPercentage,
      'earlyBirdDiscount': earlyBirdDiscount,
    };
  }

  Map<String, dynamic> toFirestore() => toMap();

  CodingEvent copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? date,
    String? location,
    double? latitude,
    double? longitude,
    String? imageUrl,
    List<String>? speakerIds,
    String? category,
    String? categoryId,
    bool? isFree,
    double? entryFee,
    String? currency,
    List<Speaker>? speakers,
    List<Sponsor>? sponsors,
    int? participantCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? entryTiming,
    List<String>? rules,
    int? totalSeats,
    int? bookedSeats,
    bool? isVipEnabled,
    double? vipPrice,
    double? vipDiscountPercentage,
    double? earlyBirdDiscount,
  }) {
    return CodingEvent(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      date: date ?? this.date,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      speakerIds: speakerIds ?? this.speakerIds,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      isFree: isFree ?? this.isFree,
      entryFee: entryFee ?? this.entryFee,
      currency: currency ?? this.currency,
      speakers: speakers ?? this.speakers,
      sponsors: sponsors ?? this.sponsors,
      participantCount: participantCount ?? this.participantCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      entryTiming: entryTiming ?? this.entryTiming,
      rules: rules ?? this.rules,
      totalSeats: totalSeats ?? this.totalSeats,
      bookedSeats: bookedSeats ?? this.bookedSeats,
      isVipEnabled: isVipEnabled ?? this.isVipEnabled,
      vipPrice: vipPrice ?? this.vipPrice,
      vipDiscountPercentage: vipDiscountPercentage ?? this.vipDiscountPercentage,
      earlyBirdDiscount: earlyBirdDiscount ?? this.earlyBirdDiscount,
    );
  }
}

class Participant {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final String? profileImage;
  final double profileCompletion;
  final double? latitude;
  final double? longitude;
  final String role; // 'user', 'organizer', 'admin'
  final DateTime? joinedAt;
  final bool isOnline;
  final DateTime? lastActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  Participant({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    this.profileImage,
    this.profileCompletion = 0.5,
    this.latitude,
    this.longitude,
    this.role = 'user',
    this.joinedAt,
    this.isOnline = false,
    this.lastActive,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory Participant.fromMap(Map<String, dynamic> data, String id) {
    return Participant(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      mobile: data['mobile'] ?? '',
      profileImage: data['profileImage'],
      profileCompletion: (data['profileCompletion'] ?? 0.5).toDouble(),
      latitude: (data['location'] is Map ? (data['location']['lat'] ?? 0.0).toDouble() : 0.0),
      longitude: (data['location'] is Map ? (data['location']['lng'] ?? 0.0).toDouble() : 0.0),
      role: data['role'] ?? 'user',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate(),
      isOnline: data['isOnline'] ?? false,
      lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  factory Participant.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Participant.fromMap(data, doc.id);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'mobile': mobile,
      'profileImage': profileImage,
      'profileCompletion': profileCompletion,
      'location': {
        'lat': latitude,
        'lng': longitude,
      },
      'role': role,
      'joinedAt': joinedAt != null ? Timestamp.fromDate(joinedAt!) : null,
      'isOnline': isOnline,
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': isActive,
    };
  }
}

class Sponsor {
  final String id;
  final String name;
  final String company;
  final String jobPosition;
  final String logoUrl;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String tier;
  final String websiteUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final String eventId;

  // New Digital Booth Fields
  final String bannerUrl;
  final String tagline;
  final String? detailedDescription;
  final List<Map<String, dynamic>> offers;
  final List<Map<String, dynamic>> products;
  final List<String> media;
  final String? instagramUrl;
  final String? linkedinUrl;
  final String? youtubeUrl;
  final String? boothLocation;
  final String? chatUrl; // Community/Chat platform URL

  Sponsor({
    required this.id,
    this.eventId = '',
    required this.name,
    required this.company,
    this.jobPosition = '',
    required this.tier,
    required this.logoUrl,
    required this.websiteUrl,
    this.description,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.bannerUrl = '',
    this.tagline = '',
    this.detailedDescription,
    this.offers = const [],
    this.products = const [],
    this.media = const [],
    this.instagramUrl,
    this.linkedinUrl,
    this.youtubeUrl,
    this.boothLocation,
    this.chatUrl,
  });

  factory Sponsor.fromMap(Map<String, dynamic> data, String id) {
    return Sponsor(
      id: id,
      eventId: data['eventId'] ?? '',
      name: data['name'] ?? '',
      company: data['company'] ?? '',
      jobPosition: data['jobPosition'] ?? '',
      tier: data['tier'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      websiteUrl: data['websiteUrl'] ?? '',
      description: data['description'],
      latitude: (data['location'] is Map ? (data['location']['lat'] ?? 0.0).toDouble() : 0.0),
      longitude: (data['location'] is Map ? (data['location']['lng'] ?? 0.0).toDouble() : 0.0),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      bannerUrl: data['bannerUrl'] ?? '',
      tagline: data['tagline'] ?? '',
      detailedDescription: data['detailedDescription'],
      offers: List<Map<String, dynamic>>.from(data['offers'] ?? []),
      products: List<Map<String, dynamic>>.from(data['products'] ?? []),
      media: List<String>.from(data['media'] ?? []),
      instagramUrl: data['instagramUrl'],
      linkedinUrl: data['linkedinUrl'],
      youtubeUrl: data['youtubeUrl'],
      boothLocation: data['boothLocation'],
      chatUrl: data['chatUrl'],
    );
  }

  factory Sponsor.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Sponsor.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'name': name,
      'company': company,
      'jobPosition': jobPosition,
      'tier': tier,
      'logoUrl': logoUrl,
      'websiteUrl': websiteUrl,
      'description': description,
      'location': {
        'lat': latitude,
        'lng': longitude,
      },
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': isActive,
      'bannerUrl': bannerUrl,
      'tagline': tagline,
      'detailedDescription': detailedDescription,
      'offers': offers,
      'products': products,
      'media': media,
      'instagramUrl': instagramUrl,
      'linkedinUrl': linkedinUrl,
      'youtubeUrl': youtubeUrl,
      'boothLocation': boothLocation,
      'chatUrl': chatUrl,
    };
  }

  Map<String, dynamic> toFirestore() => toMap();

  Sponsor copyWith({
    String? id,
    String? eventId,
    String? name,
    String? company,
    String? jobPosition,
    String? tier,
    String? logoUrl,
    String? websiteUrl,
    String? description,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? bannerUrl,
    String? tagline,
    String? detailedDescription,
    List<Map<String, dynamic>>? offers,
    List<Map<String, dynamic>>? products,
    List<String>? media,
    String? instagramUrl,
    String? linkedinUrl,
    String? youtubeUrl,
    String? boothLocation,
    String? chatUrl,
  }) {
    return Sponsor(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      company: company ?? this.company,
      jobPosition: jobPosition ?? this.jobPosition,
      tier: tier ?? this.tier,
      logoUrl: logoUrl ?? this.logoUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      tagline: tagline ?? this.tagline,
      detailedDescription: detailedDescription ?? this.detailedDescription,
      offers: offers ?? this.offers,
      products: products ?? this.products,
      media: media ?? this.media,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      boothLocation: boothLocation ?? this.boothLocation,
      chatUrl: chatUrl ?? this.chatUrl,
    );
  }
}

class Speaker {
  final String id;
  final String name;
  final String topic;
  final String company;
  final String imageUrl;
  final String? bio;
  final String role;
  final String linkedinUrl;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  String get photoUrl => imageUrl;

  final String eventId;

  Speaker({
    required this.id,
    this.eventId = '',
    required this.name,
    this.topic = '',
    this.company = '',
    required this.imageUrl,
    this.bio,
    required this.role,
    required this.linkedinUrl,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory Speaker.fromMap(Map<String, dynamic> data, String id) {
    return Speaker(
      id: id,
      eventId: data['eventId'] ?? '',
      name: data['name'] ?? '',
      topic: data['topic'] ?? '',
      company: data['company'] ?? '',
      imageUrl: data['imageUrl'] ?? data['photoUrl'] ?? '',
      bio: data['bio'],
      role: data['role'] ?? '',
      linkedinUrl: data['linkedinUrl'] ?? data['linkedInUrl'] ?? '',
      latitude: (data['location'] is Map ? (data['location']['lat'] ?? 0.0).toDouble() : 0.0),
      longitude: (data['location'] is Map ? (data['location']['lng'] ?? 0.0).toDouble() : 0.0),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  factory Speaker.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Speaker.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'name': name,
      'topic': topic,
      'company': company,
      'imageUrl': imageUrl,
      'bio': bio,
      'role': role,
      'linkedinUrl': linkedinUrl,
      'location': {
        'lat': latitude,
        'lng': longitude,
      },
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': isActive,
    };
  }

  Map<String, dynamic> toFirestore() => toMap();

  Speaker copyWith({
    String? id,
    String? eventId,
    String? name,
    String? topic,
    String? company,
    String? imageUrl,
    String? bio,
    String? role,
    String? linkedinUrl,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Speaker(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      topic: topic ?? this.topic,
      company: company ?? this.company,
      imageUrl: imageUrl ?? this.imageUrl,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class EventSpeakerLink {
  final String id;
  final String eventId;
  final String speakerId;
  final bool isFeatured;
  final int displayOrder;
  final DateTime? createdAt;

  EventSpeakerLink({
    required this.id,
    required this.eventId,
    required this.speakerId,
    this.isFeatured = false,
    this.displayOrder = 0,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'speakerId': speakerId,
      'isFeatured': isFeatured,
      'displayOrder': displayOrder,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory EventSpeakerLink.fromMap(Map<String, dynamic> data, String id) {
    return EventSpeakerLink(
      id: id,
      eventId: data['eventId'] ?? '',
      speakerId: data['speakerId'] ?? '',
      isFeatured: data['isFeatured'] ?? false,
      displayOrder: data['displayOrder'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class EventSponsorLink {
  final String id;
  final String eventId;
  final String sponsorId;
  final String tier;
  final int displayOrder;
  final DateTime? createdAt;

  EventSponsorLink({
    required this.id,
    required this.eventId,
    required this.sponsorId,
    this.tier = '',
    this.displayOrder = 0,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'sponsorId': sponsorId,
      'tier': tier,
      'displayOrder': displayOrder,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory EventSponsorLink.fromMap(Map<String, dynamic> data, String id) {
    return EventSponsorLink(
      id: id,
      eventId: data['eventId'] ?? '',
      sponsorId: data['sponsorId'] ?? '',
      tier: data['tier'] ?? '',
      displayOrder: data['displayOrder'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc, String currentUserId) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      text: data['text'] ?? data['messageText'] ?? '',
      isMe: data['senderId'] == currentUserId,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
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

  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CourseModel(
      id: doc.id,
      title: data['title'] ?? '',
      level: data['level'] ?? '',
      duration: data['duration'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      benefits: List<String>.from(data['benefits'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'level': level,
      'duration': duration,
      'price': price,
      'imageUrl': imageUrl,
      'benefits': benefits,
    };
  }
}

class OnboardingPageData {
  final String title;
  final String description;
  final String? imageUrl;
  final String? iconName; // Fallback if no image

  OnboardingPageData({
    required this.title,
    required this.description,
    this.imageUrl,
    this.iconName,
  });

  factory OnboardingPageData.fromMap(Map<String, dynamic> data) {
    return OnboardingPageData(
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      iconName: data['iconName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'iconName': iconName,
    };
  }
}

class BrandingInfo {
  final String companyName;
  final String? companyLogoUrl;
  final String? splashImageUrl;
  final String? splashText;
  final String splashAnimationType; // 'fade', 'scale', 'slide', 'rotate'
  final List<OnboardingPageData> onboardingPages;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BrandingInfo({
    required this.companyName,
    this.companyLogoUrl,
    this.splashImageUrl,
    this.splashText,
    this.splashAnimationType = 'scale',
    this.onboardingPages = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory BrandingInfo.fromMap(Map<String, dynamic> data) {
    return BrandingInfo(
      companyName: data['companyName'] ?? 'Event App',
      companyLogoUrl: data['companyLogoUrl'],
      splashImageUrl: data['splashImageUrl'],
      splashText: data['splashText'],
      splashAnimationType: data['splashAnimationType'] ?? 'scale',
      onboardingPages: (data['onboardingPages'] as List?)
              ?.map((p) => OnboardingPageData.fromMap(Map<String, dynamic>.from(p)))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'companyLogoUrl': companyLogoUrl,
      'splashImageUrl': splashImageUrl,
      'splashText': splashText,
      'splashAnimationType': splashAnimationType,
      'onboardingPages': onboardingPages.map((p) => p.toMap()).toList(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  BrandingInfo copyWith({
    String? companyName,
    String? companyLogoUrl,
    String? splashImageUrl,
    String? splashText,
    String? splashAnimationType,
    List<OnboardingPageData>? onboardingPages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BrandingInfo(
      companyName: companyName ?? this.companyName,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
      splashImageUrl: splashImageUrl ?? this.splashImageUrl,
      splashText: splashText ?? this.splashText,
      splashAnimationType: splashAnimationType ?? this.splashAnimationType,
      onboardingPages: onboardingPages ?? this.onboardingPages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ProfileItem {
  final String id;
  final String title;
  final int iconCodePoint;
  final String route;
  final int order;
  final bool isEnabled;

  ProfileItem({
    required this.id,
    required this.title,
    required this.iconCodePoint,
    required this.route,
    this.order = 0,
    this.isEnabled = true,
  });

  factory ProfileItem.fromMap(Map<String, dynamic> data, String id) {
    return ProfileItem(
      id: id,
      title: data['title'] ?? '',
      iconCodePoint: data['iconCodePoint'] ?? 0xe1b0, // Default icon
      route: data['route'] ?? '',
      order: data['order'] ?? 0,
      isEnabled: data['isEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'iconCodePoint': iconCodePoint,
      'route': route,
      'order': order,
      'isEnabled': isEnabled,
    };
  }

  ProfileItem copyWith({
    String? id,
    String? title,
    int? iconCodePoint,
    String? route,
    int? order,
    bool? isEnabled,
  }) {
    return ProfileItem(
      id: id ?? this.id,
      title: title ?? this.title,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      route: route ?? this.route,
      order: order ?? this.order,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

class EntryPass {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String status; // 'ACTIVE', 'USED'
  final DateTime? entryTime;
  final String? scannedByAdminId;
  final DateTime createdAt;
  final String? transactionId; // Groups tickets from same purchase
  final int ticketNumber; // Position in group (1, 2, 3...)
  final int totalTickets; // Total tickets in transaction

  EntryPass({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    this.status = 'ACTIVE',
    this.entryTime,
    this.scannedByAdminId,
    required this.createdAt,
    this.transactionId,
    this.ticketNumber = 1,
    this.totalTickets = 1,
  });

  factory EntryPass.fromMap(Map<String, dynamic> data, String id) {
    return EntryPass(
      id: id,
      eventId: data['eventId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      status: data['status'] ?? 'ACTIVE',
      entryTime: (data['entryTime'] as Timestamp?)?.toDate(),
      scannedByAdminId: data['scannedByAdminId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      transactionId: data['transactionId'],
      ticketNumber: data['ticketNumber'] ?? 1,
      totalTickets: data['totalTickets'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'userName': userName,
      'status': status,
      'entryTime': entryTime != null ? Timestamp.fromDate(entryTime!) : null,
      'scannedByAdminId': scannedByAdminId,
      'createdAt': Timestamp.fromDate(createdAt),
      'transactionId': transactionId,
      'ticketNumber': ticketNumber,
      'totalTickets': totalTickets,
    };
  }

  EntryPass copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? userName,
    String? status,
    DateTime? entryTime,
    String? scannedByAdminId,
    DateTime? createdAt,
    String? transactionId,
    int? ticketNumber,
    int? totalTickets,
  }) {
    return EntryPass(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      status: status ?? this.status,
      entryTime: entryTime ?? this.entryTime,
      scannedByAdminId: scannedByAdminId ?? this.scannedByAdminId,
      createdAt: createdAt ?? this.createdAt,
      transactionId: transactionId ?? this.transactionId,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      totalTickets: totalTickets ?? this.totalTickets,
    );
  }
}

class PersonalEvent {
  final String id;
  final String userId;
  final String title;
  final bool isAllDay;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String email;
  final String reminder;
  final String repeat;
  final String notes;
  final DateTime createdAt;

  PersonalEvent({
    required this.id,
    required this.userId,
    required this.title,
    this.isAllDay = false,
    required this.startDate,
    required this.endDate,
    this.location = '',
    this.email = '',
    this.reminder = '10 mins before',
    this.repeat = 'Don\'t repeat',
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'isAllDay': isAllDay,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'location': location,
      'email': email,
      'reminder': reminder,
      'repeat': repeat,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PersonalEvent.fromFirestore(Map<String, dynamic> data) {
    return PersonalEvent(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      isAllDay: data['isAllDay'] ?? false,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      email: data['email'] ?? '',
      reminder: data['reminder'] ?? '10 mins before',
      repeat: data['repeat'] ?? 'Don\'t repeat',
      notes: data['notes'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class LiveFeedItem {
  final String id;
  final String eventId;
  final String type; // 'video', 'image', 'template'
  final String? contentUrl;
  final String? templateType; // 'certificate', 'guest', 'invite', 'sponsor', 'intro'
  final Map<String, dynamic> templateData;
  final DateTime createdAt;
  final bool isActive;

  LiveFeedItem({
    required this.id,
    required this.eventId,
    required this.type,
    this.contentUrl,
    this.templateType,
    this.templateData = const {},
    DateTime? createdAt,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now();

  factory LiveFeedItem.fromMap(Map<String, dynamic> data, String id) {
    return LiveFeedItem(
      id: id,
      eventId: data['eventId'] ?? '',
      type: data['type'] ?? 'image',
      contentUrl: data['contentUrl'],
      templateType: data['templateType'],
      templateData: Map<String, dynamic>.from(data['templateData'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'type': type,
      'contentUrl': contentUrl,
      'templateType': templateType,
      'templateData': templateData,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  LiveFeedItem copyWith({
    String? id,
    String? eventId,
    String? type,
    String? contentUrl,
    String? templateType,
    Map<String, dynamic>? templateData,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return LiveFeedItem(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      type: type ?? this.type,
      contentUrl: contentUrl ?? this.contentUrl,
      templateType: templateType ?? this.templateType,
      templateData: templateData ?? this.templateData,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

