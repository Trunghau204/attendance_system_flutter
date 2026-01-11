import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'utils/constants.dart';
import 'screens/auth/login_screen.dart';
import 'screens/user/home/home_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'services/api_service.dart';

/// ========================================
/// MAIN APP - Entry point
/// ========================================
void main() {
  runApp(const AttendanceApp());

  // Cấu hình EasyLoading
  _configureEasyLoading();
}

/// Cấu hình EasyLoading toàn cục
void _configureEasyLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.white
    ..backgroundColor = Colors.black87
    ..indicatorColor = Colors.white
    ..textColor = Colors.white
    ..maskColor = Colors.blue.withOpacity(0.5)
    ..userInteractions = false
    ..dismissOnTap = false;
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  /// Xác định màn hình home dựa trên session và role
  Future<Widget> _determineHomeScreen() async {
    final apiService = ApiService();

    // Check xem đã login chưa
    final isLoggedIn = await apiService.isLoggedIn();
    if (!isLoggedIn) {
      return const LoginScreen();
    }

    try {
      // Nếu đã login, lấy thông tin user để check role
      final userInfo = await apiService.getMe();
      final data = userInfo['data'];

      // Check role field (singular)
      final roleField = data?['role'];
      if (roleField != null) {
        final roleStr = roleField.toString().toLowerCase();
        if (roleStr.contains('admin')) {
          return const AdminHomeScreen();
        }
      }

      // Check roles field (array) nếu có
      final rolesField = data?['roles'];
      if (rolesField != null) {
        if (rolesField is List) {
          final isAdmin = rolesField.any((role) {
            return role.toString().toLowerCase().contains('admin');
          });
          if (isAdmin) {
            return const AdminHomeScreen();
          }
        } else if (rolesField is String) {
          if (rolesField.toLowerCase().contains('admin')) {
            return const AdminHomeScreen();
          }
        }
      }

      // Mặc định là user
      return const HomeScreen();
    } catch (e) {
      // Nếu có lỗi (session hết hạn, network error...), về login
      return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Attendance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Kiểm tra session và role để navigate đúng screen
      home: FutureBuilder<Widget>(
        future: _determineHomeScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data ?? const LoginScreen();
        },
      ),

      // EasyLoading builder
      builder: EasyLoading.init(),
    );
  }
}
