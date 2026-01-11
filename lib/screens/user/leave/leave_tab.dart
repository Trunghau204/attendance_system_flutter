import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../../models/common/leave_request.dart';
import '../../../models/common/overtime_request.dart';
import '../../../services/api_service.dart';
import '../../../utils/constants.dart';

/// ========================================
/// LEAVE TAB - Đơn xin nghỉ/tăng ca
/// ========================================
class LeaveTab extends StatefulWidget {
  final int userId;
  final int initialTabIndex;

  const LeaveTab({super.key, required this.userId, this.initialTabIndex = 0});

  @override
  State<LeaveTab> createState() => _LeaveTabState();
}

class _LeaveTabState extends State<LeaveTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  List<LeaveRequest> _leaveRequests = [];
  List<OvertimeRequest> _overtimeRequests = [];
  bool _isLoadingLeave = false;
  bool _isLoadingOvertime = false;
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('vi_VN', null);
    setState(() {
      _localeInitialized = true;
    });
    _loadLeaveRequests();
    _loadOvertimeRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaveRequests() async {
    setState(() => _isLoadingLeave = true);
    final result = await _apiService.getLeaveRequests(userId: widget.userId);
    if (result['success']) {
      setState(() {
        _leaveRequests = result['data'];
        _isLoadingLeave = false;
      });
    } else {
      setState(() => _isLoadingLeave = false);
    }
  }

  Future<void> _loadOvertimeRequests() async {
    setState(() => _isLoadingOvertime = true);
    final result = await _apiService.getOvertimeRequests(userId: widget.userId);
    if (result['success']) {
      setState(() {
        _overtimeRequests = result['data'];
        _isLoadingOvertime = false;
      });
    } else {
      setState(() => _isLoadingOvertime = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hiển thị loading trong khi khởi tạo locale
    if (!_localeInitialized) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          title: const Text('Đơn xin nghỉ/tăng ca'),
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Đơn xin nghỉ/tăng ca'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Nghỉ phép', icon: Icon(Icons.event_busy)),
            Tab(text: 'Tăng ca', icon: Icon(Icons.access_time)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildLeaveRequestTab(), _buildOvertimeRequestTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(),
        backgroundColor: AppConstants.primaryColor,
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Tạo đơn' : 'Tạo đơn'),
      ),
    );
  }

  // ========== LEAVE REQUEST TAB ==========
  Widget _buildLeaveRequestTab() {
    if (_isLoadingLeave) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_leaveRequests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadLeaveRequests,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 100),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có đơn nghỉ phép nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLeaveRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _leaveRequests.length,
        itemBuilder: (context, index) {
          final request = _leaveRequests[index];
          return _buildLeaveRequestCard(request);
        },
      ),
    );
  }

  Widget _buildLeaveRequestCard(LeaveRequest request) {
    Color statusColor;
    IconData statusIcon;

    switch (request.status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default: // pending
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(request.status),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  request.leaveType,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('dd/MM/yyyy').format(request.fromDate)} - ${DateFormat('dd/MM/yyyy').format(request.toDate)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.note, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.reason,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ========== OVERTIME REQUEST TAB ==========
  Widget _buildOvertimeRequestTab() {
    if (_isLoadingOvertime) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_overtimeRequests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadOvertimeRequests,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 100),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có đơn tăng ca nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOvertimeRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _overtimeRequests.length,
        itemBuilder: (context, index) {
          final request = _overtimeRequests[index];
          return _buildOvertimeRequestCard(request);
        },
      ),
    );
  }

  Widget _buildOvertimeRequestCard(OvertimeRequest request) {
    Color statusColor;
    IconData statusIcon;

    switch (request.status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default: // pending
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(request.status),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${request.totalHours.toStringAsFixed(1)} giờ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat(
                      'EEEE, dd/MM/yyyy',
                      'vi_VN',
                    ).format(request.overtimeDate),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  '${request.startTime.format(context)} - ${request.endTime.format(context)} (${request.totalHours.toStringAsFixed(1)}h)',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.note, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.reason,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ========== CREATE DIALOG ==========
  void _showCreateDialog() {
    if (_tabController.index == 0) {
      _showCreateLeaveDialog();
    } else {
      _showCreateOvertimeDialog();
    }
  }

  void _showCreateLeaveDialog() {
    DateTime fromDate = DateTime.now();
    DateTime toDate = DateTime.now();
    String reason = '';
    String leaveType = 'Nghỉ phép';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tạo đơn nghỉ phép'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: leaveType,
                  decoration: const InputDecoration(
                    labelText: 'Loại nghỉ',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Nghỉ phép', 'Nghỉ ốm', 'Nghỉ việc riêng']
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => leaveType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Từ ngày'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(fromDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: fromDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => fromDate = picked);
                    }
                  },
                ),
                ListTile(
                  title: const Text('Đến ngày'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(toDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: toDate.isAfter(fromDate) ? toDate : fromDate,
                      firstDate: fromDate,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => toDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Lý do',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) => reason = value,
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
                if (reason.isEmpty) {
                  EasyLoading.showError('Vui lòng nhập lý do');
                  return;
                }

                Navigator.pop(context);
                await EasyLoading.show(status: 'Đang gửi đơn...');

                final result = await _apiService.createLeaveRequest(
                  userId: widget.userId,
                  fromDate: fromDate,
                  toDate: toDate,
                  reason: reason,
                  leaveType: leaveType,
                );

                await EasyLoading.dismiss();

                if (result['success']) {
                  await EasyLoading.showSuccess('Tạo đơn thành công!');
                  _loadLeaveRequests();
                } else {
                  await EasyLoading.showError(result['message']);
                }
              },
              child: const Text('Tạo đơn'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateOvertimeDialog() {
    DateTime overtimeDate = DateTime.now();
    TimeOfDay startTime = const TimeOfDay(hour: 18, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 20, minute: 0);
    String reason = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tạo đơn tăng ca'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Ngày tăng ca'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(overtimeDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: overtimeDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 7),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      setDialogState(() => overtimeDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Giờ bắt đầu'),
                  subtitle: Text(startTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: startTime,
                    );
                    if (picked != null) {
                      setDialogState(() => startTime = picked);
                    }
                  },
                ),
                ListTile(
                  title: const Text('Giờ kết thúc'),
                  subtitle: Text(endTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: endTime,
                    );
                    if (picked != null) {
                      setDialogState(() => endTime = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Lý do',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) => reason = value,
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
                if (reason.isEmpty) {
                  EasyLoading.showError('Vui lòng nhập lý do');
                  return;
                }

                // Validate giờ kết thúc phải sau giờ bắt đầu
                final startMinutes = startTime.hour * 60 + startTime.minute;
                final endMinutes = endTime.hour * 60 + endTime.minute;
                if (endMinutes <= startMinutes) {
                  EasyLoading.showError('Giờ kết thúc phải sau giờ bắt đầu');
                  return;
                }

                Navigator.pop(context);
                await EasyLoading.show(status: 'Đang gửi đơn...');

                final result = await _apiService.createOvertimeRequest(
                  userId: widget.userId,
                  overtimeDate: overtimeDate,
                  startTime: startTime,
                  endTime: endTime,
                  reason: reason,
                );

                await EasyLoading.dismiss();

                if (result['success']) {
                  await EasyLoading.showSuccess('Tạo đơn thành công!');
                  _loadOvertimeRequests();
                } else {
                  await EasyLoading.showError(result['message']);
                }
              },
              child: const Text('Tạo đơn'),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Từ chối';
      default:
        return 'Chờ duyệt';
    }
  }
}
