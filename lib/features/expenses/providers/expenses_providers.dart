import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/providers/current_tenant_provider.dart';
import '../database/expenses_dao.dart';
import '../repositories/expenses_repository.dart';

final expensesDaoProvider = Provider<ExpensesDao>((ref) {
  final tenantId = ref.watch(currentTenantProvider);
  if (tenantId == null) {
    throw StateError('لا يوجد متجر حالي للمستخدم');
  }
  return ExpensesDao(ref.watch(appDatabaseProvider), tenantId);
});

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return ExpensesRepository(ref.watch(expensesDaoProvider));
});