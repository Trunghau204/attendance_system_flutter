import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/admin/attendance_adjustment.dart';
import '../../../services/api_service.dart';
import 'attendance_detail_dialog.dart';

class AttendanceAdjustmentScreen extends StatefulWidget {
  const AttendanceAdjustmentScreen({super.key});

  @override
  State<AttendanceAdjustmentScreen> createState() =>
      _AttendanceAdjustmentScreenState();
}

class _AttendanceAdjustmentScreenState
    extends State<AttendanceAdjustmentScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<AttendanceAdjustment> _attendances = [];
  List<AttendanceAdjustment> _filteredAttendances = [];
  bool _isLoading = false;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _toDate = DateTime.now();
  String? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _loadAttendances();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendances() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getAttendances(
        fromDate: _fromDate,
        toDate: _toDate,
        userId: _selectedUserId != null ? int.parse(_selectedUserId!) : null,
      );

      _attendances =
          data.map((json) => AttendanceAdjustment.fromJson(json)).toList()
            ..sort((a, b) => b.checkIn.compareTo(a.checkIn));
      _filteredAttendances = _attendances;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterAttendances(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAttendances = _attendances;
      } else {
        _filteredAttendances = _attendances
            .where(
              (a) =>
                  a.fullName.toLowerCase().contains(query.toLowerCase()) ||
                  a.locationName.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _loadAttendances();
    }
  }

  void _showAdjustmentDialog(AttendanceAdjustment attendance) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AttendanceDetailDialog(attendance: attendance),
    );

    if (result == true) {
      _loadAttendances();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điều chỉnh công'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Chọn khoảng thời gian',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên nhân viên hoặc địa điểm...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterAttendances('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterAttendances,
            ),
          ),

          // Date range info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Từ ${DateFormat('dd/MM/yyyy').format(_fromDate)} đến ${DateFormat('dd/MM/yyyy').format(_toDate)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text(
                  '${_filteredAttendances.length} bản ghi',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAttendances.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Không có dữ liệu',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAttendances,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredAttendances.length,
                      itemBuilder: (context, index) {
                        final attendance = _filteredAttendances[index];
                        return _buildAttendanceCard(attendance);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceAdjustment attendance) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isAdjusted = attendance.isAdjusted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showAdjustmentDialog(attendance),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name and Date
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      attendance.fullName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attendance.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          dateFormat.format(attendance.checkIn),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAdjusted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 14, color: Colors.orange[800]),
                          const SizedBox(width: 4),
                          Text(
                            'Đã điều chỉnh',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const Divider(height: 24),

              // Time info
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      Icons.login,
                      'Check-in',
                      attendance.checkInTimeFormatted,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoRow(
                      Icons.logout,
                      'Check-out',
                      attendance.checkOutTimeFormatted ?? '--:--',
                      attendance.checkOut != null ? Colors.blue : Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Location and Status
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      Icons.location_on,
                      'Địa điểm',
                      attendance.locationName,
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoRow(
                      Icons.info,
                      'Trạng thái',
                      attendance.status,
                      _getStatusColor(attendance.status),
                    ),
                  ),
                ],
              ),

              // Work hours
              if (attendance.workHours != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.blue[800],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tổng giờ làm: ${attendance.workHours!.toStringAsFixed(1)}h',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Adjustment info
              if (isAdjusted) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.edit_note,
                            size: 16,
                            color: Colors.orange[800],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lý do: ${attendance.adjustmentReason}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'leave':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
