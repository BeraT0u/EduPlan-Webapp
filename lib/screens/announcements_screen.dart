import 'package:flutter/material.dart';
import '../models/announcement_model.dart';
import '../models/user_model.dart';
import '../services/web_announcement_service.dart';
import '../theme/app_colors.dart';

class AnnouncementsScreen extends StatefulWidget {
  final UserModel currentUser;

  const AnnouncementsScreen({super.key, required this.currentUser});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final WebAnnouncementService _announcementService = WebAnnouncementService();

  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _category = 'Học vụ';
  String _targetSemester = 'Tất cả các kỳ';
  bool _isPublishing = false;

  Future<void> _handlePublish() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();

    if (title.isEmpty || body.isEmpty) return;

    setState(() => _isPublishing = true);
    try {
      final announcement = AnnouncementModel(
        id: '',
        title: title,
        body: body,
        category: _category,
        targetSemester: _targetSemester,
        authorName: widget.currentUser.displayName,
        status: 'published',
      );

      await _announcementService.publishAnnouncement(announcement);
      _titleCtrl.clear();
      _bodyCtrl.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã phát hành thông báo thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String selectedRole = 'staff';
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardSurface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.borderStructural),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlueSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_add_alt_1, color: AppColors.primaryBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Thêm Tài Khoản Bằng Email',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlueSurface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, size: 20, color: AppColors.primaryBlue),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Cấp trước quyền (pre-provision) cho Cố vấn hoặc Quản trị viên mới. '
                                  'Khi người dùng này đăng nhập bằng Google với email tương ứng, hệ thống sẽ tự động gán vai trò này.',
                                  style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.35),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Địa chỉ Email (*)',
                            hintText: 'vidu@fpt.edu.vn hoặc user@gmail.com',
                            prefixIcon: Icon(Icons.email_outlined, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập email';
                            }
                            final trimmed = value.trim();
                            if (!trimmed.contains('@') || !trimmed.contains('.')) {
                              return 'Email không hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Họ và tên (Tùy chọn)',
                            hintText: 'Nhập họ tên hiển thị (nếu có)',
                            prefixIcon: Icon(Icons.badge_outlined, size: 20),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Vai trò phân quyền (*)',
                            prefixIcon: Icon(Icons.admin_panel_settings_outlined, size: 20),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'staff',
                              child: Text('Cố vấn học tập (staff) - Duyệt kế hoạch & điểm'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Quản trị viên (admin) - Toàn quyền hệ thống'),
                            ),
                            DropdownMenuItem(
                              value: 'user',
                              child: Text('Sinh viên (user) - Chỉ sử dụng App mobile'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedRole = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSubmitting = true);
                          try {
                            final msg = await _announcementService.addOrUpdateUserByEmail(
                              email: emailCtrl.text,
                              role: selectedRole,
                              displayName: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(msg),
                                  backgroundColor: AppColors.successGreen,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi khi thêm tài khoản: $e'),
                                  backgroundColor: AppColors.errorRed,
                                ),
                              );
                            }
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check, size: 16),
                  label: Text(isSubmitting ? 'Đang lưu...' : 'Lưu & Phân Quyền'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteUser(UserModel user) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderStructural),
          ),
          title: const Text('Xác nhận xóa tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            'Bạn có chắc chắn muốn xóa tài khoản "${user.displayName}" (${user.email}) khỏi danh sách hệ thống?\n\n'
            'Người dùng này sẽ mất mọi quyền truy cập tương ứng.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await _announcementService.deleteUser(user.uid);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã xóa tài khoản ${user.email} thành công!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi khi xóa tài khoản: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xóa Tài Khoản'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Create Announcement Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderStructural),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Phát Hành Thông Báo Học Vụ Mới',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Thông báo này sẽ xuất hiện thời gian thực trên Hộp thư và chuông thông báo của ứng dụng Mobile Sinh viên.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _titleCtrl,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề thông báo (Tối đa 120 ký tự)',
                  hintText: 'Ví dụ: Hạn chót nộp kế hoạch học tập kỳ Fall 2026',
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Phân loại thông báo'),
                      items: const [
                        DropdownMenuItem(value: 'Học vụ', child: Text('Học vụ')),
                        DropdownMenuItem(value: 'Lịch thi', child: Text('Lịch thi')),
                        DropdownMenuItem(value: 'Cảnh báo tải', child: Text('Cảnh báo tải')),
                        DropdownMenuItem(value: 'Hệ thống', child: Text('Hệ thống')),
                      ],
                      onChanged: (val) => setState(() => _category = val ?? _category),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _targetSemester,
                      decoration: const InputDecoration(labelText: 'Học kỳ áp dụng'),
                      items: const [
                        DropdownMenuItem(value: 'Tất cả các kỳ', child: Text('Tất cả các kỳ')),
                        DropdownMenuItem(value: 'Học kỳ 1', child: Text('Học kỳ 1')),
                        DropdownMenuItem(value: 'Học kỳ 2', child: Text('Học kỳ 2')),
                        DropdownMenuItem(value: 'Học kỳ 3', child: Text('Học kỳ 3')),
                        DropdownMenuItem(value: 'Học kỳ 4', child: Text('Học kỳ 4')),
                      ],
                      onChanged: (val) => setState(() => _targetSemester = val ?? _targetSemester),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _bodyCtrl,
                maxLines: 4,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Nội dung chi tiết thông báo',
                  hintText: 'Nhập hướng dẫn cụ thể cho sinh viên...',
                ),
              ),
              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _isPublishing ? null : _handlePublish,
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Phát Hành Thông Báo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // 2. Published Announcements History
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderStructural),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lịch Sử Thông Báo Đã Phát Hành',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),

              StreamBuilder<List<AnnouncementModel>>(
                stream: _announcementService.streamAnnouncements(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Chưa có thông báo nào.'),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(color: AppColors.borderDivider),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item.category} • ${item.targetSemester} • Tác giả: ${item.authorName}\n${item.body}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.archive_outlined, size: 20),
                          tooltip: 'Lưu trữ thông báo',
                          onPressed: () => _announcementService.archiveAnnouncement(item.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),

        // 3. Role Management Section (ADMIN ONLY)
        if (widget.currentUser.isAdmin) ...[
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderStructural),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Quản Trị Phân Quyền Tài Khoản (Admin Role Manager)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Chỉ Admin mới có quyền cập nhật vai trò người dùng khác. Không ai được tự đổi quyền của chính mình.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _showAddUserDialog,
                          icon: const Icon(Icons.person_add_alt_1, size: 16),
                          label: const Text('Thêm Tài Khoản Bằng Email'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlueSurface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('ADMIN ACCESS', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                StreamBuilder<List<UserModel>>(
                  stream: _announcementService.streamUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final users = snapshot.data ?? [];
                    if (users.isEmpty) {
                      return const Text('Không có tài khoản người dùng.');
                    }

                    return Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2.5),
                        1: FlexColumnWidth(3.0),
                        2: FlexColumnWidth(1.8),
                        3: FlexColumnWidth(2.2),
                        4: FlexColumnWidth(0.8),
                      },
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderStructural))),
                          children: [
                            Padding(padding: EdgeInsets.all(10), child: Text('Họ tên', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(10), child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(10), child: Text('Vai trò hiện tại', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(10), child: Text('Thay đổi vai trò', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(10), child: Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                        ...users.map((u) {
                          final isSelf = u.uid == widget.currentUser.uid;
                          return TableRow(
                            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderDivider))),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(u.displayName, style: TextStyle(fontWeight: isSelf ? FontWeight.bold : FontWeight.normal)),
                              ),
                              Padding(padding: const EdgeInsets.all(10), child: Text(u.email)),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: u.isAdmin ? AppColors.primaryBlueSurface : (u.isStaff ? AppColors.warningSurface : AppColors.neutralSurface),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    u.role.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: u.isAdmin ? AppColors.primaryBlue : (u.isStaff ? AppColors.warningText : AppColors.neutralText),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: isSelf
                                    ? const Text('— (Chính bạn)', style: TextStyle(color: AppColors.textMuted, fontSize: 12))
                                    : DropdownButton<String>(
                                        value: u.role,
                                        isDense: true,
                                        underline: const SizedBox(),
                                        items: const [
                                          DropdownMenuItem(value: 'user', child: Text('Sinh viên (user)')),
                                          DropdownMenuItem(value: 'staff', child: Text('Cố vấn (staff)')),
                                          DropdownMenuItem(value: 'admin', child: Text('Quản trị (admin)')),
                                        ],
                                        onChanged: (newRole) {
                                          if (newRole != null && newRole != u.role) {
                                            _announcementService.updateUserRole(u.uid, newRole);
                                          }
                                        },
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                child: isSelf
                                    ? const SizedBox()
                                    : IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.errorRed),
                                        tooltip: 'Xóa tài khoản',
                                        onPressed: () => _confirmDeleteUser(u),
                                      ),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
