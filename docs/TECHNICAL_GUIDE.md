# HỆ THỐNG CHẤM CÔNG - HƯỚNG DẪN KỸ THUẬT CHI TIẾT

## 📚 MỤC LỤC

1. [Kiến trúc tổng thể](#1-kiến-trúc-tổng-thể)
2. [Luồng hoạt động chính](#2-luồng-hoạt-động-chính)
3. [Chi tiết từng module](#3-chi-tiết-từng-module)
4. [Models & Data Flow](#4-models--data-flow)
5. [API Integration](#5-api-integration)
6. [Common Issues & Solutions](#6-common-issues--solutions)

---

## 1. KIẾN TRÚC TỔNG THỂ

### 📂 Cấu trúc thư mục

```
lib/
├── main.dart                    # Entry point
├── models/                      # Data models
│   ├── admin/                  # Admin models
│   │   ├── user_management.dart
│   │   ├── shift.dart
│   │   ├── work_schedule.dart
│   │   ├── attendance_adjustment.dart
│   │   └── leave_request_management.dart
│   ├── common/                 # Shared models
│   │   ├── user.dart
│   │   ├── user_statistics.dart
│   │   ├── leave_request.dart
│   │   └── overtime_request.dart
│   └── user/                   # User models
│       └── attendance_history.dart
├── screens/                    # UI Screens
│   ├── auth/                   # Authentication
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── admin/                  # Admin screens
│   │   ├── admin_home_screen.dart
│   │   ├── user_management/
│   │   ├── shift_management/
│   │   ├── schedule_management/
│   │   ├── adjustment/
│   │   └── approval/
│   └── user/                   # User screens
│       ├── user_home_screen.dart
│       ├── tabs/
│       ├── qr_scanner_screen.dart
│       ├── leave_request_screen.dart
│       └── overtime_request_screen.dart
├── services/                   # Business logic
│   └── api_service.dart       # API calls
├── utils/                      # Utilities
│   ├── auth_storage.dart      # Token management
│   └── constants.dart         # Constants
└── widgets/                    # Reusable widgets
    ├── admin/
    └── user/
        ├── attendance_bottom_sheet.dart
        └── statistics_card.dart
```

### 🏗️ Design Patterns

**1. Singleton Pattern (ApiService)**

```dart
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Đảm bảo chỉ có 1 instance trong app
}
```

**2. MVC Pattern**

- **Model:** `lib/models/` - Data structures
- **View:** `lib/screens/` - UI
- **Controller:** `lib/services/` - Business logic

**3. Repository Pattern**

- ApiService acts as repository
- Abstracts data source (API) from UI

---

## 2. LUỒNG HOẠT ĐỘNG CHÍNH

### 🔐 A. AUTHENTICATION FLOW

```
┌─────────────┐
│ main.dart   │
│ checkAuth() │
└──────┬──────┘
       │
       ├─ Token exists? ─No─→ LoginScreen
       │                         │
       │                         ├─ User login
       │                         │    ├─ Validate input
       │                         │    ├─ Call ApiService.login()
       │                         │    │    └─ POST /api/Auth/Login
       │                         │    ├─ Receive token + user info
       │                         │    ├─ Save token (AuthStorage)
       │                         │    └─ Navigate based on role
       │                         │
       │                         └─ Register → RegisterScreen
       │                                └─ POST /api/Auth/Register
       │
       └─ Yes ─→ Check role
                  ├─ Admin → AdminHomeScreen
                  └─ User  → UserHomeScreen
```

**Code chi tiết:**

```dart
// main.dart
Future<void> checkAuth() async {
  final token = await AuthStorage.getToken();

  if (token == null) {
    // Chưa đăng nhập → LoginScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
    return;
  }

  // Có token → Lấy user info
  final user = await ApiService().getCurrentUser();

  if (user.role == 'Admin') {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => AdminHomeScreen()),
    );
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => UserHomeScreen()),
    );
  }
}

// lib/services/api_service.dart
Future<Map<String, dynamic>> login(String email, String password) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/Auth/Login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    // Lưu token
    await AuthStorage.saveToken(data['token']);

    // Lưu user info
    await AuthStorage.saveUser(data['user']);

    return data;
  } else {
    throw Exception('Đăng nhập thất bại');
  }
}

// lib/utils/auth_storage.dart
class AuthStorage {
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }
}
```

---

### 📍 B. GPS CHECK-IN FLOW

```
User nhấn "Check-in"
    │
    ├─ Kiểm tra quyền GPS
    │    ├─ Chưa có quyền → Xin quyền (Geolocator)
    │    └─ Có quyền → Tiếp tục
    │
    ├─ Lấy vị trí hiện tại
    │    └─ Geolocator.getCurrentPosition()
    │         ├─ latitude: 10.123
    │         └─ longitude: 106.456
    │
    ├─ Tính khoảng cách đến Location
    │    └─ Geolocator.distanceBetween(
    │          userLat, userLng,
    │          locationLat, locationLng
    │        )
    │         └─ distance: 45 meters
    │
    ├─ Kiểm tra trong bán kính?
    │    ├─ distance > radius (50m) → Báo lỗi "Ngoài vùng"
    │    └─ distance <= radius → Tiếp tục
    │
    ├─ Gọi API Check-in
    │    └─ POST /api/Attendance/CheckInGPS
    │         Body: {
    │           workScheduleId: 123,
    │           latitude: 10.123,
    │           longitude: 106.456
    │         }
    │
    ├─ Backend xử lý
    │    ├─ Tìm WorkSchedule
    │    ├─ Kiểm tra đã check-in chưa
    │    ├─ Tính status (OnTime, Late)
    │    ├─ Tạo Attendance record
    │    │    └─ {
    │    │         UserId: 1,
    │    │         WorkScheduleId: 123,
    │    │         CheckIn: 2026-01-11 08:05:00,
    │    │         Status: "Late",
    │    │         CheckInLatitude: 10.123,
    │    │         CheckInLongitude: 106.456
    │    │       }
    │    └─ Return success
    │
    └─ Flutter nhận response
         ├─ Hiển thị thông báo "Check-in thành công"
         ├─ Cập nhật UI (disable button)
         └─ Reload attendance history
```

**Code chi tiết:**

```dart
// lib/widgets/user/attendance_bottom_sheet.dart
Future<void> _performCheckIn() async {
  setState(() => _isLoading = true);

  try {
    // 1. Kiểm tra quyền GPS
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Cần cấp quyền vị trí';
      }
    }

    // 2. Lấy vị trí hiện tại
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // 3. Tính khoảng cách
    final location = widget.schedule.shift.location;
    double distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      location.latitude,
      location.longitude,
    );

    // 4. Kiểm tra bán kính
    if (distance > location.radius) {
      throw 'Bạn đang ở ngoài phạm vi ${location.radius}m. Khoảng cách: ${distance.toInt()}m';
    }

    // 5. Gọi API
    final result = await _apiService.checkInGPS(
      workScheduleId: widget.schedule.id,
      latitude: position.latitude,
      longitude: position.longitude,
    );

    if (result['success']) {
      // 6. Thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Check-in thành công'),
          backgroundColor: Colors.green,
        ),
      );

      // 7. Reload data
      widget.onCheckInSuccess?.call();
      Navigator.pop(context);
    }

  } catch (e) {
    // Hiển thị lỗi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

// lib/services/api_service.dart
Future<Map<String, dynamic>> checkInGPS({
  required int workScheduleId,
  required double latitude,
  required double longitude,
}) async {
  final token = await AuthStorage.getToken();

  final response = await http.post(
    Uri.parse('$baseUrl/api/Attendance/CheckInGPS'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // ← Quan trọng!
    },
    body: jsonEncode({
      'workScheduleId': workScheduleId,
      'latitude': latitude,
      'longitude': longitude,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    final error = jsonDecode(response.body);
    throw error['message'] ?? 'Check-in thất bại';
  }
}
```

**Kiến thức cần biết:**

- **Geolocator package:** Lấy GPS coordinates
- **LocationPermission:** Xin quyền truy cập vị trí
- **Geolocator.distanceBetween():** Tính khoảng cách giữa 2 điểm GPS (mét)
- **Bearer Token:** Authorization header để xác thực API

---

### 📊 C. STATISTICS FLOW

```
User vào "Thống kê"
    │
    ├─ StatisticsCard widget build()
    │    └─ Nhận UserStatistics từ parent
    │
    ├─ Parent đã load data như thế nào?
    │    └─ ProfileTab.initState()
    │         └─ _loadStatistics()
    │              │
    │              ├─ Gọi ApiService.getUserStatistics()
    │              │    └─ GET /api/Statistic?userId=1&month=1&year=2026
    │              │
    │              ├─ Backend: StatisticService.GetStatisticsAsync()
    │              │    │
    │              │    ├─ Lấy tất cả Attendance trong tháng
    │              │    │    └─ SELECT * FROM Attendances
    │              │    │         WHERE UserId = 1
    │              │    │         AND MONTH(CheckIn) = 1
    │              │    │         AND YEAR(CheckIn) = 2026
    │              │    │
    │              │    ├─ Tính từng attendance
    │              │    │    └─ CalculateWorkingHoursWithPenaltyDetail()
    │              │    │         │
    │              │    │         ├─ actualWorkHours = CheckOut - CheckIn
    │              │    │         │    Ví dụ: 22:41 - 22:33 = 8 phút = 0.133 giờ
    │              │    │         │
    │              │    │         ├─ Kiểm tra về sớm?
    │              │    │         │    if (CheckOut < ShiftEnd) {
    │              │    │         │      earlyMinutes = ShiftEnd - CheckOut
    │              │    │         │      // 23:55 - 22:41 = 74 phút
    │              │    │         │    }
    │              │    │         │
    │              │    │         ├─ Tính phạt (nếu về sớm > 30 phút)
    │              │    │         │    idealHours = ShiftEnd - CheckIn
    │              │    │         │    // 23:55 - 22:33 = 1.367 giờ
    │              │    │         │
    │              │    │         │    penaltyHours = idealHours * 0.25
    │              │    │         │    // 1.367 * 0.25 = 0.342 giờ (20 phút)
    │              │    │         │
    │              │    │         └─ Tính giờ được tính
    │              │    │              workedHours = actualWorkHours - penaltyHours
    │              │    │              // 0.133 - 0.342 = -0.209 → 0 (không âm)
    │              │    │
    │              │    ├─ Tổng hợp tất cả attendance
    │              │    │    totalWorkingHours = sum(workedHours)
    │              │    │    totalPenaltyHours = sum(penaltyHours)
    │              │    │
    │              │    └─ Return UserStatistics
    │              │         {
    │              │           totalWorkDays: 1,
    │              │           totalWorkingHours: 0.0,
    │              │           totalPenaltyHours: 0.342,
    │              │           totalLateDays: 0,
    │              │           ...
    │              │         }
    │              │
    │              └─ Flutter parse JSON → UserStatistics object
    │
    └─ StatisticsCard hiển thị
         └─ _formatHours(statistics.totalWorkingHours)
              │
              ├─ totalMinutes = (0.0 * 60).round() = 0
              ├─ h = 0 ~/ 60 = 0
              ├─ m = 0 % 60 = 0
              └─ return "0 phút"
```

**Code chi tiết:**

```dart
// lib/widgets/user/statistics_card.dart
class StatisticsCard extends StatelessWidget {
  final UserStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _buildStatRow(
            'Tổng giờ làm',
            _formatHours(statistics.totalWorkingHours),
            Icons.access_time,
            AppConstants.infoColor,
          ),
          _buildStatRow(
            'Giờ phạt',
            _formatHours(statistics.totalPenaltyHours),
            Icons.warning,
            AppConstants.errorColor,
          ),
          // ... các stat khác
        ],
      ),
    );
  }

  String _formatHours(double hours) {
    // Chuyển đổi giờ thập phân → "Xh Ym"
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60; // Division operator: chia lấy nguyên
    final m = totalMinutes % 60;  // Modulo: chia lấy dư

    if (h == 0 && m == 0) return '0 phút';
    else if (h == 0) return '$m phút';
    else if (m == 0) return '$h giờ';
    else return '${h}h ${m}m';
  }
}

// lib/models/common/user_statistics.dart
class UserStatistics {
  final int totalWorkDays;
  final double totalWorkingHours;
  final double totalPenaltyHours;
  final int totalLateDays;
  // ... các field khác

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      totalWorkDays: json['totalWorkDays'] ?? 0,
      totalWorkingHours: (json['totalWorkingHours'] as num?)?.toDouble() ?? 0.0,
      totalPenaltyHours: (json['totalPenaltyHours'] as num?)?.toDouble() ?? 0.0,
      totalLateDays: json['totalLateDays'] ?? 0,
      // ...
    );
  }
}
```

**Backend C# (StatisticService.cs):**

```csharp
private (double workedHours, double penaltyHours) CalculateWorkingHoursWithPenaltyDetail(Attendance a)
{
    var shift = a.WorkSchedule.Shift;
    var actualStart = a.CheckIn.TimeOfDay;
    var actualEnd = a.CheckOut.Value.TimeOfDay;

    // Giờ làm thực tế
    var actualWorkHours = (actualEnd - actualStart).TotalHours;

    // Xử lý qua đêm
    if (actualEnd < actualStart) {
        actualWorkHours = 24 - actualStart.TotalHours + actualEnd.TotalHours;
    }

    double workedHours = actualWorkHours;
    double penaltyHours = 0;

    // Xử lý về sớm
    if (actualEnd < shift.EndTime) {
        var earlyMinutes = (shift.EndTime - actualEnd).TotalMinutes;

        if (earlyMinutes > 30) { // Ngưỡng phạt
            var idealShiftHours = (shift.EndTime - actualStart).TotalHours;

            if (shift.EndTime < actualStart) {
                idealShiftHours = 24 - actualStart.TotalHours + shift.EndTime.TotalHours;
            }

            // Phạt 25%
            penaltyHours = idealShiftHours * 0.25;
            workedHours = actualWorkHours - penaltyHours;

            if (workedHours < 0) workedHours = 0;
        }
    }

    return (workedHours, penaltyHours);
}
```

**Kiến thức cần biết:**

- **Operators:** `~/` (chia lấy nguyên), `%` (chia lấy dư)
- **Type casting:** `as num?`, `?.toDouble()`
- **Null safety:** `??` (null-coalescing operator)
- **TimeSpan.TotalHours** (C#): Chuyển TimeSpan sang giờ thập phân

---

### 📱 D. ADMIN CRUD FLOW (Ví dụ: User Management)

```
Admin vào "Quản lý nhân viên"
    │
    ├─ UserManagementScreen.initState()
    │    └─ _loadUsers()
    │         └─ GET /api/User
    │              └─ Backend return List<User>
    │
    ├─ Hiển thị ListView
    │    └─ UserCard widgets
    │
    ├─ Admin nhấn FAB (+) "Thêm user"
    │    │
    │    └─ showDialog(UserFormDialog)
    │         │
    │         ├─ Form với các field:
    │         │    - Email (TextFormField + validator)
    │         │    - Full Name
    │         │    - Phone (10 số)
    │         │    - Role (Dropdown: Admin/User)
    │         │
    │         ├─ Admin nhập thông tin
    │         │
    │         ├─ Nhấn "Lưu"
    │         │    │
    │         │    ├─ Validation
    │         │    │    - Email regex: ^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$
    │         │    │    - Phone regex: ^[0-9]{10}$
    │         │    │
    │         │    └─ OK → Gọi API
    │         │         └─ POST /api/User
    │         │              Body: {
    │         │                email: "user@gmail.com",
    │         │                fullName: "Nguyen Van A",
    │         │                phone: "0901234567",
    │         │                role: "User"
    │         │              }
    │         │
    │         ├─ Backend xử lý
    │         │    ├─ Kiểm tra email trùng
    │         │    ├─ Hash password mặc định
    │         │    ├─ Tạo User record
    │         │    └─ Return user ID
    │         │
    │         └─ Flutter nhận response
    │              ├─ Hiển thị "Tạo thành công"
    │              ├─ Navigator.pop(context, true)
    │              └─ Parent reload list
    │
    └─ _loadUsers() được gọi lại
         └─ Danh sách cập nhật với user mới
```

**Code chi tiết:**

```dart
// lib/screens/admin/user_management/user_management_screen.dart
class UserManagementScreen extends StatefulWidget {
  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final ApiService _apiService = ApiService();
  List<UserManagement> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final result = await _apiService.getUsers();

      setState(() {
        _users = result['data']
            .map((json) => UserManagement.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _showAddUserDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => UserFormDialog(),
    );

    if (result == true) {
      _loadUsers(); // Reload
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quản lý nhân viên')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return UserCard(
                  user: user,
                  onEdit: () => _showEditUserDialog(user),
                  onDelete: () => _deleteUser(user.id),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}

// lib/screens/admin/user_management/user_form_dialog.dart
class UserFormDialog extends StatefulWidget {
  final UserManagement? user; // Null = Create, not null = Edit

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRole = 'User';

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      // Edit mode: Fill form
      _emailController.text = widget.user!.email;
      _nameController.text = widget.user!.fullName;
      _phoneController.text = widget.user!.phoneNumber ?? '';
      _selectedRole = widget.user!.role;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (widget.user == null) {
        // Create
        await ApiService().createUser(
          email: _emailController.text,
          fullName: _nameController.text,
          phone: _phoneController.text,
          role: _selectedRole,
        );
      } else {
        // Update
        await ApiService().updateUser(
          id: widget.user!.id,
          email: _emailController.text,
          fullName: _nameController.text,
          phone: _phoneController.text,
          role: _selectedRole,
        );
      }

      Navigator.pop(context, true); // Return true = success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập email';
                }
                // Email regex
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value)) {
                  return 'Email không hợp lệ';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Họ tên'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập họ tên';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Số điện thoại'),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final phoneRegex = RegExp(r'^[0-9]{10}$');
                  if (!phoneRegex.hasMatch(value)) {
                    return 'SĐT phải có 10 số';
                  }
                }
                return null;
              },
            ),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              items: ['Admin', 'User'].map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedRole = value!);
              },
              decoration: InputDecoration(labelText: 'Vai trò'),
            ),
            ElevatedButton(
              onPressed: _submit,
              child: Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Kiến thức cần biết:**

- **Form validation:** GlobalKey<FormState>, validator
- **Regex:** Email, Phone validation
- **Dialog return value:** Navigator.pop(context, value)
- **CRUD operations:** Create (POST), Read (GET), Update (PUT), Delete (DELETE)

---

## 3. CHI TIẾT TỪNG MODULE

### 📦 A. Packages Sử Dụng

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter

  # HTTP requests
  http: ^1.1.0

  # Local storage
  shared_preferences: ^2.2.2

  # GPS
  geolocator: ^10.1.0

  # QR Scanner
  mobile_scanner: ^3.5.5

  # Date formatting
  intl: ^0.18.1

  # Loading indicator
  flutter_easyloading: ^3.0.5
```

### 🎨 B. UI Components

**1. Custom Widgets**

```dart
// lib/widgets/user/attendance_bottom_sheet.dart
// Bottom sheet để check-in/check-out
// - Hiển thị thông tin ca
// - GPS location check
// - Call API

// lib/widgets/user/statistics_card.dart
// Card hiển thị thống kê
// - Format hours (giờ + phút)
// - Color coding (green, orange, red)
// - Icons cho mỗi metric

// lib/widgets/admin/user_card.dart
// Card hiển thị user trong list
// - Avatar với initial
// - User info
// - Action buttons (edit, delete, lock)
```

**2. Theme & Styling**

```dart
// lib/utils/constants.dart
class AppConstants {
  // Colors
  static const Color primaryColor = Color(0xFF6C5CE7);
  static const Color successColor = Color(0xFF00B894);
  static const Color warningColor = Color(0xFFFDCB6E);
  static const Color errorColor = Color(0xFFD63031);
  static const Color infoColor = Color(0xFF74B9FF);

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subHeadingStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
}
```

---

## 4. MODELS & DATA FLOW

### 📊 A. Data Models

**User Model:**

```dart
// lib/models/common/user.dart
class User {
  final int id;
  final String email;
  final String fullName;
  final String role; // "Admin" hoặc "User"
  final String? phoneNumber;
  final int leaveBalance;
  final bool isActive;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phoneNumber,
    required this.leaveBalance,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'],
      role: json['role'],
      phoneNumber: json['phoneNumber'],
      leaveBalance: json['leaveBalance'] ?? 12,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role,
      'phoneNumber': phoneNumber,
      'leaveBalance': leaveBalance,
      'isActive': isActive,
    };
  }
}
```

**Attendance Model:**

```dart
// lib/models/user/attendance_history.dart
class AttendanceHistory {
  final int id;
  final DateTime checkIn;
  final DateTime? checkOut;
  final String status; // "Present", "Late", "LeaveEarly"
  final String shiftName;
  final String locationName;
  final double? checkInLatitude;
  final double? checkInLongitude;

  // Computed property
  String get workingHours {
    if (checkOut == null) return '--';
    final duration = checkOut!.difference(checkIn);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}
```

### 🔄 B. Data Flow Diagram

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│              │  HTTP   │              │  SQL    │              │
│   Flutter    ├────────►│  API Server  ├────────►│   Database   │
│              │  JSON   │   (C#)       │         │  (SQL Server)│
│              │◄────────┤              │◄────────┤              │
└──────────────┘         └──────────────┘         └──────────────┘
      │                         │                         │
      │ 1. Call API            │ 2. Process             │
      │    + Token             │    + Validate          │
      │                         │    + Query DB          │
      │                         │                         │
      │ 4. Update UI           │ 3. Return JSON         │
      │    + Parse JSON        │    + HTTP 200/400      │
      │    + setState()        │                         │
      └─────────────────────────┴─────────────────────────┘
```

---

## 5. API INTEGRATION

### 🌐 A. API Endpoints

```dart
// lib/services/api_service.dart
class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000'; // Android Emulator
  // static const String baseUrl = 'http://localhost:5000'; // iOS Simulator
  // static const String baseUrl = 'http://192.168.1.100:5000'; // Real Device

  // ==================== AUTHENTICATION ====================

  /// POST /api/Auth/Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Body: { email, password }
    // Response: { token, user: {...} }
  }

  /// POST /api/Auth/Register
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    // Body: { email, password, fullName, role: "User" }
    // Response: { success, message, user: {...} }
  }

  /// GET /api/Auth/Me
  Future<User> getCurrentUser() async {
    // Headers: Authorization: Bearer {token}
    // Response: { id, email, fullName, role, ... }
  }

  // ==================== ATTENDANCE ====================

  /// POST /api/Attendance/CheckInGPS
  Future<Map<String, dynamic>> checkInGPS({
    required int workScheduleId,
    required double latitude,
    required double longitude,
  }) async {
    // Body: { workScheduleId, latitude, longitude }
    // Response: { success, message, attendance: {...} }
  }

  /// POST /api/Attendance/CheckOutGPS
  Future<Map<String, dynamic>> checkOutGPS({
    required int attendanceId,
    required double latitude,
    required double longitude,
  }) async {
    // Body: { attendanceId, latitude, longitude }
    // Response: { success, message }
  }

  /// POST /api/Attendance/CheckInQR
  Future<Map<String, dynamic>> checkInQR({
    required int workScheduleId,
  }) async {
    // Body: { workScheduleId }
    // Response: { success, message, attendance: {...} }
  }

  /// GET /api/Attendance?userId={id}&fromDate={date}&toDate={date}
  Future<List<Map<String, dynamic>>> getAttendanceHistory({
    int? userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    // Response: [{ id, checkIn, checkOut, status, ... }, ...]
  }

  // ==================== STATISTICS ====================

  /// GET /api/Statistic?userId={id}&month={m}&year={y}
  Future<UserStatistics> getUserStatistics({
    required int userId,
    required int month,
    required int year,
  }) async {
    // Response: {
    //   totalWorkDays, totalWorkingHours, totalPenaltyHours,
    //   totalLateDays, totalLeaveEarlyDays, totalAbsentDays,
    //   totalLeaveDays, totalOvertimeHours, currentLeaveBalance
    // }
  }

  // ==================== LEAVE/OVERTIME ====================

  /// POST /api/LeaveRequest
  Future<Map<String, dynamic>> createLeaveRequest({
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
    required String leaveType, // "Annual", "Sick", "Unpaid"
  }) async {
    // Body: { fromDate, toDate, reason, leaveType }
    // Response: { success, message, leaveRequest: {...} }
  }

  /// GET /api/LeaveRequest?userId={id}&status={status}
  Future<Map<String, dynamic>> getLeaveRequests({
    int? userId,
    String? status, // "Pending", "Approved", "Rejected"
  }) async {
    // Response: { success, data: [...] }
  }

  /// PUT /api/LeaveRequest/{id}/approve
  Future<Map<String, dynamic>> approveLeaveRequest(
    int id,
    String? responseNote,
  ) async {
    // Body: { responseNote }
    // Response: { success, message }
  }

  /// PUT /api/LeaveRequest/{id}/reject
  Future<Map<String, dynamic>> rejectLeaveRequest(
    int id,
    String rejectReason,
  ) async {
    // Body: { rejectReason }
    // Response: { success, message }
  }

  // ==================== ADMIN - USER ====================

  /// GET /api/User
  Future<Map<String, dynamic>> getUsers() async {
    // Response: { success, data: [...] }
  }

  /// POST /api/User
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String fullName,
    required String role,
    String? phone,
  }) async {
    // Body: { email, fullName, role, phoneNumber }
    // Response: { success, message, user: {...} }
  }

  /// PUT /api/User/{id}
  Future<Map<String, dynamic>> updateUser({
    required int id,
    required String email,
    required String fullName,
    required String role,
    String? phone,
  }) async {
    // Body: { email, fullName, role, phoneNumber }
    // Response: { success, message }
  }

  /// DELETE /api/User/{id}
  Future<Map<String, dynamic>> deleteUser(int id) async {
    // Response: { success, message }
  }

  // ==================== ADMIN - SHIFT ====================

  /// GET /api/Shift
  Future<List<Map<String, dynamic>>> getShifts() async {
    // Response: [{ id, name, startTime, endTime, locationId, ... }, ...]
  }

  /// POST /api/Shift
  Future<Map<String, dynamic>> createShift({
    required String name,
    required String startTime, // "08:00:00"
    required String endTime,   // "20:00:00"
    required int locationId,
  }) async {
    // Body: { name, startTime, endTime, locationId }
    // Response: { success, message, shift: {...} }
  }

  // ==================== ADMIN - SCHEDULE ====================

  /// GET /api/WorkSchedule?userId={id}&fromDate={date}
  Future<List<Map<String, dynamic>>> getWorkSchedules({
    int? userId,
    DateTime? fromDate,
  }) async {
    // Response: [{ id, userId, shiftId, workDate, ... }, ...]
  }

  /// POST /api/WorkSchedule
  Future<Map<String, dynamic>> createWorkSchedule({
    required int userId,
    required int shiftId,
    required DateTime workDate,
  }) async {
    // Body: { userId, shiftId, workDate }
    // Response: { success, message, workSchedule: {...} }
  }

  // ... và nhiều endpoints khác
}
```

### 🔐 B. Authentication Flow

```dart
// Mọi API request (trừ login/register) cần token

Future<Map<String, dynamic>> _makeAuthenticatedRequest(
  String method, // GET, POST, PUT, DELETE
  String endpoint,
  {Map<String, dynamic>? body}
) async {
  // 1. Lấy token từ storage
  final token = await AuthStorage.getToken();

  if (token == null) {
    throw Exception('Chưa đăng nhập');
  }

  // 2. Tạo headers với token
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token', // ← Quan trọng!
  };

  // 3. Gọi API
  http.Response response;

  if (method == 'GET') {
    response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
  } else if (method == 'POST') {
    response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
  }
  // ... tương tự cho PUT, DELETE

  // 4. Handle response
  if (response.statusCode == 200 || response.statusCode == 201) {
    return jsonDecode(response.body);
  } else if (response.statusCode == 401) {
    // Token expired hoặc invalid
    await AuthStorage.clearAuth();
    throw Exception('Phiên đăng nhập hết hạn');
  } else {
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Có lỗi xảy ra');
  }
}
```

---

## 6. COMMON ISSUES & SOLUTIONS

### ❌ A. Location Dropdown Overlay

**Vấn đề:**

- Dropdown địa điểm bị overlay text "POWERED BY STRAPI"
- Text phía sau hiện xuyên qua dropdown

**Nguyên nhân:**

- Container dropdown trong suốt
- Z-index không đúng

**Giải pháp:**

```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white, // ← Background không trong suốt
    borderRadius: BorderRadius.circular(12),
  ),
  child: DropdownButtonFormField<int>(
    isExpanded: true,
    menuMaxHeight: 200, // ← Giới hạn chiều cao
    decoration: InputDecoration(
      filled: true,
      fillColor: Colors.white, // ← Fill color
    ),
    // ...
  ),
)
```

---

### ❌ B. Statistics Showing 0 Despite Working

**Vấn đề:**

- User chấm công 8 phút
- Lịch sử hiển thị "8 phút"
- Thống kê hiển thị "0 phút"

**Nguyên nhân:**

- Backend tính giờ thực tế (8 phút)
- Về sớm 74 phút → Phạt 20 phút
- 8 - 20 = -12 → 0 (không âm)

**Giải pháp:**

- Không phải bug, là logic đúng!
- Giải thích: Về sớm quá nhiều → Bị phạt nhiều hơn giờ làm

---

### ❌ C. Dropdown Error: "items.isEmpty || value == null"

**Vấn đề:**

- Mở dialog lần 2 bị crash
- Error: "There should be exactly one item with value"

**Nguyên nhân:**

- Value của dropdown không nằm trong items list
- Backend trả về status khác với options

**Giải pháp:**

```dart
@override
void initState() {
  super.initState();
  // Đảm bảo value luôn nằm trong items
  _newStatus = _statusOptions.contains(widget.attendance.status)
      ? widget.attendance.status
      : _statusOptions.first;
}
```

---

### ❌ D. fromDate/toDate vs startDate/endDate

**Vấn đề:**

- Leave request hiển thị sai ngày (08/01 - 08/01)
- User tạo 08/01 - 09/01

**Nguyên nhân:**

- Backend trả về `fromDate` và `toDate`
- Model đọc `startDate` và `endDate`

**Giải pháp:**

```dart
factory LeaveRequestManagement.fromJson(Map<String, dynamic> json) {
  return LeaveRequestManagement(
    startDate: json['startDate'] != null
        ? DateTime.parse(json['startDate'])
        : (json['fromDate'] != null  // ← Fallback
            ? DateTime.parse(json['fromDate'])
            : DateTime.now()),
    endDate: json['endDate'] != null
        ? DateTime.parse(json['endDate'])
        : (json['toDate'] != null    // ← Fallback
            ? DateTime.parse(json['toDate'])
            : DateTime.now()),
  );
}
```

---

### ❌ E. Can't Delete User (Foreign Key Constraint)

**Vấn đề:**

- Xóa user báo lỗi "FK_SystemNotifications_Users_UserId"
- User có dữ liệu liên quan

**Giải pháp:**

```sql
-- Xóa tất cả dữ liệu liên quan trước
DELETE FROM Attendances WHERE UserId IN (SELECT Id FROM Users WHERE Email = 'user@example.com');
DELETE FROM WorkSchedules WHERE UserId IN (SELECT Id FROM Users WHERE Email = 'user@example.com');
DELETE FROM LeaveRequests WHERE UserId IN (SELECT Id FROM Users WHERE Email = 'user@example.com');
DELETE FROM OvertimeRequests WHERE UserId IN (SELECT Id FROM Users WHERE Email = 'user@example.com');
DELETE FROM SystemNotifications WHERE UserId IN (SELECT Id FROM Users WHERE Email = 'user@example.com');
DELETE FROM Users WHERE Email = 'user@example.com';
```

---

## 📖 TÀI LIỆU THAM KHẢO

### Official Docs:

- Flutter: https://flutter.dev/docs
- Dart: https://dart.dev/guides
- Geolocator: https://pub.dev/packages/geolocator
- Mobile Scanner: https://pub.dev/packages/mobile_scanner

### Tutorials:

- Flutter State Management: https://flutter.dev/docs/development/data-and-backend/state-mgmt
- HTTP Requests: https://flutter.dev/docs/cookbook/networking/fetch-data
- Form Validation: https://flutter.dev/docs/cookbook/forms/validation

---

**Ngày tạo:** 11/01/2026  
**Người tạo:** Trần Trung Hậu  
**Version:** 1.0
