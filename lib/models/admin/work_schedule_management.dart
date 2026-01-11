import 'package:flutter/material.dart';

/// Model cho quản lý lịch làm việc (Admin)
class WorkScheduleManagement {
  final int id;
  final int userId;
  final String userName;
  final int shiftId;
  final String shiftName;
  final DateTime workDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String? notes;
  final DateTime createdAt;

  WorkScheduleManagement({
    required this.id,
    required this.userId,
    required this.userName,
    required this.shiftId,
    required this.shiftName,
    required this.workDate,
    required this.startTime,
    required this.endTime,
    this.notes,
    required this.createdAt,
  });

  factory WorkScheduleManagement.fromJson(Map<String, dynamic> json) {
    // Parse start time with null safety
    final startTimeStr = json['startTime']?.toString() ?? '00:00';
    final startParts = startTimeStr.split(':');
    final startTime = TimeOfDay(
      hour: int.parse(startParts[0]),
      minute: int.parse(startParts[1]),
    );

    // Parse end time with null safety
    final endTimeStr = json['endTime']?.toString() ?? '00:00';
    final endParts = endTimeStr.split(':');
    final endTime = TimeOfDay(
      hour: int.parse(endParts[0]),
      minute: int.parse(endParts[1]),
    );

    return WorkScheduleManagement(
      id: json['id'] as int,
      userId: json['userId'] as int,
      userName:
          json['userName']?.toString() ??
          json['fullName']?.toString() ??
          'Không rõ tên',
      shiftId: json['shiftId'] as int,
      shiftName: json['shiftName']?.toString() ?? 'Không rõ ca',
      workDate: DateTime.parse(
        json['workDate']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      startTime: startTime,
      endTime: endTime,
      notes: json['notes']?.toString(),
      createdAt: DateTime.parse(
        json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'shiftId': shiftId,
      'shiftName': shiftName,
      'workDate': workDate.toIso8601String(),
      'startTime':
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      'endTime':
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Get shift color based on shift name
  Color getShiftColor() {
    final name = shiftName.toLowerCase();
    if (name.contains('sáng') || name.contains('morning')) {
      return Colors.blue;
    } else if (name.contains('chiều') || name.contains('afternoon')) {
      return Colors.orange;
    } else if (name.contains('tối') || name.contains('night')) {
      return Colors.purple;
    }
    return Colors.grey;
  }

  /// Format time range display
  String get timeRange {
    final start =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  /// Copy with method
  WorkScheduleManagement copyWith({
    int? id,
    int? userId,
    String? userName,
    int? shiftId,
    String? shiftName,
    DateTime? workDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? notes,
    DateTime? createdAt,
  }) {
    return WorkScheduleManagement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      shiftId: shiftId ?? this.shiftId,
      shiftName: shiftName ?? this.shiftName,
      workDate: workDate ?? this.workDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Filter cho lịch làm việc
class ScheduleFilter {
  final int? userId;
  final int? shiftId;
  final DateTime? fromDate;
  final DateTime? toDate;

  ScheduleFilter({this.userId, this.shiftId, this.fromDate, this.toDate});

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (userId != null) params['userId'] = userId;
    if (shiftId != null) params['shiftId'] = shiftId;
    if (fromDate != null) {
      params['fromDate'] = fromDate!.toIso8601String().split('T')[0];
    }
    if (toDate != null) {
      params['toDate'] = toDate!.toIso8601String().split('T')[0];
    }
    return params;
  }

  ScheduleFilter copyWith({
    int? userId,
    int? shiftId,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return ScheduleFilter(
      userId: userId ?? this.userId,
      shiftId: shiftId ?? this.shiftId,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }
}
