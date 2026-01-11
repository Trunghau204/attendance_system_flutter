class ActivityLog {
  final int id;
  final int userId;
  final String userName;
  final String action;
  final String description;
  final DateTime timestamp;
  final String? ipAddress;
  final String? deviceInfo;

  ActivityLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.description,
    required this.timestamp,
    this.ipAddress,
    this.deviceInfo,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      action: json['action'] ?? '',
      description: json['description'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      ipAddress: json['ipAddress'],
      deviceInfo: json['deviceInfo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'action': action,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'ipAddress': ipAddress,
      'deviceInfo': deviceInfo,
    };
  }

  // Helper method to format timestamp
  String get formattedTimestamp {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) {
          return 'Vừa xong';
        }
        return '${diff.inMinutes} phút trước';
      }
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays == 1) {
      return 'Hôm qua';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  // Helper method to get action icon
  String get actionIcon {
    if (action.contains('Login') || action.contains('Đăng nhập')) {
      return '🔓';
    } else if (action.contains('Logout') || action.contains('Đăng xuất')) {
      return '🔒';
    } else if (action.contains('Create') || action.contains('Tạo')) {
      return '➕';
    } else if (action.contains('Update') || action.contains('Cập nhật')) {
      return '✏️';
    } else if (action.contains('Delete') || action.contains('Xóa')) {
      return '🗑️';
    } else if (action.contains('Approve') || action.contains('Duyệt')) {
      return '✅';
    } else if (action.contains('Reject') || action.contains('Từ chối')) {
      return '❌';
    } else if (action.contains('Check-in') ||
        action.contains('Chấm công vào')) {
      return '📍';
    } else if (action.contains('Check-out') ||
        action.contains('Chấm công ra')) {
      return '🚪';
    }
    return '📝';
  }

  // Helper method to get action color
  String get actionColorName {
    if (action.contains('Login') || action.contains('Đăng nhập')) {
      return 'green';
    } else if (action.contains('Logout') || action.contains('Đăng xuất')) {
      return 'grey';
    } else if (action.contains('Create') || action.contains('Tạo')) {
      return 'blue';
    } else if (action.contains('Update') || action.contains('Cập nhật')) {
      return 'orange';
    } else if (action.contains('Delete') || action.contains('Xóa')) {
      return 'red';
    } else if (action.contains('Approve') || action.contains('Duyệt')) {
      return 'green';
    } else if (action.contains('Reject') || action.contains('Từ chối')) {
      return 'red';
    }
    return 'blue';
  }

  // Helper method to get friendly action display text (hide technical API endpoints)
  String get friendlyAction {
    final lowerAction = action.toLowerCase();
    final lowerDesc = description.toLowerCase();

    // Combine action and description for better matching
    final combined = '$lowerAction $lowerDesc';

    // Map specific API endpoints to friendly Vietnamese text
    if (combined.contains('activitylog')) {
      return 'Xem nhật ký hoạt động';
    } else if (combined.contains('account/me')) {
      return 'Xem thông tin tài khoản';
    } else if (combined.contains('user')) {
      return 'Quản lý người dùng';
    } else if (combined.contains('leaverequest')) {
      return 'Quản lý đơn nghỉ phép';
    } else if (combined.contains('attendance')) {
      return 'Quản lý chấm công';
    } else if (combined.contains('overtime')) {
      return 'Quản lý tăng ca';
    } else if (combined.contains('schedule')) {
      return 'Quản lý lịch làm việc';
    } else if (combined.contains('shift')) {
      return 'Quản lý ca làm việc';
    } else if (combined.contains('location')) {
      return 'Quản lý địa điểm';
    } else if (combined.contains('statistic')) {
      return 'Xem báo cáo thống kê';
    } else if (combined.contains('approval')) {
      return 'Duyệt đơn từ';
    }

    // Check for common actions
    if (combined.contains('đăng nhập') || combined.contains('login')) {
      return 'Đăng nhập hệ thống';
    } else if (combined.contains('đăng xuất') || combined.contains('logout')) {
      return 'Đăng xuất hệ thống';
    } else if (combined.contains('create') || combined.contains('tạo')) {
      return 'Tạo mới dữ liệu';
    } else if (combined.contains('update') || combined.contains('cập nhật')) {
      return 'Cập nhật dữ liệu';
    } else if (combined.contains('delete') || combined.contains('xóa')) {
      return 'Xóa dữ liệu';
    } else if (combined.contains('approve') || combined.contains('duyệt')) {
      return 'Duyệt đơn';
    } else if (combined.contains('reject') || combined.contains('từ chối')) {
      return 'Từ chối đơn';
    } else if (combined.contains('check-in') ||
        combined.contains('chấm công vào')) {
      return 'Chấm công vào';
    } else if (combined.contains('check-out') ||
        combined.contains('chấm công ra')) {
      return 'Chấm công ra';
    }

    // If contains API path but no match above
    if (combined.contains('/api/') || combined.contains('truy cập')) {
      return 'Truy cập hệ thống';
    }

    // Return original action if no technical terms
    return action;
  }

  // Get display text: prioritize description, fallback to friendly action
  String get displayText {
    // Skip description if it contains technical terms or API paths
    if (description.isNotEmpty &&
        !description.contains('/api/') &&
        !description.contains('GET ') &&
        !description.contains('POST ') &&
        !description.contains('PUT ') &&
        !description.contains('DELETE ') &&
        !description.toLowerCase().contains('truy cập /api') &&
        description.length > 5) {
      return description;
    }
    return friendlyAction;
  }
}
