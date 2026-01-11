import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../screens/user/qr_scanner/qr_scanner_screen.dart';

/// ========================================
/// ATTENDANCE BOTTOM SHEET
/// Bottom sheet để chọn loại chấm công
/// ========================================
class AttendanceBottomSheet extends StatefulWidget {
  final int userId;
  final int? workScheduleId;
  final VoidCallback onSuccess;

  const AttendanceBottomSheet({
    super.key,
    required this.userId,
    this.workScheduleId,
    required this.onSuccess,
  });

  @override
  State<AttendanceBottomSheet> createState() => _AttendanceBottomSheetState();
}

class _AttendanceBottomSheetState extends State<AttendanceBottomSheet> {
  final ApiService _apiService = ApiService();

  /// ==================== CHECK-IN BẰNG GPS ====================
  Future<void> _checkInWithGPS() async {
    Navigator.pop(context); // Đóng bottom sheet

    try {
      EasyLoading.show(status: 'Đang lấy vị trí...');

      // 1. Kiểm tra GPS service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await EasyLoading.dismiss();
        await EasyLoading.showError('Vui lòng bật GPS');
        return;
      }

      // 2. Kiểm tra quyền location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          await EasyLoading.dismiss();
          await EasyLoading.showError('Quyền truy cập GPS bị từ chối');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await EasyLoading.dismiss();
        await EasyLoading.showError(
          'Quyền GPS bị từ chối vĩnh viễn. Vui lòng bật trong Cài đặt',
        );
        return;
      }

      // 3. Lấy vị trí hiện tại với timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      EasyLoading.show(status: 'Đang chấm công...');

      // Gọi API check-in GPS
      // Backend không lưu Shift.LocationId, chỉ dùng Location có isDefault=true
      final result = await _apiService.checkInGPS(
        userId: widget.userId,
        workScheduleId: widget.workScheduleId,
        latitude: position.latitude,
        longitude: position.longitude,
        deviceInfo: 'Flutter App - GPS',
      );

      await EasyLoading.dismiss();

      if (result['success'] == true) {
        await EasyLoading.showSuccess('Check-in thành công!');
        widget.onSuccess();
      } else {
        await EasyLoading.showError(result['message'] ?? 'Không thể check-in');
      }
    } catch (e) {
      await EasyLoading.dismiss();

      String errorMessage = 'Lỗi: $e';
      if (e.toString().contains('Location services are disabled')) {
        errorMessage = 'Vui lòng bật GPS';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Không thể lấy vị trí GPS. Vui lòng thử lại';
      }

      await EasyLoading.showError(errorMessage);
    }
  }

  /// ==================== CHECK-IN BẰNG QR CODE ====================
  Future<void> _checkInWithQR() async {
    Navigator.pop(context); // Đóng bottom sheet

    try {
      // Mở màn hình quét QR
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QRScannerScreen()),
      );

      // QR Scanner tự xử lý check-in và callback
      widget.onSuccess();
    } catch (e) {
      await EasyLoading.showError('Lỗi: $e');
    }
  }

  /// ==================== CHECK-OUT ====================
  Future<void> _checkOut() async {
    Navigator.pop(context);

    if (widget.workScheduleId == null) {
      await EasyLoading.showError('Không tìm thấy ca làm việc!');
      return;
    }

    await EasyLoading.show(status: 'Đang check-out...');

    try {
      // Lấy vị trí
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition();
      } catch (e) {
        // Không có GPS cũng được
      }

      final result = await _apiService.checkOut(
        userId: widget.userId,
        workScheduleId: widget.workScheduleId!,
        latitude: position?.latitude,
        longitude: position?.longitude,
        deviceInfo: 'Flutter App',
      );

      await EasyLoading.dismiss();

      if (result['success']) {
        await EasyLoading.showSuccess(AppConstants.msgCheckOutSuccess);
        widget.onSuccess();
      } else {
        await EasyLoading.showError(result['message']);
      }
    } catch (e) {
      await EasyLoading.dismiss();
      await EasyLoading.showError('Lỗi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadiusLarge),
        ),
      ),
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Chọn phương thức chấm công',
            style: AppConstants.subHeadingStyle,
          ),
          const SizedBox(height: 24),

          // Options
          _buildOption(
            icon: Icons.gps_fixed,
            title: 'Chấm công bằng GPS',
            subtitle: 'Sử dụng vị trí của bạn',
            color: AppConstants.primaryColor,
            onTap: _checkInWithGPS,
          ),
          const SizedBox(height: 12),
          _buildOption(
            icon: Icons.qr_code_scanner,
            title: 'Quét mã QR',
            subtitle: 'Quét mã tại văn phòng',
            color: AppConstants.secondaryColor,
            onTap: _checkInWithQR,
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 12),
          _buildOption(
            icon: Icons.logout,
            title: 'Check-out',
            subtitle: 'Kết thúc ca làm việc',
            color: AppConstants.warningColor,
            onTap: _checkOut,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppConstants.bodyTextStyle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppConstants.captionStyle),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
