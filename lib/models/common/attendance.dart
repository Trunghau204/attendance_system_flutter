/// ========================================
/// ATTENDANCE MODEL - Bản ghi chấm công
/// ========================================
class Attendance {
  final int id;
  final int userId;
  final String fullName;
  final DateTime checkIn;
  final DateTime? checkOut;
  final String status; // OnTime, Late, Absent
  final String attendanceType; // Normal, GPS, QR, Face
  final String? locationName;
  final String? deviceInfo;
  final String? checkInPhotoUrl;
  final String? checkOutPhotoUrl;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;

  Attendance({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.checkIn,
    this.checkOut,
    required this.status,
    required this.attendanceType,
    this.locationName,
    this.deviceInfo,
    this.checkInPhotoUrl,
    this.checkOutPhotoUrl,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      fullName: json['fullName'] ?? '',
      checkIn: DateTime.parse(json['checkIn']),
      checkOut: json['checkOut'] != null
          ? DateTime.parse(json['checkOut'])
          : null,
      status: json['status'] ?? 'OnTime',
      attendanceType: json['attendanceType'] ?? 'Normal',
      locationName: json['locationName'],
      deviceInfo: json['deviceInfo'],
      checkInPhotoUrl: json['checkInPhotoUrl'],
      checkOutPhotoUrl: json['checkOutPhotoUrl'],
      checkInLatitude: json['checkInLatitude']?.toDouble(),
      checkInLongitude: json['checkInLongitude']?.toDouble(),
      checkOutLatitude: json['checkOutLatitude']?.toDouble(),
      checkOutLongitude: json['checkOutLongitude']?.toDouble(),
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
    };
  }

  /// Tính thời gian làm việc (giờ)
  double get workingHours {
    if (checkOut == null) return 0;
    return checkOut!.difference(checkIn).inMinutes / 60;
  }

  /// Kiểm tra đã check-out chưa
  bool get hasCheckedOut => checkOut != null;
}
