import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/study_plan_model.dart';
import '../theme/app_colors.dart';
import '../widgets/kpi_card.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onNavigateToReviews;

  const DashboardScreen({super.key, required this.onNavigateToReviews});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _totalStudents = 0;
  int _pendingPlans = 0;
  int _approvedPlans = 0;
  int _publishedCourses = 0;
  int _rejectedPlans = 0;
  bool _isLoading = true;
  List<StudyPlanModel> _recentPlans = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardMetrics();
  }

  Future<void> _fetchDashboardMetrics() async {
    setState(() => _isLoading = true);
    try {
      // 4 Firestore Aggregation Queries (count)
      final studentsCountSnap = await _firestore.collection('students').count().get();
      final pendingSnap = await _firestore.collection('study_plans').where('status', isEqualTo: 'pending').count().get();
      final approvedSnap = await _firestore.collection('study_plans').where('status', isEqualTo: 'approved').count().get();
      final coursesSnap = await _firestore.collection('courses').where('status', isEqualTo: 'published').count().get();
      final rejectedSnap = await _firestore.collection('study_plans').where('status', isEqualTo: 'rejected').count().get();

      // Recent 5 plans
      final recentDocs = await _firestore.collection('study_plans').limit(5).get();
      final recentList = recentDocs.docs.map((d) => StudyPlanModel.fromMap(d.data(), d.id)).toList();

      setState(() {
        _totalStudents = studentsCountSnap.count ?? 0;
        _pendingPlans = pendingSnap.count ?? 0;
        _approvedPlans = approvedSnap.count ?? 0;
        _publishedCourses = coursesSnap.count ?? 0;
        _rejectedPlans = rejectedSnap.count ?? 0;
        _recentPlans = recentList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4 KPI Cards (>= 3 figures required by assignment)
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isWide ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isWide ? 1.5 : 1.3,
              children: [
                KpiCard(
                  title: 'TỔNG SINH VIÊN',
                  value: '$_totalStudents',
                  icon: Icons.groups_outlined,
                  iconColor: AppColors.primaryBlue,
                  subtitle: 'Đang theo học kỳ Fall 2026',
                ),
                KpiCard(
                  title: 'KẾ HOẠCH CHỜ DUYỆT',
                  value: '$_pendingPlans',
                  icon: Icons.pending_actions,
                  iconColor: AppColors.warningText,
                  subtitle: 'Cần Cố vấn xem xét',
                ),
                KpiCard(
                  title: 'ĐÃ PHÊ DUYỆT',
                  value: '$_approvedPlans',
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.successText,
                  subtitle: 'Lộ trình hợp lệ',
                ),
                KpiCard(
                  title: 'MÔN HỌC ĐANG MỞ',
                  value: '$_publishedCourses',
                  icon: Icons.auto_stories_outlined,
                  iconColor: Colors.purple,
                  subtitle: 'Có sẵn trên Mobile',
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 28),

        // 1 Visual Chart (Tỷ lệ phân bố kế hoạch học tập)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderStructural, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Biểu đồ Phân bổ Kế hoạch Học tập (Học kỳ hiện tại)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Tải lại chỉ số',
                    onPressed: _fetchDashboardMetrics,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Visual Breakdown Bars
              _buildMetricBar('Kế hoạch Đã duyệt (Approved)', _approvedPlans, AppColors.successText, AppColors.successSurface),
              const SizedBox(height: 12),
              _buildMetricBar('Kế hoạch Chờ duyệt (Pending)', _pendingPlans, AppColors.warningText, AppColors.warningSurface),
              const SizedBox(height: 12),
              _buildMetricBar('Kế hoạch Yêu cầu chỉnh sửa (Rejected)', _rejectedPlans, AppColors.dangerText, AppColors.dangerSurface),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Recent 5 Plans Table
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderStructural, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kế hoạch Học tập Mới Gửi gần đây',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: widget.onNavigateToReviews,
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Xem tất cả & Duyệt'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_recentPlans.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Chưa có kế hoạch nào được nộp.'),
                  ),
                )
              else
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2.5),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(1.5),
                    3: FlexColumnWidth(1.5),
                    4: FlexColumnWidth(1.5),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.borderStructural)),
                      ),
                      children: [
                        Padding(padding: EdgeInsets.all(10), child: Text('Sinh viên', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(10), child: Text('Học kỳ', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(10), child: Text('Số môn / TC', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(10), child: Text('Tải / tuần', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(10), child: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                    ..._recentPlans.map((plan) {
                      return TableRow(
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.borderDivider)),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(plan.studentName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(plan.semesterName),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text('${plan.courses.length} môn (${plan.totalCredits} TC)'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              '${plan.totalSelfStudyHours.toInt()}h/tuần',
                              style: TextStyle(
                                color: plan.totalSelfStudyHours > 25 ? AppColors.dangerText : AppColors.textPrimary,
                                fontWeight: plan.totalSelfStudyHours > 25 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: _buildStatusBadge(plan.status),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBar(String label, int count, Color color, Color bgColor) {
    final total = (_approvedPlans + _pendingPlans + _rejectedPlans);
    final ratio = total > 0 ? (count / total) : 0.0;
    final percent = (ratio * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text('$count kế hoạch ($percent%)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: AppColors.borderStructural.withValues(alpha: 0.4),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
      ],
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
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
