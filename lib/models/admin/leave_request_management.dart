/// Model for Leave Request Management (Admin view)
class LeaveRequestManagement {
  final int id;
  final int userId;
  final String userName;
  final String userEmail;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final double totalDays;
  final String reason;
  final String status; // Pending, Approved, Rejected
  final String? responseNote;
  final int? respondedBy;
  final String? respondedByName;
  final DateTime? respondedAt;
  final DateTime createdAt;

  LeaveRequestManagement({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    this.responseNote,
    this.respondedBy,
    this.respondedByName,
    this.respondedAt,
    required this.createdAt,
  });

  factory LeaveRequestManagement.fromJson(Map<String, dynamic> json) {
    return LeaveRequestManagement(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      userName:
          json['userName']?.toString() ??
          json['fullName']?.toString() ??
          'Không rõ tên',
      userEmail: json['userEmail']?.toString() ?? '',
      leaveType: json['leaveType']?.toString() ?? 'Annual',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'].toString())
          : (json['fromDate'] != null
                ? DateTime.parse(json['fromDate'].toString())
                : DateTime.now()),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'].toString())
          : (json['toDate'] != null
                ? DateTime.parse(json['toDate'].toString())
                : DateTime.now()),
      totalDays: (json['totalDays'] is int)
          ? (json['totalDays'] as int).toDouble()
          : (json['totalDays'] as double? ?? 0.0),
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      responseNote: json['responseNote']?.toString(),
      respondedBy: json['respondedBy'] as int?,
      respondedByName: json['respondedByName']?.toString(),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'leaveType': leaveType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalDays': totalDays,
      'reason': reason,
      'status': status,
      'responseNote': responseNote,
      'respondedBy': respondedBy,
      'respondedByName': respondedByName,
      'respondedAt': respondedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Check if request is pending
  bool get isPending => status == 'Pending';

  /// Check if request is approved
  bool get isApproved => status == 'Approved';

  /// Check if request is rejected
  bool get isRejected => status == 'Rejected';

  /// Get status color
  String get statusColor {
    switch (status) {
      case 'Pending':
        return 'orange';
      case 'Approved':
        return 'green';
      case 'Rejected':
        return 'red';
      default:
        return 'grey';
    }
  }

  /// Get leave type display name
  String get leaveTypeDisplay {
    switch (leaveType) {
      case 'Annual':
        return 'Nghỉ phép năm';
      case 'Sick':
        return 'Nghỉ ốm';
      case 'Unpaid':
        return 'Nghỉ không lương';
      case 'Maternity':
        return 'Nghỉ thai sản';
      case 'Other':
        return 'Khác';
      default:
        return leaveType;
    }
  }
}
