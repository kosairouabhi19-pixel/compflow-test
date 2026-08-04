import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'payments_table.dart';

part 'payments_dao.g.dart';

@DriftAccessor(tables: [Payments])
class PaymentsDao extends DatabaseAccessor<AppDatabase>
    with _$PaymentsDaoMixin {
  PaymentsDao(super.db);

  Future<List<Payment>> getAllPayments() => select(payments).get();

  Stream<List<Payment>> watchAllPayments() => select(payments).watch();

  Future<Payment?> getPaymentById(String id) =>
      (select(payments)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertPayment(PaymentsCompanion payment) =>
      into(payments).insert(payment);

  Future<bool> updatePayment(Payment payment) =>
      update(payments).replace(payment);

  Future<int> deletePayment(String id) =>
      (delete(payments)..where((t) => t.id.equals(id))).go();
}