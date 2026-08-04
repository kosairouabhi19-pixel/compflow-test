import '../database/invoices_dao.dart';
import '../../../core/database/app_database.dart';

class InvoicesRepository {
  final InvoicesDao _dao;

  InvoicesRepository(this._dao);

  Stream<List<Invoice>> watchAllInvoices() {
    return _dao.watchAllInvoices();
  }

  Future<List<Invoice>> getAllInvoices() {
    return _dao.getAllInvoices();
  }

  Future<Invoice?> getInvoiceById(String id) {
    return _dao.getInvoiceById(id);
  }

  Future<int> insertInvoice(InvoicesCompanion invoice) {
    return _dao.insertInvoice(invoice);
  }

  Future<bool> updateInvoice(Invoice invoice) {
    return _dao.updateInvoice(invoice);
  }

  Future<int> deleteInvoice(String id) {
    return _dao.deleteInvoice(id);
  }
}