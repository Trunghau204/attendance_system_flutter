import 'package:flutter/material.dart';
import '../../models/common/user_statistics.dart';
import '../../utils/constants.dart';

/// Widget hiển thị thống kê công việc
class StatisticsCard extends StatelessWidget {
  final UserStatistics statistics;
  final bool isCompact; // Nếu true, hiển thị dạng compact cho Home

  const StatisticsCard({
    super.key,
    required this.statistics,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactView();
    }
    return _buildFullView();
  }

  /// View đầy đủ cho Profile tab
  Widget _buildFullView() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thống kê công việc', style: AppConstants.headingStyle),
            const Divider(height: 24),
            _buildStatRow(
              'Số ngày làm việc',
              '${statistics.totalWorkDays} ngày',
              Icons.calendar_today,
              AppConstants.primaryColor,
            ),
            _buildStatRow(
              'Tổng giờ làm',
              _formatHours(statistics.totalWorkingHours),
              Icons.access_time,
              AppConstants.infoColor,
            ),
            _buildStatRow(
              'Số ngày đi muộn',
              '${statistics.totalLateDays} ngày',
              Icons.schedule,
              AppConstants.warningColor,
            ),
            _buildStatRow(
              'Số ngày về sớm',
              '${statistics.totalLeaveEarlyDays} ngày',
              Icons.logout,
              AppConstants.warningColor,
            ),
            _buildStatRow(
              'Số ngày vắng mặt',
              '${statistics.totalAbsentDays} ngày',
              Icons.event_busy,
              AppConstants.errorColor,
            ),
            _buildStatRow(
              'Số ngày nghỉ phép',
              '${statistics.totalLeaveDays} ngày',
              Icons.event_available,
              AppConstants.infoColor,
            ),
            _buildStatRow(
              'Giờ tăng ca',
              _formatHours(statistics.totalOvertimeHours),
              Icons.nightlight_round,
              AppConstants.successColor,
            ),
            _buildStatRow(
              'Số ngày phép còn lại',
              '${statistics.currentLeaveBalance} ngày',
              Icons.beach_access,
              AppConstants.primaryColor,
            ),
            if (statistics.totalPenaltyHours > 0)
              _buildStatRow(
                'Giờ phạt',
                _formatHours(statistics.totalPenaltyHours),
                Icons.warning,
                AppConstants.errorColor,
              ),
          ],
        ),
      ),
    );
  }

  /// View compact cho Home tab - chỉ hiển thị các chỉ số quan trọng
  Widget _buildCompactView() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Thống kê tháng này', style: AppConstants.subHeadingStyle),
                Icon(
                  Icons.bar_chart,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCompactStat(
                    '${statistics.totalWorkDays}',
                    'Ngày làm',
                    AppConstants.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildCompactStat(
                    _formatHours(statistics.totalWorkingHours),
                    'Giờ làm',
                    AppConstants.infoColor,
                  ),
                ),
                Expanded(
                  child: _buildCompactStat(
                    '${statistics.totalLateDays}',
                    'Đi muộn',
                    AppConstants.warningColor,
                  ),
                ),
                Expanded(
                  child: _buildCompactStat(
                    '${statistics.currentLeaveBalance}',
                    'Phép còn',
                    AppConstants.successColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(label, style: AppConstants.bodyTextStyle),
          ),
          Flexible(
            child: Text(
              value,
              style: AppConstants.subHeadingStyle.copyWith(color: color),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Format giờ thành dạng "Xh Ym" hoặc "X phút"
  String _formatHours(double hours) {
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;

    if (h == 0 && m == 0) {
      return '0 phút';
    } else if (h == 0) {
      return '$m phút';
    } else if (m == 0) {
      return '$h giờ';
    } else {
      return '${h}h ${m}m';
    }
  }

  Widget _buildCompactStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppConstants.captionStyle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
