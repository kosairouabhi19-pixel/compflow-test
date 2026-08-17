import '../../../core/database/app_database.dart';
import '../database/payments_dao.dart';

class PaymentsRepository {
  final PaymentsDao _dao;

  PaymentsRepository(this._dao);

  Stream<List<Payment>> watchAllPayments(String tenantId) =>
      _dao.watchAllPayments(tenantId);

  Future<List<Payment>> getAllPayments(String tenantId) =>
      _dao.getAllPayments(tenantId);

  Future<Payment?> getPaymentById(String id, String tenantId) =>
      _dao.getPaymentById(id, tenantId);

  Future<int> insertPayment(PaymentsCompanion payment, String tenantId) =>
      _dao.insertPayment(payment, tenantId);

  Future<bool> updatePayment(Payment payment, String tenantId) =>
      _dao.updatePayment(payment, tenantId);

  Future<int> deletePayment(String id, String tenantId) =>
      _dao.deletePayment(id, tenantId);
}