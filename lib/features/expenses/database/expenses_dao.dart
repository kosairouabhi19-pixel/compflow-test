import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_queue_writer.dart';
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

  Future<int> insertExpense(ExpensesCompanion expense) async {
    final id = expense.id.value;
    if (id.isEmpty) throw StateError('An expense id is required before insertion.');
    final inserted = await into(expenses).insert(
      expense.copyWith(tenantId: Value(tenantId)),
    );
    final created = await (select(expenses)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId)))
        .getSingle();
    await _enqueue(created);
    return inserted;
  }

  Future<bool> updateExpense(Expense expense) async {
    if (expense.tenantId != tenantId || expense.deletedAt != null) return false;
    final updated = await (update(expenses)
          ..where((t) => t.id.equals(expense.id) & t.tenantId.equals(tenantId)))
        .write(expense);
    if (updated == 0) return false;
    await _enqueue(expense);
    return true;
  }

  Future<int> deleteExpense(String id) async {
    final now = DateTime.now().toUtc();
    final affected = await (update(expenses)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId)))
        .write(ExpensesCompanion(
      deletedAt: Value(now),
      updatedAt: Value(now),
    ));
    if (affected > 0) {
      final deleted = await (select(expenses)
            ..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId)))
          .getSingleOrNull();
      if (deleted != null) await _enqueue(deleted);
    }
    return affected;
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

  Future<void> _enqueue(Expense expense) {
    return SyncQueueWriter(db).enqueueUpsert(
      tenantId: tenantId,
      entityType: 'expense',
      entityId: expense.id,
      payload: {
        'id': expense.id,
        'tenantId': expense.tenantId,
        'createdAt': expense.createdAt.toUtc().toIso8601String(),
        'updatedAt': expense.updatedAt.toUtc().toIso8601String(),
        'deletedAt': expense.deletedAt?.toUtc().toIso8601String(),
        'version': expense.version,
        'syncStatus': expense.syncStatus,
        'deviceId': expense.deviceId,
        'title': expense.title,
        'amount': expense.amount,
        'expenseDate': expense.expenseDate.toUtc().toIso8601String(),
        'category': expense.category,
        'notes': expense.notes,
      },
    );
  }
}
