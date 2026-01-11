/// Model for Overtime Request Management (Admin view)
class OvertimeRequestManagement {
  final int id;
  final int userId;
  final String userName;
  final String userEmail;
  final DateTime overtimeDate;
  final String startTime;
  final String endTime;
  final double hours;
  final String reason;
  final String status; // Pending, Approved, Rejected
  final String? responseNote;
  final int? respondedBy;
  final String? respondedByName;
  final DateTime? respondedAt;
  final DateTime createdAt;

  OvertimeRequestManagement({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.overtimeDate,
    required this.startTime,
    required this.endTime,
    required this.hours,
    required this.reason,
    required this.status,
    this.responseNote,
    this.respondedBy,
    this.respondedByName,
    this.respondedAt,
    required this.createdAt,
  });

  factory OvertimeRequestManagement.fromJson(Map<String, dynamic> json) {
    return OvertimeRequestManagement(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      userName:
          json['userName']?.toString() ??
          json['fullName']?.toString() ??
          'Không rõ tên',
      userEmail: json['userEmail']?.toString() ?? '',
      overtimeDate: json['overtimeDate'] != null
          ? DateTime.parse(json['overtimeDate'].toString())
          : DateTime.now(),
      startTime: json['startTime']?.toString() ?? '00:00',
      endTime: json['endTime']?.toString() ?? '00:00',
      hours: (json['hours'] is int)
          ? (json['hours'] as int).toDouble()
          : (json['hours'] as double? ?? 0.0),
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
      'overtimeDate': overtimeDate.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'hours': hours,
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
}
