import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../models/user_model.dart';
import '../services/web_course_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_alert_banner.dart';

class CoursesScreen extends StatefulWidget {
  final UserModel currentUser;

  const CoursesScreen({super.key, required this.currentUser});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final WebCourseService _courseService = WebCourseService();
  final ScrollController _horizontalScrollCtrl = ScrollController();
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _categoryFilter = 'all';

  @override
  void dispose() {
    _horizontalScrollCtrl.dispose();
    super.dispose();
  }

  void _showCourseDialog({
    required List<CourseModel> allCourses,
    CourseModel? existingCourse,
  }) {
    final isEditing = existingCourse != null;
    final codeCtrl = TextEditingController(text: existingCourse?.code ?? '');
    final nameCtrl = TextEditingController(text: existingCourse?.name ?? '');
    final creditsCtrl = TextEditingController(text: '${existingCourse?.credits ?? 3}');
    final hoursCtrl = TextEditingController(text: '${existingCourse?.defaultSelfStudyHours ?? 7.0}');
    
    // Assessment Breakdown
    final existingBreakdown = existingCourse?.assessmentBreakdown ?? {};
    final assignmentCtrl = TextEditingController(text: '${existingBreakdown['assignment'] ?? 20}');
    final labCtrl = TextEditingController(text: '${existingBreakdown['lab'] ?? 20}');
    final peCtrl = TextEditingController(text: '${existingBreakdown['pe'] ?? 30}');
    final feCtrl = TextEditingController(text: '${existingBreakdown['fe'] ?? 30}');

    // Study Tips
    final tipCtrl = TextEditingController();
    List<String> studyTips = List.from(existingCourse?.studyTips ?? [
      'Đọc giáo trình và hoàn thiện bài tập thực hành hàng tuần.',
    ]);

    String category = existingCourse?.category ?? 'Chuyên ngành SE';
    String status = existingCourse?.status ?? 'published';
    double difficulty = existingCourse?.difficulty ?? 3.0;
    String? prereqCode = existingCourse?.prerequisiteCode;

    // Filter available prerequisite options (exclude self)
    final availablePrereqs = allCourses
        .where((c) => c.code != existingCourse?.code)
        .map((c) => c.code)
        .toSet()
        .toList()..sort();

    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final a = int.tryParse(assignmentCtrl.text) ?? 0;
            final l = int.tryParse(labCtrl.text) ?? 0;
            final pe = int.tryParse(peCtrl.text) ?? 0;
            final fe = int.tryParse(feCtrl.text) ?? 0;
            final totalPercent = a + l + pe + fe;
            final isSum100 = totalPercent == 100;

            return AlertDialog(
              backgroundColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlueSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit_note : Icons.add_circle_outline,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Chỉnh Sửa Môn Học: ${existingCourse.code}' : 'Thêm Môn Học Mới',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: 620,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dialogError != null) ...[
                        AppAlertBanner(message: dialogError!, isError: true),
                        const SizedBox(height: 12),
                      ],

                      // Code & Name
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: codeCtrl,
                              enabled: !isEditing,
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 12,
                              decoration: const InputDecoration(
                                labelText: 'Mã môn (Viết hoa)',
                                hintText: 'PRM393, PRO192...',
                                counterText: '',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: nameCtrl,
                              maxLength: 120,
                              decoration: const InputDecoration(
                                labelText: 'Tên môn học',
                                hintText: 'Lập trình Di động...',
                                counterText: '',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Credits & Self-Study Hours
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: creditsCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Số tín chỉ (1..10)',
                                suffixText: 'TC',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: hoursCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Giờ tự học/tuần',
                                suffixText: 'h/tuần',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Prerequisite & Category
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              initialValue: prereqCode,
                              decoration: const InputDecoration(labelText: 'Môn tiên quyết'),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('— Không có (None) —', style: TextStyle(color: AppColors.textMuted)),
                                ),
                                ...availablePrereqs.map((code) {
                                  return DropdownMenuItem<String?>(
                                    value: code,
                                    child: Text(code),
                                  );
                                }),
                              ],
                              onChanged: (val) => setDialogState(() => prereqCode = val),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: category,
                              decoration: const InputDecoration(labelText: 'Danh mục môn học'),
                              items: const [
                                DropdownMenuItem(value: 'Chuyên ngành SE', child: Text('Chuyên ngành SE')),
                                DropdownMenuItem(value: 'Cơ sở ngành', child: Text('Cơ sở ngành')),
                                DropdownMenuItem(value: 'Toán & Thống kê', child: Text('Toán & Thống kê')),
                                DropdownMenuItem(value: 'Đại cương', child: Text('Đại cương')),
                                DropdownMenuItem(value: 'Kỹ năng mềm', child: Text('Kỹ năng mềm')),
                              ],
                              onChanged: (val) => setDialogState(() => category = val ?? category),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Difficulty Slider
                      Text(
                        'Độ khó môn học: ${difficulty.toStringAsFixed(1)} / 5.0 ⭐',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Slider(
                        value: difficulty,
                        min: 1.0,
                        max: 5.0,
                        divisions: 8,
                        label: '${difficulty.toStringAsFixed(1)} ⭐',
                        activeColor: AppColors.primaryBlue,
                        onChanged: (v) => setDialogState(() => difficulty = v),
                      ),
                      const SizedBox(height: 10),

                      // Assessment Breakdown (% Assignment, Lab, PE, FE)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCanvas,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSum100 ? AppColors.borderStructural : AppColors.dangerBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Tỷ trọng điểm đánh giá (Tổng = 100%)',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                Text(
                                  'Tổng: $totalPercent%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isSum100 ? AppColors.successText : AppColors.dangerText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: assignmentCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'Assignment %', isDense: true),
                                    onChanged: (_) => setDialogState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: labCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'Lab %', isDense: true),
                                    onChanged: (_) => setDialogState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: peCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'PE %', isDense: true),
                                    onChanged: (_) => setDialogState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: feCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'FE %', isDense: true),
                                    onChanged: (_) => setDialogState(() {}),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Study Tips Section
                      const Text(
                        'Mẹo học tập cho sinh viên (Study Tips):',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: tipCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Nhập mẹo học tập (VD: Làm trước Lab 1-4)...',
                                isDense: true,
                              ),
                              onSubmitted: (val) {
                                if (val.trim().isNotEmpty) {
                                  setDialogState(() {
                                    studyTips.add(val.trim());
                                    tipCtrl.clear();
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (tipCtrl.text.trim().isNotEmpty) {
                                setDialogState(() {
                                  studyTips.add(tipCtrl.text.trim());
                                  tipCtrl.clear();
                                });
                              }
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Thêm mẹo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (studyTips.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: studyTips.asMap().entries.map((entry) {
                            return Chip(
                              backgroundColor: AppColors.backgroundCanvas,
                              side: const BorderSide(color: AppColors.borderStructural),
                              label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () {
                                setDialogState(() {
                                  studyTips.removeAt(entry.key);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Status Field
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(labelText: 'Trạng thái phát hành'),
                        items: const [
                          DropdownMenuItem(value: 'published', child: Text('Published (Công khai cho Mobile)')),
                          DropdownMenuItem(value: 'draft', child: Text('Draft (Bản nháp nội bộ)')),
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
                  child: const Text('Hủy bỏ'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final code = codeCtrl.text.trim().toUpperCase();
                    final name = nameCtrl.text.trim();
                    final credits = int.tryParse(creditsCtrl.text) ?? 3;
                    final hours = double.tryParse(hoursCtrl.text) ?? 7.0;

                    if (code.isEmpty || name.isEmpty) {
                      setDialogState(() => dialogError = 'Vui lòng điền đầy đủ Mã môn và Tên môn.');
                      return;
                    }

                    if (totalPercent != 100) {
                      setDialogState(() => dialogError = 'Tổng tỷ trọng điểm (Assignment + Lab + PE + FE) bắt buộc phải bằng 100%.');
                      return;
                    }

                    final course = CourseModel(
                      id: isEditing ? existingCourse.id : code,
                      code: code,
                      name: name,
                      credits: credits,
                      defaultSelfStudyHours: hours,
                      prerequisiteCode: prereqCode,
                      category: category,
                      status: status,
                      difficulty: difficulty,
                      assessmentBreakdown: {
                        'assignment': a,
                        'lab': l,
                        'pe': pe,
                        'fe': fe,
                      },
                      studyTips: studyTips,
                    );

                    try {
                      if (isEditing) {
                        await _courseService.updateCourse(course);
                      } else {
                        await _courseService.addCourse(course);
                      }
                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      setDialogState(() => dialogError = 'Lỗi lưu Firestore: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppColors.dangerText),
              SizedBox(width: 8),
              Text('Xác Nhận Xóa Vĩnh Viễn'),
            ],
          ),
          content: Text(
            'Hành động này sẽ XÓA CỨNG môn học "${course.code} - ${course.name}" khỏi cơ sở dữ liệu Cloud Firestore.\n\n'
            'Chỉ Quản trị viên (Admin) mới có quyền thực hiện. Mọi kế hoạch hoặc tham chiếu môn này sẽ bị ảnh hưởng. Bạn có chắc chắn muốn xóa không?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy bỏ')),
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
    return StreamBuilder<List<CourseModel>>(
      stream: _courseService.streamCourses(),
      builder: (context, snapshot) {
        // 1. Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(60),
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            ),
          );
        }

        // 2. Error State
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: AppAlertBanner(
                message: 'Không thể tải danh mục môn học: ${snapshot.error}',
                isError: true,
              ),
            ),
          );
        }

        final rawCourses = snapshot.data ?? [];

        // Apply Search & Filter
        var filteredCourses = rawCourses.where((c) {
          final matchesQuery = _searchQuery.isEmpty ||
              c.code.toLowerCase().contains(_searchQuery) ||
              c.name.toLowerCase().contains(_searchQuery);
          final matchesStatus = _statusFilter == 'all' || c.status == _statusFilter;
          final matchesCategory = _categoryFilter == 'all' || c.category == _categoryFilter;
          return matchesQuery && matchesStatus && matchesCategory;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toolbar (Search + Filters + Add Button)
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
                    flex: 3,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm theo mã môn hoặc tên môn...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Category Filter
                  DropdownButton<String>(
                    value: _categoryFilter,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tất cả danh mục')),
                      DropdownMenuItem(value: 'Chuyên ngành SE', child: Text('Chuyên ngành SE')),
                      DropdownMenuItem(value: 'Cơ sở ngành', child: Text('Cơ sở ngành')),
                      DropdownMenuItem(value: 'Toán & Thống kê', child: Text('Toán & Thống kê')),
                      DropdownMenuItem(value: 'Đại cương', child: Text('Đại cương')),
                      DropdownMenuItem(value: 'Kỹ năng mềm', child: Text('Kỹ năng mềm')),
                    ],
                    onChanged: (val) => setState(() => _categoryFilter = val ?? 'all'),
                  ),
                  const SizedBox(width: 12),

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
                    onPressed: () => _showCourseDialog(allCourses: rawCourses),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Thêm Môn Học Mới'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Empty State
            if (filteredCourses.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(48),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderStructural),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.menu_book_outlined, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      rawCourses.isEmpty
                          ? 'Chưa có môn học nào trong cơ sở dữ liệu.'
                          : 'Không tìm thấy môn học nào phù hợp với bộ lọc.',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    if (rawCourses.isEmpty)
                      ElevatedButton.icon(
                        onPressed: () => _showCourseDialog(allCourses: rawCourses),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Tạo Môn Học Đầu Tiên'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                      )
                    else
                      OutlinedButton(
                        onPressed: () => setState(() {
                          _searchQuery = '';
                          _statusFilter = 'all';
                          _categoryFilter = 'all';
                        }),
                        child: const Text('Đặt lại bộ lọc'),
                      ),
                  ],
                ),
              )
            else
              // 4. Populated State (Courses Data Table)
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderStructural),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Scrollbar(
                        controller: _horizontalScrollCtrl,
                        thumbVisibility: true,
                        trackVisibility: true,
                        child: SingleChildScrollView(
                          controller: _horizontalScrollCtrl,
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: DataTable(
                              columnSpacing: 28,
                              horizontalMargin: 20,
                              showCheckboxColumn: false,
                              headingRowColor: WidgetStateProperty.all(AppColors.backgroundCanvas),
                              columns: const [
                                DataColumn(label: Text('Mã môn', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Tên môn học', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Số TC', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Độ khó', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Giờ tự học', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Tiên quyết', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Tỷ trọng điểm', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: filteredCourses.map((course) {
                                final b = course.assessmentBreakdown;
                                final breakdownSummary = b.isNotEmpty
                                    ? 'A:${b['assignment'] ?? 0}% L:${b['lab'] ?? 0}% PE:${b['pe'] ?? 0}% FE:${b['fe'] ?? 0}%'
                                    : 'Chưa cài';

                                return DataRow(
                                  onSelectChanged: (_) => _showCourseDialog(allCourses: rawCourses, existingCourse: course),
                                  cells: [
                                    DataCell(
                                      Tooltip(
                                        message: 'Bấm để chỉnh sửa môn học này',
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              course.code,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primaryBlue,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.edit_outlined, size: 14, color: AppColors.primaryBlue),
                                          ],
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(course.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          Text(course.category, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text('${course.credits} TC')),
                                    DataCell(Text('${course.difficulty.toStringAsFixed(1)} ⭐')),
                                    DataCell(Text('${course.defaultSelfStudyHours.toInt()}h/tuần')),
                                    DataCell(Text(course.prerequisiteCode ?? '—')),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.backgroundCanvas,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: AppColors.borderStructural),
                                        ),
                                        child: Text(breakdownSummary, style: const TextStyle(fontSize: 11)),
                                      ),
                                    ),
                                    DataCell(_buildStatusBadge(course.status)),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FilledButton.tonalIcon(
                                            onPressed: () => _showCourseDialog(allCourses: rawCourses, existingCourse: course),
                                            icon: const Icon(Icons.edit, size: 14),
                                            label: const Text('Sửa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            style: FilledButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              visualDensity: VisualDensity.compact,
                                              backgroundColor: AppColors.primaryBlueSurface,
                                              foregroundColor: AppColors.primaryBlue,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          IconButton(
                                            icon: Icon(
                                              course.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                                              size: 18,
                                              color: AppColors.textSecondary,
                                            ),
                                            tooltip: course.isArchived ? 'Khôi phục (Publish)' : 'Lưu trữ / Ẩn (Archive)',
                                            visualDensity: VisualDensity.compact,
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              final targetStatus = course.isArchived ? 'published' : 'archived';
                                              _courseService.setCourseStatus(
                                                course.id.isNotEmpty ? course.id : course.code,
                                                targetStatus,
                                              );
                                            },
                                          ),
                                          // Hard Delete: ONLY FOR ADMIN
                                          if (widget.currentUser.isAdmin) ...[
                                            const SizedBox(width: 4),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.dangerText),
                                              tooltip: 'Xóa vĩnh viễn (Admin)',
                                              visualDensity: VisualDensity.compact,
                                              padding: const EdgeInsets.all(4),
                                              constraints: const BoxConstraints(),
                                              onPressed: () => _confirmDeleteCourse(course),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
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
