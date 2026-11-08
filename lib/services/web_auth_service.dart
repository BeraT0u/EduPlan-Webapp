import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class WebAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  Future<UserModel?> signInWithGoogle() async {
    final googleProvider = GoogleAuthProvider();
    googleProvider.setCustomParameters({'prompt': 'select_account'});

    final userCredential = await _auth.signInWithPopup(googleProvider);
    final user = userCredential.user;
    if (user == null) return null;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      final newUser = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'Sinh viên mới',
        photoUrl: user.photoURL,
        role: 'user', // Mặc định role là user
      );
      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
      return newUser;
    }

    return UserModel.fromMap(userDoc.data()!, user.uid);
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, user.uid);
    }
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
