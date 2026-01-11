import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../utils/constants.dart';

/// Dialog phân ca hàng loạt
class BulkScheduleDialog extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> shifts;

  const BulkScheduleDialog({
    super.key,
    required this.users,
    required this.shifts,
  });

  @override
  State<BulkScheduleDialog> createState() => _BulkScheduleDialogState();
}

class _BulkScheduleDialogState extends State<BulkScheduleDialog> {
  final ApiService _apiService = ApiService();
  final TextEditingController _notesController = TextEditingController();

  List<int> _selectedUserIds = [];
  int? _selectedShiftId;
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now().add(const Duration(days: 7));
  Set<int> _selectedWeekdays = {1, 2, 3, 4, 5}; // Mon-Fri by default

  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
        if (_toDate.isBefore(_fromDate)) {
          _toDate = _fromDate.add(const Duration(days: 7));
        }
      });
    }
  }

  Future<void> _selectToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: _fromDate,
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _toDate = picked;
      });
    }
  }

  void _showUserSelector() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Chọn nhân viên'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: widget.users.map((user) {
                final userId = user['id'] as int;
                final isSelected = _selectedUserIds.contains(userId);

                return CheckboxListTile(
                  title: Text(user['fullName']?.toString() ?? 'Unknown'),
                  subtitle: Text(user['email']?.toString() ?? ''),
                  value: isSelected,
                  onChanged: (checked) {
                    setDialogState(() {
                      if (checked == true) {
                        _selectedUserIds.add(userId);
                      } else {
                        _selectedUserIds.remove(userId);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  _selectedUserIds.clear();
                });
              },
              child: const Text('Bỏ chọn tất cả'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Xong'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    // Validation
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 nhân viên'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate selected users exist in the list
    final validUserIds = widget.users.map((u) => u['id'] as int).toSet();
    final invalidIds = _selectedUserIds
        .where((id) => !validUserIds.contains(id))
        .toList();
    if (invalidIds.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nhân viên ID ${invalidIds.join(", ")} không tồn tại trong hệ thống',
          ),
          backgroundColor: Colors.red,
        ),
      );
      // Remove invalid IDs
      setState(() {
        _selectedUserIds.removeWhere((id) => invalidIds.contains(id));
      });
      return;
    }

    if (_selectedShiftId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ca làm việc'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 ngày trong tuần'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _apiService.bulkCreateSchedules(
        userIds: _selectedUserIds,
        shiftId: _selectedShiftId!,
        fromDate: _fromDate,
        toDate: _toDate,
        weekdays: _selectedWeekdays.toList(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, {
          'success': true,
          'fromDate': _fromDate,
          'createdCount': result['createdCount'] ?? 0,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã tạo ${result['createdCount'] ?? 0} lịch làm việc',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Clean up error message
        String errorMsg = e.toString();
        if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.substring(11);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Phân ca hàng loạt',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Select users
                    const Text(
                      'Nhân viên *',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _showUserSelector,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedUserIds.isEmpty
                                  ? 'Chọn nhân viên'
                                  : '${_selectedUserIds.length} nhân viên đã chọn',
                              style: TextStyle(
                                color: _selectedUserIds.isEmpty
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Select shift
                    const Text(
                      'Ca làm việc *',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedShiftId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      hint: const Text('Chọn ca làm việc'),
                      items: widget.shifts.map((shift) {
                        return DropdownMenuItem<int>(
                          value: shift['id'] as int,
                          child: Text(
                            '${shift['name']?.toString() ?? 'Unknown'} (${shift['startTime']?.toString() ?? ''} - ${shift['endTime']?.toString() ?? ''})',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedShiftId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date range
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Từ ngày *',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _selectFromDate,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${_fromDate.day}/${_fromDate.month}/${_fromDate.year}',
                                      ),
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Đến ngày *',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _selectToDate,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${_toDate.day}/${_toDate.month}/${_toDate.year}',
                                      ),
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Weekdays
                    const Text(
                      'Ngày trong tuần *',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildWeekdayChip('T2', 1),
                        _buildWeekdayChip('T3', 2),
                        _buildWeekdayChip('T4', 3),
                        _buildWeekdayChip('T5', 4),
                        _buildWeekdayChip('T6', 5),
                        _buildWeekdayChip('T7', 6),
                        _buildWeekdayChip('CN', 7),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    const Text(
                      'Ghi chú',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Ghi chú (tùy chọn)',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Preview
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tổng quan:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('• ${_selectedUserIds.length} nhân viên'),
                          Text(
                            '• Từ ${_fromDate.day}/${_fromDate.month} đến ${_toDate.day}/${_toDate.month}',
                          ),
                          Text('• Các ngày: ${_getWeekdayNames()}'),
                          Text(
                            '• Dự kiến tạo: ~${_calculateTotal()} lịch làm việc',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Tạo lịch'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayChip(String label, int weekday) {
    final isSelected = _selectedWeekdays.contains(weekday);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedWeekdays.add(weekday);
          } else {
            _selectedWeekdays.remove(weekday);
          }
        });
      },
      selectedColor: AppConstants.primaryColor.withOpacity(0.3),
    );
  }

  String _getWeekdayNames() {
    const names = {
      1: 'T2',
      2: 'T3',
      3: 'T4',
      4: 'T5',
      5: 'T6',
      6: 'T7',
      7: 'CN',
    };
    return _selectedWeekdays.map((day) => names[day]).join(', ');
  }

  int _calculateTotal() {
    if (_selectedUserIds.isEmpty || _selectedWeekdays.isEmpty) return 0;

    int count = 0;
    DateTime current = _fromDate;
    while (current.isBefore(_toDate) || current.isAtSameMomentAs(_toDate)) {
      if (_selectedWeekdays.contains(current.weekday)) {
        count += _selectedUserIds.length;
      }
      current = current.add(const Duration(days: 1));
    }
    return count;
  }
}
