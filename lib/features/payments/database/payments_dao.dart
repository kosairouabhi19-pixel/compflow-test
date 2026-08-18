import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_queue_writer.dart';
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

  Future<int> insertPayment(PaymentsCompanion payment, String tenantId) async {
    final id = payment.id.value;
    if (id.isEmpty) throw StateError('A payment id is required before insertion.');
    final inserted = await into(payments).insert(
      payment.copyWith(tenantId: Value(tenantId)),
    );
    final created = await (select(payments)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId)))
        .getSingle();
    await _enqueue(created, tenantId);
    return inserted;
  }

  Future<bool> updatePayment(Payment payment, String tenantId) async {
    if (payment.tenantId != tenantId || payment.deletedAt != null) return false;
    final updated = await (update(payments)
          ..where((t) => t.id.equals(payment.id) & t.tenantId.equals(tenantId)))
        .write(payment);
    if (updated == 0) return false;
    await _enqueue(payment, tenantId);
    return true;
  }

  Future<int> deletePayment(String id, String tenantId) async {
    final now = DateTime.now().toUtc();
    final affected = await (update(payments)
          ..where((t) =>
              t.id.equals(id) &
              t.tenantId.equals(tenantId) &
              t.deletedAt.isNull()))
        .write(PaymentsCompanion(
      deletedAt: Value(now),
      updatedAt: Value(now),
    ));
    if (affected > 0) {
      final deleted = await (select(payments)
            ..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId)))
          .getSingleOrNull();
      if (deleted != null) await _enqueue(deleted, tenantId);
    }
    return affected;
  }

  Future<void> _enqueue(Payment payment, String tenantId) {
    return SyncQueueWriter(db).enqueueUpsert(
      tenantId: tenantId,
      entityType: 'payment',
      entityId: payment.id,
      payload: {
        'id': payment.id,
        'tenantId': payment.tenantId,
        'createdAt': payment.createdAt.toUtc().toIso8601String(),
        'updatedAt': payment.updatedAt.toUtc().toIso8601String(),
        'deletedAt': payment.deletedAt?.toUtc().toIso8601String(),
        'version': payment.version,
        'syncStatus': payment.syncStatus,
        'deviceId': payment.deviceId,
        'customerId': payment.customerId,
        'amount': payment.amount,
        'paymentDate': payment.paymentDate.toUtc().toIso8601String(),
        'paymentMethod': payment.paymentMethod,
        'notes': payment.notes,
      },
    );
  }
}
