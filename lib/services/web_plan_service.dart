import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_plan_model.dart';

class WebPlanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _plansRef =>
      _firestore.collection('study_plans');

  Stream<List<StudyPlanModel>> streamPlans() {
    return _plansRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return StudyPlanModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> reviewPlan({
    required String planId,
    required bool isApproved,
    required String reviewerEmail,
    required String reviewReason,
  }) async {
    final status = isApproved ? 'approved' : 'rejected';
    await _plansRef.doc(planId).update({
      'status': status,
      'reviewReason': reviewReason,
      'reviewedBy': reviewerEmail,
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getCompletedCoursesForStudent(
    String userId, {
    String? semesterName,
  }) async {
    try {
      final snap = await _firestore
          .collection('students')
          .doc(userId)
          .collection('completed_courses')
          .get();

      if (snap.docs.isEmpty) return [];

      final list = snap.docs.map((d) => d.data()).toList();
      if (semesterName != null && semesterName.isNotEmpty) {
        final matches = list.where((c) {
          final sem = c['semesterName'] as String?;
          return sem != null &&
              (sem == semesterName ||
                  semesterName.contains(sem) ||
                  sem.contains(semesterName));
        }).toList();
        if (matches.isNotEmpty) return matches;
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> confirmSemesterAcceptance({
    required String planId,
    required String reviewerEmail,
    required String reviewReason,
  }) async {
    await _plansRef.doc(planId).update({
      'status': 'completed',
      'isCompleted': true,
      'reviewReason': reviewReason,
      'reviewedBy': reviewerEmail,
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
