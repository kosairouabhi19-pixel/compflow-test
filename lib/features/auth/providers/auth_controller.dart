import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthState.initial()) {
    _authSubscription = _authRepository.authStateChanges().listen(
      (firebaseUser) async {
        if (firebaseUser == null) {
          state = state.copyWith(
            isLoading: false,
            clearUser: true,
            errorMessage: null,
          );
          return;
        }

        try {
          final appUser = await _authRepository.getCurrentUserProfile();

          if (appUser == null) {
            await _authRepository.signOut();
            state = state.copyWith(
              isLoading: false,
              clearUser: true,
              errorMessage: null,
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

          state = state.copyWith(
            isLoading: false,
            user: appUser,
            errorMessage: null,
          );
        } catch (e) {
          state = state.copyWith(
            isLoading: false,
            clearUser: true,
            errorMessage: e.toString(),
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
  StreamSubscription<dynamic>? _authSubscription;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      await _authRepository.signIn(
        email: email,
        password: password,
      );

      final appUser = await _authRepository.getCurrentUserProfile();

      if (appUser == null) {
        await _authRepository.signOut();
        state = state.copyWith(
          isLoading: false,
          clearUser: true,
          errorMessage: 'User profile not found. Please register through the app.',
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

      state = state.copyWith(
        isLoading: false,
        user: appUser,
        errorMessage: null,
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
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

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

  Future<void> resetPassword({
    required String email,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

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
      await _authRepository.signOut();
      state = state.copyWith(isLoading: false, errorMessage: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}