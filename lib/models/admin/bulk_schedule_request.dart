/// Request model để phân ca hàng loạt
class BulkScheduleRequest {
  final List<int> userIds;
  final int shiftId;
  final DateTime fromDate;
  final DateTime toDate;
  final List<int> weekdays; // 1=Monday, 7=Sunday
  final String? notes;

  BulkScheduleRequest({
    required this.userIds,
    required this.shiftId,
    required this.fromDate,
    required this.toDate,
    required this.weekdays,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'UserIds': userIds,
      'ShiftId': shiftId,
      'FromDate': fromDate.toIso8601String().split('T')[0],
      'ToDate': toDate.toIso8601String().split('T')[0],
      'Weekdays': weekdays,
      'Notes': notes,
    };
  }

  /// Validate request
  String? validate() {
    if (userIds.isEmpty) {
      return 'Vui lòng chọn ít nhất 1 nhân viên';
    }
    if (weekdays.isEmpty) {
      return 'Vui lòng chọn ít nhất 1 ngày trong tuần';
    }
    if (fromDate.isAfter(toDate)) {
      return 'Ngày bắt đầu phải trước ngày kết thúc';
    }
    return null;
  }

  /// Calculate total schedules to create
  int calculateTotalSchedules() {
    int count = 0;
    DateTime current = fromDate;
    while (current.isBefore(toDate) || current.isAtSameMomentAs(toDate)) {
      if (weekdays.contains(current.weekday)) {
        count += userIds.length;
      }
      current = current.add(const Duration(days: 1));
    }
    return count;
  }

  /// Get weekday names
  String get weekdayNames {
    const names = {
      1: 'T2',
      2: 'T3',
      3: 'T4',
      4: 'T5',
      5: 'T6',
      6: 'T7',
      7: 'CN',
    };
    return weekdays.map((day) => names[day]).join(', ');
  }
}

/// Request model để tạo/sửa 1 schedule
class CreateScheduleRequest {
  final int userId;
  final int shiftId;
  final DateTime workDate;
  final String? notes;

  CreateScheduleRequest({
    required this.userId,
    required this.shiftId,
    required this.workDate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'UserId': userId,
      'ShiftId': shiftId,
      'WorkDate': workDate.toIso8601String().split('T')[0],
      'Notes': notes,
    };
  }

  String? validate() {
    if (userId <= 0) {
      return 'Vui lòng chọn nhân viên';
    }
    if (shiftId <= 0) {
      return 'Vui lòng chọn ca làm việc';
    }
    return null;
  }
}

/// Request model để cập nhật schedule
class UpdateScheduleRequest {
  final int id;
  final int? shiftId;
  final String? notes;

  UpdateScheduleRequest({required this.id, this.shiftId, this.notes});

  Map<String, dynamic> toJson() {
    return {'Id': id, 'ShiftId': shiftId, 'Notes': notes};
  }
}
