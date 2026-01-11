/// ========================================
/// USER MODEL - Thông tin người dùng
/// ========================================
class User {
  final int id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? departmentName;
  final List<String> roles;
  final bool isActive;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.departmentName,
    required this.roles,
    required this.isActive,
  });

  /// Chuyển từ JSON sang Object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      departmentName: json['departmentName'],
      roles: json['roles'] != null ? List<String>.from(json['roles']) : [],
      isActive: json['isActive'] ?? true,
    );
  }

  /// Chuyển từ Object sang JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'departmentName': departmentName,
      'roles': roles,
      'isActive': isActive,
    };
  }

  /// Kiểm tra có phải Admin không
  bool get isAdmin => roles.contains('Admin');
}
