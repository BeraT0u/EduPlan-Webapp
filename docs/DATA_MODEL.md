# Data Model & Security Matrix (Cloud Firestore)

## 1. Danh sách Collections

### 1. `users/{uid}`
- `uid` (string, required): UID từ Firebase Auth.
- `email` (string, required): Email tài khoản.
- `displayName` (string): Họ tên hiển thị.
- `photoUrl` (string): URL ảnh đại diện.
- `role` (string): `'user'` | `'staff'` | `'admin'`.
- `status` (string): `'active'`.
- `updatedAt` (timestamp): Thời gian cập nhật.

### 2. `courses/{courseId}`
- `id` (string): ID môn học.
- `code` (string <= 12): Mã môn (VD: `PRM393`, `PRO192`).
- `name` (string <= 120): Tên môn học.
- `credits` (int 1..10): Số tín chỉ (thường là 3).
- `difficulty` (double 1..5): Đánh giá độ khó môn học.
- `defaultSelfStudyHours` (double): Giờ tự học gợi ý mỗi tuần.
- `prerequisiteCode` (string, nullable): Mã môn tiên quyết.
- `category` (string): Phân loại (`Chuyên ngành SE`, `Cơ sở ngành`, ...).
- `assessmentBreakdown` (map): Tỷ lệ % Assignment, Lab, PE, FE.
- `studyTips` (list<string>): Mẹo học tập.
- `status` (string): `'draft'` | `'published'` | `'archived'`.
- `updatedAt` (timestamp): Thời gian cập nhật.

### 3. `study_plans/{planId}`
- `id` (string): ID bản kế hoạch (VD: `{uid}_Học_kỳ_3`).
- `userId` (string): UID của sinh viên.
- `studentName` (string): Tên sinh viên.
- `studentCode` (string): MSSV.
- `semesterName` (string): Tên học kỳ.
- `courses` (list<map>): Danh sách các môn đã chọn kèm chi tiết tín chỉ, giờ học.
- `totalCredits` (int): Tổng tín chỉ đăng ký.
- `totalSelfStudyHours` (double): Tổng giờ tự học/tuần.
- `maxSafeThresholdHours` (double): Ngưỡng cảnh báo (mặc định 25h).
- `tuitionFee` (int): Học phí tạm tính.
- `status` (string): `'draft'` | `'pending'` | `'approved'` | `'rejected'` | `'completed'`.
- `reviewReason` (string, nullable): Nhận xét của Cố vấn khi duyệt hoặc từ chối (>= 3 ký tự).
- `reviewedBy` (string, nullable): Email/UID người duyệt.
- `reviewedAt` (timestamp, nullable): Thời gian duyệt.
- `updatedAt` (timestamp): Thời gian cập nhật.

### 4. `announcements/{id}`
- `id` (string): ID thông báo.
- `title` (string <= 120): Tiêu đề thông báo.
- `body` (string <= 1000): Nội dung thông báo.
- `category` (string): `'Học vụ'` | `'Lịch thi'` | `'Cảnh báo tải'` | `'Hệ thống'`.
- `targetSemester` (string): Học kỳ áp dụng.
- `authorUid` (string): UID người đăng.
- `authorName` (string): Tên người đăng.
- `status` (string): `'published'` | `'archived'`.
- `createdAt` (timestamp): Thời gian đăng.
