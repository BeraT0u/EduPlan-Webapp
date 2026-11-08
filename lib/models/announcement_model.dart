class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final String category;
  final String targetSemester;
  final String authorName;
  final String status; // 'published' | 'archived'
  final DateTime? createdAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    this.category = 'Học vụ',
    this.targetSemester = 'Tất cả các kỳ',
    this.authorName = 'Cố vấn học tập',
    this.status = 'published',
    this.createdAt,
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String id) {
    return AnnouncementModel(
      id: id,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      category: map['category'] as String? ?? 'Học vụ',
      targetSemester: map['targetSemester'] as String? ?? 'Tất cả các kỳ',
      authorName: map['authorName'] as String? ?? 'Cố vấn học tập',
      status: map['status'] as String? ?? 'published',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'category': category,
      'targetSemester': targetSemester,
      'authorName': authorName,
      'status': status,
    };
  }
}
