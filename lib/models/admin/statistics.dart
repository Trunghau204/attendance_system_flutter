class Statistics {
  final int? userId;
  final String? userName;
  final DateTime fromDate;
  final DateTime toDate;
  final int totalWorkDays;
  final double totalWorkingHours;
  final int totalLateDays;
  final int totalLeaveEarlyDays;
  final int totalAbsentDays;
  final int totalLeaveDays;
  final double totalOvertimeHours;
  final int currentLeaveBalance;
  final double totalPenaltyHours;

  Statistics({
    this.userId,
    this.userName,
    required this.fromDate,
    required this.toDate,
    required this.totalWorkDays,
    required this.totalWorkingHours,
    required this.totalLateDays,
    required this.totalLeaveEarlyDays,
    required this.totalAbsentDays,
    required this.totalLeaveDays,
    required this.totalOvertimeHours,
    required this.currentLeaveBalance,
    required this.totalPenaltyHours,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      userId: json['userId'] ?? json['UserId'],
      userName: json['userName'] ?? json['UserName'],
      fromDate: DateTime.parse(json['fromDate'] ?? json['FromDate']),
      toDate: DateTime.parse(json['toDate'] ?? json['ToDate']),
      totalWorkDays: json['totalWorkDays'] ?? json['TotalWorkDays'] ?? 0,
      totalWorkingHours:
          (json['totalWorkingHours'] ?? json['TotalWorkingHours'] ?? 0.0)
              .toDouble(),
      totalLateDays: json['totalLateDays'] ?? json['TotalLateDays'] ?? 0,
      totalLeaveEarlyDays:
          json['totalLeaveEarlyDays'] ?? json['TotalLeaveEarlyDays'] ?? 0,
      totalAbsentDays: json['totalAbsentDays'] ?? json['TotalAbsentDays'] ?? 0,
      totalLeaveDays: json['totalLeaveDays'] ?? json['TotalLeaveDays'] ?? 0,
      totalOvertimeHours:
          (json['totalOvertimeHours'] ?? json['TotalOvertimeHours'] ?? 0.0)
              .toDouble(),
      currentLeaveBalance:
          json['currentLeaveBalance'] ?? json['CurrentLeaveBalance'] ?? 0,
      totalPenaltyHours:
          (json['totalPenaltyHours'] ?? json['TotalPenaltyHours'] ?? 0.0)
              .toDouble(),
    );
  }

  // Helper methods
  double get attendanceRate {
    if (totalWorkDays == 0) return 0;
    final totalDays = toDate.difference(fromDate).inDays + 1;
    return (totalWorkDays / totalDays) * 100;
  }

  double get lateRate {
    if (totalWorkDays == 0) return 0;
    return (totalLateDays / totalWorkDays) * 100;
  }

  double get effectiveWorkingHours => totalWorkingHours - totalPenaltyHours;

  String get dateRangeDisplay =>
      '${fromDate.day}/${fromDate.month}/${fromDate.year} - ${toDate.day}/${toDate.month}/${toDate.year}';
}
