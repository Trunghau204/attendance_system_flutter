import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../user/home/home_screen.dart';
import '../admin/admin_home_screen.dart';
import 'register_screen.dart';

/// ========================================
/// LOGIN SCREEN - Màn hình đăng nhập
/// ========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers cho TextField
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Key cho Form validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // API Service instance
  final ApiService _apiService = ApiService();

  // Biến trạng thái
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Hàm xử lý đăng nhập
  Future<void> _handleLogin() async {
    // Validate form trước
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Hiển thị loading
    await EasyLoading.show(
      status: 'Đang đăng nhập...',
      maskType: EasyLoadingMaskType.black,
    );

    setState(() {
      _isLoading = true;
    });

    try {
      // Gọi API login
      final result = await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Ẩn loading
      await EasyLoading.dismiss();

      if (result['success']) {
        // Đăng nhập thành công
        await EasyLoading.showSuccess(
          AppConstants.msgLoginSuccess,
          duration: const Duration(seconds: 1),
        );

        // Kiểm tra role và navigate đúng screen
        if (mounted) {
          final userInfo = await _apiService.getMe();

          final data = userInfo['data'];

          // Backend trả về "role: Admin" (singular, không phải roles array)
          bool isAdmin = false;

          // Phương án 1: Check trường "role" (singular)
          final roleField = data?['role'];
          if (roleField != null) {
            final roleStr = roleField.toString().toLowerCase();
            isAdmin = roleStr.contains('admin');
          }

          // Phương án 2: Check trường "roles" (array) nếu có
          if (!isAdmin) {
            final rolesField = data?['roles'];
            if (rolesField != null) {
              if (rolesField is List) {
                isAdmin = rolesField.any((role) {
                  final roleStr = role.toString().toLowerCase();
                  return roleStr.contains('admin');
                });
              } else if (rolesField is String) {
                isAdmin = rolesField.toLowerCase().contains('admin');
              }
            }
          }

          if (isAdmin) {
            // Admin -> AdminHomeScreen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
            );
          } else {
            // User -> HomeScreen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        }
      } else {
        // Đăng nhập thất bại
        await EasyLoading.showError(
          result['message'] ?? AppConstants.msgLoginFailed,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      await EasyLoading.dismiss();
      await EasyLoading.showError(
        AppConstants.msgNetworkError,
        duration: const Duration(seconds: 2),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo hoặc Icon App
                  Icon(
                    Icons.fingerprint,
                    size: 100,
                    color: AppConstants.primaryColor,
                  ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),

                  const SizedBox(height: AppConstants.paddingLarge),

                  // Tiêu đề
                  Text(
                    'Smart Attendance',
                    style: AppConstants.headingStyle.copyWith(
                      fontSize: 28,
                      color: AppConstants.primaryColor,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: -0.2, end: 0),

                  const SizedBox(height: AppConstants.paddingSmall),

                  Text(
                    'Hệ thống chấm công thông minh',
                    style: AppConstants.captionStyle,
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: AppConstants.paddingLarge * 2),

                  // TextField Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Nhập email của bạn',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      if (!value.contains('@')) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2, end: 0),

                  const SizedBox(height: AppConstants.paddingMedium),

                  // TextField Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      hintText: 'Nhập mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      if (value.length < 6) {
                        return 'Mật khẩu phải có ít nhất 6 ký tự';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2, end: 0),

                  const SizedBox(height: AppConstants.paddingLarge),

                  // Nút Đăng nhập
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium,
                          ),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'ĐĂNG NHẬP',
                              style: AppConstants.buttonTextStyle,
                            ),
                    ),
                  ).animate().fadeIn(delay: 700.ms).scale(delay: 700.ms),

                  const SizedBox(height: AppConstants.paddingMedium),

                  // Đăng ký tài khoản
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Chưa có tài khoản? ',
                        style: AppConstants.bodyTextStyle,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Đăng ký ngay',
                          style: AppConstants.bodyTextStyle.copyWith(
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 800.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
