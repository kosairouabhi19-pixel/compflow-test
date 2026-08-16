import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_providers.dart';

/// Provides the tenant context for the currently authenticated user.
///
/// A null value means there is no authenticated user or the authenticated
/// profile does not have a valid tenant id yet. Data-access layers must not
/// fall back to a default tenant when this is null.
final currentTenantProvider = Provider<String?>((ref) {
  final user = ref.watch(authControllerProvider).user;
  final tenantId = user?.tenantId.trim();

  if (tenantId == null || tenantId.isEmpty) {
    return null;
  }

  return tenantId;
});
