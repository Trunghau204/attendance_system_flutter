import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../models/common/work_schedule.dart';
import '../../../services/api_service.dart';
import '../../../utils/constants.dart';

/// ========================================
/// SCHEDULE TAB - Lịch làm việc
/// ========================================
class ScheduleTab extends StatefulWidget {
  final int userId;

  const ScheduleTab({super.key, required this.userId});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  final ApiService _apiService = ApiService();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  Map<DateTime, List<WorkSchedule>> _schedulesByDate = {};
  bool _isLoading = false;
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
  }

  /// Khởi tạo locale data cho tiếng Việt
  Future<void> _initializeLocale() async {
    await initializeDateFormatting('vi_VN', null);
    setState(() {
      _localeInitialized = true;
    });
    _loadMonthSchedules();
  }

  /// Load lịch làm việc của tháng hiện tại
  Future<void> _loadMonthSchedules() async {
    setState(() => _isLoading = true);

    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    final result = await _apiService.getWorkSchedule(
      userId: widget.userId,
      fromDate: firstDay,
      toDate: lastDay,
    );

    if (result['success']) {
      final List<WorkSchedule> schedules = result['data'];

      // Group schedules by date
      final Map<DateTime, List<WorkSchedule>> groupedSchedules = {};
      for (var schedule in schedules) {
        final date = DateTime(
          schedule.workDate.year,
          schedule.workDate.month,
          schedule.workDate.day,
        );
        if (groupedSchedules[date] == null) {
          groupedSchedules[date] = [];
        }
        groupedSchedules[date]!.add(schedule);
      }

      setState(() {
        _schedulesByDate = groupedSchedules;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result['message'])));
      }
    }
  }

  /// Lấy danh sách schedule của một ngày cụ thể
  List<WorkSchedule> _getSchedulesForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _schedulesByDate[normalizedDay] ?? [];
  }

  /// Màu sắc cho từng loại ca
  Color _getShiftColor(String shiftName) {
    if (shiftName.toLowerCase().contains('sáng')) {
      return Colors.orange.shade200;
    } else if (shiftName.toLowerCase().contains('chiều')) {
      return Colors.blue.shade200;
    } else if (shiftName.toLowerCase().contains('tối') ||
        shiftName.toLowerCase().contains('đêm')) {
      return Colors.purple.shade200;
    } else {
      return Colors.green.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hiển thị loading trong khi khởi tạo locale
    if (!_localeInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        // Calendar
        SliverToBoxAdapter(
          child: Card(
            margin: const EdgeInsets.all(16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: TableCalendar<WorkSchedule>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              eventLoader: _getSchedulesForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              locale: 'vi_VN',

              // Styling
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppConstants.primaryColor,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: AppConstants.accentColor,
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
              ),

              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                formatButtonTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),

              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },

              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },

              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
                _loadMonthSchedules();
              },
            ),
          ),
        ),

        // Legend
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('Ca sáng', Colors.orange.shade200),
                _buildLegendItem('Ca chiều', Colors.blue.shade200),
                _buildLegendItem('Ca tối', Colors.purple.shade200),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Selected day schedules
        _isLoading
            ? const SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            : _buildScheduleSliver(),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildScheduleSliver() {
    final schedules = _getSchedulesForDay(_selectedDay);

    if (schedules.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Không có lịch làm việc',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDay),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: _buildScheduleCard(schedules[index]),
        );
      }, childCount: schedules.length),
    );
  }

  Widget _buildScheduleCard(WorkSchedule schedule) {
    final shiftColor = _getShiftColor(schedule.shiftName);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [shiftColor.withOpacity(0.3), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shift name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: shiftColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      schedule.shiftName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${schedule.startTime} - ${schedule.endTime}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Details
              _buildDetailRow(
                Icons.calendar_today,
                'Ngày làm việc',
                DateFormat(
                  'EEEE, dd/MM/yyyy',
                  'vi_VN',
                ).format(schedule.workDate),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
