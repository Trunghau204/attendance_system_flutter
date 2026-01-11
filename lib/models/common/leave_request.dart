/// ========================================
/// LEAVE REQUEST MODEL - Đơn xin nghỉ phép
/// ========================================
class LeaveRequest {
  final int id;
  final int userId;
  final String fullName;
  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  final String status; // Pending, Approved, Rejected
  final String leaveType; // Annual, Sick, Unpaid, Emergency, Other
  final DateTime createdAt;
  final int? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? rejectReason;

  LeaveRequest({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.status,
    required this.leaveType,
    required this.createdAt,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.rejectReason,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      fullName: json['fullName'] ?? '',
      fromDate: DateTime.parse(json['fromDate']),
      toDate: DateTime.parse(json['toDate']),
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'Pending',
      leaveType: json['leaveType'] ?? 'Other',
      createdAt: DateTime.parse(json['createdAt']),
      approvedBy: json['approvedBy'],
      approvedByName: json['approvedByName'],
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'])
          : null,
      rejectReason: json['rejectReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'fromDate': fromDate.toIso8601String(),
      'toDate': toDate.toIso8601String(),
      'reason': reason,
      'status': status,
      'leaveType': leaveType,
      'createdAt': createdAt.toIso8601String(),
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectReason': rejectReason,
    };
  }

  /// Tính số ngày nghỉ
  int get totalDays => toDate.difference(fromDate).inDays + 1;

  /// Kiểm tra còn pending không
  bool get isPending => status == 'Pending';

  /// Lấy màu theo trạng thái
  String getStatusColor() {
    switch (status) {
      case 'Approved':
        return 'green';
      case 'Rejected':
        return 'red';
      default:
        return 'orange';
    }
  }
}
