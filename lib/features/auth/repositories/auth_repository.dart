import 'package:firebase_auth/firebase_auth.dart';

import '../services/firebase_auth_service.dart';

class AuthRepository {
  AuthRepository({FirebaseAuthService? firebaseAuthService})
      : _firebaseAuthService = firebaseAuthService ?? FirebaseAuthService();

  final FirebaseAuthService _firebaseAuthService;

  User? get currentUser => _firebaseAuthService.currentUser;

  Stream<User?> authStateChanges() => _firebaseAuthService.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _firebaseAuthService.signIn(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> register({
    required String email,
    required String password,
  }) {
    return _firebaseAuthService.register(
      fullName: '',
      email: email,
      password: password,
    );
  }

  Future<void> resetPassword({required String email}) {
    return _firebaseAuthService.resetPassword(email: email);
  }

  Future<void> signOut() {
    return _firebaseAuthService.signOut();
  }
}