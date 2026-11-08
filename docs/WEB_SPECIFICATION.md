# Đặc tả Kỹ thuật Web Admin Portal (PRM393 Final Assignment)

## 1. Giới thiệu & Mục tiêu
- **Tên cổng**: EduPlan Web Admin Portal
- **Người dùng mục tiêu**: 
  - `staff` (Cố vấn Học tập): Quản lý môn học, duyệt kế hoạch học tập của sinh viên, đăng thông báo.
  - `admin` (Quản trị viên Đào tạo): Toàn quyền của `staff` + Xóa vĩnh viễn môn học tạo nhầm + Quản trị phân quyền tài khoản người dùng (`users/{uid}.role`).
- **Nền tảng**: Flutter Web (Responsive, tối ưu cho màn hình rộng Desktop / Tablet >= 600dp).
- **Hệ màu thiết kế**: Warm Paper Academic Design System
  - Background: `#FBF6EB` (Kem giấy ấm)
  - Card / Khung nội dung: `#FFFDF7` (Trắng ngà)
  - Border: `#EAE1D0` (Viền xám kem 1px solid)
  - Màu chủ đạo CTA: `#2563EB` (Xanh hoàng gia)
  - Danger: `#DC2626` / `#FEE2E2` (Từ chối, lỗi, cảnh báo)
  - Success: `#15803D` / `#DCFCE7` (Đã duyệt, công khai)
  - Warning: `#78350F` / `#FEF3C7` (Chờ duyệt, lưu ý)

---

## 2. Danh sách 4 Màn hình Chính + 1 Form Phát hành

### 2.1. Màn hình WEB-01: Sign-In & Role Gate Screen (`/login`)
- **Giao diện**: Card đăng nhập căn giữa màn hình trên nền `#FBF6EB`.
- **Cơ chế xác thực**:
  - Đăng nhập bằng Google qua `FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider())`.
  - Đọc trường `role` từ document `users/{user.uid}` trên Firestore.
  - **Kiểm tra phân quyền (Role Gate)**:
    - Nếu `role == 'staff'` hoặc `role == 'admin'` -> Cho phép đăng nhập, chuyển hướng sang `/dashboard`.
    - Nếu `role == 'user'` (sinh viên) -> Tự động gọi `signOut()` và hiển thị banner đỏ từ chối truy cập:
      *"Từ chối truy cập: Tài khoản [email] thuộc vai trò Sinh viên (user). Cổng Web Admin chỉ dành riêng cho Cố vấn học tập (staff) và Quản trị viên (admin)."*

### 2.2. Màn hình WEB-02: Academic Dashboard (`/dashboard`)
- **Khung giao diện**: `WebShellScaffold` gồm Sidebar (NavigationRail) bên trái rộng 250px + Nội dung chính bên phải.
- **Components bắt buộc**:
  - **4 Thẻ KPI thống kê tổng hợp từ Firestore Aggregation Queries (`.count()`)**:
    1. Tổng số sinh viên: `firestore.collection('students').count().get()`
    2. Kế hoạch chờ duyệt (`Pending`): `firestore.collection('study_plans').where('status', isEqualTo: 'pending').count().get()`
    3. Kế hoạch đã phê duyệt (`Approved`): `firestore.collection('study_plans').where('status', isEqualTo: 'approved').count().get()`
    4. Môn học đang mở (`Published`): `firestore.collection('courses').where('status', isEqualTo: 'published').count().get()`
  - **1 Biểu đồ trực quan (Visual Chart)**:
    - Thể hiện tỷ lệ trạng thái kế hoạch học tập (`Pending` vs `Approved` vs `Rejected`) và thống kê phân bổ tải học tập theo danh mục môn học (`Chuyên ngành SE` vs `Cơ sở ngành`).
  - **Bảng 5 kế hoạch mới nhất**: Hiển thị nhanh các sinh viên vừa gửi kế hoạch, có nút click chuyển thẳng sang màn hình duyệt `/reviews`.

### 2.3. Màn hình WEB-03: Course Catalog Management (`/courses`)
- **Toàn quyền CRUD thực thể `courses`**:
  - **Tìm kiếm & Lọc**: Ô tìm kiếm mã/tên môn + Bộ lọc trạng thái (`Tất cả`, `Published`, `Draft`, `Archived`).
  - **Bảng dữ liệu**: Mã môn (`code`), Tên môn (`name`), Tín chỉ (`credits`), Độ khó (`difficulty`), Giờ tự học/tuần (`defaultSelfStudyHours`), Môn tiên quyết (`prerequisiteCode`), Phân loại (`category`), Trạng thái (`status`).
  - **Thêm môn học mới (`+ Thêm môn học`)**: Dialog nhập mã môn (in hoa), tên môn (<= 120 ký tự), tín chỉ (1..10), giờ tự học, môn tiên quyết, danh mục, tỷ trọng điểm, mẹo học tập.
  - **Chỉnh sửa môn học (✏️)**: Cho phép sửa mọi trường thông tin môn học đã có.
  - **Lưu trữ / Ẩn môn (`Archive`)**: Cho cả `staff` và `admin`. Đổi `status: 'archived'` để ẩn khỏi Mobile app nhưng không làm mất điểm của khóa trước.
  - **Xóa vĩnh viễn môn học (🗑️)**: **Chỉ hiển thị cho `admin`**. Có hộp thoại xác nhận cảnh báo trước khi xóa cứng khỏi Firestore.

### 2.4. Màn hình WEB-04: Study Plan Review Queue (`/reviews`)
- **Hàng đợi xét duyệt kế hoạch học tập của sinh viên**:
  - **Tab phân loại**: `Chờ duyệt (Pending)` • `Đã duyệt (Approved)` • `Từ chối (Rejected)` • `Tất cả`.
  - **Chi tiết kế hoạch**: Tên sinh viên, MSSV, học kỳ, danh sách môn đã chọn, tổng số tín chỉ, tổng giờ tự học (tô đỏ cảnh báo nếu > 25h/tuần), học phí dự kiến.
  - **Hành động xét duyệt**:
    - Ô nhập `reviewReason` (Bắt buộc nhập nhận xét / lý do tối thiểu 3 ký tự).
    - Nút xanh **"Phê duyệt (Approve)"**: Cập nhật `status: 'approved'`, `reviewReason`, `reviewedBy`, `reviewedAt` lên Firestore -> Mobile App sinh viên chuyển sang badge xanh tức thì.
    - Nút đỏ **"Yêu cầu chỉnh sửa (Reject)"**: Cập nhật `status: 'rejected'`, `reviewReason` -> Mobile App sinh viên nhận lý do từ chối để sửa lại kế hoạch.

### 2.5. Màn hình WEB-05: Announcements & Role Management (`/announcements`)
- **Phát hành thông báo**:
  - Form tạo thông báo học vụ: Tiêu đề (`title` <= 120 ký tự), Phân loại (`Học vụ`, `Lịch thi`, `Cảnh báo tải`), Học kỳ áp dụng, Nội dung chi tiết (`body`).
  - Khi bấm phát hành, dữ liệu ghi vào `announcements` -> Mobile App nhận thông báo thời gian thực trên chuông thông báo.
- **Quản trị phân quyền (Chỉ hiển thị khi đăng nhập bằng `admin`)**:
  - Bảng danh sách tài khoản từ `users/{uid}`.
  - Cho phép Admin thay đổi `role` của người dùng khác giữa `'user'`, `'staff'`, `'admin'`.
  - Khóa dropdown của chính Admin đang đăng nhập (tuân thủ quy tắc *"không ai được tự đổi quyền của chính mình"*).
