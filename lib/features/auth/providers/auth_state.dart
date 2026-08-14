import '../models/app_user_model.dart';

class AuthState {
  const AuthState({
    required this.isLoading,
    required this.user,
    required this.errorMessage,
  });

  factory AuthState.initial() {
    return const AuthState(
      isLoading: true,
      user: null,
      errorMessage: null,
    );
  }

  final bool isLoading;
  final AppUserModel? user;
  final String? errorMessage;

  AuthState copyWith({
    bool? isLoading,
    AppUserModel? user,
    String? errorMessage,
    bool clearUser = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
