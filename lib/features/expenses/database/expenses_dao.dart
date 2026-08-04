import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'expenses_table.dart';

part 'expenses_dao.g.dart';

@DriftAccessor(tables: [Expenses])
class ExpensesDao extends DatabaseAccessor<AppDatabase>
    with _$ExpensesDaoMixin {
  ExpensesDao(super.db);

  Future<List<Expense>> getAllExpenses() => select(expenses).get();

  Stream<List<Expense>> watchAllExpenses() => select(expenses).watch();

  Future<Expense?> getExpenseById(String id) =>
      (select(expenses)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertExpense(ExpensesCompanion expense) =>
      into(expenses).insert(expense);

  Future<bool> updateExpense(Expense expense) =>
      update(expenses).replace(expense);

  Future<int> deleteExpense(String id) =>
      (delete(expenses)..where((t) => t.id.equals(id))).go();
}