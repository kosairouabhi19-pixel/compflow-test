import 'package:drift/drift.dart';
import 'invoices_table.dart';
import '../../../core/database/app_database.dart';

part 'invoices_dao.g.dart';

@DriftAccessor(tables: [Invoices])
class InvoicesDao extends DatabaseAccessor<AppDatabase>
    with _$InvoicesDaoMixin {
  InvoicesDao(super.db);

  Future<List<Invoice>> getAllInvoices() {
    return select(invoices).get();
  }

  Stream<List<Invoice>> watchAllInvoices() {
    return select(invoices).watch();
  }

  Future<Invoice?> getInvoiceById(String id) {
    return (select(invoices)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertInvoice(InvoicesCompanion invoice) {
    return into(invoices).insert(invoice);
  }

  Future<bool> updateInvoice(Invoice invoice) {
    return update(invoices).replace(invoice);
  }

  Future<int> deleteInvoice(String id) {
    return (delete(invoices)..where((t) => t.id.equals(id))).go();
  }
}