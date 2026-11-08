import 'package:flutter/material.dart';
import '../models/study_plan_model.dart';
import '../models/user_model.dart';
import '../services/web_plan_service.dart';
import '../theme/app_colors.dart';

class ReviewsScreen extends StatefulWidget {
  final UserModel currentUser;

  const ReviewsScreen({super.key, required this.currentUser});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final WebPlanService _planService = WebPlanService();
  String _activeTab = 'pending';

  void _showReviewDialog(StudyPlanModel plan, bool isApprove) {
    final reasonCtrl = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Row(
                children: [
                  Icon(
                    isApprove ? Icons.check_circle_outline : Icons.highlight_off,
                    color: isApprove ? AppColors.successText : AppColors.dangerText,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isApprove ? 'Phê Duyệt Kế Hoạch' : 'Yêu Cầu Chỉnh Sửa Kế Hoạch',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sinh viên: ${plan.studentName} (${plan.studentCode.isNotEmpty ? plan.studentCode : plan.userId})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text('Học kỳ: ${plan.semesterName} • ${plan.courses.length} môn (${plan.totalCredits} TC)'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Nhận xét / Lý do của Cố vấn học tập (Bắt buộc)',
                        hintText: isApprove
                            ? 'Ví dụ: Kế hoạch phân bổ đều, đủ điều kiện tiên quyết.'
                            : 'Ví dụ: Tổng giờ tự học 34h vượt ngưỡng 25h, vui lòng đổi bớt môn.',
                        errorText: errorText,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderStructural),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabButton('pending', 'Chờ duyệt (Pending)'),
              _buildTabButton('approved', 'Đã duyệt (Approved)'),
              _buildTabButton('rejected', 'Yêu cầu sửa (Rejected)'),
              _buildTabButton('all', 'Tất cả'),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Plans Stream
        StreamBuilder<List<StudyPlanModel>>(
          stream: _planService.streamPlans(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
            }

            var plans = snapshot.data ?? [];
            if (_activeTab != 'all') {
              plans = plans.where((p) => p.status == _activeTab).toList();
            }

            if (plans.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderStructural),
                ),
                child: const Text('Không có kế hoạch học tập nào trong danh mục này.'),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: plans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final plan = plans[index];
                final isOverloaded = plan.totalSelfStudyHours > plan.maxSafeThresholdHours;

                return Container(
                  padding: const EdgeInsets.all(20),
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
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                plan.studentName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 8),
                              if (plan.studentCode.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundCanvas,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.borderStructural),
                                  ),
                                  child: Text(
                                    plan.studentCode,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ],
                          ),
                          _buildStatusBadge(plan.status),
                        ],
                      ),

                      const SizedBox(height: 8),
                      Text(
                        'Học kỳ: ${plan.semesterName} • Đăng ký: ${plan.courses.length} môn (${plan.totalCredits} TC) • Học phí ước tính: ${plan.tuitionFee} đ',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),

                      const SizedBox(height: 8),
                      // Workload Metric
                      Row(
                        children: [
                          Icon(
                            isOverloaded ? Icons.warning_amber_rounded : Icons.schedule,
                            size: 16,
                            color: isOverloaded ? AppColors.dangerText : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tải tự học: ${plan.totalSelfStudyHours.toInt()}h/tuần (Ngưỡng an toàn: ${plan.maxSafeThresholdHours.toInt()}h)',
                            style: TextStyle(
                              color: isOverloaded ? AppColors.dangerText : AppColors.textPrimary,
                              fontWeight: isOverloaded ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                          if (isOverloaded) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.dangerSurface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Cảnh báo quá tải', style: TextStyle(color: AppColors.dangerText, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
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
                            'Nhận xét Cố vấn: ${plan.reviewReason}',
                            style: TextStyle(
                              color: plan.isApproved ? AppColors.successText : AppColors.dangerText,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      // Actions (Approve / Reject)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _showReviewDialog(plan, false),
                            icon: const Icon(Icons.close, size: 16, color: AppColors.dangerText),
                            label: const Text('Yêu Cầu Sửa', style: TextStyle(color: AppColors.dangerText)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _showReviewDialog(plan, true),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Phê Duyệt Kế Hoạch'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.successText,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTabButton(String tabKey, String label) {
    final isSelected = _activeTab == tabKey;
    return InkWell(
      onTap: () => setState(() => _activeTab = tabKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlueSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
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
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
