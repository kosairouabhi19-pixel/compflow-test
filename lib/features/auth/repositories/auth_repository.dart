import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user_model.dart';
import '../services/firebase_auth_service.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuthService? firebaseAuthService,
    FirebaseFirestore? firestore,
  })  : _firebaseAuthService =
            firebaseAuthService ?? FirebaseAuthService(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuthService _firebaseAuthService;
  final FirebaseFirestore _firestore;

  User? get currentUser => _firebaseAuthService.currentUser;

  Stream<User?> authStateChanges() =>
      _firebaseAuthService.authStateChanges();

  Future<AppUserModel?> getCurrentUserProfile() async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    final document = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return AppUserModel.fromFirestore(
      document.data()!,
      user.uid,
    );
  }

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
    required String fullName,
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuthService.register(
      fullName: fullName,
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Failed to create Firebase user.');
    }

    final appUser = AppUserModel(
      uid: user.uid,
      tenantId: user.uid,
      fullName: fullName,
      email: email,
      role: 'owner',
      isActive: true,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(appUser.toFirestore());

    return credential;
  }

  Future<void> resetPassword({required String email}) {
    return _firebaseAuthService.resetPassword(email: email);
  }

  Future<void> signOut() {
    return _firebaseAuthService.signOut();
  }
}