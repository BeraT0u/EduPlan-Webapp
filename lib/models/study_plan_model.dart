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
  final String status; // 'draft' | 'pending' | 'approved' | 'rejected' | 'completed'
  final String? reviewReason;
  final String? reviewedBy;
  final DateTime? reviewedAt;

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
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory StudyPlanModel.fromMap(Map<String, dynamic> map, String id) {
    return StudyPlanModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? 'Sinh viên',
      studentCode: map['studentCode'] as String? ?? '',
      semesterName: map['semesterName'] as String? ?? 'Học kỳ',
      courses: (map['courses'] as List?)?.map((e) => (e as Map).cast<String, dynamic>()).toList() ?? [],
      totalCredits: (map['totalCredits'] as num?)?.toInt() ?? 0,
      totalSelfStudyHours: (map['totalSelfStudyHours'] as num?)?.toDouble() ?? 0.0,
      maxSafeThresholdHours: (map['maxSafeThresholdHours'] as num?)?.toDouble() ?? 25.0,
      tuitionFee: (map['tuitionFee'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'pending',
      reviewReason: map['reviewReason'] as String?,
      reviewedBy: map['reviewedBy'] as String?,
    );
  }
}
