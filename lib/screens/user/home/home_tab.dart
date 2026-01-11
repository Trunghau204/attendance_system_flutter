import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:shimmer/shimmer.dart';
import '../../../services/api_service.dart';
import '../../../utils/constants.dart';
import '../../../models/common/work_schedule.dart';
import '../../../models/common/user_statistics.dart';
import '../../../widgets/user/attendance_bottom_sheet.dart';
import '../../../widgets/user/statistics_card.dart';

/// ========================================
/// HOME TAB - Trang chủ (Chấm công)
/// ========================================
class HomeTab extends StatefulWidget {
  final Function(int index, {int? leaveTabIndex}) onTabChange;

  const HomeTab({super.key, required this.onTabChange});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final ApiService _apiService = ApiService();

  WorkSchedule? _todaySchedule;
  bool _isLoading = true;
  String _userName = '';
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load dữ liệu ban đầu
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy userId từ SharedPreferences
      _userId = await _apiService.getUserId();

      if (_userId == null) {
        // Chưa đăng nhập, quay lại màn hình login
        return;
      }

      // Lấy thông tin user
      final userResult = await _apiService.getMe();
      if (userResult['success']) {
        setState(() {
          _userName = userResult['data']['fullName'] ?? '';
        });
      }

      // Lấy ca làm việc hôm nay
      final scheduleResult = await _apiService.getTodaySchedule(_userId!);
      if (scheduleResult['success']) {
        setState(() {
          _todaySchedule = scheduleResult['data'];
        });
      }
    } catch (e) {
      // Xử lý lỗi
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Hiển thị bottom sheet chọn loại chấm công
  void _showAttendanceOptions() {
    if (_userId == null) {
      EasyLoading.showError('Vui lòng đăng nhập lại');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AttendanceBottomSheet(
        userId: _userId!,
        workScheduleId: _todaySchedule?.id,
        onSuccess: () {
          // Refresh lại data sau khi chấm công thành công
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trang chủ')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - Chào người dùng
              _buildGreetingSection(),
              const SizedBox(height: AppConstants.paddingLarge),

              // Card hiển thị ca làm việc hôm nay
              _isLoading ? _buildShimmerCard() : _buildScheduleCard(),
              const SizedBox(height: AppConstants.paddingLarge),

              // Nút chấm công lớn
              _buildAttendanceButton(),
              const SizedBox(height: AppConstants.paddingLarge),

              // Quick actions
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget: Lời chào
  Widget _buildGreetingSection() {
    final hour = DateTime.now().hour;
    String greeting = 'Chào buổi sáng';
    if (hour >= 12 && hour < 18) {
      greeting = 'Chào buổi chiều';
    } else if (hour >= 18) {
      greeting = 'Chào buổi tối';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(greeting, style: AppConstants.captionStyle).animate().fadeIn(),
        const SizedBox(height: 4),
        Text(
          _userName.isNotEmpty ? _userName : 'Nhân viên',
          style: AppConstants.headingStyle,
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
      ],
    );
  }

  /// Widget: Card ca làm việc hôm nay
  Widget _buildScheduleCard() {
    if (_todaySchedule == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 48,
                  color: AppConstants.textHintColor,
                ),
                const SizedBox(height: 8),
                Text(
                  'Hôm nay bạn không có ca làm việc',
                  style: AppConstants.captionStyle,
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn();
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.access_time,
                    color: AppConstants.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ca làm việc hôm nay',
                        style: AppConstants.captionStyle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _todaySchedule!.shiftName,
                        style: AppConstants.subHeadingStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeInfo(
                  'Giờ vào',
                  _todaySchedule!.startTime,
                  Icons.login,
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                _buildTimeInfo('Giờ ra', _todaySchedule!.endTime, Icons.logout),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale();
  }

  /// Widget: Hiển thị giờ vào/ra
  Widget _buildTimeInfo(String label, String time, IconData icon) {
    // Format time: "08:00:00" -> "08:00"
    final displayTime = time.length >= 5 ? time.substring(0, 5) : time;

    return Column(
      children: [
        Icon(icon, color: AppConstants.primaryColor, size: 20),
        const SizedBox(height: 4),
        Text(label, style: AppConstants.captionStyle),
        const SizedBox(height: 2),
        Text(
          displayTime,
          style: AppConstants.subHeadingStyle.copyWith(
            color: AppConstants.primaryColor,
          ),
        ),
      ],
    );
  }

  /// Widget: Shimmer loading
  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(child: Container(height: 150, color: Colors.white)),
    );
  }

  /// Widget: Nút chấm công lớn
  Widget _buildAttendanceButton() {
    return Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppConstants.primaryColor,
                AppConstants.primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showAttendanceOptions,
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusLarge,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fingerprint, size: 60, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    'CHẤM CÔNG',
                    style: AppConstants.buttonTextStyle.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nhấn để bắt đầu',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 2000.ms, delay: 1000.ms)
        .shake(hz: 1, curve: Curves.easeInOutCubic);
  }

  /// Widget: Quick actions
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tiện ích', style: AppConstants.subHeadingStyle),
        const SizedBox(height: AppConstants.paddingMedium),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Xin nghỉ',
                Icons.assignment,
                AppConstants.warningColor,
                () {
                  // Navigate to Leave tab (index 2)
                  widget.onTabChange(2);
                },
              ),
            ),
            const SizedBox(width: AppConstants.paddingSmall),
            Expanded(
              child: _buildQuickActionCard(
                'Thống kê',
                Icons.bar_chart,
                Colors.purple,
                _showStatisticsDialog,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  /// Hiển thị dialog thống kê
  Future<void> _showStatisticsDialog() async {
    if (_userId == null) {
      EasyLoading.showError('Vui lòng đăng nhập lại');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _StatisticsDialog(userId: _userId!),
    );
  }

  /// Widget: Quick action card
  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(title, style: AppConstants.captionStyle),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog thống kê với chọn tháng
class _StatisticsDialog extends StatefulWidget {
  final int userId;

  const _StatisticsDialog({required this.userId});

  @override
  State<_StatisticsDialog> createState() => _StatisticsDialogState();
}

class _StatisticsDialogState extends State<_StatisticsDialog> {
  final ApiService _apiService = ApiService();

  UserStatistics? _statistics;
  bool _isLoading = false;

  late int _selectedMonth;
  late int _selectedYear;

  final List<String> _monthNames = [
    'Tháng 1',
    'Tháng 2',
    'Tháng 3',
    'Tháng 4',
    'Tháng 5',
    'Tháng 6',
    'Tháng 7',
    'Tháng 8',
    'Tháng 9',
    'Tháng 10',
    'Tháng 11',
    'Tháng 12',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    // Tính fromDate và toDate từ tháng/năm đã chọn
    final fromDate = DateTime(_selectedYear, _selectedMonth, 1);
    final toDate = DateTime(_selectedYear, _selectedMonth + 1, 0);

    final result = await _apiService.getUserStatistics(
      userId: widget.userId,
      fromDate: fromDate,
      toDate: toDate,
    );

    setState(() {
      _isLoading = false;
      if (result['success']) {
        _statistics = result['data'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppConstants.primaryColor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Thống kê công việc',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Chọn tháng/năm
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Chọn tháng
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: _selectedMonth,
                        decoration: const InputDecoration(
                          labelText: 'Tháng',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: List.generate(12, (index) {
                          final month = index + 1;
                          return DropdownMenuItem(
                            value: month,
                            child: Text(_monthNames[index]),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedMonth = value;
                            });
                            _loadStatistics();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Chọn năm
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedYear,
                        decoration: const InputDecoration(
                          labelText: 'Năm',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: List.generate(5, (index) {
                          final year = DateTime.now().year - 2 + index;
                          return DropdownMenuItem(
                            value: year,
                            child: Text('$year'),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedYear = value;
                            });
                            _loadStatistics();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Nội dung thống kê
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _statistics != null
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: StatisticsCard(statistics: _statistics!),
                      )
                    : const Center(child: Text('Không có dữ liệu thống kê')),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
