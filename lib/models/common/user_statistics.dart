/// Model cho thống kê công việc của user
class UserStatistics {
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

  UserStatistics({
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

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      fromDate: DateTime.parse(json['fromDate']),
      toDate: DateTime.parse(json['toDate']),
      totalWorkDays: json['totalWorkDays'] ?? 0,
      totalWorkingHours: (json['totalWorkingHours'] ?? 0).toDouble(),
      totalLateDays: json['totalLateDays'] ?? 0,
      totalLeaveEarlyDays: json['totalLeaveEarlyDays'] ?? 0,
      totalAbsentDays: json['totalAbsentDays'] ?? 0,
      totalLeaveDays: json['totalLeaveDays'] ?? 0,
      totalOvertimeHours: (json['totalOvertimeHours'] ?? 0).toDouble(),
      currentLeaveBalance: json['currentLeaveBalance'] ?? 0,
      totalPenaltyHours: (json['totalPenaltyHours'] ?? 0).toDouble(),
    );
  }
}
