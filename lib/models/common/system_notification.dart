/// ========================================
/// NOTIFICATION MODEL - Thông báo hệ thống
/// ========================================
class SystemNotification {
  final int id;
  final int? userId;
  final String title;
  final String message;
  final String type; // Info, Warning, Success, Error
  final bool isRead;
  final DateTime createdAt;

  SystemNotification({
    required this.id,
    this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory SystemNotification.fromJson(Map<String, dynamic> json) {
    return SystemNotification(
      id: json['id'] ?? 0,
      userId: json['userId'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'Info',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
