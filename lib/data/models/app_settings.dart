class AppSettings {
  final String primaryColor;
  final String secondaryColor;
  final String logoUrl;
  final String appIconUrl;
  final Map<String, dynamic> brandingJson;

  AppSettings({
    required this.primaryColor,
    required this.secondaryColor,
    required this.logoUrl,
    required this.appIconUrl,
    required this.brandingJson,
  });

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      primaryColor: map['primaryColor'] ?? '#FFFFFF',
      secondaryColor: map['secondaryColor'] ?? '#000000',
      logoUrl: map['logoUrl'] ?? '',
      appIconUrl: map['appIconUrl'] ?? '',
      brandingJson: map['brandingJson'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'logoUrl': logoUrl,
      'appIconUrl': appIconUrl,
      'brandingJson': brandingJson,
    };
  }
}
