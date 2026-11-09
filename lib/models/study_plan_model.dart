class StudyPlanModel {
  final String id;
  final String userId;
  final String studentName;
  final String studentCode;
  final String semesterName;
  final List<Map<String, dynamic>> courses;
  final int totalCredits;
  final double totalSelfStudyHours;
  final double maxSafeThresholdHours;
  final int tuitionFee;
  final String status; // 'draft' | 'pending' | 'approved' | 'rejected' | 'pending_acceptance' | 'acceptance_rejected' | 'completed'
  final String? reviewReason;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final List<Map<String, dynamic>> submittedGrades;

  StudyPlanModel({
    required this.id,
    required this.userId,
    required this.studentName,
    this.studentCode = '',
    required this.semesterName,
    this.courses = const [],
    this.totalCredits = 0,
    this.totalSelfStudyHours = 0.0,
    this.maxSafeThresholdHours = 25.0,
    this.tuitionFee = 0,
    this.status = 'pending',
    this.reviewReason,
    this.reviewedBy,
    this.reviewedAt,
    this.submittedGrades = const [],
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isPendingAcceptance => status == 'pending_acceptance';
  bool get isAcceptanceRejected => status == 'acceptance_rejected';
  bool get isCompleted => status == 'completed';

  factory StudyPlanModel.fromMap(Map<String, dynamic> map, String id) {
    final coursesList = (map['courses'] as List?)
            ?.map((e) => (e as Map).cast<String, dynamic>())
            .toList() ??
        [];

    final submittedGradesList = (map['submittedGrades'] as List?)
            ?.map((e) => (e as Map).cast<String, dynamic>())
            .toList() ??
        [];

    // Parse or auto-calculate total credits from courses if missing or 0
    int parsedCredits = (map['totalCredits'] as num?)?.toInt() ??
        (map['credits'] as num?)?.toInt() ??
        (map['totalCredit'] as num?)?.toInt() ??
        0;

    if (parsedCredits == 0 && coursesList.isNotEmpty) {
      parsedCredits = coursesList.fold<int>(0, (sum, c) {
        final cr = (c['credits'] as num?)?.toInt() ??
            (c['credit'] as num?)?.toInt() ??
            0;
        return sum + cr;
      });
    }

    // Parse or auto-calculate total self study hours from courses if missing or 0
    double parsedHours = (map['totalSelfStudyHours'] as num?)?.toDouble() ??
        (map['totalHours'] as num?)?.toDouble() ??
        (map['weeklyWorkloadHours'] as num?)?.toDouble() ??
        (map['selfStudyHours'] as num?)?.toDouble() ??
        (map['workloadHours'] as num?)?.toDouble() ??
        0.0;

    if (parsedHours == 0.0 && coursesList.isNotEmpty) {
      parsedHours = coursesList.fold<double>(0.0, (sum, c) {
        final h = (c['plannedSelfStudyHours'] as num?)?.toDouble() ??
            (c['defaultSelfStudyHours'] as num?)?.toDouble() ??
            (c['hours'] as num?)?.toDouble() ??
            (c['selfStudyHours'] as num?)?.toDouble() ??
            (c['weeklyHours'] as num?)?.toDouble() ??
            0.0;
        return sum + h;
      });
    }

    return StudyPlanModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? (map['fullName'] as String? ?? 'Sinh viên'),
      studentCode: map['studentCode'] as String? ?? (map['studentId'] as String? ?? ''),
      semesterName: map['semesterName'] as String? ?? (map['semester'] as String? ?? 'Học kỳ'),
      courses: coursesList,
      totalCredits: parsedCredits,
      totalSelfStudyHours: parsedHours,
      maxSafeThresholdHours: (map['maxSafeThresholdHours'] as num?)?.toDouble() ??
          (map['safeThresholdHours'] as num?)?.toDouble() ??
          25.0,
      tuitionFee: (map['tuitionFee'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'pending',
      reviewReason: map['reviewReason'] as String?,
      reviewedBy: map['reviewedBy'] as String?,
      submittedGrades: submittedGradesList,
    );
  }
}
