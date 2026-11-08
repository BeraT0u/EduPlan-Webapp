class CourseModel {
  final String id;
  final String code;
  final String name;
  final int credits;
  final double difficulty;
  final double defaultSelfStudyHours;
  final String? prerequisiteCode;
  final String category;
  final Map<String, dynamic> assessmentBreakdown;
  final List<String> studyTips;
  final String status; // 'published' | 'draft' | 'archived'

  CourseModel({
    required this.id,
    required this.code,
    required this.name,
    this.credits = 3,
    this.difficulty = 3.0,
    this.defaultSelfStudyHours = 7.0,
    this.prerequisiteCode,
    this.category = 'Chuyên ngành SE',
    this.assessmentBreakdown = const {},
    this.studyTips = const [],
    this.status = 'published',
  });

  bool get isPublished => status == 'published';
  bool get isArchived => status == 'archived';
  bool get isDraft => status == 'draft';

  factory CourseModel.fromMap(Map<String, dynamic> map, String id) {
    return CourseModel(
      id: id,
      code: map['code'] as String? ?? id,
      name: map['name'] as String? ?? '',
      credits: (map['credits'] as num?)?.toInt() ?? 3,
      difficulty: (map['difficulty'] as num?)?.toDouble() ?? 3.0,
      defaultSelfStudyHours: (map['defaultSelfStudyHours'] as num?)?.toDouble() ?? 7.0,
      prerequisiteCode: map['prerequisiteCode'] as String?,
      category: map['category'] as String? ?? 'Chuyên ngành SE',
      assessmentBreakdown: (map['assessmentBreakdown'] as Map?)?.cast<String, dynamic>() ?? {},
      studyTips: (map['studyTips'] as List?)?.cast<String>() ?? [],
      status: map['status'] as String? ?? 'published',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'credits': credits,
      'difficulty': difficulty,
      'defaultSelfStudyHours': defaultSelfStudyHours,
      'prerequisiteCode': prerequisiteCode,
      'category': category,
      'assessmentBreakdown': assessmentBreakdown,
      'studyTips': studyTips,
      'status': status,
    };
  }

  CourseModel copyWith({
    String? name,
    int? credits,
    double? difficulty,
    double? defaultSelfStudyHours,
    String? prerequisiteCode,
    String? category,
    String? status,
  }) {
    return CourseModel(
      id: id,
      code: code,
      name: name ?? this.name,
      credits: credits ?? this.credits,
      difficulty: difficulty ?? this.difficulty,
      defaultSelfStudyHours: defaultSelfStudyHours ?? this.defaultSelfStudyHours,
      prerequisiteCode: prerequisiteCode ?? this.prerequisiteCode,
      category: category ?? this.category,
      assessmentBreakdown: assessmentBreakdown,
      studyTips: studyTips,
      status: status ?? this.status,
    );
  }
}
