import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'expenses_table.dart';

part 'expenses_dao.g.dart';

@DriftAccessor(tables: [Expenses])
class ExpensesDao extends DatabaseAccessor<AppDatabase>
    with _$ExpensesDaoMixin {
  ExpensesDao(super.db, this.tenantId);

  final String tenantId;

  Future<List<Expense>> getAllExpenses() {
    return (select(expenses)
          ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull()))
        .get();
  }

  Stream<List<Expense>> watchAllExpenses() {
    return (select(expenses)
          ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull()))
        .watch();
  }

  Future<Expense?> getExpenseById(String id) {
    return (select(expenses)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId) & t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<int> insertExpense(ExpensesCompanion expense) {
    return into(expenses).insert(expense.copyWith(tenantId: Value(tenantId)));
  }

  Future<bool> updateExpense(Expense expense) {
    if (expense.tenantId != tenantId || expense.deletedAt != null) {
      return Future.value(false);
    }
    return (update(expenses)
          ..where((t) => t.id.equals(expense.id) & t.tenantId.equals(tenantId)))
        .write(expense);
  }

  Future<int> deleteExpense(String id) {
    return (update(expenses)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId)))
        .write(ExpensesCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<List<Expense>> searchExpenses(String query) {
    return (select(expenses)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.deletedAt.isNull() &
              (t.title.like('%$query%') |
                  t.category.like('%$query%') |
                  t.notes.like('%$query%'))))
        .get();
  }
}