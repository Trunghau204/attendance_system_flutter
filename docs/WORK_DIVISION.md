# PHÂN CÔNG CÔNG VIỆC - HỆ THỐNG CHẤM CÔNG

**Dự án:** Attendance System Flutter  
**Thời gian hoàn thành:** Tháng 1/2026  
**Số thành viên:** 4 người

---

## 📋 DANH SÁCH THÀNH VIÊN

1. **Trần Trung Hậu** - Leader/Main Developer (40% công việc)
2. **Trương Phước Hưng** - Developer (20% công việc)
3. **Nguyễn Trần Đăng Khoa** - Developer (20% công việc)
4. **Nguyễn Tuấn Vũ** - Developer (20% công việc)

---

## 👨‍💻 1. TRẦN TRUNG HẬU (Leader - 40%)

### 🎯 Trách nhiệm chính:

- **Thiết kế kiến trúc tổng thể**
- **Tích hợp Backend API**
- **Code review và hỗ trợ team**

### 📱 Chức năng đã làm:

#### A. Authentication & Core Services (30%)

**Files liên quan:**

- `lib/services/api_service.dart` - Core API service
- `lib/screens/auth/login_screen.dart` - Màn hình đăng nhập
- `lib/screens/auth/register_screen.dart` - Màn hình đăng ký
- `lib/utils/auth_storage.dart` - Quản lý token

**Giải thích chi tiết:**

```dart
// lib/services/api_service.dart
class ApiService {
  // Singleton pattern để đảm bảo chỉ có 1 instance
  static final ApiService _instance = ApiService._internal();

  // Method login
  Future<Map<String, dynamic>> login(String email, String password) async {
    // 1. Gửi POST request đến /api/Auth/Login
    // 2. Nhận response với token và user info
    // 3. Lưu token vào SharedPreferences
    // 4. Return user data
  }
}
```

**Câu hỏi thầy có thể hỏi:**

- Q: "Luồng đăng nhập chạy như thế nào?"
- A:
  1. User nhập email/password ở LoginScreen
  2. Gọi ApiService.login()
  3. API trả về token + user info
  4. Lưu token vào AuthStorage (SharedPreferences)
  5. Điều hướng đến AdminHomeScreen hoặc UserHomeScreen dựa vào role
- Q: "Token được lưu ở đâu?"
- A: Lưu trong SharedPreferences thông qua AuthStorage, key là 'auth_token'

---

#### B. GPS Check-in System (40%)

**Files liên quan:**

- `lib/widgets/user/attendance_bottom_sheet.dart` - UI check-in
- `lib/services/api_service.dart` (method checkInGPS)

**Giải thích chi tiết:**

```dart
// lib/widgets/user/attendance_bottom_sheet.dart
Future<void> _performCheckIn() async {
  // 1. Lấy vị trí hiện tại (GPS)
  Position position = await Geolocator.getCurrentPosition();

  // 2. Kiểm tra có trong bán kính location không
  double distance = Geolocator.distanceBetween(
    position.latitude, position.longitude,
    locationLat, locationLng
  );

  if (distance > location.radius) {
    // Ngoài phạm vi → Báo lỗi
    return;
  }

  // 3. Gọi API check-in
  await apiService.checkInGPS(
    workScheduleId: schedule.id,
    latitude: position.latitude,
    longitude: position.longitude,
  );

  // 4. Cập nhật UI
}
```

**Câu hỏi thầy có thể hỏi:**

- Q: "GPS check-in hoạt động như thế nào?"
- A:

  1. User nhấn nút Check-in/Check-out
  2. App xin quyền GPS (Geolocator)
  3. Lấy tọa độ hiện tại
  4. Tính khoảng cách đến Location (Geolocator.distanceBetween)
  5. Nếu trong bán kính → Gọi API /api/Attendance/CheckInGPS
  6. Backend lưu attendance với GPS coordinates
  7. Hiển thị thông báo thành công

- Q: "Làm sao kiểm tra user có trong vùng không?"
- A: Dùng Geolocator.distanceBetween() tính khoảng cách giữa vị trí hiện tại và Location.coordinates, so sánh với Location.radius

---

#### C. Statistics & Working Hours (30%)

**Files liên quan:**

- `lib/widgets/user/statistics_card.dart` - Hiển thị thống kê
- `lib/models/common/user_statistics.dart` - Model dữ liệu
- Backend: `StatisticService.cs` (tính giờ làm, phạt)

**Giải thích chi tiết:**

```dart
// lib/widgets/user/statistics_card.dart
String _formatHours(double hours) {
  // Chuyển giờ thập phân sang định dạng dễ đọc
  final totalMinutes = (hours * 60).round();
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;

  // Ví dụ:
  // 0.133 giờ (8 phút) → "8 phút"
  // 1.4 giờ → "1h 24m"
  // 12.5 giờ → "12h 30m"
}
```

**Backend logic (quan trọng để giải thích):**

```csharp
// StatisticService.cs - CalculateWorkingHoursWithPenaltyDetail
private (double workedHours, double penaltyHours) Calculate(...) {
  // 1. Tính giờ thực tế = Check-out - Check-in
  var actualWorkHours = (actualEnd - actualStart).TotalHours;

  // 2. Kiểm tra về sớm
  if (actualEnd < shiftEnd) {
    var earlyMinutes = (shiftEnd - actualEnd).TotalMinutes;

    // 3. Nếu về sớm > 30 phút → Phạt
    if (earlyMinutes > 30) {
      // Phạt 25% giờ ca lý tưởng
      penaltyHours = idealShiftHours * 0.25;
      workedHours = actualWorkHours - penaltyHours;
    }
  }

  return (workedHours, penaltyHours);
}
```

**Câu hỏi thầy có thể hỏi:**

- Q: "Giờ làm được tính như thế nào?"
- A:

  1. Flutter gọi API /api/Statistic
  2. Backend tính:
     - Giờ thực tế = Check-out - Check-in
     - Nếu về sớm > 30 phút: Phạt 25% giờ ca lý tưởng
     - Giờ được tính = Giờ thực tế - Giờ phạt (không âm)
  3. Trả về UserStatistics
  4. Flutter hiển thị qua StatisticsCard với \_formatHours()

- Q: "Tại sao làm 8 phút nhưng hiện 0 phút?"
- A: Vì về sớm 74 phút (> 30 phút) nên bị phạt 20 phút, 8 - 20 = -12 → 0 phút

---

### 📊 Tổng kết code của Trần Trung Hậu:

- **40+ files Flutter** đã code/review
- **3 backend services** đã điều chỉnh logic
- **100+ debug prints** đã dọn dẹp
- **15+ bugs** đã fix

---

## 👨‍💻 2. TRƯƠNG PHƯỚC HƯNG (20%)

### 📱 Chức năng đã làm:

#### A. Admin - User Management (60%)

**Files liên quan:**

- `lib/screens/admin/user_management/user_management_screen.dart`
- `lib/screens/admin/user_management/user_form_dialog.dart`
- `lib/models/admin/user_management.dart`

**Giải thích chi tiết:**

```dart
// lib/screens/admin/user_management/user_management_screen.dart
class UserManagementScreen extends StatefulWidget {
  // Screen quản lý user: CRUD operations

  // Các chức năng chính:
  // 1. Hiển thị danh sách user (ListView)
  // 2. Tìm kiếm user (TextField + filter)
  // 3. Thêm user mới (showDialog → UserFormDialog)
  // 4. Sửa thông tin user
  // 5. Xóa user (với confirmation)
  // 6. Reset password
  // 7. Khóa/Mở khóa tài khoản
}

// Luồng thêm user:
void _showAddUserDialog() async {
  final result = await showDialog(
    context: context,
    builder: (context) => UserFormDialog(),
  );

  if (result == true) {
    _loadUsers(); // Reload danh sách
  }
}
```

**Câu hỏi thầy có thể hỏi:**

- Q: "Làm sao thêm user mới?"
- A:

  1. Admin nhấn FAB (+)
  2. Hiện UserFormDialog với form input
  3. Nhập thông tin (email, fullName, role, phone)
  4. Validation: Email format, phone 10 số
  5. Gọi ApiService.createUser()
  6. POST đến /api/User
  7. Backend tạo user với password mặc định
  8. Reload danh sách user

- Q: "Tìm kiếm user hoạt động thế nào?"
- A: TextField onChange → Filter list theo fullName hoặc email (contains, case-insensitive)

---

#### B. Admin - Approval Management (40%)

**Files liên quan:**

- `lib/screens/admin/approval/admin_approval_screen.dart`
- `lib/screens/admin/approval/leave_request_detail_dialog.dart`
- `lib/screens/admin/approval/overtime_request_detail_dialog.dart`

**Giải thích chi tiết:**

```dart
// lib/screens/admin/approval/admin_approval_screen.dart
class AdminApprovalScreen extends StatefulWidget {
  // 2 tabs: Nghỉ phép | Tăng ca

  // Luồng duyệt đơn nghỉ phép:
  Future<void> _approveLeaveRequest(int id) async {
    // 1. Hiện confirmation dialog
    // 2. Nhập response note (optional)
    // 3. Gọi API PUT /api/LeaveRequest/{id}/approve
    // 4. Backend:
    //    - Update status = "Approved"
    //    - Trừ LeaveBalance của user
    //    - Lưu approvedBy, approvedAt
    // 5. Reload list
  }
}
```

**Câu hỏi thầy có thể hỏi:**

- Q: "Admin duyệt đơn nghỉ phép như thế nào?"
- A:

  1. Admin vào tab "Nghỉ phép"
  2. Nhấn vào 1 đơn → Hiện LeaveRequestDetailDialog
  3. Xem thông tin: User, ngày nghỉ, lý do, số ngày
  4. Nhấn "Duyệt" → Hiện confirmation
  5. Gọi API approveLeaveRequest(id, responseNote)
  6. Backend update status, trừ phép
  7. Đơn chuyển sang "Đã duyệt"

- Q: "Tại sao ngày hiện sai (08/01 - 08/01)?"
- A: Ban đầu model đọc sai field (startDate/endDate thay vì fromDate/toDate), đã fix bằng cách thêm fallback trong fromJson()

---

### 📊 Tổng kết code của Trương Phước Hưng:

- **6 files Flutter** chính
- **2 models** (UserManagement, LeaveRequestManagement)
- **CRUD operations** cho User
- **Approval workflow** cho Leave/Overtime

---

## 👨‍💻 3. NGUYỄN TRẦN ĐĂNG KHOA (20%)

### 📱 Chức năng đã làm:

#### A. Admin - Shift Management (50%)

**Files liên quan:**

- `lib/screens/admin/shift_management/shift_management_screen.dart`
- `lib/screens/admin/shift_management/shift_form_dialog.dart`
- `lib/models/admin/shift.dart`

**Giải thích chi tiết:**

```dart
// lib/screens/admin/shift_management/shift_form_dialog.dart
class ShiftFormDialog extends StatefulWidget {
  // Form tạo/sửa ca làm việc

  // Các field:
  // - Tên ca (TextField)
  // - Giờ bắt đầu (TimePicker)
  // - Giờ kết thúc (TimePicker)
  // - Địa điểm (DropdownButtonFormField<Location>)
  // - Màu sắc (ColorPicker - optional)

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }
}
```

**Fix quan trọng - Location Dropdown Overlay:**

```dart
// Fix UI issue: Dropdown bị overlay text "POWERED BY STRAPI"
Container(
  decoration: BoxDecoration(
    color: Colors.white, // ← Thêm background trắng
    borderRadius: BorderRadius.circular(12),
  ),
  child: DropdownButtonFormField<int>(
    isExpanded: true,
    menuMaxHeight: 200, // ← Giới hạn chiều cao
    decoration: InputDecoration(
      filled: true,
      fillColor: Colors.white, // ← Đảm bảo không trong suốt
    ),
  ),
)
```

**Câu hỏi thầy có thể hỏi:**

- Q: "Làm sao tạo ca làm việc?"
- A:

  1. Admin vào "Quản lý ca"
  2. Nhấn FAB (+) → ShiftFormDialog
  3. Nhập tên ca, chọn giờ bắt đầu/kết thúc (TimePicker)
  4. Chọn Location từ dropdown (đã load từ API)
  5. Validation: EndTime > StartTime
  6. Gọi ApiService.createShift()
  7. POST đến /api/Shift
  8. Backend lưu shift với LocationId
  9. Reload danh sách

- Q: "Tại sao dropdown địa điểm bị lỗi UI?"
- A: Ban đầu dropdown trong suốt nên text phía sau hiện lên. Fix bằng cách wrap trong Container với background trắng, thêm fillColor

---

#### B. Admin - Schedule Management (50%)

**Files liên quan:**

- `lib/screens/admin/schedule_management/admin_schedule_screen.dart`
- `lib/screens/admin/schedule_management/schedule_form_dialog.dart`
- `lib/models/admin/work_schedule.dart`

**Giải thích chi tiết:**

```dart
// lib/screens/admin/schedule_management/admin_schedule_screen.dart
class AdminScheduleScreen extends StatefulWidget {
  // Phân công ca làm cho user

  // Các chức năng:
  // 1. Hiển thị lịch làm theo user
  // 2. Chọn user (Dropdown)
  // 3. Chọn tuần/tháng (DatePicker)
  // 4. Tạo lịch làm mới
  // 5. Sửa lịch
  // 6. Xóa lịch

  Future<void> _createSchedule() async {
    // 1. Chọn user
    // 2. Chọn shift
    // 3. Chọn ngày làm việc
    // 4. Gọi API POST /api/WorkSchedule
    // 5. Backend:
    //    - Kiểm tra trùng lịch
    //    - Tạo WorkSchedule (UserId, ShiftId, WorkDate)
  }
}
```

**Câu hỏi thầy có thể hỏi:**

- Q: "Phân công ca làm hoạt động thế nào?"
- A:

  1. Admin vào "Quản lý lịch làm"
  2. Chọn user từ dropdown
  3. Nhấn "Thêm lịch" → ScheduleFormDialog
  4. Chọn shift, chọn ngày
  5. Validation: Không trùng lịch
  6. Gọi ApiService.createWorkSchedule()
  7. Backend tạo WorkSchedule
  8. User sẽ thấy ca này khi check-in

- Q: "WorkSchedule và Shift khác nhau thế nào?"
- A:
  - Shift: Template ca làm (8h-20h, Ca sáng)
  - WorkSchedule: Lịch cụ thể (User X làm Shift Y vào ngày Z)

---

### 📊 Tổng kết code của Nguyễn Trần Đăng Khoa:

- **6 files Flutter** chính
- **3 models** (Shift, WorkSchedule, Location)
- **Time picker integration**
- **Dropdown UI fixes**

---

## 👨‍💻 4. NGUYỄN TUẤN VŨ (20%)

### 📱 Chức năng đã làm:

#### A. User - QR Check-in System (40%)

**Files liên quan:**

- `lib/screens/user/qr_scanner_screen.dart`
- `lib/services/api_service.dart` (method checkInQR)

**Giải thích chi tiết:**

```dart
// lib/screens/user/qr_scanner_screen.dart
class QRScannerScreen extends StatefulWidget {
  // Màn hình quét QR để check-in

  // Sử dụng: mobile_scanner package

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;

      if (code != null) {
        // 1. Parse QR code → workScheduleId
        // 2. Gọi API check-in
        _performCheckIn(code);
        break;
      }
    }
  }

  Future<void> _performCheckIn(String qrCode) async {
    try {
      await _apiService.checkInQR(
        workScheduleId: int.parse(qrCode),
      );

      // Hiển thị thông báo thành công
    } catch (e) {
      // Hiển thị lỗi
    }
  }
}
```

**Câu hỏi thầy có thể hỏi:**

- Q: "QR check-in hoạt động như thế nào?"
- A:

  1. User vào tab QR Scanner
  2. Mở camera (mobile_scanner)
  3. Quét QR code chứa workScheduleId
  4. Parse QR code → Lấy workScheduleId
  5. Gọi API /api/Attendance/CheckInQR
  6. Backend:
     - Kiểm tra WorkSchedule tồn tại
     - Tạo Attendance
     - Lưu CheckIn time
  7. Hiển thị thông báo thành công

- Q: "QR code chứa gì?"
- A: Chứa workScheduleId (số nguyên) để xác định ca làm việc

---

#### B. User - Leave & Overtime Requests (35%)

**Files liên quan:**

- `lib/screens/user/leave_request_screen.dart`
- `lib/screens/user/overtime_request_screen.dart`
- `lib/models/common/leave_request.dart`
- `lib/models/common/overtime_request.dart`

**Giải thích chi tiết:**

```dart
// lib/screens/user/leave_request_screen.dart
class LeaveRequestScreen extends StatefulWidget {
  // Màn hình tạo đơn xin nghỉ phép

  Future<void> _submitLeaveRequest() async {
    // Validation
    if (_fromDate.isAfter(_toDate)) {
      // Lỗi: Ngày bắt đầu > Ngày kết thúc
      return;
    }

    // Tính số ngày nghỉ
    final days = _toDate.difference(_fromDate).inDays + 1;

    // Gọi API
    await _apiService.createLeaveRequest(
      fromDate: _fromDate,
      toDate: _toDate,
      reason: _reasonController.text,
      leaveType: _selectedLeaveType,
    );

    // Backend:
    // 1. Tạo LeaveRequest với status = "Pending"
    // 2. Chưa trừ LeaveBalance (chờ approve)
    // 3. Notify admin
  }
}
```

**Câu hỏi thầy có thể hỏi:**

- Q: "User tạo đơn nghỉ phép như thế nào?"
- A:

  1. User vào "Nghỉ phép"
  2. Nhấn FAB (+)
  3. Chọn ngày bắt đầu/kết thúc (DateRangePicker)
  4. Chọn loại nghỉ (Annual/Sick/Unpaid/Emergency)
  5. Nhập lý do
  6. Nhấn "Gửi đơn"
  7. Validation: fromDate <= toDate
  8. Gọi API POST /api/LeaveRequest
  9. Backend tạo đơn với status="Pending"
  10. Đơn chờ admin duyệt

- Q: "Khi nào trừ phép?"
- A: Chỉ trừ khi admin approve, không trừ khi pending hay rejected

---

#### C. User - Attendance History (25%)

**Files liên quan:**

- `lib/screens/user/tabs/attendance_tab.dart`
- `lib/models/user/attendance_history.dart`

**Giải thích chi tiết:**

```dart
// lib/screens/user/tabs/attendance_tab.dart
class AttendanceTab extends StatefulWidget {
  // Tab hiển thị lịch sử chấm công

  Future<void> _loadAttendances() async {
    // Gọi API GET /api/Attendance?userId={id}
    final data = await _apiService.getAttendanceHistory(
      userId: currentUser.id,
      fromDate: _selectedMonth,
    );

    // Parse sang AttendanceHistory
    setState(() {
      _attendances = data.map((json) =>
        AttendanceHistory.fromJson(json)
      ).toList();
    });
  }

  // Hiển thị:
  // - Ngày, ca làm
  // - Check-in, Check-out time
  // - Số giờ làm (tính client-side)
  // - Status (Present, Late, LeaveEarly)
  // - Địa điểm check-in
}
```

**Tính giờ làm client-side:**

```dart
String _calculateWorkingHours(DateTime checkIn, DateTime? checkOut) {
  if (checkOut == null) return '--';

  final duration = checkOut.difference(checkIn);
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;

  return '${hours}h ${minutes}m';
}
```

**Câu hỏi thầy có thể hỏi:**

- Q: "Lịch sử chấm công hiển thị gì?"
- A: Hiển thị list AttendanceHistory với:

  - Ngày, tên ca, địa điểm
  - Check-in time, check-out time
  - Số giờ làm (tính từ check-in/check-out)
  - Status (Present, Late, LeaveEarly)
  - Có thể lọc theo tháng

- Q: "Số giờ làm ở đây khác thống kê?"
- A:
  - Lịch sử: Tính đơn giản check-out - check-in
  - Thống kê: Tính từ backend với logic phạt

---

### 📊 Tổng kết code của Nguyễn Tuấn Vũ:

- **5 files Flutter** chính
- **QR Scanner integration**
- **Date picker & Time picker**
- **Leave/Overtime workflow**

---

## 🎯 TỔNG KẾT PHÂN CÔNG

### Tỷ lệ công việc:

- **Trần Trung Hậu:** 40% (Authentication, GPS Check-in, Statistics, API Integration, Code Review)
- **Trương Phước Hưng:** 20% (User Management, Approval Management)
- **Nguyễn Trần Đăng Khoa:** 20% (Shift Management, Schedule Management)
- **Nguyễn Tuấn Vũ:** 20% (QR Check-in, Leave/Overtime Requests, Attendance History)

### Số lượng files/thành viên:

- **Trần Trung Hậu:** ~40 files
- **Trương Phước Hưng:** ~8 files
- **Nguyễn Trần Đăng Khoa:** ~8 files
- **Nguyễn Tuấn Vũ:** ~7 files

---

## 📝 LƯU Ý KHI BẢO VỆ

### Câu hỏi chung thầy có thể hỏi:

**1. "Flutter khác gì với React Native?"**

- Flutter: Dùng Dart, render native UI qua Skia
- React Native: Dùng JavaScript, dùng native components

**2. "State management trong Flutter là gì?"**

- Dự án dùng StatefulWidget với setState()
- Có thể dùng Provider, Bloc, Riverpod cho app lớn

**3. "API integration hoạt động thế nào?"**

- Dùng http package
- ApiService class (singleton)
- Lưu token trong SharedPreferences
- Mỗi request kèm token trong header

**4. "Async/Await trong Flutter?"**

- Future<T>: Đại diện cho giá trị async
- async: Đánh dấu function bất đồng bộ
- await: Chờ Future hoàn thành

**5. "Widget tree là gì?"**

- Cây các Widget lồng nhau
- Flutter rebuild widget khi setState()
- Stateful vs Stateless widget

---

## ✅ CHECKLIST TRƯỚC KHI BẢO VỆ

### Mỗi thành viên cần:

- [ ] Đọc kỹ phần mình làm
- [ ] Chạy thử app, test chức năng
- [ ] Hiểu luồng code từ UI → API → Backend
- [ ] Biết file nào liên quan đến chức năng
- [ ] Chuẩn bị demo (nếu cần)
- [ ] Đọc phần "Câu hỏi thầy có thể hỏi"

---

**Ngày tạo:** 11/01/2026  
**Người tạo:** Trần Trung Hậu  
**Version:** 1.0
