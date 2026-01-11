# 📱 HỆ THỐNG CHẤM CÔNG - ATTENDANCE SYSTEM

> **Dự án:** Flutter Attendance System với GPS/QR Check-in  
> **Nhóm:** 4 thành viên  
> **Ngày hoàn thành:** Tháng 1/2026

---

## 🎯 TỔNG QUAN DỰ ÁN

### Mô tả

Hệ thống chấm công hiện đại cho doanh nghiệp, hỗ trợ:

- ✅ Chấm công GPS (kiểm tra vị trí)
- ✅ Chấm công QR Code
- ✅ Quản lý ca làm việc
- ✅ Thống kê giờ làm, phạt
- ✅ Quản lý nghỉ phép, tăng ca
- ✅ Admin dashboard

### Công nghệ sử dụng

**Frontend:**

- Flutter 3.x
- Dart 3.x
- Packages: geolocator, mobile_scanner, http, shared_preferences

**Backend:**

- ASP.NET Core 9.0
- Entity Framework Core
- SQL Server
- JWT Authentication

---

## 👥 THÀNH VIÊN NHÓM

| STT | Họ và tên                 | Vai trò         | Chức năng đảm nhận                                        |
| --- | ------------------------- | --------------- | --------------------------------------------------------- |
| 1   | **Trần Trung Hậu**        | Leader/Main Dev | Authentication, GPS Check-in, Statistics, API Integration |
| 2   | **Trương Phước Hưng**     | Developer       | User Management, Approval Management                      |
| 3   | **Nguyễn Trần Đăng Khoa** | Developer       | Shift Management, Schedule Management                     |
| 4   | **Nguyễn Tuấn Vũ**        | Developer       | QR Check-in, Leave/Overtime Requests                      |

📄 **Chi tiết phân công:** Xem [WORK_DIVISION.md](docs/WORK_DIVISION.md)

---

## 📂 CẤU TRÚC DỰ ÁN

```
attendance_system_flutter/
├── android/                # Android platform
├── ios/                    # iOS platform
├── lib/                    # Flutter source code
│   ├── main.dart          # Entry point
│   ├── models/            # Data models
│   ├── screens/           # UI screens
│   ├── services/          # Business logic (API)
│   ├── utils/             # Utilities
│   └── widgets/           # Reusable widgets
├── docs/                  # Documentation
│   ├── WORK_DIVISION.md   # Phân công công việc
│   ├── TECHNICAL_GUIDE.md # Hướng dẫn kỹ thuật
│   └── MEMBER_GUIDE.md    # Hướng dẫn cho từng thành viên
├── pubspec.yaml           # Dependencies
└── README.md              # This file
```

---

## 🚀 HƯỚNG DẪN CÀI ĐẶT

### 1. Yêu cầu hệ thống

- **Flutter SDK:** >= 3.0.0
- **Dart SDK:** >= 3.0.0
- **Android Studio / VS Code**
- **Git**

### 2. Clone dự án

```bash
# Clone repository về máy
git clone https://github.com/your-username/attendance_system_flutter.git

# Hoặc nếu đã tạo Git local
cd D:\WorkSpace\LT_Flutter\attendance_system_flutter
git init
git add .
git commit -m "Initial commit"
```

### 3. Cài đặt dependencies

```bash
# Vào thư mục dự án
cd attendance_system_flutter

# Cài đặt packages
flutter pub get
```

### 4. Cấu hình Backend API

Mở file `lib/services/api_service.dart` và sửa `baseUrl`:

```dart
// Android Emulator
static const String baseUrl = 'http://10.0.2.2:5000';

// iOS Simulator
static const String baseUrl = 'http://localhost:5000';

// Real Device (thay bằng IP máy chạy backend)
static const String baseUrl = 'http://192.168.1.100:5000';
```

### 5. Chạy ứng dụng

```bash
# Kiểm tra devices
flutter devices

# Chạy trên device/emulator
flutter run

# Hoặc chạy trên device cụ thể
flutter run -d <device_id>
```

---

## 🔐 TÀI KHOẢN TEST

### Admin

- **Email:** `admin@gmail.com`
- **Password:** `Admin@123`

### User

- **Email:** `user@gmail.com`
- **Password:** `User@123`

---

---

## 📱 CHỨC NĂNG CHÍNH

### User Features:

- 🔐 Đăng nhập / Đăng ký
- 📍 Check-in/Check-out bằng GPS
- 📷 Check-in/Check-out bằng QR Code
- 📊 Xem thống kê công việc
- 📅 Xem lịch sử chấm công
- 📝 Tạo đơn xin nghỉ phép
- ⏰ Tạo đơn xin tăng ca
- 👤 Quản lý profile

### Admin Features:

- 👥 Quản lý nhân viên (CRUD)
- 🕐 Quản lý ca làm việc
- 📆 Phân công lịch làm
- 📍 Quản lý địa điểm
- ✅ Duyệt đơn nghỉ phép/tăng ca
- 🔧 Điều chỉnh chấm công

---

## 📞 LIÊN HỆ

**Leader:** Trần Trung Hậu - tranhau5065@gmail.com

---

## 📝 LICENSE

MIT License - Dự án học tập, không dùng cho mục đích thương mại.

