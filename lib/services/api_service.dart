import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../models/common/attendance.dart';
import '../models/common/work_schedule.dart';
import '../models/common/leave_request.dart';
import '../models/common/overtime_request.dart';
import '../models/common/system_notification.dart';
import '../models/common/user_statistics.dart';
import '../models/admin/user_management.dart';
import '../models/admin/user_filter.dart';
import '../models/admin/create_user_request.dart';
import '../models/admin/update_user_request.dart';

/// ========================================
/// API SERVICE - Tất cả các hàm gọi API
/// ========================================
class ApiService {
  // Singleton pattern để dùng chung 1 instance
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // HTTP Client với cookie support
  final http.Client _client = http.Client();

  // Lưu cookie session (quan trọng cho authentication)
  String? _sessionCookie;

  /// ==================== AUTHENTICATION ====================

  /// Đăng nhập
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.loginEndpoint}',
      );

      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        // Lưu cookie session từ response
        final setCookie = response.headers['set-cookie'];
        if (setCookie != null) {
          _sessionCookie = _extractSessionCookie(setCookie);
        }

        // Parse thông tin user từ response
        final data = jsonDecode(response.body);

        // Lưu thông tin vào SharedPreferences
        await _saveUserInfo(data);

        return {'success': true, 'data': data};
      } else {
        // Backend có thể trả về text thuần hoặc JSON
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'message': error['error'] ?? 'Đăng nhập thất bại',
          };
        } catch (_) {
          // Nếu không parse được JSON, dùng text thuần
          return {
            'success': false,
            'message': response.body.isNotEmpty
                ? response.body
                : 'Đăng nhập thất bại (${response.statusCode})',
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  /// Đăng ký tài khoản mới
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.registerEndpoint}',
      );

      // Backend ASP.NET Core cần field names viết hoa theo C# convention
      final requestBody = {
        'Email': email,
        'Password': password,
        'FullName': fullName,
        'PhoneNumber': phone,
      };

      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Đăng ký thành công!'};
      } else {
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'message': error['error'] ?? error['message'] ?? 'Đăng ký thất bại',
          };
        } catch (_) {
          return {
            'success': false,
            'message': response.body.isNotEmpty
                ? response.body
                : 'Đăng ký thất bại (Status: ${response.statusCode})',
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  /// Gửi OTP về email
  Future<Map<String, dynamic>> sendOTP(String email) async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.sendOTPEndpoint}',
      );

      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'OTP đã được gửi!'};
      } else {
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'message': error['error'] ?? 'Gửi OTP thất bại',
          };
        } catch (_) {
          return {
            'success': false,
            'message': response.body.isNotEmpty
                ? response.body
                : 'Gửi OTP thất bại',
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  /// Xác nhận OTP
  Future<Map<String, dynamic>> verifyOTP(String email, String otp) async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.verifyOTPEndpoint}',
      );

      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Xác nhận thành công!'};
      } else {
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'message': error['error'] ?? 'OTP không đúng',
          };
        } catch (_) {
          return {
            'success': false,
            'message': response.body.isNotEmpty
                ? response.body
                : 'OTP không đúng',
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  /// Lấy thông tin user hiện tại
  Future<Map<String, dynamic>> getMe() async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.getMeEndpoint}',
      );

      final response = await _client.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Không lấy được thông tin user'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Đăng xuất
  Future<bool> logout() async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.logoutEndpoint}',
      );

      await _client.post(url, headers: _getHeaders());

      // Xóa thông tin local
      _sessionCookie = null;
      await _clearUserInfo();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Đổi mật khẩu
  Future<Map<String, dynamic>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.changePasswordEndpoint}',
      );

      final response = await _client.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'OldPassword': oldPassword,
          'NewPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Đổi mật khẩu thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// ==================== ATTENDANCE (CHẤM CÔNG) ====================

  /// Check-in bằng GPS
  Future<Map<String, dynamic>> checkInGPS({
    required int userId,
    required double latitude,
    required double longitude,
    int? workScheduleId,
    int? locationId,
    String? photoUrl,
    String? deviceInfo,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.checkInEndpoint}',
      );

      final body = {
        'UserId': userId,
        'WorkScheduleId': workScheduleId,
        // Backend không lưu LocationId của Shift, để null để backend tự tìm isDefault Location
        'Latitude': latitude,
        'Longitude': longitude,
        'PhotoUrl': photoUrl ?? '',
        'DeviceInfo': deviceInfo ?? 'Flutter App',
        'LocationName': 'GPS Location',
      };

      final response = await _client.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': Attendance.fromJson(data)};
      } else {
        final error = jsonDecode(response.body);
        // Lấy message từ nhiều field khác nhau
        String errorMessage =
            error['error'] ??
            error['message'] ??
            error['Message'] ??
            error['title'] ??
            'Check-in thất bại';
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Check-in bằng QR Code
  Future<Map<String, dynamic>> checkInQR({
    required int userId,
    required String qrCodeContent,
    double? latitude,
    double? longitude,
    String? deviceInfo,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.checkInQREndpoint}',
      );

      final response = await _client.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'UserId': userId,
          'QrCodeContent': qrCodeContent,
          'Latitude': latitude,
          'Longitude': longitude,
          'DeviceInfo': deviceInfo ?? 'Flutter App',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': Attendance.fromJson(data)};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Mã QR không hợp lệ',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Check-out
  Future<Map<String, dynamic>> checkOut({
    required int userId,
    required int workScheduleId,
    double? latitude,
    double? longitude,
    String? deviceInfo,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.checkOutEndpoint}',
      );

      final response = await _client.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'UserId': userId,
          'WorkScheduleId': workScheduleId,
          'Latitude': latitude,
          'Longitude': longitude,
          'DeviceInfo': deviceInfo ?? 'Flutter App',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': Attendance.fromJson(data)};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Check-out thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Lấy lịch sử chấm công
  Future<Map<String, dynamic>> getAttendanceHistory({
    int? userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final params = <String, String>{};
      if (userId != null) params['userId'] = userId.toString();
      if (fromDate != null) params['fromDate'] = fromDate.toIso8601String();
      if (toDate != null) params['toDate'] = toDate.toIso8601String();

      final url = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.attendanceListEndpoint}',
      ).replace(queryParameters: params);

      final response = await _client.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final attendances = jsonList
            .map((json) => Attendance.fromJson(json))
            .toList();
        return {'success': true, 'data': attendances};
      } else {
        return {'success': false, 'message': 'Không lấy được lịch sử'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// ==================== WORK SCHEDULE (LỊCH LÀM VIỆC) ====================

  /// Lấy lịch làm việc
  Future<Map<String, dynamic>> getWorkSchedule({
    int? userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final params = <String, String>{};
      if (userId != null) params['userId'] = userId.toString();
      if (fromDate != null) params['fromDate'] = fromDate.toIso8601String();
      if (toDate != null) params['toDate'] = toDate.toIso8601String();

      final url = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.workScheduleEndpoint}',
      ).replace(queryParameters: params);

      final response = await _client.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final schedules = jsonList
            .map((json) => WorkSchedule.fromJson(json))
            .toList();
        return {'success': true, 'data': schedules};
      } else {
        return {'success': false, 'message': 'Không lấy được lịch làm việc'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Lấy ca làm việc hôm nay
  Future<Map<String, dynamic>> getTodaySchedule(int userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    final result = await getWorkSchedule(
      userId: userId,
      fromDate: startOfDay,
      toDate: endOfDay,
    );

    if (result['success'] && result['data'] != null) {
      final schedules = result['data'] as List<WorkSchedule>;
      if (schedules.isNotEmpty) {
        return {'success': true, 'data': schedules.first};
      }
    }

    return {'success': false, 'message': 'Không có ca làm việc hôm nay'};
  }

  /// ==================== LEAVE REQUEST (ĐƠN NGHỈ PHÉP) ====================

  /// Tạo đơn nghỉ phép
  Future<Map<String, dynamic>> createLeaveRequest({
    required int userId,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
    required String leaveType,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.leaveRequestEndpoint}',
      );

      // Map LeaveType string to enum integer
      int leaveTypeEnum;
      switch (leaveType) {
        case 'Nghỉ phép':
          leaveTypeEnum = 0; // AnnualLeave
          break;
        case 'Nghỉ ốm':
          leaveTypeEnum = 1; // SickLeave
          break;
        case 'Nghỉ việc riêng':
          leaveTypeEnum = 2; // PersonalLeave
          break;
        default:
          leaveTypeEnum = 0;
      }

      final requestBody = {
        'UserId': userId,
        'FromDate': DateFormat('yyyy-MM-dd').format(fromDate),
        'ToDate': DateFormat('yyyy-MM-dd').format(toDate),
        'Reason': reason,
        'LeaveType': leaveTypeEnum,
      };

      final response = await _client.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': LeaveRequest.fromJson(data)};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              error['error'] ?? error['message'] ?? 'Tạo đơn nghỉ thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Lấy danh sách đơn nghỉ phép
  /// Lấy danh sách đơn xin nghỉ phép (User + Admin)
  /// [userId] - Filter by user ID (for user view)
  /// [status] - Filter by status: Pending, Approved, Rejected (for admin view)
  Future<Map<String, dynamic>> getLeaveRequests({
    int? userId,
    String? status,
  }) async {
    try {
      final params = <String, String>{};
      if (userId != null) params['userId'] = userId.toString();
      if (status != null && status.isNotEmpty) params['status'] = status;

      final url = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.leaveRequestEndpoint}',
      ).replace(queryParameters: params);

      final response = await _client.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final requests = jsonList
            .map((json) => LeaveRequest.fromJson(json))
            .toList();
        return {'success': true, 'data': requests};
      } else {
        return {
          'success': false,
          'message': 'Không lấy được danh sách đơn nghỉ',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// ==================== OVERTIME REQUEST (ĐƠN TĂNG CA) ====================

  /// Tạo đơn tăng ca
  Future<Map<String, dynamic>> createOvertimeRequest({
    required int userId,
    required DateTime overtimeDate,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required String reason,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.overtimeRequestEndpoint}',
      );

      // Format TimeOfDay to TimeSpan string "HH:mm:ss"
      final startTimeStr =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';
      final endTimeStr =
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00';

      final requestBody = {
        'UserId': userId,
        'Date': DateFormat('yyyy-MM-dd').format(overtimeDate),
        'StartTime': startTimeStr,
        'EndTime': endTimeStr,
        'Reason': reason,
      };

      final response = await _client.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': OvertimeRequest.fromJson(data)};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              error['error'] ?? error['message'] ?? 'Tạo đơn tăng ca thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Lấy danh sách đơn tăng ca
  /// Lấy danh sách đơn xin tăng ca (User + Admin)
  /// [userId] - Filter by user ID (for user view)
  /// [status] - Filter by status: Pending, Approved, Rejected (for admin view)
  Future<Map<String, dynamic>> getOvertimeRequests({
    int? userId,
    String? status,
  }) async {
    try {
      final params = <String, String>{};
      if (userId != null) params['userId'] = userId.toString();
      if (status != null && status.isNotEmpty) params['status'] = status;

      final url = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.overtimeRequestEndpoint}',
      ).replace(queryParameters: params);

      final response = await _client.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final requests = jsonList
            .map((json) => OvertimeRequest.fromJson(json))
            .toList();
        return {'success': true, 'data': requests};
      } else {
        return {
          'success': false,
          'message': 'Không lấy được danh sách tăng ca',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// ==================== NOTIFICATIONS ====================

  /// Lấy thông báo của user
  Future<Map<String, dynamic>> getMyNotifications() async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.notificationsEndpoint}',
      );

      final response = await _client.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final notifications = jsonList
            .map((json) => SystemNotification.fromJson(json))
            .toList();
        return {'success': true, 'data': notifications};
      } else {
        return {'success': false, 'message': 'Không lấy được thông báo'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Lấy thống kê của user
  Future<Map<String, dynamic>> getUserStatistics({
    required int userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      // Nếu không truyền fromDate/toDate, lấy thống kê tháng hiện tại
      final now = DateTime.now();
      final from = fromDate ?? DateTime(now.year, now.month, 1);
      final to = toDate ?? DateTime(now.year, now.month + 1, 0);

      // Backend chỉ có /api/Statistic/ (không cần userId trong URL)
      // Backend sẽ lấy userId từ Session
      final url = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.statisticEndpoint}'
        '?FromDate=${from.toIso8601String()}'
        '&ToDate=${to.toIso8601String()}',
      );

      final response = await _client.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final statistics = UserStatistics.fromJson(data);
        return {'success': true, 'data': statistics};
      } else {
        return {
          'success': false,
          'message': 'Không lấy được thống kê (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Cập nhật thông tin user (department, phone)
  Future<Map<String, dynamic>> updateUserProfile({
    String? department,
    String? phoneNumber,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.getMeEndpoint}',
      );

      final body = <String, dynamic>{};
      if (department != null) body['Department'] = department;
      if (phoneNumber != null) body['PhoneNumber'] = phoneNumber;

      final response = await _client.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Cập nhật thành công'};
      } else {
        return {'success': false, 'message': 'Cập nhật thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// ==================== HELPER METHODS ====================

  /// Tạo headers cho request (Bao gồm cookie session)
  Map<String, String> _getHeaders() {
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (_sessionCookie != null) {
      headers['Cookie'] = _sessionCookie!;
    }

    return headers;
  }

  /// Trích xuất session cookie từ Set-Cookie header
  String _extractSessionCookie(String setCookieHeader) {
    // VD: ".AspNetCore.Session=xxx; path=/; httponly"
    final parts = setCookieHeader.split(';');
    if (parts.isNotEmpty) {
      return parts.first;
    }
    return setCookieHeader;
  }

  /// Lưu thông tin user vào SharedPreferences
  Future<void> _saveUserInfo(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(AppConstants.keyUserId, data['id'] ?? 0);
    await prefs.setString(AppConstants.keyFullName, data['fullName'] ?? '');
    await prefs.setString(AppConstants.keyEmail, data['email'] ?? '');

    // Lưu role (nếu có)
    if (data['roles'] != null && data['roles'].isNotEmpty) {
      await prefs.setString(AppConstants.keyRole, data['roles'][0]);
    }

    await prefs.setBool(AppConstants.keyIsLoggedIn, true);
  }

  /// Xóa thông tin user khỏi SharedPreferences
  Future<void> _clearUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Lấy UserId từ SharedPreferences
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.keyUserId);
  }

  /// Kiểm tra đã đăng nhập chưa
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }

  /// Lấy Role của user
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyRole);
  }

  /// ==================== USER MANAGEMENT (ADMIN) ====================

  /// Lấy danh sách nhân viên (Admin only)
  /// Filter: keyword, departmentId, isActive, role, page, pageSize
  Future<Map<String, dynamic>> getUsers(UserFilter filter) async {
    try {
      final queryParams = filter.toQueryParams();

      final uri = Uri.parse('${AppConstants.baseUrl}/api/User').replace(
        queryParameters: queryParams.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );

      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final users = data
            .map((json) => UserManagement.fromJson(json))
            .toList();

        return {
          'items': users,
          'totalCount':
              users.length, // Backend chưa có pagination, tạm dùng length
        };
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Tạo nhân viên mới (Admin only)
  Future<void> createUser(CreateUserRequest request) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/api/User');

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Cập nhật thông tin nhân viên (Admin only)
  Future<void> updateUser(UpdateUserRequest request) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/api/User/${request.id}');

      // Try PATCH method first (ASP.NET Core often uses PATCH for partial updates)
      var response = await http.patch(
        url,
        headers: _getHeaders(),
        body: jsonEncode(request.toJson()),
      );

      // If PATCH fails, try PUT
      if (response.statusCode != 200 && response.statusCode != 204) {
        response = await http.put(
          url,
          headers: _getHeaders(),
          body: jsonEncode(request.toJson()),
        );
      }

      // If still fails, try POST as last resort
      if (response.statusCode != 200 && response.statusCode != 204) {
        final postUrl = Uri.parse('${AppConstants.baseUrl}/api/User/Update');
        response = await http.post(
          postUrl,
          headers: _getHeaders(),
          body: jsonEncode(request.toJson()),
        );
      }

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorMsg = response.body.isNotEmpty
            ? response.body
            : 'Failed to update user';
        throw Exception(errorMsg);
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Xóa nhân viên (Admin only)
  Future<void> deleteUser(int id) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/api/User/$id');

      final response = await http.delete(url, headers: _getHeaders());

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Khóa/Mở khóa tài khoản (Admin only)
  Future<void> toggleUserStatus(int id) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/api/User/$id/status');

      final response = await http.patch(url, headers: _getHeaders());

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to toggle user status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Gán quyền cho user (Admin only)
  Future<void> assignRole(int userId, int roleId) async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}/api/User/$userId/assign-role',
      );

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'roleId': roleId}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to assign role: ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Gỡ quyền của user (Admin only)
  Future<void> removeRole(int userId, int roleId) async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}/api/User/$userId/remove-role',
      ).replace(queryParameters: {'roleId': roleId.toString()});

      final response = await http.delete(url, headers: _getHeaders());

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to remove role: ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Reset mật khẩu cho user (Admin only)
  Future<void> resetPassword(int userId) async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}/api/User/$userId/reset-password',
      );

      final response = await http.post(url, headers: _getHeaders());

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to reset password: ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Lấy thống kê dashboard admin
  /// Trả về: totalEmployees, todayAttendance, pendingRequests, lateEarly
  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    try {
      // Vì backend có thể chưa có endpoint tổng hợp, tạm thời gọi các API riêng lẻ

      // 1. Tổng nhân viên - Dùng getUsers() với filter rỗng
      int totalEmployees = 0;
      try {
        final usersResult = await getUsers(UserFilter());
        totalEmployees = usersResult['items'].length;
      } catch (e) {
        // Error getting total employees
      }

      // 2. Đã chấm công hôm nay - Lấy từ attendance API
      int todayAttendance = 0;
      try {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final attendanceUrl = Uri.parse(
          '${AppConstants.baseUrl}/api/Attendance?date=$today',
        );
        final attendanceResponse = await http.get(
          attendanceUrl,
          headers: _getHeaders(),
        );
        if (attendanceResponse.statusCode == 200) {
          final List<dynamic> attendances = jsonDecode(attendanceResponse.body);
          todayAttendance = attendances.length;
        }
      } catch (e) {
        // Error getting today attendance
      }

      // 3. Đơn chờ duyệt - Lấy từ leave requests API
      int pendingRequests = 0;
      try {
        final leaveUrl = Uri.parse('${AppConstants.baseUrl}/api/LeaveRequest');
        final leaveResponse = await http.get(leaveUrl, headers: _getHeaders());
        if (leaveResponse.statusCode == 200) {
          final List<dynamic> requests = jsonDecode(leaveResponse.body);
          pendingRequests = requests
              .where((r) => r['status']?.toString().toLowerCase() == 'pending')
              .length;
        }
      } catch (e) {
        // Error getting pending requests
      }

      // 4. Đi muộn/Về sớm hôm nay - Tính từ attendance
      int lateEarly = 0;
      try {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final attendanceUrl = Uri.parse(
          '${AppConstants.baseUrl}/api/Attendance?date=$today',
        );
        final attendanceResponse = await http.get(
          attendanceUrl,
          headers: _getHeaders(),
        );
        if (attendanceResponse.statusCode == 200) {
          final List<dynamic> attendances = jsonDecode(attendanceResponse.body);
          lateEarly = attendances.where((a) {
            final isLate = a['isLate'] == true;
            final isEarlyLeave = a['isEarlyLeave'] == true;
            return isLate || isEarlyLeave;
          }).length;
        }
      } catch (e) {
        // Error getting late/early
      }

      return {
        'totalEmployees': totalEmployees,
        'todayAttendance': todayAttendance,
        'pendingRequests': pendingRequests,
        'lateEarly': lateEarly,
      };
    } catch (e) {
      return {
        'totalEmployees': 0,
        'todayAttendance': 0,
        'pendingRequests': 0,
        'lateEarly': 0,
      };
    }
  }

  // ==================== WORK SCHEDULE MANAGEMENT (ADMIN) ====================

  /// Lấy danh sách lịch làm việc (Admin xem tất cả)
  Future<List<dynamic>> getWorkSchedules({
    int? userId,
    int? shiftId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (userId != null) queryParams['userId'] = userId.toString();
      if (shiftId != null) queryParams['shiftId'] = shiftId.toString();
      if (fromDate != null) {
        queryParams['fromDate'] = fromDate.toIso8601String().split('T')[0];
      }
      if (toDate != null) {
        queryParams['toDate'] = toDate.toIso8601String().split('T')[0];
      }

      final url = Uri.parse(
        '${AppConstants.baseUrl}/api/WorkSchedule',
      ).replace(queryParameters: queryParams);

      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to load schedules: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Tạo lịch làm việc cho 1 user
  Future<void> createSchedule({
    required int userId,
    required int shiftId,
    required DateTime workDate,
    String? notes,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/api/WorkSchedule');

      final body = {
        'UserId': userId,
        'ShiftId': shiftId,
        'WorkDate': workDate.toIso8601String().split('T')[0],
        'Notes': notes,
      };

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create schedule: ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Phân ca hàng loạt (Bulk assign)
  Future<Map<String, dynamic>> bulkCreateSchedules({
    required List<int> userIds,
    required int shiftId,
    required DateTime fromDate,
    required DateTime toDate,
    required List<int> weekdays,
    String? notes,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/api/WorkSchedule/bulk');

      final body = {
        'UserIds': userIds,
        'ShiftId': shiftId,
        'FromDate': fromDate.toIso8601String().split('T')[0],
        'ToDate': toDate.toIso8601String().split('T')[0],
        'Weekdays': weekdays,
        'Notes': notes,
      };

      final response = await _client.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        // Parse error message from backend
        String errorMessage = 'Không thể tạo lịch làm việc';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (_) {
          errorMessage = response.body;
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Cập nhật lịch làm việc
  Future<void> updateSchedule({
    required int id,
    int? shiftId,
    String? notes,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/api/WorkSchedule/$id');

      final body = <String, dynamic>{'Id': id};
      if (shiftId != null) body['ShiftId'] = shiftId;
      if (notes != null) body['Notes'] = notes;

      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to update schedule: ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Xóa lịch làm việc
  Future<void> deleteSchedule(int id) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/api/WorkSchedule/$id');

      final response = await http.delete(url, headers: _getHeaders());

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete schedule: ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// ==================== ADMIN - APPROVAL MANAGEMENT ====================

  /// Phê duyệt đơn xin nghỉ phép
  Future<void> approveLeaveRequest({
    required int id,
    String? responseNote,
  }) async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        throw Exception('Chưa đăng nhập');
      }

      final url = Uri.parse('${AppConstants.baseUrl}/api/LeaveRequest/approve');

      final body = <String, dynamic>{
        'Id': id,
        'Status': 1,
        'ApprovedBy': userId,
      };
      if (responseNote != null && responseNote.isNotEmpty) {
        body['ReviewerComment'] = responseNote;
      }

      final response = await _client.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorBody = response.body.isNotEmpty
            ? response.body
            : 'No error details';
        throw Exception(
          'Failed to approve request (${response.statusCode}): $errorBody',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Từ chối đơn xin nghỉ phép
  Future<void> rejectLeaveRequest({
    required int id,
    required String responseNote,
  }) async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        throw Exception('Chưa đăng nhập');
      }

      final url = Uri.parse('${AppConstants.baseUrl}/api/LeaveRequest/approve');

      final body = <String, dynamic>{
        'Id': id,
        'Status': 2,
        'ApprovedBy': userId,
        'ReviewerComment': responseNote,
      };

      final response = await _client.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorBody = response.body.isNotEmpty
            ? response.body
            : 'No error details';
        throw Exception(
          'Failed to reject request (${response.statusCode}): $errorBody',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Phê duyệt đơn xin tăng ca
  Future<void> approveOvertimeRequest({
    required int id,
    String? responseNote,
  }) async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        throw Exception('Chưa đăng nhập');
      }

      final url = Uri.parse(
        '${AppConstants.baseUrl}/api/OvertimeRequest/approve',
      );

      final body = <String, dynamic>{
        'Id': id,
        'Status': 1,
        'ApprovedBy': userId,
      };

      final response = await _client.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorBody = response.body.isNotEmpty
            ? response.body
            : 'No error details';
        throw Exception(
          'Failed to approve overtime request (${response.statusCode}): $errorBody',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Từ chối đơn xin tăng ca
  Future<void> rejectOvertimeRequest({
    required int id,
    required String responseNote,
  }) async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        throw Exception('Chưa đăng nhập');
      }

      final url = Uri.parse(
        '${AppConstants.baseUrl}/api/OvertimeRequest/approve',
      );

      final body = <String, dynamic>{
        'Id': id,
        'Status': 2,
        'ApprovedBy': userId,
      };

      final response = await _client.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorBody = response.body.isNotEmpty
            ? response.body
            : 'No error details';
        throw Exception(
          'Failed to reject overtime request (${response.statusCode}): $errorBody',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy danh sách chấm công (có thể filter theo userId, date range, status)
  Future<List<dynamic>> getAttendances({
    int? userId,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
  }) async {
    try {
      final params = <String, String>{};
      if (userId != null) params['userId'] = userId.toString();
      if (fromDate != null) {
        params['fromDate'] = fromDate.toIso8601String();
      }
      if (toDate != null) {
        params['toDate'] = toDate.toIso8601String();
      }
      if (status != null && status.isNotEmpty) {
        params['status'] = status;
      }

      final url = Uri.parse(
        '${AppConstants.baseUrl}/api/Attendance',
      ).replace(queryParameters: params);

      final response = await _client.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data;
      } else {
        throw Exception('Failed to get attendances: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Điều chỉnh chấm công
  Future<void> adjustAttendance({
    required int id,
    DateTime? newCheckIn,
    DateTime? newCheckOut,
    required String adjustmentReason,
    String? newStatus,
  }) async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        throw Exception('Chưa đăng nhập');
      }

      final url = Uri.parse('${AppConstants.baseUrl}/api/Attendance/adjust');

      final body = <String, dynamic>{
        'Id': id,
        'AdjustedBy': userId,
        'AdjustmentReason': adjustmentReason,
      };

      if (newCheckIn != null) {
        body['NewCheckIn'] = newCheckIn.toIso8601String();
      }
      if (newCheckOut != null) {
        body['NewCheckOut'] = newCheckOut.toIso8601String();
      }
      if (newStatus != null && newStatus.isNotEmpty) {
        // Convert status string to enum number based on backend AttendanceStatus
        final statusMap = {
          'Present': 0,
          'Absent': 1,
          'Late': 2,
          'Leave': 3,
          'LeaveEarly': 4,
          'EarlyCheckIn': 5,
          'LateCheckOut': 6,
        };
        body['NewStatus'] = statusMap[newStatus] ?? 0;
      }

      final response = await _client.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorBody = response.body.isNotEmpty
            ? response.body
            : 'No error details';
        throw Exception(
          'Failed to adjust attendance (${response.statusCode}): $errorBody',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================
  // SHIFT MANAGEMENT
  // ============================================================

  /// Lấy danh sách ca làm việc
  Future<List<dynamic>> getShifts() async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/api/Shift');

      final response = await _client.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data;
      } else {
        throw Exception('Failed to get shifts: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Tạo ca làm việc mới
  Future<Map<String, dynamic>> createShift({
    required String name,
    required String startTime, // Format: "HH:mm:ss"
    required String endTime,
    bool isActive = true,
    String? description,
    int? locationId,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/api/Shift');

      final body = <String, dynamic>{
        'Name': name,
        'StartTime': startTime,
        'EndTime': endTime,
        'IsActive': isActive,
      };
      if (description != null && description.isNotEmpty) {
        body['Description'] = description;
      }
      if (locationId != null) {
        body['LocationId'] = locationId;
      }

      final headers = _getHeaders();

      final response = await _client.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorBody = response.body.isNotEmpty
            ? response.body
            : 'No error details';
        throw Exception(
          'Failed to create shift (${response.statusCode}): $errorBody',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Cập nhật ca làm việc
  Future<void> updateShift({
    required int id,
    required String name,
    required String startTime,
    required String endTime,
    required bool isActive,
    String? description,
    int? locationId,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/api/Shift');

      final body = <String, dynamic>{
        'Id': id,
        'Name': name,
        'StartTime': startTime,
        'EndTime': endTime,
        'IsActive': isActive,
      };
      if (description != null && description.isNotEmpty) {
        body['Description'] = description;
      }
      if (locationId != null) {
        body['LocationId'] = locationId;
      }

      final response = await _client.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorBody = response.body.isNotEmpty
            ? response.body
            : 'No error details';
        throw Exception(
          'Failed to update shift (${response.statusCode}): $errorBody',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Xóa ca làm việc
  Future<void> deleteShift(int id) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/api/Shift/$id');

      final response = await _client.delete(url, headers: _getHeaders());

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorBody = response.body.isNotEmpty
            ? response.body
            : 'No error details';
        throw Exception(
          'Failed to delete shift (${response.statusCode}): $errorBody',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Thay đổi trạng thái ca (active/inactive)
  Future<void> changeShiftStatus(int id, bool isActive) async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}/api/Shift/$id/status?isActive=$isActive',
      );

      final response = await _client.patch(url, headers: _getHeaders());

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorBody = response.body.isNotEmpty
            ? response.body
            : 'No error details';
        throw Exception(
          'Failed to change shift status (${response.statusCode}): $errorBody',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================
  // LOCATION MANAGEMENT
  // ============================================================

  /// Lấy danh sách địa điểm
  Future<List<dynamic>> getLocations() async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/api/Location');

      final response = await _client.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data;
      } else {
        throw Exception('Failed to get locations: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Tạo địa điểm mới
  Future<Map<String, dynamic>> createLocation({
    required String name,
    required double latitude,
    required double longitude,
    required int radiusInMeters,
    bool isDefault = false,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/api/Location');

      final body = <String, dynamic>{
        'Name': name,
        'Latitude': latitude,
        'Longitude': longitude,
        'RadiusInMeters': radiusInMeters,
        'IsDefault': isDefault,
      };

      final response = await _client.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception(
          'Failed to create location (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Cập nhật địa điểm
  Future<void> updateLocation({
    required int id,
    required String name,
    required double latitude,
    required double longitude,
    required int radiusInMeters,
    required bool isDefault,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/api/Location/$id');

      final body = <String, dynamic>{
        'Id': id,
        'Name': name,
        'Latitude': latitude,
        'Longitude': longitude,
        'RadiusInMeters': radiusInMeters,
        'IsDefault': isDefault,
      };

      final response = await _client.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
      } else {
        throw Exception(
          'Failed to update location (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Xóa địa điểm
  Future<void> deleteLocation(int id) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/api/Location/$id');

      final response = await _client.delete(url, headers: _getHeaders());

      if (response.statusCode == 204 || response.statusCode == 200) {
      } else {
        throw Exception(
          'Failed to delete location (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  /// Lấy thống kê
  Future<Map<String, dynamic>> getStatistics({
    int? userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (userId != null) {
        queryParams['userId'] = userId.toString();
      }
      if (fromDate != null) {
        queryParams['fromDate'] = fromDate.toIso8601String();
      }
      if (toDate != null) {
        queryParams['toDate'] = toDate.toIso8601String();
      }

      final url = Uri.parse(
        '${AppConstants.baseUrl}/api/Statistic',
      ).replace(queryParameters: queryParams);

      final response = await _client.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to get statistics: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Export thống kê ra Excel
  Future<List<int>> exportStatistics({
    int? userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (userId != null) {
        queryParams['userId'] = userId.toString();
      }
      if (fromDate != null) {
        queryParams['fromDate'] = fromDate.toIso8601String();
      }
      if (toDate != null) {
        queryParams['toDate'] = toDate.toIso8601String();
      }

      final url = Uri.parse(
        '${AppConstants.baseUrl}/api/Statistic/export',
      ).replace(queryParameters: queryParams);

      final response = await _client.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to export statistics: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ======================== ACTIVITY LOGS ========================

  /// Get activity logs with filters
  /// GET /api/ActivityLogs?userId={userId}&action={action}&fromDate={fromDate}&toDate={toDate}
  Future<List<dynamic>> getActivityLogs({
    int? userId,
    String? action,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (userId != null) {
        queryParams['userId'] = userId.toString();
      }
      if (action != null && action.isNotEmpty) {
        queryParams['action'] = action;
      }
      if (fromDate != null) {
        queryParams['fromDate'] = fromDate.toIso8601String();
      }
      if (toDate != null) {
        queryParams['toDate'] = toDate.toIso8601String();
      }

      final url = Uri.parse(
        '${AppConstants.baseUrl}/api/ActivityLogs',
      ).replace(queryParameters: queryParams);

      final response = await _client.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data as List<dynamic>;
      } else {
        throw Exception('Failed to get activity logs: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete old activity logs
  /// DELETE /api/ActivityLogs/cleanup?weeks={weeks}
  Future<Map<String, dynamic>> deleteOldActivityLogs({int weeks = 4}) async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}/api/ActivityLogs/cleanup?weeks=$weeks',
      );

      final response = await _client.delete(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to delete old logs: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Export activity logs to Excel
  /// GET /api/ActivityLogs/export-excel
  Future<List<int>> exportActivityLogs() async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}/api/ActivityLogs/export-excel',
      );

      final response = await _client.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to export activity logs: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ======================== QR CODE ========================

  /// Generate QR Code image (Admin only)
  /// GET /api/Attendance/generate-qr
  Future<List<int>> generateQRCode() async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}/api/Attendance/generate-qr',
      );

      final response = await _client.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to generate QR code: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Check-in by QR Code (User)
  /// POST /api/Attendance/check-in/qr
  Future<Map<String, dynamic>> checkInByQR({
    required String qrCodeContent,
    double? latitude,
    double? longitude,
    String? deviceInfo,
  }) async {
    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}/api/Attendance/check-in/qr',
      );

      final body = {
        'qrCodeContent': qrCodeContent,
        'latitude': latitude,
        'longitude': longitude,
        'deviceInfo': deviceInfo ?? 'Flutter App',
      };

      final response = await _client.post(
        url,
        headers: _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to check-in by QR');
      }
    } catch (e) {
      rethrow;
    }
  }
}
