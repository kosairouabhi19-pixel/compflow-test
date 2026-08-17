import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'payments_table.dart';

part 'payments_dao.g.dart';

@DriftAccessor(tables: [Payments])
class PaymentsDao extends DatabaseAccessor<AppDatabase>
    with _$PaymentsDaoMixin {
  PaymentsDao(super.db);

  Future<List<Payment>> getAllPayments(String tenantId) {
    return (select(payments)
          ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull()))
        .get();
  }

  Stream<List<Payment>> watchAllPayments(String tenantId) {
    return (select(payments)
          ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull()))
        .watch();
  }

  Future<Payment?> getPaymentById(String id, String tenantId) {
    return (select(payments)
          ..where((t) =>
              t.id.equals(id) &
              t.tenantId.equals(tenantId) &
              t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<int> insertPayment(PaymentsCompanion payment, String tenantId) {
    return into(payments).insert(
      payment.copyWith(tenantId: Value(tenantId)),
    );
  }

  Future<bool> updatePayment(Payment payment, String tenantId) {
    if (payment.tenantId != tenantId || payment.deletedAt != null) {
      return Future.value(false);
    }
    return update(payments).replace(payment);
  }

  Future<int> deletePayment(String id, String tenantId) {
    return (update(payments)
          ..where((t) =>
              t.id.equals(id) &
              t.tenantId.equals(tenantId) &
              t.deletedAt.isNull()))
        .write(
      PaymentsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}