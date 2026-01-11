import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/admin/location_management.dart';
import '../../../services/api_service.dart';

class LocationFormDialog extends StatefulWidget {
  final LocationManagement? location;

  const LocationFormDialog({super.key, this.location});

  @override
  State<LocationFormDialog> createState() => _LocationFormDialogState();
}

class _LocationFormDialogState extends State<LocationFormDialog> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();

  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.location != null) {
      // Edit mode
      _nameController.text = widget.location!.name;
      _latitudeController.text = widget.location!.latitude.toString();
      _longitudeController.text = widget.location!.longitude.toString();
      _radiusController.text = widget.location!.radiusInMeters.toString();
      _isDefault = widget.location!.isDefault;
    } else {
      // Create mode - default values
      _radiusController.text = '100';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final latitude = double.parse(_latitudeController.text.trim());
      final longitude = double.parse(_longitudeController.text.trim());
      final radiusInMeters = int.parse(_radiusController.text.trim());

      if (widget.location == null) {
        // Create
        await _apiService.createLocation(
          name: name,
          latitude: latitude,
          longitude: longitude,
          radiusInMeters: radiusInMeters,
          isDefault: _isDefault,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tạo địa điểm thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Update
        await _apiService.updateLocation(
          id: widget.location!.id,
          name: name,
          latitude: latitude,
          longitude: longitude,
          radiusInMeters: radiusInMeters,
          isDefault: _isDefault,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật địa điểm thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.location != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit
                                  ? 'Chỉnh sửa địa điểm'
                                  : 'Thêm địa điểm mới',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isEdit
                                  ? 'Cập nhật thông tin địa điểm'
                                  : 'Nhập thông tin địa điểm',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Tên địa điểm *',
                      hintText: 'VD: Trụ sở chính, Chi nhánh HCM...',
                      prefixIcon: const Icon(Icons.business),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên địa điểm';
                      }
                      if (value.trim().length > 100) {
                        return 'Tên không được quá 100 ký tự';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),

                  const SizedBox(height: 16),

                  // Latitude field
                  TextFormField(
                    controller: _latitudeController,
                    decoration: InputDecoration(
                      labelText: 'Vĩ độ (Latitude) *',
                      hintText: 'VD: 10.762622',
                      prefixIcon: const Icon(Icons.map),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^-?\d*\.?\d*'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập vĩ độ';
                      }
                      final lat = double.tryParse(value.trim());
                      if (lat == null) {
                        return 'Vĩ độ không hợp lệ';
                      }
                      if (lat < -90 || lat > 90) {
                        return 'Vĩ độ phải trong khoảng -90 đến 90';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),

                  const SizedBox(height: 16),

                  // Longitude field
                  TextFormField(
                    controller: _longitudeController,
                    decoration: InputDecoration(
                      labelText: 'Kinh độ (Longitude) *',
                      hintText: 'VD: 106.660172',
                      prefixIcon: const Icon(Icons.place),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^-?\d*\.?\d*'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập kinh độ';
                      }
                      final lng = double.tryParse(value.trim());
                      if (lng == null) {
                        return 'Kinh độ không hợp lệ';
                      }
                      if (lng < -180 || lng > 180) {
                        return 'Kinh độ phải trong khoảng -180 đến 180';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),

                  const SizedBox(height: 16),

                  // Radius field
                  TextFormField(
                    controller: _radiusController,
                    decoration: InputDecoration(
                      labelText: 'Bán kính cho phép (mét) *',
                      hintText: 'VD: 100, 500, 1000...',
                      prefixIcon: const Icon(Icons.radar),
                      suffix: const Text('m'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      helperText:
                          'Khoảng cách tối đa để có thể check-in tại địa điểm này',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập bán kính';
                      }
                      final radius = int.tryParse(value.trim());
                      if (radius == null || radius <= 0) {
                        return 'Bán kính phải là số dương';
                      }
                      if (radius > 10000) {
                        return 'Bán kính không được quá 10km';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),

                  const SizedBox(height: 16),

                  // Is Default switch
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Địa điểm mặc định',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'Sử dụng làm địa điểm check-in mặc định',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isDefault,
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() => _isDefault = value);
                                },
                          activeColor: Colors.amber,
                        ),
                      ],
                    ),
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Hủy'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _save,
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(isEdit ? 'Cập nhật' : 'Thêm'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
