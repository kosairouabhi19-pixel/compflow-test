import 'package:drift/drift.dart';
import 'invoices_table.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_queue_writer.dart';

part 'invoices_dao.g.dart';

@DriftAccessor(tables: [Invoices])
class InvoicesDao extends DatabaseAccessor<AppDatabase>
    with _$InvoicesDaoMixin {
  InvoicesDao(super.db);

  Future<List<Invoice>> getAllInvoices(String tenantId) {
    return (select(invoices)
          ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull()))
        .get();
  }

  Stream<List<Invoice>> watchAllInvoices(String tenantId) {
    return (select(invoices)
          ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull()))
        .watch();
  }

  Future<Invoice?> getInvoiceById(String id, String tenantId) {
    return (select(invoices)
          ..where((t) =>
              t.id.equals(id) &
              t.tenantId.equals(tenantId) &
              t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<int> insertInvoice(InvoicesCompanion invoice, String tenantId) async {
    final id = invoice.id.value;
    if (id.isEmpty) throw StateError('An invoice id is required before insertion.');
    final inserted = await into(invoices).insert(
      invoice.copyWith(tenantId: Value(tenantId)),
    );
    final created = await (select(invoices)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId)))
        .getSingle();
    await _enqueue(created, tenantId);
    return inserted;
  }

  Future<bool> updateInvoice(Invoice invoice, String tenantId) async {
    if (invoice.tenantId != tenantId || invoice.deletedAt != null) return false;
    final updated = await (update(invoices)
          ..where((t) => t.id.equals(invoice.id) & t.tenantId.equals(tenantId)))
        .write(invoice);
    if (updated == 0) return false;
    await _enqueue(invoice, tenantId);
    return true;
  }

  Future<int> deleteInvoice(String id, String tenantId) async {
    final now = DateTime.now().toUtc();
    final affected = await (update(invoices)
          ..where((t) =>
              t.id.equals(id) &
              t.tenantId.equals(tenantId) &
              t.deletedAt.isNull()))
        .write(InvoicesCompanion(
      deletedAt: Value(now),
      updatedAt: Value(now),
    ));
    if (affected > 0) {
      final deleted = await (select(invoices)
            ..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId)))
          .getSingleOrNull();
      if (deleted != null) await _enqueue(deleted, tenantId);
    }
    return affected;
  }

  Future<void> _enqueue(Invoice invoice, String tenantId) {
    return SyncQueueWriter(db).enqueueUpsert(
      tenantId: tenantId,
      entityType: 'invoice',
      entityId: invoice.id,
      payload: {
        'id': invoice.id,
        'tenantId': invoice.tenantId,
        'createdAt': invoice.createdAt.toUtc().toIso8601String(),
        'updatedAt': invoice.updatedAt.toUtc().toIso8601String(),
        'deletedAt': invoice.deletedAt?.toUtc().toIso8601String(),
        'version': invoice.version,
        'syncStatus': invoice.syncStatus,
        'deviceId': invoice.deviceId,
        'customerId': invoice.customerId,
        'invoiceNumber': invoice.invoiceNumber,
        'total': invoice.total,
        'paid': invoice.paid,
        'remaining': invoice.remaining,
        'invoiceDate': invoice.invoiceDate.toUtc().toIso8601String(),
        'status': invoice.status,
      },
    );
  }
}
