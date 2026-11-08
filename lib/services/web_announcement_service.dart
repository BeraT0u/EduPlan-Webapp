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
}
