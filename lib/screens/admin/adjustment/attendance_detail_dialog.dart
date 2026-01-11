import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/admin/attendance_adjustment.dart';
import '../../../services/api_service.dart';

class AttendanceDetailDialog extends StatefulWidget {
  final AttendanceAdjustment attendance;

  const AttendanceDetailDialog({super.key, required this.attendance});

  @override
  State<AttendanceDetailDialog> createState() => _AttendanceDetailDialogState();
}

class _AttendanceDetailDialogState extends State<AttendanceDetailDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _reasonController = TextEditingController();

  late DateTime _newCheckIn;
  late DateTime? _newCheckOut;
  String? _newStatus;
  bool _isLoading = false;

  final List<String> _statusOptions = [
    'Present',
    'Absent',
    'Late',
    'Leave',
    'LeaveEarly',
    'EarlyCheckIn',
    'LateCheckOut',
  ];

  @override
  void initState() {
    super.initState();
    _newCheckIn = widget.attendance.checkIn;
    _newCheckOut = widget.attendance.checkOut;
    // Đảm bảo _newStatus luôn nằm trong _statusOptions
    _newStatus = _statusOptions.contains(widget.attendance.status)
        ? widget.attendance.status
        : _statusOptions.first;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectCheckInTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_newCheckIn),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteTextColor: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _newCheckIn = DateTime(
          _newCheckIn.year,
          _newCheckIn.month,
          _newCheckIn.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _selectCheckOutTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _newCheckOut != null
          ? TimeOfDay.fromDateTime(_newCheckOut!)
          : TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteTextColor: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final baseDate = _newCheckOut ?? _newCheckIn;
        _newCheckOut = DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _saveAdjustment() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập lý do điều chỉnh')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.adjustAttendance(
        id: widget.attendance.id,
        newCheckIn: _newCheckIn,
        newCheckOut: _newCheckOut,
        adjustmentReason: _reasonController.text.trim(),
        newStatus: _newStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Điều chỉnh thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        widget.attendance.fullName[0].toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.attendance.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'dd/MM/yyyy',
                            ).format(widget.attendance.checkIn),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Original info section
                    _buildSectionTitle('Thông tin gốc'),
                    const SizedBox(height: 12),
                    _buildOriginalInfoCard(),

                    const SizedBox(height: 24),

                    // Edit section
                    _buildSectionTitle('Điều chỉnh'),
                    const SizedBox(height: 12),

                    // Check-in time
                    _buildTimeField(
                      label: 'Giờ vào',
                      icon: Icons.login,
                      color: Colors.green,
                      time: _newCheckIn,
                      onTap: _selectCheckInTime,
                    ),

                    const SizedBox(height: 12),

                    // Check-out time
                    _buildTimeField(
                      label: 'Giờ ra',
                      icon: Icons.logout,
                      color: Colors.blue,
                      time: _newCheckOut,
                      onTap: _selectCheckOutTime,
                      optional: true,
                    ),

                    const SizedBox(height: 12),

                    // Status dropdown
                    DropdownButtonFormField<String>(
                      value: _newStatus,
                      decoration: InputDecoration(
                        labelText: 'Trạng thái',
                        prefixIcon: const Icon(Icons.info_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _statusOptions.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _newStatus = value);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Reason field
                    TextField(
                      controller: _reasonController,
                      decoration: InputDecoration(
                        labelText: 'Lý do điều chỉnh *',
                        hintText: 'Nhập lý do điều chỉnh...',
                        prefixIcon: const Icon(Icons.edit_note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 3,
                      enabled: !_isLoading,
                    ),

                    // Previous adjustment info (if exists)
                    if (widget.attendance.isAdjusted) ...[
                      const SizedBox(height: 16),
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
                                  Icons.history,
                                  size: 16,
                                  color: Colors.orange[800],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Điều chỉnh trước đó',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Lý do: ${widget.attendance.adjustmentReason}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (widget.attendance.adjustedAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Thời gian: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.attendance.adjustedAt!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveAdjustment,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('Lưu điều chỉnh'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildOriginalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildInfoRow('Giờ vào', widget.attendance.checkInTimeFormatted),
          const Divider(height: 16),
          _buildInfoRow(
            'Giờ ra',
            widget.attendance.checkOutTimeFormatted ?? 'Chưa check-out',
          ),
          const Divider(height: 16),
          _buildInfoRow('Địa điểm', widget.attendance.locationName),
          const Divider(height: 16),
          _buildInfoRow('Trạng thái', widget.attendance.status),
          if (widget.attendance.workHours != null) ...[
            const Divider(height: 16),
            _buildInfoRow(
              'Tổng giờ',
              '${widget.attendance.workHours!.toStringAsFixed(1)}h',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTimeField({
    required String label,
    required IconData icon,
    required Color color,
    required DateTime? time,
    required VoidCallback onTap,
    bool optional = false,
  }) {
    final timeStr = time != null
        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
        : '--:--';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label + (optional ? ' (Tùy chọn)' : ''),
          prefixIcon: Icon(icon, color: color),
          suffixIcon: const Icon(Icons.access_time),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          timeStr,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
