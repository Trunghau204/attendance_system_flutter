class AttendanceAdjustment {
  final int id;
  final int userId;
  final String fullName;
  final DateTime checkIn;
  final DateTime? checkOut;
  final String status; // Present, Absent, Late, etc.
  final String attendanceType; // OnSite, Remote, Hybrid
  final String locationName;
  final String deviceInfo;
  final String? checkInPhotoUrl;
  final String? checkOutPhotoUrl;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final String? adjustmentReason;
  final String? adjustedByName;
  final DateTime? adjustedAt;

  AttendanceAdjustment({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.checkIn,
    this.checkOut,
    required this.status,
    required this.attendanceType,
    required this.locationName,
    required this.deviceInfo,
    this.checkInPhotoUrl,
    this.checkOutPhotoUrl,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.adjustmentReason,
    this.adjustedByName,
    this.adjustedAt,
  });

  factory AttendanceAdjustment.fromJson(Map<String, dynamic> json) {
    return AttendanceAdjustment(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      fullName: json['fullName'] ?? '',
      checkIn: DateTime.parse(json['checkIn']),
      checkOut: json['checkOut'] != null
          ? DateTime.parse(json['checkOut'])
          : null,
      status: json['status'] ?? '',
      attendanceType: json['attendanceType'] ?? '',
      locationName: json['locationName'] ?? '',
      deviceInfo: json['deviceInfo'] ?? '',
      checkInPhotoUrl: json['checkInPhotoUrl'],
      checkOutPhotoUrl: json['checkOutPhotoUrl'],
      checkInLatitude: json['checkInLatitude']?.toDouble(),
      checkInLongitude: json['checkInLongitude']?.toDouble(),
      checkOutLatitude: json['checkOutLatitude']?.toDouble(),
      checkOutLongitude: json['checkOutLongitude']?.toDouble(),
      adjustmentReason: json['adjustmentReason'],
      adjustedByName: json['adjustedByName'],
      adjustedAt: json['adjustedAt'] != null
          ? DateTime.parse(json['adjustedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut?.toIso8601String(),
      'status': status,
      'attendanceType': attendanceType,
      'locationName': locationName,
      'deviceInfo': deviceInfo,
      'checkInPhotoUrl': checkInPhotoUrl,
      'checkOutPhotoUrl': checkOutPhotoUrl,
      'checkInLatitude': checkInLatitude,
      'checkInLongitude': checkInLongitude,
      'checkOutLatitude': checkOutLatitude,
      'checkOutLongitude': checkOutLongitude,
      'adjustmentReason': adjustmentReason,
      'adjustedByName': adjustedByName,
      'adjustedAt': adjustedAt?.toIso8601String(),
    };
  }

  // Helper: Check if already adjusted
  bool get isAdjusted =>
      adjustmentReason != null && adjustmentReason!.isNotEmpty;

  // Helper: Calculate work hours
  double? get workHours {
    if (checkOut == null) return null;
    return checkOut!.difference(checkIn).inMinutes / 60.0;
  }

  // Helper: Format check-in time
  String get checkInTimeFormatted {
    return '${checkIn.hour.toString().padLeft(2, '0')}:${checkIn.minute.toString().padLeft(2, '0')}';
  }

  // Helper: Format check-out time
  String? get checkOutTimeFormatted {
    if (checkOut == null) return null;
    return '${checkOut!.hour.toString().padLeft(2, '0')}:${checkOut!.minute.toString().padLeft(2, '0')}';
  }
}
