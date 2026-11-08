# EduPlan Web Admin Portal — Standalone Development Workspace

Thư mục này được đóng gói độc lập để lập trình viên hoặc thành viên nhóm có thể mở ra và lập trình ứng dụng **Web Admin** mà không sợ bị xung đột với mã nguồn của ứng dụng Mobile.

---

## 1. Cấu hình Firebase & Tài khoản Test

### Thông tin Firebase Project
- **Project ID**: `prm393-eduplan`
- **Hosting URL**: `https://prm393-eduplan.web.app`
- **Web App ID**: `1:420624932039:web:d6e86b9e79327f5b5132e2`
- **Web API Key**: `AIzaSyBNDRg8O_RS-a4Mq_WfkK3R_yrO3q21ScU`

### Tài khoản Test đã được cấp quyền trên Firestore (`users/{uid}`)
1. **Admin 1**: `hughnguyen1201@gmail.com` (UID: `eFrk6K0tbQVUkDOwG2kW899c3dF2`, `role: "admin"`)
2. **Admin 2 / Staff**: `dangnhathuy2001@gmail.com` (UID: `BDu5Ih3qFXZWtehulyJKXbuBeDj1`, `role: "admin"`)
3. **Sinh viên (Test từ chối quyền / Gate)**: Bất kỳ email Google nào khác (hoặc tài khoản test sinh viên có `role: "user"`).

---

## 2. Hướng dẫn Chạy Thử nghiệm (Quickstart)

```bash
# 1. Di chuyển vào thư mục web_admin_portal
cd web_admin_portal

# 2. Cài đặt các gói phụ thuộc
flutter pub get

# 3. Chạy trên trình duyệt Chrome (Web)
flutter run -d chrome
```

---

## 3. Cấu trúc Thư mục

```text
web_admin_portal/
├── README.md                      # Hướng dẫn khởi chạy & bối cảnh
├── pubspec.yaml                   # Danh sách package cho Flutter Web
├── docs/
│   ├── WEB_SPECIFICATION.md       # Đặc tả chi tiết 4 màn hình + 1 form
│   └── DATA_MODEL.md              # Bảng dữ liệu Firestore & Security Rules
├── web/
│   ├── index.html                 # Cấu hình Web + Google Client ID
│   └── manifest.json              # Web Manifest
└── lib/
    ├── main.dart                  # Khởi chạy MaterialApp & Khung điều hướng
    ├── firebase_options.dart      # Cấu hình Firebase Web chính thức
    ├── theme/                     # Hệ màu & Typography Warm Paper Academic
    ├── models/                    # Các data models dùng chung
    ├── services/                  # Các service gọi Firebase Auth & Firestore
    ├── widgets/                   # Các widget dùng chung (Sidebar, Card, Alert Banner)
    └── screens/                   # 5 màn hình Web Admin theo đặc tả
```

---

## 4. Danh sách 5 Màn hình cần Lập trình (Theo Mục 7 của Đề bài)

1. **`lib/screens/login_screen.dart` (`/login`)**:
   - Nút đăng nhập Google với popup.
   - Kiểm tra `role` trong Firestore `users/{uid}`. Nếu là `user` -> Sign out ngay và hiển thị thông báo lỗi quyền.
2. **`lib/screens/dashboard_screen.dart` (`/dashboard`)**:
   - 4 Thẻ KPI: Tổng sinh viên, Kế hoạch chờ duyệt, Kế hoạch đã duyệt, Môn đang mở (sử dụng Firestore `count().get()`).
   - 1 Biểu đồ trực quan (Biểu đồ cột/thanh phân bố tải học tập).
   - Danh sách 5 kế hoạch mới nhất.
3. **`lib/screens/courses_screen.dart` (`/courses`)**:
   - Bảng danh mục môn học với tìm kiếm và lọc trạng thái.
   - Nút `+ Thêm môn học mới` (Modal form tạo môn).
   - Nút `Sửa` (✏️) để cập nhật thông tin môn.
   - Nút `Lưu trữ` (Archive) cho Cố vấn/Admin và nút `Xóa vĩnh viễn` (🗑️) dành riêng cho Admin.
4. **`lib/screens/reviews_screen.dart` (`/reviews`)**:
   - Danh sách các kế hoạch sinh viên gửi duyệt (Real-time Stream `study_plans`).
   - Ô nhập nhận xét `reviewReason` (bắt buộc >= 3 ký tự).
   - Nút **Phê duyệt (`Approve`)** và **Từ chối (`Reject`)**.
5. **`lib/screens/announcements_screen.dart` (`/announcements`)**:
   - Form soạn và phát hành thông báo học vụ (`announcements`).
   - Bảng Quản trị phân quyền tài khoản (chỉ Admin mới thấy) để đổi quyền người dùng khác.
