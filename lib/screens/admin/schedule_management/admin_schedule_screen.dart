import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../models/admin/work_schedule_management.dart';
import '../../../models/admin/user_filter.dart';
import '../../../services/api_service.dart';
import '../../../utils/constants.dart';
import 'bulk_schedule_dialog.dart';
import 'schedule_detail_dialog.dart';

/// Màn hình quản lý lịch làm việc (Admin)
class AdminScheduleScreen extends StatefulWidget {
  const AdminScheduleScreen({super.key});

  @override
  State<AdminScheduleScreen> createState() => _AdminScheduleScreenState();
}

class _AdminScheduleScreenState extends State<AdminScheduleScreen> {
  final ApiService _apiService = ApiService();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  Map<DateTime, List<WorkScheduleManagement>> _schedules = {};
  List<Map<String, dynamic>> _shifts = [];
  List<Map<String, dynamic>> _users = [];

  bool _isLoading = true;
  String? _errorMessage;

  int? _selectedUserId;
  int? _selectedShiftId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadShifts(), _loadUsers(), _loadSchedules()]);
  }

  Future<void> _loadShifts() async {
    try {
      final shifts = await _apiService.getShifts();
      setState(() {
        _shifts = shifts.map((shift) {
          if (shift is Map<String, dynamic>) {
            return shift;
          } else {
            return shift as Map<String, dynamic>;
          }
        }).toList();
      });
    } catch (e) {
      // Error loading shifts
    }
  }

  Future<void> _loadUsers() async {
    try {
      final response = await _apiService.getUsers(UserFilter());
      final items = response['items'] as List;
      setState(() {
        _users = items.map((item) {
          if (item is Map<String, dynamic>) {
            return item;
          } else {
            // Convert UserManagement object to map
            return {
              'id': item.id,
              'fullName': item.fullName,
              'email': item.email,
            };
          }
        }).toList();
      });
    } catch (e) {
      // Error loading users
    }
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load schedules for the current month
      final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      final schedules = await _apiService.getWorkSchedules(
        userId: _selectedUserId,
        shiftId: _selectedShiftId,
        fromDate: firstDay,
        toDate: lastDay,
      );

      // Group schedules by date
      final Map<DateTime, List<WorkScheduleManagement>> groupedSchedules = {};
      for (var json in schedules) {
        final schedule = WorkScheduleManagement.fromJson(json);
        final dateKey = DateTime(
          schedule.workDate.year,
          schedule.workDate.month,
          schedule.workDate.day,
        );

        if (!groupedSchedules.containsKey(dateKey)) {
          groupedSchedules[dateKey] = [];
        }
        groupedSchedules[dateKey]!.add(schedule);
      }

      setState(() {
        _schedules = groupedSchedules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<WorkScheduleManagement> _getSchedulesForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _schedules[dateKey] ?? [];
  }

  Future<void> _showBulkScheduleDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => BulkScheduleDialog(users: _users, shifts: _shifts),
    );

    if (result != null && result['success'] == true) {
      // Chuyển calendar sang tháng đã tạo lịch
      if (result['fromDate'] != null) {
        setState(() {
          _focusedDay = result['fromDate'] as DateTime;
        });
      }
      _loadSchedules();
    }
  }

  Future<void> _showScheduleDetailDialog(
    DateTime date,
    List<WorkScheduleManagement> schedules,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ScheduleDetailDialog(
        date: date,
        schedules: schedules,
        shifts: _shifts,
      ),
    );

    if (result == true) {
      _loadSchedules();
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    int? tempUserId = _selectedUserId;
    int? tempShiftId = _selectedShiftId;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lọc lịch làm việc',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // User filter
              const Text(
                'Nhân viên',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                value: tempUserId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Tất cả nhân viên'),
                  ),
                  ..._users.map((user) {
                    return DropdownMenuItem<int?>(
                      value: user['id'] as int?,
                      child: Text(user['fullName']?.toString() ?? 'Unknown'),
                    );
                  }),
                ],
                onChanged: (value) {
                  setModalState(() {
                    tempUserId = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Shift filter
              const Text(
                'Ca làm việc',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                value: tempShiftId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Tất cả ca'),
                  ),
                  ..._shifts.map((shift) {
                    return DropdownMenuItem<int?>(
                      value: shift['id'] as int?,
                      child: Text(shift['name']?.toString() ?? 'Unknown'),
                    );
                  }),
                ],
                onChanged: (value) {
                  setModalState(() {
                    tempShiftId = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedUserId = null;
                          _selectedShiftId = null;
                        });
                        Navigator.pop(context);
                        _loadSchedules();
                      },
                      child: const Text('Xóa bộ lọc'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedUserId = tempUserId;
                          _selectedShiftId = tempShiftId;
                        });
                        Navigator.pop(context);
                        _loadSchedules();
                      },
                      child: const Text('Áp dụng'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý lịch làm việc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSchedules,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadSchedules,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Calendar
                TableCalendar(
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2030),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: _calendarFormat,
                  eventLoader: _getSchedulesForDay,
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });

                    final schedules = _getSchedulesForDay(selectedDay);
                    if (schedules.isNotEmpty) {
                      _showScheduleDetailDialog(selectedDay, schedules);
                    }
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                    _loadSchedules();
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: AppConstants.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                  ),
                ),
                const Divider(),

                // Selected day schedules
                Expanded(child: _buildSchedulesList()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showBulkScheduleDialog,
        icon: const Icon(Icons.add),
        label: const Text('Phân ca hàng loạt'),
      ),
    );
  }

  Widget _buildSchedulesList() {
    final schedules = _getSchedulesForDay(_selectedDay);

    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không có lịch làm việc',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: schedule.getShiftColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.schedule, color: schedule.getShiftColor()),
            ),
            title: Text(
              schedule.userName.isNotEmpty ? schedule.userName : 'Không rõ tên',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: schedule.getShiftColor(),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        schedule.shiftName.isNotEmpty
                            ? schedule.shiftName
                            : 'Không rõ ca',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      schedule.timeRange,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                if (schedule.notes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    schedule.notes!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteSchedule(schedule),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteSchedule(WorkScheduleManagement schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa lịch làm việc của ${schedule.userName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiService.deleteSchedule(schedule.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xóa lịch làm việc thành công'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSchedules();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
