import 'package:flutter/material.dart';
import '../models/study_plan_model.dart';
import '../models/user_model.dart';
import '../services/web_plan_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_alert_banner.dart';

class ReviewsScreen extends StatefulWidget {
  final UserModel currentUser;

  const ReviewsScreen({super.key, required this.currentUser});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final WebPlanService _planService = WebPlanService();
  late final Stream<List<StudyPlanModel>> _plansStream;
  final TextEditingController _searchCtrl = TextEditingController();

  // Mode: 'plan' (Duyệt Kế Hoạch Đăng Ký) vs 'acceptance' (Duyệt Nghiệm Thu & Điểm Môn)
  String _reviewMode = 'plan';

  // Sub-tabs for Plan Mode
  String _activeTab = 'pending';
  String _searchQuery = '';
  final Set<String> _expandedPlanIds = {};

  // Cache for completed courses grades
  final Map<String, Future<List<Map<String, dynamic>>>> _cachedCompletedCourses = {};

  @override
  void initState() {
    super.initState();
    _plansStream = _planService.streamPlans();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _getGradesForPlan(StudyPlanModel plan) {
    final cacheKey = '${plan.userId}_${plan.semesterName}';
    if (!_cachedCompletedCourses.containsKey(cacheKey)) {
      _cachedCompletedCourses[cacheKey] = _planService.getCompletedCoursesForStudent(
        plan.userId,
        semesterName: plan.semesterName,
      );
    }
    return _cachedCompletedCourses[cacheKey]!;
  }

  void _showReviewDialog(StudyPlanModel plan, bool isApprove) {
    final reasonCtrl = TextEditingController();
    String? errorText;

    final suggestions = isApprove
        ? [
            'Lộ trình học tập cân bằng, đảm bảo điều kiện tiên quyết.',
            'Phân bổ giờ tự học hợp lý, đồng ý phê duyệt kế hoạch.',
            'Kế hoạch đạt chuẩn chương trình đào tạo, chúc bạn học tốt.',
          ]
        : [
            'Tổng giờ tự học vượt ngưỡng an toàn 25h/tuần, vui lòng giảm bớt 1 môn.',
            'Chưa đạt điều kiện môn tiên quyết, vui lòng kiểm tra lại lộ trình.',
            'Số lượng tín chỉ quá tải cho kỳ này, vui lòng cân đối lại số môn.',
          ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isApprove ? AppColors.successSurface : AppColors.dangerSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isApprove ? Icons.check_circle_outline : Icons.highlight_off,
                      color: isApprove ? AppColors.successText : AppColors.dangerText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isApprove ? 'Phê Duyệt Kế Hoạch Học Tập' : 'Yêu Cầu Chỉnh Sửa Kế Hoạch',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: 540,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student Summary Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCanvas,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderStructural),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  plan.studentName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                if (plan.studentCode.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppColors.borderStructural),
                                    ),
                                    child: Text(plan.studentCode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${plan.semesterName} • ${plan.courses.length} môn (${plan.totalCredits} TC) • Tải tự học: ${plan.totalSelfStudyHours.toInt()}h/tuần',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Fast Suggestion Chips
                      const Text(
                        'Gợi ý nhận xét nhanh (Bấm để chọn):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: suggestions.map((s) {
                          return ActionChip(
                            label: Text(s, style: const TextStyle(fontSize: 12)),
                            backgroundColor: AppColors.backgroundCanvas,
                            side: const BorderSide(color: AppColors.borderStructural),
                            onPressed: () {
                              setDialogState(() {
                                reasonCtrl.text = s;
                                errorText = null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Remark TextField
                      TextField(
                        controller: reasonCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Nhận xét của Cố vấn học tập (Bắt buộc tối thiểu 3 ký tự)',
                          hintText: isApprove
                              ? 'Nhập lý do phê duyệt hoặc dặn dò sinh viên...'
                              : 'Chỉ rõ lý do từ chối để sinh viên chỉnh sửa lại môn học...',
                          errorText: errorText,
                        ),
                        onChanged: (_) {
                          if (errorText != null) {
                            setDialogState(() => errorText = null);
                          }
                        },
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
                    final reason = reasonCtrl.text.trim();
                    if (reason.length < 3) {
                      setDialogState(() {
                        errorText = 'Vui lòng nhập nhận xét tối thiểu 3 ký tự.';
                      });
                      return;
                    }

                    await _planService.reviewPlan(
                      planId: plan.id,
                      isApproved: isApprove,
                      reviewerEmail: widget.currentUser.email,
                      reviewReason: reason,
                    );

                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isApprove ? AppColors.successText : AppColors.dangerText,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(isApprove ? 'Xác Nhận Phê Duyệt' : 'Gửi Yêu Cầu Sửa'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAcceptanceDialog(StudyPlanModel plan) {
    final reasonCtrl = TextEditingController(text: 'Đã hoàn thành và nghiệm thu kết quả học tập học kỳ.');
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.verified, color: Color(0xFF7E22CE)),
                  ),
                  const SizedBox(width: 12),
                  const Text('Xác Nhận Nghiệm Thu Kỳ Học', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sinh viên: ${plan.studentName} (${plan.studentCode})', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Học kỳ nghiệm thu: ${plan.semesterName}'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Nhận xét tổng kết của Cố vấn học tập',
                        errorText: errorText,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy bỏ')),
                ElevatedButton(
                  onPressed: () async {
                    if (reasonCtrl.text.trim().length < 3) {
                      setDialogState(() => errorText = 'Vui lòng nhập tối thiểu 3 ký tự.');
                      return;
                    }
                    await _planService.confirmSemesterAcceptance(
                      planId: plan.id,
                      reviewerEmail: widget.currentUser.email,
                      reviewReason: reasonCtrl.text.trim(),
                    );
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7E22CE),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Lưu Xác Nhận Nghiệm Thu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StudyPlanModel>>(
      stream: _plansStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(60),
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: AppAlertBanner(
                message: 'Không thể tải hàng đợi kế hoạch: ${snapshot.error}',
                isError: true,
              ),
            ),
          );
        }

        final allPlans = snapshot.data ?? [];

        // Split into 2 main functional datasets:
        // 1. Registration Plans (status: pending, approved, rejected)
        final registrationPlans = allPlans.where((p) => p.status != 'completed').toList();
        // 2. Acceptance Plans (status: completed)
        final acceptancePlans = allPlans.where((p) => p.status == 'completed').toList();

        final pendingCount = registrationPlans.where((p) => p.status == 'pending').length;
        final approvedCount = registrationPlans.where((p) => p.status == 'approved').length;
        final rejectedCount = registrationPlans.where((p) => p.status == 'rejected').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TOP SEGMENTED SWITCHER (Phân định rõ 2 chức năng)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderStructural),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModeButton(
                      modeKey: 'plan',
                      icon: Icons.checklist_rtl_rounded,
                      title: '1. Duyệt Kế Hoạch Học Tập (Đăng Ký Môn)',
                      subtitle: 'Xét duyệt kế hoạch học kỳ mới • Cảnh báo tải tự học >25h',
                      countBadge: '${registrationPlans.length}',
                      activeColor: AppColors.primaryBlue,
                      activeBg: AppColors.primaryBlueSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildModeButton(
                      modeKey: 'acceptance',
                      icon: Icons.school_rounded,
                      title: '2. Duyệt Nghiệm Thu Kỳ Học & Bảng Điểm',
                      subtitle: 'Xem bảng điểm số sinh viên đã nhập • Xác nhận nghiệm thu',
                      countBadge: '${acceptancePlans.length}',
                      activeColor: const Color(0xFF7E22CE),
                      activeBg: const Color(0xFFF3E8FF),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Render content based on selected mode
            if (_reviewMode == 'plan')
              _buildPlanReviewView(registrationPlans, pendingCount, approvedCount, rejectedCount)
            else
              _buildAcceptanceView(acceptancePlans),
          ],
        );
      },
    );
  }

  // ==========================================
  // VIEW 1: DUYỆT KẾ HOẠCH ĐĂNG KÝ MÔN HỌC
  // ==========================================
  Widget _buildPlanReviewView(
    List<StudyPlanModel> registrationPlans,
    int pendingCount,
    int approvedCount,
    int rejectedCount,
  ) {
    var filteredPlans = registrationPlans.where((p) {
      final matchesTab = _activeTab == 'all' || p.status == _activeTab;
      final matchesQuery = _searchQuery.isEmpty ||
          p.studentName.toLowerCase().contains(_searchQuery) ||
          p.studentCode.toLowerCase().contains(_searchQuery) ||
          p.semesterName.toLowerCase().contains(_searchQuery);
      return matchesTab && matchesQuery;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-toolbar: Filter Tabs + Search
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderStructural),
          ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTabButton('pending', 'Chờ duyệt', pendingCount, AppColors.warningText, AppColors.warningSurface),
                      const SizedBox(width: 8),
                      _buildTabButton('approved', 'Đã duyệt', approvedCount, AppColors.successText, AppColors.successSurface),
                      const SizedBox(width: 8),
                      _buildTabButton('rejected', 'Yêu cầu sửa', rejectedCount, AppColors.dangerText, AppColors.dangerSurface),
                      const SizedBox(width: 8),
                      _buildTabButton('all', 'Tất cả kế hoạch', registrationPlans.length, AppColors.neutralText, AppColors.neutralSurface),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên hoặc MSSV...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        if (filteredPlans.isEmpty)
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
                Icon(
                  _activeTab == 'pending' ? Icons.task_alt : Icons.inbox_outlined,
                  size: 48,
                  color: _activeTab == 'pending' ? AppColors.successText : AppColors.textMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  _activeTab == 'pending'
                      ? 'Tuyệt vời! Không còn kế hoạch đăng ký nào đang chờ duyệt.'
                      : (_searchQuery.isNotEmpty
                          ? 'Không tìm thấy sinh viên nào khớp với từ khóa "$_searchQuery".'
                          : 'Không có kế hoạch học tập nào trong mục này.'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredPlans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final plan = filteredPlans[index];
              final isExpanded = _expandedPlanIds.contains(plan.id);
              final isOverloaded = plan.totalSelfStudyHours > plan.maxSafeThresholdHours;
              final workloadRatio = plan.maxSafeThresholdHours > 0
                  ? (plan.totalSelfStudyHours / plan.maxSafeThresholdHours).clamp(0.0, 1.5)
                  : 0.0;

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOverloaded ? AppColors.dangerBorder : AppColors.borderStructural,
                    width: isOverloaded ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.primaryBlueSurface,
                                    child: Text(
                                      plan.studentName.isNotEmpty ? plan.studentName[0].toUpperCase() : 'S',
                                      style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(plan.studentName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                          const SizedBox(width: 8),
                                          if (plan.studentCode.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.backgroundCanvas,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: AppColors.borderStructural),
                                              ),
                                              child: Text(plan.studentCode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Đăng ký: ${plan.semesterName} • ${plan.courses.length} môn (${plan.totalCredits} TC)',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              _buildStatusBadge(plan.status),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Workload Progress Gauge
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isOverloaded ? AppColors.dangerSurface.withValues(alpha: 0.3) : AppColors.backgroundCanvas,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isOverloaded ? AppColors.dangerBorder : AppColors.borderStructural),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          isOverloaded ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                                          size: 16,
                                          color: isOverloaded ? AppColors.dangerText : AppColors.successText,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isOverloaded
                                              ? 'Cảnh báo: Tải tự học ${plan.totalSelfStudyHours.toInt()}h/tuần vượt ngưỡng an toàn (${plan.maxSafeThresholdHours.toInt()}h)'
                                              : 'Tải tự học an toàn: ${plan.totalSelfStudyHours.toInt()}h/tuần (Ngưỡng an toàn: ${plan.maxSafeThresholdHours.toInt()}h)',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isOverloaded ? FontWeight.bold : FontWeight.w600,
                                            color: isOverloaded ? AppColors.dangerText : AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text('Học phí: ${plan.tuitionFee > 0 ? '${plan.tuitionFee} đ' : 'Chưa tính'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: (workloadRatio / 1.5).clamp(0.0, 1.0),
                                    backgroundColor: AppColors.borderStructural.withValues(alpha: 0.5),
                                    valueColor: AlwaysStoppedAnimation<Color>(isOverloaded ? AppColors.dangerText : AppColors.successText),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (plan.reviewReason != null && plan.reviewReason!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: plan.isApproved ? AppColors.successSurface.withValues(alpha: 0.4) : AppColors.dangerSurface.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Nhận xét của Cố vấn: ${plan.reviewReason}${plan.reviewedBy != null ? ' (bởi ${plan.reviewedBy})' : ''}',
                                style: TextStyle(color: plan.isApproved ? AppColors.successText : AppColors.dangerText, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Expandable Registered Courses List
                    if (plan.courses.isNotEmpty) ...[
                      const Divider(height: 1, color: AppColors.borderStructural),
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedPlanIds.remove(plan.id);
                            } else {
                              _expandedPlanIds.add(plan.id);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.list_alt, size: 16, color: AppColors.primaryBlue),
                                  const SizedBox(width: 8),
                                  Text(
                                    isExpanded ? 'Ẩn danh sách môn học đăng ký' : 'Xem chi tiết ${plan.courses.length} môn học sinh viên đăng ký học',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
                                  ),
                                ],
                              ),
                              Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: AppColors.primaryBlue),
                            ],
                          ),
                        ),
                      ),
                      if (isExpanded)
                        Container(
                          color: AppColors.backgroundCanvas.withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Table(
                            columnWidths: const {
                              0: FlexColumnWidth(1.5),
                              1: FlexColumnWidth(3.5),
                              2: FlexColumnWidth(1.2),
                              3: FlexColumnWidth(1.5),
                            },
                            children: [
                              const TableRow(
                                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderStructural))),
                                children: [
                                  Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Mã môn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Tên môn học', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Tín chỉ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Giờ tự học', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                ],
                              ),
                              ...plan.courses.map((c) {
                                final code = c['code'] as String? ?? '—';
                                final name = c['name'] as String? ?? '—';
                                final credits = c['credits'] ?? c['credit'] ?? 3;
                                final hours = c['defaultSelfStudyHours'] ?? c['hours'] ?? 7;
                                return TableRow(
                                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderDivider))),
                                  children: [
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryBlue))),
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(name, style: const TextStyle(fontSize: 12))),
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('$credits TC', style: const TextStyle(fontSize: 12))),
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('${hours}h/tuần', style: const TextStyle(fontSize: 12))),
                                  ],
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                    ],

                    // Action Buttons
                    const Divider(height: 1, color: AppColors.borderStructural),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _showReviewDialog(plan, false),
                            icon: const Icon(Icons.close, size: 16, color: AppColors.dangerText),
                            label: const Text('Yêu Cầu Sửa', style: TextStyle(color: AppColors.dangerText)),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.dangerBorder)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _showReviewDialog(plan, true),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Phê Duyệt Kế Hoạch'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.successText, foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // ==============================================================
  // VIEW 2: DUYỆT NGHIỆM THU KỲ HỌC & BẢNG ĐIỂM MÔN HỌC (COMPLETED)
  // ==============================================================
  Widget _buildAcceptanceView(List<StudyPlanModel> acceptancePlans) {
    if (acceptancePlans.isEmpty) {
      return Container(
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
          children: const [
            Icon(Icons.school_outlined, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'Chưa có kỳ học nào được sinh viên nộp nghiệm thu.',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: acceptancePlans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final plan = acceptancePlans[index];

        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD8B4FE), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.school, color: Color(0xFF7E22CE), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(plan.studentName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                const SizedBox(width: 8),
                                if (plan.studentCode.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundCanvas,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppColors.borderStructural),
                                    ),
                                    child: Text(plan.studentCode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('Học kỳ nghiệm thu: ${plan.semesterName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFD8B4FE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.verified, size: 14, color: Color(0xFF7E22CE)),
                          SizedBox(width: 6),
                          Text('Đã Nghiệm Thu', style: TextStyle(color: Color(0xFF7E22CE), fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.borderStructural),

              // Grades Table for this Semester
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _getGradesForPlan(plan),
                builder: (context, gradeSnap) {
                  if (gradeSnap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF7E22CE))),
                    );
                  }

                  final coursesWithGrades = gradeSnap.data ?? [];

                  if (coursesWithGrades.isEmpty) {
                    // Fallback to plan.courses if completed_courses subcollection has no separate documents
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Đã hoàn thành ${plan.courses.length} môn học (${plan.totalCredits} TC). Sinh viên chưa nhập điểm chi tiết.',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  // Calculate stats
                  int totalEarnedCredits = 0;
                  double weightedGradeSum = 0;
                  int passedCount = 0;

                  for (var c in coursesWithGrades) {
                    final cr = (c['credits'] as num?)?.toInt() ?? 3;
                    final g = (c['grade'] as num?)?.toDouble() ?? 0.0;
                    final isPass = c['isPassed'] as bool? ?? (g >= 5.0);
                    if (isPass) {
                      totalEarnedCredits += cr;
                      passedCount++;
                    }
                    weightedGradeSum += (g * cr);
                  }

                  final avgGrade = totalEarnedCredits > 0 ? (weightedGradeSum / totalEarnedCredits) : 0.0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Metric Summary Bar
                      Container(
                        color: const Color(0xFFFAF5FF),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Số môn nghiệm thu', '${coursesWithGrades.length} môn'),
                            _buildStatItem('Tín chỉ tích lũy', '$totalEarnedCredits TC'),
                            _buildStatItem('Điểm TB Học kỳ', '${avgGrade.toStringAsFixed(2)} / 10'),
                            _buildStatItem('Tỷ lệ qua môn', '$passedCount/${coursesWithGrades.length} (${((passedCount / coursesWithGrades.length) * 100).toInt()}%)'),
                          ],
                        ),
                      ),

                      const Divider(height: 1, color: AppColors.borderStructural),

                      // Detailed Table of Courses & Grades
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1.5),
                            1: FlexColumnWidth(3.5),
                            2: FlexColumnWidth(1.2),
                            3: FlexColumnWidth(1.5),
                            4: FlexColumnWidth(1.2),
                            5: FlexColumnWidth(1.5),
                          },
                          children: [
                            const TableRow(
                              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderStructural, width: 1.5))),
                              children: [
                                Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Mã môn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Tên môn học', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Số TC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Điểm số (0-10)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Điểm chữ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Kết quả', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                              ],
                            ),
                            ...coursesWithGrades.map((course) {
                              final code = course['code'] as String? ?? '—';
                              final name = course['name'] as String? ?? '—';
                              final cr = (course['credits'] as num?)?.toInt() ?? 3;
                              final grade = (course['grade'] as num?)?.toDouble() ?? 0.0;
                              final letter = course['gradeLetter'] as String? ?? (grade >= 8.5 ? 'A' : (grade >= 7.0 ? 'B' : (grade >= 5.5 ? 'C' : 'D')));
                              final isPassed = course['isPassed'] as bool? ?? (grade >= 5.0);

                              return TableRow(
                                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderDivider))),
                                children: [
                                  Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(code, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7E22CE)))),
                                  Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
                                  Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text('$cr TC')),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: Text(
                                      grade.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isPassed ? AppColors.successText : AppColors.dangerText,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.backgroundCanvas,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppColors.borderStructural),
                                      ),
                                      child: Text(letter, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: Text(
                                      isPassed ? '✅ Đạt' : '❌ Chưa đạt',
                                      style: TextStyle(
                                        color: isPassed ? AppColors.successText : AppColors.dangerText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Advisor Review Action / History
              const Divider(height: 1, color: AppColors.borderStructural),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (plan.reviewReason != null && plan.reviewReason!.isNotEmpty)
                      Expanded(
                        child: Text(
                          'Đánh giá Cố vấn: "${plan.reviewReason}" (bởi ${plan.reviewedBy ?? 'Cố vấn'})',
                          style: const TextStyle(color: Color(0xFF7E22CE), fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      )
                    else
                      const Text('Chưa có ghi chú đánh giá học kỳ.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ElevatedButton.icon(
                      onPressed: () => _showAcceptanceDialog(plan),
                      icon: const Icon(Icons.edit_note, size: 16),
                      label: const Text('Đánh Giá & Cập Nhật Nghiệm Thu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7E22CE),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeButton({
    required String modeKey,
    required IconData icon,
    required String title,
    required String subtitle,
    required String countBadge,
    required Color activeColor,
    required Color activeBg,
  }) {
    final isSelected = _reviewMode == modeKey;
    return InkWell(
      onTap: () => setState(() => _reviewMode = modeKey),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? activeColor : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : AppColors.backgroundCanvas,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: isSelected ? activeColor : AppColors.textSecondary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? activeColor : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? activeColor : AppColors.borderStructural,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          countBadge,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isSelected ? activeColor.withValues(alpha: 0.8) : AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF7E22CE))),
      ],
    );
  }

  Widget _buildTabButton(String tabKey, String label, int count, Color activeColor, Color activeBg) {
    final isSelected = _activeTab == tabKey;
    return InkWell(
      onTap: () => setState(() => _activeTab = tabKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? activeColor.withValues(alpha: 0.3) : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : AppColors.borderStructural,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = AppColors.neutralSurface;
    Color text = AppColors.neutralText;
    String label = status;

    if (status == 'pending') {
      bg = AppColors.warningSurface;
      text = AppColors.warningText;
      label = 'Chờ duyệt';
    } else if (status == 'approved') {
      bg = AppColors.successSurface;
      text = AppColors.successText;
      label = 'Đã duyệt';
    } else if (status == 'rejected') {
      bg = AppColors.dangerSurface;
      text = AppColors.dangerText;
      label = 'Yêu cầu sửa';
    } else if (status == 'completed') {
      bg = const Color(0xFFF3E8FF);
      text = const Color(0xFF7E22CE);
      label = 'Đã hoàn thành';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
