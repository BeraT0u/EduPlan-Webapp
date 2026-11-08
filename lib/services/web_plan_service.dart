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
}
