import '../../../core/database/app_database.dart';
import '../database/expenses_dao.dart';

class ExpensesRepository {
  final ExpensesDao _dao;

  ExpensesRepository(this._dao);

  Stream<List<Expense>> watchAllExpenses() => _dao.watchAllExpenses();

  Future<List<Expense>> getAllExpenses() => _dao.getAllExpenses();

  Future<Expense?> getExpenseById(String id) =>
      _dao.getExpenseById(id);

  Future<int> insertExpense(ExpensesCompanion expense) =>
      _dao.insertExpense(expense);

  Future<bool> updateExpense(Expense expense) =>
      _dao.updateExpense(expense);

  Future<int> deleteExpense(String id) =>
      _dao.deleteExpense(id);
}