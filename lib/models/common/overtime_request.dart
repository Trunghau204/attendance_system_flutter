import 'package:flutter/material.dart';

/// ========================================
/// OVERTIME REQUEST MODEL - Đơn tăng ca
/// ========================================
class OvertimeRequest {
  final int id;
  final int userId;
  final String fullName;
  final DateTime overtimeDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String reason;
  final String status; // Pending, Approved, Rejected
  final String? approvedByName; // Nullable

  OvertimeRequest({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.overtimeDate,
    required this.startTime,
    required this.endTime,
    required this.reason,
    required this.status,
    this.approvedByName,
  });

  factory OvertimeRequest.fromJson(Map<String, dynamic> json) {
    // Parse TimeSpan "HH:mm:ss" to TimeOfDay
    TimeOfDay parseTimeSpan(String timeSpan) {
      final parts = timeSpan.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return OvertimeRequest(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      fullName: json['fullName'] ?? '',
      overtimeDate: DateTime.parse(
        json['date'],
      ), // Backend uses "date" not "overtimeDate"
      startTime: parseTimeSpan(json['startTime'] ?? '00:00:00'),
      endTime: parseTimeSpan(json['endTime'] ?? '00:00:00'),
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'Pending',
      approvedByName: json['approvedByName'], // Nullable
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'date': overtimeDate.toIso8601String(),
      'startTime':
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
      'endTime':
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
      'reason': reason,
      'status': status,
    };
  }

  bool get isPending => status == 'Pending';

  // Tính số giờ tăng ca
  double get totalHours {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return (endMinutes - startMinutes) / 60.0;
  }
}
