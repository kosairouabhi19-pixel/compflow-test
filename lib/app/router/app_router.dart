import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/pages/auth_loading_page.dart';
import '../../features/auth/pages/forgot_password_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/providers/auth_state.dart';
import '../../shared/layouts/main_layout.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/auth-loading',
    routes: [
      GoRoute(
        path: '/auth-loading',
        builder: (context, state) => const AuthLoadingPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainLayout(),
      ),
    ],
  );

  ref.listen<AuthState?>(
    authControllerProvider,
    (previous, next) {
      if (next == null || next.isLoading) {
        return;
      }

      final location =
          router.routerDelegate.currentConfiguration.uri.path;

      final isAuthPage =
          location == '/login' ||
          location == '/forgot-password' ||
          location == '/auth-loading';

      if (next.user == null) {
        if (location != '/login' && location != '/forgot-password') {
          router.go('/login');
        }
        return;
      }

      if (isAuthPage) {
        router.go('/home');
      }
    },
  );

  return router;
});
