import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../models/user_model.dart';
import '../repositories/users_repository.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository();
});

final usersProvider = StreamProvider<List<UserModel>>((ref) {
  final authState = ref.watch(authControllerProvider);
  final tenantId = authState.user?.tenantId;

  if (tenantId == null || tenantId.isEmpty) {
    return const Stream.empty();
  }

  return ref.watch(usersRepositoryProvider).watchUsers(tenantId);
});