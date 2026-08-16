import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/pages/forgot_password_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/providers/auth_state.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
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
        builder: (context, state) => const DashboardPage(),
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
          location == '/forgot-password';

      if (next.user == null) {
        if (!isAuthPage) {
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
