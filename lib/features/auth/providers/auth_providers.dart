import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../app/providers/app_settings_providers.dart';
import '../repositories/auth_repository.dart';
import '../services/device_session_service.dart';
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

final deviceSessionServiceProvider = Provider<DeviceSessionService>((ref) {
  return DeviceSessionService(ref.watch(sharedPreferencesProvider));
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final deviceSessionService = ref.watch(deviceSessionServiceProvider);
  return AuthController(
    authRepository: authRepository,
    deviceSessionService: deviceSessionService,
  );
});
