class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String role; // 'user' | 'staff' | 'admin'
  final String status;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.role,
    this.status = 'active',
  });

  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff';
  bool get isStaffOrAdmin => role == 'staff' || role == 'admin';

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? (map['fullName'] as String? ?? 'Chưa đặt tên'),
      photoUrl: map['photoUrl'] as String? ?? map['avatarUrl'] as String?,
      role: map['role'] as String? ?? 'user',
      status: map['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
      'status': status,
    };
  }
}
