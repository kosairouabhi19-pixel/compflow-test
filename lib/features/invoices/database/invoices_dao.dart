import 'package:drift/drift.dart';
import 'invoices_table.dart';
import '../../../core/database/app_database.dart';

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

  Future<int> insertInvoice(InvoicesCompanion invoice, String tenantId) {
    return into(invoices).insert(
      invoice.copyWith(tenantId: Value(tenantId)),
    );
  }

  Future<bool> updateInvoice(Invoice invoice, String tenantId) {
    if (invoice.tenantId != tenantId || invoice.deletedAt != null) {
      return Future.value(false);
    }
    return update(invoices).replace(invoice);
  }

  Future<int> deleteInvoice(String id, String tenantId) {
    return (update(invoices)
          ..where((t) =>
              t.id.equals(id) &
              t.tenantId.equals(tenantId) &
              t.deletedAt.isNull()))
        .write(
      InvoicesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}