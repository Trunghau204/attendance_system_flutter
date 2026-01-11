class LocationManagement {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final int radiusInMeters;
  final bool isDefault;

  LocationManagement({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusInMeters,
    required this.isDefault,
  });

  factory LocationManagement.fromJson(Map<String, dynamic> json) {
    return LocationManagement(
      id: json['id'] ?? json['Id'] ?? 0,
      name: json['name'] ?? json['Name'] ?? '',
      latitude: (json['latitude'] ?? json['Latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? json['Longitude'] ?? 0.0).toDouble(),
      radiusInMeters: json['radiusInMeters'] ?? json['RadiusInMeters'] ?? 100,
      isDefault: json['isDefault'] ?? json['IsDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': name,
      'Latitude': latitude,
      'Longitude': longitude,
      'RadiusInMeters': radiusInMeters,
      'IsDefault': isDefault,
    };
  }

  // Helper methods
  String get coordinates =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  String get radiusDisplay => radiusInMeters >= 1000
      ? '${(radiusInMeters / 1000).toStringAsFixed(1)} km'
      : '$radiusInMeters m';
}
