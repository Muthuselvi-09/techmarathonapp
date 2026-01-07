class UserLocation {
  final double latitude;
  final double longitude;
  final String city;
  final String area;

  UserLocation({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.area,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'area': area,
    };
  }

  factory UserLocation.fromMap(Map<String, dynamic> map) {
    return UserLocation(
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      city: map['city'] ?? '',
      area: map['area'] ?? '',
    );
  }
}
