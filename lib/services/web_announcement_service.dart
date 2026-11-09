import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement_model.dart';
import '../models/user_model.dart';

class WebAnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<AnnouncementModel>> streamAnnouncements() {
    return _firestore.collection('announcements').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return AnnouncementModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> publishAnnouncement(AnnouncementModel announcement) async {
    final data = announcement.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('announcements').add(data);
  }

  Future<void> archiveAnnouncement(String id) async {
    await _firestore.collection('announcements').doc(id).update({
      'status': 'archived',
    });
  }

  Stream<List<UserModel>> streamUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> updateUserRole(String targetUid, String newRole) async {
    await _firestore.collection('users').doc(targetUid).update({
      'role': newRole,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> addOrUpdateUserByEmail({
    required String email,
    required String role,
    String? displayName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    // Check if user already exists with this email
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final updateData = <String, dynamic>{
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (displayName != null && displayName.trim().isNotEmpty) {
        updateData['displayName'] = displayName.trim();
      }
      await doc.reference.update(updateData);
      return 'Đã cập nhật vai trò ${role.toUpperCase()} cho tài khoản $normalizedEmail';
    } else {
      final newDoc = _firestore.collection('users').doc();
      final effectiveName = (displayName != null && displayName.trim().isNotEmpty)
          ? displayName.trim()
          : normalizedEmail.split('@').first;

      await newDoc.set({
        'uid': newDoc.id,
        'email': normalizedEmail,
        'displayName': effectiveName,
        'role': role,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return 'Đã cấp quyền thành công cho tài khoản $normalizedEmail ($role)';
    }
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }
}
