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
                      value: _category,
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
                      value: _targetSemester,
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlueSurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('ADMIN ACCESS', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11)),
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
                        1: FlexColumnWidth(3),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(2),
                      },
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderStructural))),
                          children: [
                            Padding(padding: EdgeInsets.all(10), child: Text('Họ tên', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(10), child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(10), child: Text('Vai trò hiện tại', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(10), child: Text('Thay đổi vai trò', style: TextStyle(fontWeight: FontWeight.bold))),
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
