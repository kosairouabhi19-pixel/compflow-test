import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  Future<UserCredential> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(fullName);
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  Future<void> resetPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  Exception _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return Exception('البريد الإلكتروني غير صالح.');
      case 'user-disabled':
        return Exception('تم تعطيل هذا الحساب.');
      case 'user-not-found':
        return Exception('لا يوجد مستخدم بهذا البريد الإلكتروني.');
      case 'wrong-password':
        return Exception('كلمة المرور غير صحيحة.');
      case 'email-already-in-use':
        return Exception('هذا البريد الإلكتروني مستخدم بالفعل.');
      case 'weak-password':
        return Exception('كلمة المرور ضعيفة جدًا.');
      case 'operation-not-allowed':
        return Exception('هذه العملية غير مسموح بها حاليًا.');
      case 'invalid-credential':
        return Exception('بيانات الاعتماد غير صالحة.');
      case 'too-many-requests':
        return Exception('تم إرسال عدد كبير من الطلبات، حاول لاحقًا.');
      case 'network-request-failed':
        return Exception('حدث خطأ في الاتصال بالشبكة.');
      default:
        return Exception('حدث خطأ غير متوقع، حاول مرة أخرى.');
    }
  }
}