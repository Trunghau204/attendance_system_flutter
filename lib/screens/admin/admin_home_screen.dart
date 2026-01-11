import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import 'user_management/user_list_screen.dart';
import 'schedule_management/admin_schedule_screen.dart';
import 'approval/admin_approval_screen.dart';
import 'adjustment/attendance_adjustment_screen.dart';
import 'shift_management/shift_management_screen.dart';
import 'location_management/location_management_screen.dart';
import 'statistics/statistics_screen.dart';
import 'activity_logs/activity_logs_screen.dart';
import 'qr_code/qr_code_generator_screen.dart';

/// Admin Home Screen - Dashboard với menu 11 modules
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final ApiService _apiService = ApiService();
  String _adminName = '';
  String _adminEmail = '';

  // Statistics data
  int _totalEmployees = 0;
  int _todayAttendance = 0;
  int _pendingRequests = 0;
  int _lateEarly = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
    _loadDashboardStats();
  }

  Future<void> _loadAdminInfo() async {
    final userInfo = await _apiService.getMe();
    if (userInfo['success'] == true) {
      setState(() {
        _adminName = userInfo['data']['fullName'] ?? '';
        _adminEmail = userInfo['data']['email'] ?? '';
      });
    }
  }

  Future<void> _loadDashboardStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final stats = await _apiService.getAdminDashboardStats();
      setState(() {
        _totalEmployees = stats['totalEmployees'] ?? 0;
        _todayAttendance = stats['todayAttendance'] ?? 0;
        _pendingRequests = stats['pendingRequests'] ?? 0;
        _lateEarly = stats['lateEarly'] ?? 0;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _apiService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text('Admin Dashboard'), elevation: 0),
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            _buildWelcomeCard(),
            const SizedBox(height: 24),

            // Statistics Overview (4 cards)
            _buildStatisticsSection(),
            const SizedBox(height: 24),

            // Quick Access Modules
            const Text(
              'Quản lý hệ thống',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildModulesGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: AppConstants.primaryColor),
            accountName: Text(
              _adminName.isNotEmpty ? _adminName : 'Admin',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(_adminEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _adminName.isNotEmpty ? _adminName[0].toUpperCase() : 'A',
                style: TextStyle(
                  fontSize: 32,
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.people,
            title: 'Quản lý nhân viên',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserListScreen()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.schedule,
            title: 'Quản lý lịch làm việc',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminScheduleScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.approval,
            title: 'Duyệt đơn',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminApprovalScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.edit_calendar,
            title: 'Điều chỉnh công',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AttendanceAdjustmentScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.access_time,
            title: 'Quản lý ca',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShiftManagementScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.location_on,
            title: 'Quản lý địa điểm',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LocationManagementScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.bar_chart,
            title: 'Thống kê tổng quan',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StatisticsScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.history,
            title: 'Nhật ký hoạt động',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ActivityLogsScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.qr_code,
            title: 'Tạo mã QR',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QRCodeGeneratorScreen(),
                ),
              );
            },
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Đăng xuất',
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppConstants.primaryColor),
      title: Text(title),
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor,
            AppConstants.primaryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xin chào,',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  _adminName.isNotEmpty ? _adminName : 'Administrator',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Quản trị viên hệ thống',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              size: 40,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tổng quan hôm nay',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (_isLoadingStats)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: _loadDashboardStats,
                tooltip: 'Làm mới',
              ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildStatCard(
              icon: Icons.people,
              title: 'Tổng nhân viên',
              value: _isLoadingStats ? '...' : '$_totalEmployees',
              color: Colors.blue,
            ),
            _buildStatCard(
              icon: Icons.check_circle,
              title: 'Đã chấm công',
              value: _isLoadingStats ? '...' : '$_todayAttendance',
              color: Colors.green,
            ),
            _buildStatCard(
              icon: Icons.pending_actions,
              title: 'Đơn chờ duyệt',
              value: _isLoadingStats ? '...' : '$_pendingRequests',
              color: Colors.orange,
            ),
            _buildStatCard(
              icon: Icons.warning,
              title: 'Đi muộn/Về sớm',
              value: _isLoadingStats ? '...' : '$_lateEarly',
              color: Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildModulesGrid() {
    final modules = [
      {
        'icon': Icons.people,
        'title': 'Nhân viên',
        'subtitle': 'Quản lý user',
        'color': Colors.blue,
        'priority': 5,
        'screen': const UserListScreen(),
      },
      {
        'icon': Icons.schedule,
        'title': 'Lịch làm việc',
        'subtitle': 'Phân ca',
        'color': Colors.green,
        'priority': 5,
        'screen': const AdminScheduleScreen(),
      },
      {
        'icon': Icons.approval,
        'title': 'Duyệt đơn',
        'subtitle': 'Nghỉ/Tăng ca',
        'color': Colors.orange,
        'priority': 4,
        'screen': const AdminApprovalScreen(),
      },
      {
        'icon': Icons.edit_calendar,
        'title': 'Điều chỉnh công',
        'subtitle': 'Sửa chấm công',
        'color': Colors.purple,
        'priority': 4,
        'screen': const AttendanceAdjustmentScreen(),
      },
      {
        'icon': Icons.access_time,
        'title': 'Quản lý ca',
        'subtitle': 'Ca làm việc',
        'color': Colors.teal,
        'priority': 3,
        'screen': const ShiftManagementScreen(),
      },
      {
        'icon': Icons.location_on,
        'title': 'Địa điểm',
        'subtitle': 'Locations',
        'color': Colors.red,
        'priority': 3,
        'screen': const LocationManagementScreen(),
      },
      {
        'icon': Icons.bar_chart,
        'title': 'Thống kê',
        'subtitle': 'Báo cáo',
        'color': Colors.cyan,
        'priority': 4,
        'screen': const StatisticsScreen(),
      },
      {
        'icon': Icons.history,
        'title': 'Nhật ký',
        'subtitle': 'Activity logs',
        'color': Colors.brown,
        'priority': 2,
        'screen': const ActivityLogsScreen(),
      },
      {
        'icon': Icons.qr_code,
        'title': 'QR Code',
        'subtitle': 'Tạo mã QR',
        'color': Colors.pink,
        'priority': 2,
        'screen': const QRCodeGeneratorScreen(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return _buildModuleCard(
          icon: module['icon'] as IconData,
          title: module['title'] as String,
          subtitle: module['subtitle'] as String,
          color: module['color'] as Color,
          priority: module['priority'] as int,
          screen: module['screen'] as Widget?,
        );
      },
    );
  }

  Widget _buildModuleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required int priority,
    Widget? screen,
  }) {
    return InkWell(
      onTap: () {
        if (screen != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đang phát triển...')));
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
