import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../models/common/attendance.dart';
import '../../../utils/constants.dart';

/// ========================================
/// HISTORY TAB - Lịch sử chấm công
/// ========================================
class HistoryTab extends StatefulWidget {
  final int userId;

  const HistoryTab({super.key, required this.userId});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final ApiService _apiService = ApiService();
  List<Attendance> _attendances = [];
  bool _isLoading = true;

  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceHistory();
  }

  Future<void> _fetchAttendanceHistory() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _apiService.getAttendanceHistory(
      userId: widget.userId,
      fromDate: _selectedFromDate,
      toDate: _selectedToDate,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      setState(() {
        _attendances = result['data'] as List<Attendance>;
        // Sắp xếp theo ngày mới nhất
        _attendances.sort((a, b) => b.checkIn.compareTo(a.checkIn));
      });
    } else {
      EasyLoading.showError(result['message']);
    }
  }

  /// Chọn khoảng thời gian lọc
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedFromDate != null && _selectedToDate != null
          ? DateTimeRange(start: _selectedFromDate!, end: _selectedToDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppConstants.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedFromDate = picked.start;
        _selectedToDate = picked.end;
      });
      await _fetchAttendanceHistory();
    }
  }

  /// Xóa bộ lọc
  void _clearFilter() {
    setState(() {
      _selectedFromDate = null;
      _selectedToDate = null;
    });
    _fetchAttendanceHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedFromDate != null)
            FloatingActionButton(
              mini: true,
              heroTag: 'clear',
              backgroundColor: Colors.grey,
              onPressed: _clearFilter,
              child: const Icon(Icons.clear, color: Colors.white),
            ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'filter',
            backgroundColor: AppConstants.primaryColor,
            onPressed: _selectDateRange,
            child: const Icon(Icons.date_range, color: Colors.white),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAttendanceHistory,
              child: _attendances.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      itemCount: _attendances.length,
                      itemBuilder: (context, index) {
                        return _buildAttendanceCard(_attendances[index]);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Chưa có lịch sử chấm công',
                style: AppConstants.headingStyle.copyWith(
                  color: AppConstants.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedFromDate != null
                    ? 'Không có dữ liệu trong khoảng thời gian này'
                    : 'Hãy bắt đầu chấm công ngay!',
                style: AppConstants.bodyTextStyle.copyWith(
                  color: AppConstants.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceCard(Attendance attendance) {
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final timeFormatter = DateFormat('HH:mm');

    // Tính số giờ làm việc
    String workHours = '--';
    if (attendance.checkOut != null) {
      final duration = attendance.checkOut!.difference(attendance.checkIn);
      workHours = '${duration.inHours}h ${duration.inMinutes % 60}m';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - Ngày và trạng thái
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppConstants.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateFormatter.format(attendance.checkIn),
                      style: AppConstants.headingStyle.copyWith(fontSize: 16),
                    ),
                  ],
                ),
                _buildStatusChip(attendance.status),
              ],
            ),
            const Divider(height: 24),

            // Check-in Time
            _buildTimeRow(
              icon: Icons.login,
              label: 'Check-in',
              time: timeFormatter.format(attendance.checkIn),
              color: AppConstants.successColor,
            ),
            const SizedBox(height: 8),

            // Check-out Time
            _buildTimeRow(
              icon: Icons.logout,
              label: 'Check-out',
              time: attendance.checkOut != null
                  ? timeFormatter.format(attendance.checkOut!)
                  : '--:--',
              color: AppConstants.warningColor,
            ),
            const SizedBox(height: 12),

            // Work Hours
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 20,
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  const Text('Số giờ làm: ', style: AppConstants.bodyTextStyle),
                  Text(
                    workHours,
                    style: AppConstants.headingStyle.copyWith(
                      fontSize: 16,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow({
    required IconData icon,
    required String label,
    required String time,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppConstants.bodyTextStyle.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          time,
          style: AppConstants.headingStyle.copyWith(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'ontime':
      case 'on time':
        color = AppConstants.successColor;
        label = 'Đúng giờ';
        break;
      case 'late':
        color = AppConstants.warningColor;
        label = 'Đi muộn';
        break;
      case 'absent':
        color = AppConstants.errorColor;
        label = 'Vắng';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: AppConstants.captionStyle.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
