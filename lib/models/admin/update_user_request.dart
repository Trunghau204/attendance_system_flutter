/// Request model để cập nhật thông tin nhân viên
class UpdateUserRequest {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final bool isActive;

  UpdateUserRequest({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'Id': id,
      'FullName': fullName,
      'Email': email,
      'IsActive': isActive,
    };

    // Chỉ thêm phone nếu có giá trị
    final phoneValue = phone;
    if (phoneValue != null && phoneValue.isNotEmpty) {
      json['PhoneNumber'] = phoneValue;
    }

    return json;
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
    return null;
  }
}
