import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';

class WebCourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _coursesRef =>
      _firestore.collection('courses');

  Stream<List<CourseModel>> streamCourses() {
    return _coursesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CourseModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> addCourse(CourseModel course) async {
    final docRef = _coursesRef.doc(course.code);
    final data = course.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await docRef.set(data);
  }

  Future<void> updateCourse(CourseModel course) async {
    final docRef = _coursesRef.doc(course.id.isNotEmpty ? course.id : course.code);
    final data = course.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await docRef.update(data);
  }

  Future<void> setCourseStatus(String courseId, String newStatus) async {
    await _coursesRef.doc(courseId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCourse(String courseId) async {
    await _coursesRef.doc(courseId).delete();
  }
}
