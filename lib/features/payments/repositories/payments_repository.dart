import '../../../core/database/app_database.dart';
import '../database/payments_dao.dart';

class PaymentsRepository {
  final PaymentsDao _dao;

  PaymentsRepository(this._dao);

  Stream<List<Payment>> watchAllPayments() => _dao.watchAllPayments();

  Future<List<Payment>> getAllPayments() => _dao.getAllPayments();

  Future<Payment?> getPaymentById(String id) => _dao.getPaymentById(id);

  Future<int> insertPayment(PaymentsCompanion payment) =>
      _dao.insertPayment(payment);

  Future<bool> updatePayment(Payment payment) =>
      _dao.updatePayment(payment);

  Future<int> deletePayment(String id) =>
      _dao.deletePayment(id);
}