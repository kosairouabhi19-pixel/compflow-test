import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../database/expenses_dao.dart';
import '../repositories/expenses_repository.dart';

final expensesDaoProvider = Provider<ExpensesDao>((ref) {
  return ExpensesDao(ref.watch(appDatabaseProvider));
});

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return ExpensesRepository(ref.watch(expensesDaoProvider));
});
