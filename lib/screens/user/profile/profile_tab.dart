import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../../services/api_service.dart';
import '../../../utils/constants.dart';
import '../../auth/login_screen.dart';

/// Tab thông tin cá nhân
class ProfileTab extends StatefulWidget {
  final int userId;

  const ProfileTab({super.key, required this.userId});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final ApiService _apiService = ApiService();

  String _fullName = '';
  String _email = '';
  String _role = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final result = await _apiService.getMe();
    if (result['success']) {
      setState(() {
        _fullName = result['data']['fullName'] ?? '';
        _email = result['data']['email'] ?? '';
        _role =
            result['data']['role'] ??
            'User'; // Backend trả về 'role' chứ không phải 'roles'
      });
    }
  }

  String _getRoleInVietnamese(String role) {
    if (role.isEmpty) return 'Nhân viên';

    switch (role.toLowerCase()) {
      case 'admin':
        return 'Quản trị viên';
      case 'user':
        return 'Nhân viên';
      default:
        return 'Nhân viên';
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await EasyLoading.show(status: 'Đang đăng xuất...');
      await _apiService.logout();
      await EasyLoading.dismiss();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin cá nhân')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        children: [
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppConstants.primaryColor,
              child: Text(
                _fullName.isNotEmpty ? _fullName[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 36, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Center(child: Text(_fullName, style: AppConstants.headingStyle)),
          const SizedBox(height: 4),
          Center(child: Text(_email, style: AppConstants.captionStyle)),
          const SizedBox(height: 24),

          // Info cards
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.badge,
                color: AppConstants.primaryColor,
              ),
              title: const Text('Vai trò'),
              subtitle: Text(
                _getRoleInVietnamese(_role),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.primaryColor,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Actions
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Đổi mật khẩu'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showChangePasswordDialog,
          ),

          ListTile(
            leading: const Icon(Icons.logout, color: AppConstants.errorColor),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(color: AppConstants.errorColor),
            ),
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  /// Hiển thị dialog đổi mật khẩu
  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Đổi mật khẩu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: obscureOld,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu cũ',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureOld ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setDialogState(() => obscureOld = !obscureOld),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setDialogState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu mới',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () => setDialogState(
                        () => obscureConfirm = !obscureConfirm,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final oldPassword = oldPasswordController.text.trim();
                final newPassword = newPasswordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();

                // Validation
                if (oldPassword.isEmpty ||
                    newPassword.isEmpty ||
                    confirmPassword.isEmpty) {
                  EasyLoading.showError('Vui lòng điền đầy đủ thông tin');
                  return;
                }

                if (newPassword.length < 6) {
                  EasyLoading.showError('Mật khẩu mới phải có ít nhất 6 ký tự');
                  return;
                }

                if (newPassword != confirmPassword) {
                  EasyLoading.showError('Mật khẩu mới không khớp');
                  return;
                }

                Navigator.pop(context);
                await EasyLoading.show(status: 'Đang đổi mật khẩu...');

                final result = await _apiService.changePassword(
                  oldPassword,
                  newPassword,
                );

                await EasyLoading.dismiss();

                if (result['success']) {
                  await EasyLoading.showSuccess('Đổi mật khẩu thành công!');
                } else {
                  await EasyLoading.showError(result['message']);
                }
              },
              child: const Text('Đổi mật khẩu'),
            ),
          ],
        ),
      ),
    );
  }
}
