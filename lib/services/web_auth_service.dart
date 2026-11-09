import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';

class WebAuthService {
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  WebAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null),
        _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? const Stream.empty();

  User? get currentFirebaseUser => _auth?.currentUser;

  Future<UserModel?> signInWithGoogle() async {
    final auth = _auth;
    final firestore = _firestore;
    if (auth == null || firestore == null) return null;

    final googleProvider = GoogleAuthProvider();
    googleProvider.setCustomParameters({'prompt': 'select_account'});

    final userCredential = await auth.signInWithPopup(googleProvider);
    final user = userCredential.user;
    if (user == null) return null;

    final userDoc = await firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      final newUser = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'Sinh viên mới',
        photoUrl: user.photoURL,
        role: 'user', // Mặc định role là user
      );
      await firestore.collection('users').doc(user.uid).set(newUser.toMap());
      return newUser;
    }

    return UserModel.fromMap(userDoc.data()!, user.uid);
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final auth = _auth;
    final firestore = _firestore;
    if (auth == null || firestore == null) return null;

    final user = auth.currentUser;
    if (user == null) return null;

    final doc = await firestore.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, user.uid);
    }
    return null;
  }

  Future<void> signOut() async {
    await _auth?.signOut();
  }
}
