import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../models/user_model.dart';
import '../services/web_course_service.dart';
import '../theme/app_colors.dart';

class CoursesScreen extends StatefulWidget {
  final UserModel currentUser;

  const CoursesScreen({super.key, required this.currentUser});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final WebCourseService _courseService = WebCourseService();
  String _searchQuery = '';
  String _statusFilter = 'all';

  void _showCourseDialog({CourseModel? existingCourse}) {
    final isEditing = existingCourse != null;
    final codeCtrl = TextEditingController(text: existingCourse?.code ?? '');
    final nameCtrl = TextEditingController(text: existingCourse?.name ?? '');
    final creditsCtrl = TextEditingController(text: '${existingCourse?.credits ?? 3}');
    final hoursCtrl = TextEditingController(text: '${existingCourse?.defaultSelfStudyHours ?? 7.0}');
    final prereqCtrl = TextEditingController(text: existingCourse?.prerequisiteCode ?? '');
    String category = existingCourse?.category ?? 'Chuyên ngành SE';
    String status = existingCourse?.status ?? 'published';
    double difficulty = existingCourse?.difficulty ?? 3.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(
                isEditing ? 'Chỉnh Sửa Môn Học: ${existingCourse.code}' : 'Thêm Môn Học Mới',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: codeCtrl,
                        enabled: !isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Mã môn (Ví dụ: PRN231, AIE411)',
                          hintText: 'Tối đa 12 ký tự, viết hoa',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tên môn học',
                          hintText: 'Tối đa 120 ký tự',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: creditsCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Số tín chỉ (1..10)'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: hoursCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Giờ tự học/tuần'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: prereqCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Môn tiên quyết (để trống nếu không có)',
                          hintText: 'Ví dụ: PRO192',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: category,
                        decoration: const InputDecoration(labelText: 'Danh mục môn học'),
                        items: const [
                          DropdownMenuItem(value: 'Chuyên ngành SE', child: Text('Chuyên ngành SE')),
                          DropdownMenuItem(value: 'Cơ sở ngành', child: Text('Cơ sở ngành')),
                          DropdownMenuItem(value: 'Toán & Thống kê', child: Text('Toán & Thống kê')),
                          DropdownMenuItem(value: 'Đại cương', child: Text('Đại cương')),
                        ],
                        onChanged: (val) => setDialogState(() => category = val ?? category),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(labelText: 'Trạng thái phát hành'),
                        items: const [
                          DropdownMenuItem(value: 'published', child: Text('Published (Công khai cho Mobile)')),
                          DropdownMenuItem(value: 'draft', child: Text('Draft (Bản nháp)')),
                          DropdownMenuItem(value: 'archived', child: Text('Archived (Lưu trữ / Ẩn)')),
                        ],
                        onChanged: (val) => setDialogState(() => status = val ?? status),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final code = codeCtrl.text.trim().toUpperCase();
                    final name = nameCtrl.text.trim();
                    final credits = int.tryParse(creditsCtrl.text) ?? 3;
                    final hours = double.tryParse(hoursCtrl.text) ?? 7.0;
                    final prereq = prereqCtrl.text.trim().isEmpty ? null : prereqCtrl.text.trim().toUpperCase();

                    if (code.isEmpty || name.isEmpty) return;

                    final course = CourseModel(
                      id: isEditing ? existingCourse.id : code,
                      code: code,
                      name: name,
                      credits: credits,
                      defaultSelfStudyHours: hours,
                      prerequisiteCode: prereq,
                      category: category,
                      status: status,
                      difficulty: difficulty,
                    );

                    if (isEditing) {
                      await _courseService.updateCourse(course);
                    } else {
                      await _courseService.addCourse(course);
                    }

                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isEditing ? 'Lưu Thay Đổi' : 'Tạo Môn Học'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteCourse(CourseModel course) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppColors.dangerText),
              SizedBox(width: 8),
              Text('Xác Nhận Xóa Vĩnh Viễn'),
            ],
          ),
          content: Text(
            'Hành động này sẽ XÓA CỨNG môn học "${course.code} - ${course.name}" khỏi cơ sở dữ liệu Cloud Firestore.\n\n'
            'Chỉ Quản trị viên (Admin) mới có quyền thực hiện. Bạn có chắc chắn muốn xóa không?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                await _courseService.deleteCourse(course.id.isNotEmpty ? course.id : course.code);
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dangerText,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xóa Vĩnh Viễn'),
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
        // Toolbar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderStructural),
          ),
          child: Row(
            children: [
              // Search Field
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm theo mã môn hoặc tên môn...',
                    prefixIcon: Icon(Icons.search, size: 20),
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
              ),
              const SizedBox(width: 16),

              // Status Filter
              DropdownButton<String>(
                value: _statusFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tất cả trạng thái')),
                  DropdownMenuItem(value: 'published', child: Text('Published')),
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(value: 'archived', child: Text('Archived')),
                ],
                onChanged: (val) => setState(() => _statusFilter = val ?? 'all'),
              ),
              const SizedBox(width: 16),

              // Add Course Button
              ElevatedButton.icon(
                onPressed: () => _showCourseDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm Môn Học Mới'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Courses Table
        StreamBuilder<List<CourseModel>>(
          stream: _courseService.streamCourses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
            }

            var courses = snapshot.data ?? [];
            if (_searchQuery.isNotEmpty) {
              courses = courses.where((c) {
                return c.code.toLowerCase().contains(_searchQuery) ||
                       c.name.toLowerCase().contains(_searchQuery);
              }).toList();
            }
            if (_statusFilter != 'all') {
              courses = courses.where((c) => c.status == _statusFilter).toList();
            }

            if (courses.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderStructural),
                ),
                child: const Text('Không tìm thấy môn học nào phù hợp.'),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderStructural),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.backgroundCanvas),
                  columns: const [
                    DataColumn(label: Text('Mã môn', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Tên môn học', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Số TC', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Giờ tự học', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Tiên quyết', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: courses.map((course) {
                    return DataRow(
                      cells: [
                        DataCell(Text(course.code, style: const TextStyle(fontWeight: FontWeight.w700))),
                        DataCell(Text(course.name)),
                        DataCell(Text('${course.credits} TC')),
                        DataCell(Text('${course.defaultSelfStudyHours.toInt()}h/tuần')),
                        DataCell(Text(course.prerequisiteCode ?? '—')),
                        DataCell(_buildStatusBadge(course.status)),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Chỉnh sửa môn học',
                                onPressed: () => _showCourseDialog(existingCourse: course),
                              ),
                              IconButton(
                                icon: Icon(
                                  course.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                tooltip: course.isArchived ? 'Khôi phục (Publish)' : 'Lưu trữ (Archive)',
                                onPressed: () {
                                  final targetStatus = course.isArchived ? 'published' : 'archived';
                                  _courseService.setCourseStatus(course.id.isNotEmpty ? course.id : course.code, targetStatus);
                                },
                              ),
                              // Hard Delete: ONLY FOR ADMIN
                              if (widget.currentUser.isAdmin)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.dangerText),
                                  tooltip: 'Xóa vĩnh viễn (Admin)',
                                  onPressed: () => _confirmDeleteCourse(course),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = AppColors.neutralSurface;
    Color text = AppColors.neutralText;
    String label = status;

    if (status == 'published') {
      bg = AppColors.successSurface;
      text = AppColors.successText;
      label = 'Published';
    } else if (status == 'draft') {
      bg = AppColors.neutralSurface;
      text = AppColors.neutralText;
      label = 'Draft';
    } else if (status == 'archived') {
      bg = AppColors.warningSurface;
      text = AppColors.warningText;
      label = 'Archived';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
