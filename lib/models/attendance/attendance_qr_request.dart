class AttendanceQRCodeRequest {
  final String qrCodeContent;
  final double? latitude;
  final double? longitude;
  final String? deviceInfo;

  AttendanceQRCodeRequest({
    required this.qrCodeContent,
    this.latitude,
    this.longitude,
    this.deviceInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'qrCodeContent': qrCodeContent,
      'latitude': latitude,
      'longitude': longitude,
      'deviceInfo': deviceInfo,
    };
  }

  factory AttendanceQRCodeRequest.fromJson(Map<String, dynamic> json) {
    return AttendanceQRCodeRequest(
      qrCodeContent: json['qrCodeContent'] ?? '',
      latitude: json['latitude'],
      longitude: json['longitude'],
      deviceInfo: json['deviceInfo'],
    );
  }
}
