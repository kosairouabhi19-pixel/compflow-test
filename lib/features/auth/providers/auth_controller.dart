import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../repositories/auth_repository.dart';
import '../services/device_session_service.dart';
import 'auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required AuthRepository authRepository,
    required DeviceSessionService deviceSessionService,
  })  : _authRepository = authRepository,
        _deviceSessionService = deviceSessionService,
        super(AuthState.initial()) {
    _authSubscription = _authRepository.authStateChanges().listen(
      (firebaseUser) async {
        if (firebaseUser == null) {
          _heartbeatTimer?.cancel();
          _heartbeatTimer = null;
          _activeSessionUid = null;
          state = state.copyWith(
            isLoading: false,
            clearUser: true,
            errorMessage: _pendingAuthError,
          );
          _pendingAuthError = null;
          return;
        }

        try {
          final appUser = await _authRepository.getCurrentUserProfile();

          if (appUser == null) {
            await _authRepository.signOut();
            state = state.copyWith(
              isLoading: false,
              clearUser: true,
              errorMessage: 'User profile not found. Please contact the store owner.',
            );
            return;
          }

          if (!appUser.isActive) {
            await _authRepository.signOut();
            state = state.copyWith(
              isLoading: false,
              clearUser: true,
              errorMessage: 'This account is inactive.',
            );
            return;
          }

          await _activateSession(appUser);
        } catch (e) {
          _pendingAuthError = e.toString();
          await _authRepository.signOut();
          state = state.copyWith(
            isLoading: false,
            clearUser: true,
            errorMessage: _pendingAuthError,
          );
        }
      },
      onError: (Object error) {
        state = state.copyWith(
          isLoading: false,
          clearUser: true,
          errorMessage: error.toString(),
        );
      },
    );
  }

  final AuthRepository _authRepository;
  final DeviceSessionService _deviceSessionService;
  StreamSubscription<dynamic>? _authSubscription;
  Timer? _heartbeatTimer;
  String? _activeSessionUid;
  String? _pendingAuthError;

  Future<void> _activateSession(appUser) async {
    if (_activeSessionUid == appUser.uid) return;

    await _deviceSessionService.acquire(appUser);
    _activeSessionUid = appUser.uid;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      final uid = _activeSessionUid;
      if (uid == null) return;
      try {
        await _deviceSessionService.heartbeat(uid);
      } catch (_) {
        // A temporary network failure should not log the user out immediately.
      }
    });

    state = state.copyWith(
      isLoading: false,
      user: appUser,
      errorMessage: null,
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authRepository.signIn(
        email: email,
        password: password,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearUser: true,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authRepository.register(
        fullName: fullName,
        email: email,
        password: password,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> resetPassword({required String email}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authRepository.resetPassword(email: email);
      state = state.copyWith(isLoading: false, errorMessage: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final uid = _activeSessionUid ?? state.user?.uid;
      if (uid != null) {
        await _deviceSessionService.release(uid);
      }
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
      _activeSessionUid = null;
      await _authRepository.signOut();
      state = state.copyWith(isLoading: false, errorMessage: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}