/// ========================================
/// WORK SCHEDULE MODEL - Lịch làm việc
/// ========================================
class WorkSchedule {
  final int id;
  final int userId;
  final String fullName;
  final DateTime workDate;
  final int shiftId;
  final String shiftName;
  final String startTime; // VD: "08:00:00"
  final String endTime; // VD: "17:00:00"
  final bool isRestDay;

  WorkSchedule({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.workDate,
    required this.shiftId,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
    required this.isRestDay,
  });

  factory WorkSchedule.fromJson(Map<String, dynamic> json) {
    return WorkSchedule(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      fullName: json['fullName'] ?? '',
      workDate: DateTime.parse(json['workDate']),
      shiftId: json['shiftId'] ?? 0,
      shiftName: json['shiftName'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      isRestDay: json['isRestDay'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'workDate': workDate.toIso8601String(),
      'shiftId': shiftId,
      'shiftName': shiftName,
      'startTime': startTime,
      'endTime': endTime,
      'isRestDay': isRestDay,
    };
  }

  /// Hiển thị giờ làm việc dạng "08:00 - 17:00"
  String get displayTime =>
      '${_formatTime(startTime)} - ${_formatTime(endTime)}';

  String _formatTime(String time) {
    // Chuyển "08:00:00" thành "08:00"
    if (time.length >= 5) {
      return time.substring(0, 5);
    }
    return time;
  }
}
