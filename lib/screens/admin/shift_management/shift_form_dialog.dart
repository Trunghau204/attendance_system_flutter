import 'package:flutter/material.dart';
import '../../../models/admin/shift_management.dart';
import '../../../services/api_service.dart';

class ShiftFormDialog extends StatefulWidget {
  final ShiftManagement? shift; // null = create mode, not null = edit mode

  const ShiftFormDialog({super.key, this.shift});

  @override
  State<ShiftFormDialog> createState() => _ShiftFormDialogState();
}

class _ShiftFormDialogState extends State<ShiftFormDialog> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _isActive = true;
  bool _isLoading = false;
  int? _selectedLocationId;
  List<dynamic> _locations = [];

  @override
  void initState() {
    super.initState();
    if (widget.shift != null) {
      // Edit mode
      _nameController.text = widget.shift!.name;
      _descriptionController.text = widget.shift!.description ?? '';
      _startTime = widget.shift!.startTime;
      _endTime = widget.shift!.endTime;
      _isActive = widget.shift!.isActive;
      _selectedLocationId = widget.shift!.locationId;
    } else {
      // Create mode - default values
      _startTime = const TimeOfDay(hour: 8, minute: 0);
      _endTime = const TimeOfDay(hour: 17, minute: 0);
    }
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final locations = await _apiService.getLocations();
      setState(() => _locations = locations);
    } catch (e) {
      // Error loading locations
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
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
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
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
      setState(() => _endTime = picked);
    }
  }

  String _formatTimeSpan(TimeOfDay time) {
    // ASP.NET Core TimeSpan format: "HH:mm:ss"
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes:00';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();

      // Validate name is not empty
      if (name.isEmpty) {
        throw Exception('Tên ca không được để trống');
      }

      final startTime = _formatTimeSpan(_startTime);
      final endTime = _formatTimeSpan(_endTime);
      final description = _descriptionController.text.trim();

      if (widget.shift == null) {
        // Create
        await _apiService.createShift(
          name: name,
          startTime: startTime,
          endTime: endTime,
          isActive: _isActive,
          description: description.isEmpty ? null : description,
          locationId: _selectedLocationId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tạo ca thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Update
        await _apiService.updateShift(
          id: widget.shift!.id,
          name: name,
          startTime: startTime,
          endTime: endTime,
          isActive: _isActive,
          description: description.isEmpty ? null : description,
          locationId: _selectedLocationId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật ca thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) Navigator.pop(context, true);
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
    final isEditMode = widget.shift != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
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
                      Icon(
                        isEditMode ? Icons.edit : Icons.add,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEditMode ? 'Cập nhật ca' : 'Thêm ca mới',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
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
                      // Name field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Tên ca *',
                          hintText: 'VD: Ca sáng, Ca chiều...',
                          prefixIcon: const Icon(Icons.label),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên ca';
                          }
                          if (value.trim().length > 100) {
                            return 'Tên ca không được quá 100 ký tự';
                          }
                          return null;
                        },
                        enabled: !_isLoading,
                      ),

                      const SizedBox(height: 16),

                      // Start time
                      _buildTimeField(
                        label: 'Giờ bắt đầu *',
                        icon: Icons.login,
                        color: Colors.green,
                        time: _startTime,
                        onTap: _selectStartTime,
                      ),

                      const SizedBox(height: 16),

                      // End time
                      _buildTimeField(
                        label: 'Giờ kết thúc *',
                        icon: Icons.logout,
                        color: Colors.blue,
                        time: _endTime,
                        onTap: _selectEndTime,
                      ),

                      const SizedBox(height: 16),

                      // Location dropdown
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<int>(
                          value: _selectedLocationId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Địa điểm (Tùy chọn)',
                            hintText: 'Chọn địa điểm cho ca làm việc',
                            prefixIcon: const Icon(Icons.location_on),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('Không chỉ định'),
                            ),
                            ..._locations.map((location) {
                              return DropdownMenuItem<int>(
                                value: location['id'],
                                child: Text(
                                  '${location['name']} (${location['radiusInMeters']}m)',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() => _selectedLocationId = value);
                                },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Active switch
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isActive ? Icons.toggle_on : Icons.toggle_off,
                              color: _isActive ? Colors.green : Colors.grey,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Trạng thái',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    _isActive
                                        ? 'Ca đang hoạt động'
                                        : 'Ca bị vô hiệu hóa',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isActive,
                              onChanged: _isLoading
                                  ? null
                                  : (value) {
                                      setState(() => _isActive = value);
                                    },
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Mô tả (Tùy chọn)',
                          hintText: 'Thêm mô tả cho ca làm việc...',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 3,
                        maxLength: 500,
                        validator: (value) {
                          if (value != null && value.trim().length > 500) {
                            return 'Mô tả không được quá 500 ký tự';
                          }
                          return null;
                        },
                        enabled: !_isLoading,
                      ),

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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
                              onPressed: _isLoading ? null : _save,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
                                  : Text(isEditMode ? 'Cập nhật' : 'Tạo mới'),
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
      ),
    );
  }

  Widget _buildTimeField({
    required String label,
    required IconData icon,
    required Color color,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
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
