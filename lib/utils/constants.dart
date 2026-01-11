import 'package:flutter/material.dart';

/// ========================================
/// CONSTANTS - Hằng số toàn cục của app
/// ========================================

class AppConstants {
  // ==================== API CONFIG ====================

  /// Base URL của Backend API
  /// - Emulator Android: sử dụng 10.0.2.2
  /// - Thiết bị thật: thay bằng IP máy tính (VD: 192.168.1.100)
  /// - iOS Simulator: sử dụng localhost
  static const String baseUrl = 'http://10.0.2.2:5000';

  // Các endpoint API chính
  static const String loginEndpoint = '/api/Account/login';
  static const String registerEndpoint = '/api/Account/register';
  static const String sendOTPEndpoint = '/api/Account/send-otp';
  static const String verifyOTPEndpoint = '/api/Account/verify-otp';
  static const String logoutEndpoint = '/api/Account/logout';
  static const String getMeEndpoint = '/api/Account/me';
  static const String changePasswordEndpoint = '/api/Account/change-password';

  static const String checkInEndpoint = '/api/Attendance/check-in';
  static const String checkInQREndpoint = '/api/Attendance/check-in/qr';
  static const String checkOutEndpoint = '/api/Attendance/check-out';
  static const String attendanceListEndpoint = '/api/Attendance';

  static const String workScheduleEndpoint = '/api/WorkSchedule';
  static const String leaveRequestEndpoint = '/api/LeaveRequest';
  static const String overtimeRequestEndpoint = '/api/OvertimeRequest';
  static const String statisticEndpoint = '/api/Statistic';
  static const String notificationsEndpoint = '/api/SystemNotifications/me';

  // ==================== SHARED PREFERENCES KEYS ====================
  static const String keyUserId = 'userId';
  static const String keyFullName = 'fullName';
  static const String keyEmail = 'email';
  static const String keyRole = 'role';
  static const String keyIsLoggedIn = 'isLoggedIn';

  // ==================== APP COLORS ====================
  static const Color primaryColor = Color(0xFF6C63FF); // Màu tím chủ đạo
  static const Color secondaryColor = Color(0xFF03DAC6); // Màu xanh phụ
  static const Color accentColor = Color(0xFFFF6584); // Màu hồng nhấn

  static const Color backgroundColor = Color(0xFFF5F6FA);
  static const Color cardColor = Colors.white;

  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);

  static const Color textPrimaryColor = Color(0xFF2E2E2E);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color textHintColor = Color(0xFFBDBDBD);

  // ==================== TEXT STYLES ====================
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );

  static const TextStyle subHeadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static const TextStyle bodyTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimaryColor,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondaryColor,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // ==================== DIMENSIONS ====================
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;

  // ==================== DURATIONS ====================
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration loadingDuration = Duration(seconds: 2);

  // ==================== GPS CONFIG ====================
  /// Bán kính cho phép chấm công (đơn vị: mét)
  static const double allowedRadius = 100.0; // 100m

  // ==================== QR CODE CONFIG ====================
  /// Mã bí mật của công ty (phải khớp với backend)
  static const String validQRCode = 'MyCompany_Secret_QR_2024';

  // ==================== MESSAGES ====================
  static const String msgLoginSuccess = 'Đăng nhập thành công!';
  static const String msgLoginFailed = 'Email hoặc mật khẩu không đúng!';
  static const String msgNetworkError = 'Lỗi kết nối mạng. Vui lòng thử lại!';
  static const String msgCheckInSuccess = 'Chấm công thành công!';
  static const String msgCheckOutSuccess = 'Check-out thành công!';
  static const String msgLocationDenied =
      'Bạn cần cấp quyền vị trí để chấm công!';
  static const String msgCameraDenied = 'Bạn cần cấp quyền camera để chụp ảnh!';
  static const String msgOutsideRange =
      'Bạn đang ở ngoài phạm vi cho phép chấm công!';
  static const String msgQRInvalid = 'Mã QR không hợp lệ!';
}

/// ========================================
/// APP THEME - Thiết lập theme tổng thể
/// ========================================
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primaryColor: AppConstants.primaryColor,
    scaffoldBackgroundColor: AppConstants.backgroundColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      secondary: AppConstants.secondaryColor,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),

    cardTheme: const CardThemeData(
      surfaceTintColor: Colors.transparent, // Đảm bảo Card màu trắng thuần
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(AppConstants.borderRadiusMedium),
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLarge,
          vertical: AppConstants.paddingMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        textStyle: AppConstants.buttonTextStyle,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        borderSide: const BorderSide(
          color: AppConstants.primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        borderSide: const BorderSide(color: AppConstants.errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingMedium,
      ),
    ),
  );
}
