import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../repositories/auth_repository.dart';
import '../services/firebase_auth_service.dart';
import 'auth_controller.dart';
import 'auth_state.dart';

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuthService = ref.watch(firebaseAuthServiceProvider);
  return AuthRepository(firebaseAuthService: firebaseAuthService);
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository: authRepository);
});