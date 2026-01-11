/// Model cho quản lý nhân viên (Admin view)
class UserManagement {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final int? departmentId;
  final String? departmentName;
  final List<String> roles;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserManagement({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.departmentId,
    this.departmentName,
    required this.roles,
    required this.isActive,
    required this.createdAt,
    this.lastLogin,
  });

  factory UserManagement.fromJson(Map<String, dynamic> json) {
    // Parse roles - backend có thể trả về 'roles', 'role', hoặc 'roleNames'
    List<String> rolesList = [];
    if (json['roles'] != null && json['roles'] is List) {
      rolesList = List<String>.from(json['roles']);
    } else if (json['role'] != null) {
      rolesList = [json['role'].toString()];
    } else if (json['roleNames'] != null && json['roleNames'] is List) {
      rolesList = List<String>.from(json['roleNames']);
    }

    // Parse phone - backend có thể dùng 'phone' hoặc 'phoneNumber'
    final phone = json['phone'] ?? json['phoneNumber'];

    return UserManagement(
      id: json['id'] ?? json['userId'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: phone,
      departmentId: json['departmentId'],
      departmentName: json['departmentName'],
      roles: rolesList,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'roles': roles,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  /// Check if user has specific role
  bool hasRole(String role) {
    return roles.any((r) => r.toLowerCase() == role.toLowerCase());
  }

  /// Get display role (primary role)
  String get displayRole {
    if (roles.isEmpty) return 'User';
    return roles.first;
  }

  /// Get status color
  String get statusText {
    return isActive ? 'Hoạt động' : 'Đã khóa';
  }
}
