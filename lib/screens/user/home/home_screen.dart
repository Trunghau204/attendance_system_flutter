import 'package:flutter/material.dart';
import '../../../utils/constants.dart';
import '../../../services/api_service.dart';
import 'home_tab.dart';
import '../attendance/calendar_tab.dart';
import '../leave/leave_tab.dart';
import '../profile/profile_tab.dart';

/// ========================================
/// HOME SCREEN - Màn hình chính với Bottom Navigation
/// ========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  int _currentIndex = 0;
  int _leaveTabIndex = 0; // Track which sub-tab to show in LeaveTab
  int? _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final userId = await _apiService.getUserId();
    setState(() {
      _userId = userId;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> tabs = [
      HomeTab(
        onTabChange: (index, {int? leaveTabIndex}) {
          setState(() {
            _currentIndex = index;
            if (leaveTabIndex != null) {
              _leaveTabIndex = leaveTabIndex;
            }
          });
        },
      ), // Trang chủ - Chấm công
      CalendarTab(userId: _userId!), // Lịch sử + Lịch làm việc
      LeaveTab(
        userId: _userId!,
        initialTabIndex: _leaveTabIndex,
        key: ValueKey(_leaveTabIndex), // Force rebuild when index changes
      ), // Đơn xin nghỉ
      ProfileTab(userId: _userId!), // Thông tin cá nhân
    ];

    return Scaffold(
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Lịch',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Đơn từ',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
        ],
      ),
    );
  }
}
