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

- ASP.NET Core 6.0
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

## 📚 TÀI LIỆU HƯỚNG DẪN

### Dành cho thành viên nhóm:

1. **[WORK_DIVISION.md](docs/WORK_DIVISION.md)**

   - Phân công công việc chi tiết
   - Code của từng thành viên
   - Câu hỏi thầy có thể hỏi
   - Checklist bảo vệ

2. **[TECHNICAL_GUIDE.md](docs/TECHNICAL_GUIDE.md)**
   - Kiến trúc hệ thống
   - Luồng hoạt động chi tiết
   - API endpoints
   - Common issues & solutions

### Tài liệu chung:

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Geolocator Package](https://pub.dev/packages/geolocator)
- [Mobile Scanner Package](https://pub.dev/packages/mobile_scanner)

---

## 🌳 HƯỚNG DẪN GIT

### A. Tạo Repository Local

```bash
# 1. Vào thư mục dự án
cd D:\WorkSpace\LT_Flutter\attendance_system_flutter

# 2. Khởi tạo Git
git init

# 3. Add tất cả files
git add .

# 4. Commit đầu tiên
git commit -m "Initial commit - Attendance System Flutter"
```

### B. Tạo Repository trên GitHub

1. Đăng nhập GitHub
2. Nhấn "New repository"
3. Tên repo: `attendance_system_flutter`
4. Description: "Flutter attendance system with GPS/QR check-in"
5. Chọn **Private** (nếu không muốn public)
6. **KHÔNG** tích "Initialize this repository with a README"
7. Create repository

### C. Push code lên GitHub

```bash
# 1. Add remote repository (thay YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/attendance_system_flutter.git

# 2. Đổi tên branch sang main
git branch -M main

# 3. Push lần đầu
git push -u origin main
```

### D. Clone về máy khác (cho thành viên khác)

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/attendance_system_flutter.git

# Vào thư mục
cd attendance_system_flutter

# Cài đặt dependencies
flutter pub get

# Chạy app
flutter run
```

### E. Các lệnh Git thường dùng

```bash
# Xem status
git status

# Add file mới/thay đổi
git add .

# Commit
git commit -m "Fix: Sửa lỗi GPS check-in"

# Push lên GitHub
git push

# Pull code mới nhất
git pull

# Xem lịch sử commit
git log --oneline
```

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

## 🎓 HƯỚNG DẪN CHO THÀNH VIÊN

### 1. Trần Trung Hậu (Leader)

**Files cần nắm:** api_service.dart, login_screen.dart, attendance_bottom_sheet.dart, statistics_card.dart  
**Xem chi tiết:** [WORK_DIVISION.md](docs/WORK_DIVISION.md#1-trần-trung-hậu-leader---40)

### 2. Trương Phước Hưng

**Files cần nắm:** user_management_screen.dart, user_form_dialog.dart, admin_approval_screen.dart  
**Xem chi tiết:** [WORK_DIVISION.md](docs/WORK_DIVISION.md#2-trương-phước-hưng-20)

### 3. Nguyễn Trần Đăng Khoa

**Files cần nắm:** shift_management_screen.dart, shift_form_dialog.dart, admin_schedule_screen.dart  
**Xem chi tiết:** [WORK_DIVISION.md](docs/WORK_DIVISION.md#3-nguyễn-trần-đăng-khoa-20)

### 4. Nguyễn Tuấn Vũ

**Files cần nắm:** qr_scanner_screen.dart, leave_request_screen.dart, attendance_tab.dart  
**Xem chi tiết:** [WORK_DIVISION.md](docs/WORK_DIVISION.md#4-nguyễn-tuấn-vũ-20)

---

## 🐛 COMMON ISSUES

### 1. "Location services are disabled"

Bật GPS trên device/emulator: Settings > Location > On

### 2. "Failed to load data from API"

Kiểm tra backend đang chạy và baseUrl trong api_service.dart

### 3. "Token expired"

Đăng xuất và đăng nhập lại (Token JWT hết hạn sau 24h)

### 4. "Camera permission denied"

Vào Settings > Apps > Permissions > Cho phép Camera

---

## 📞 LIÊN HỆ

**Leader:** Trần Trung Hậu - tranhau5065@gmail.com

---

## 📝 LICENSE

MIT License - Dự án học tập, không dùng cho mục đích thương mại.

---

**Cập nhật lần cuối:** 11/01/2026  
**Version:** 1.0  
**Status:** ✅ Hoàn thành
