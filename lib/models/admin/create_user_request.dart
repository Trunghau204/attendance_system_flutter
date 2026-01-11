/// Request model để tạo nhân viên mới
class CreateUserRequest {
  final String fullName;
  final String email;
  final String password;
  final String? phone;
  final int? departmentId;
  final List<int> roleIds;
  final bool isActive;

  CreateUserRequest({
    required this.fullName,
    required this.email,
    required this.password,
    this.phone,
    this.departmentId,
    this.roleIds = const [],
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'FullName': fullName,
      'Email': email,
      'Password': password,
      'PhoneNumber': phone,
      'DepartmentId': departmentId,
      'RoleId': roleIds.isNotEmpty ? roleIds.first : null,
      'IsActive': isActive,
    };
  }

  /// Validate request
  String? validate() {
    if (fullName.trim().isEmpty) {
      return 'Vui lòng nhập họ tên';
    }
    if (email.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    if (!email.contains('@')) {
      return 'Email không hợp lệ';
    }
    if (password.trim().isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (password.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }
}
