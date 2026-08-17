import '../database/invoices_dao.dart';
import '../../../core/database/app_database.dart';

class InvoicesRepository {
  final InvoicesDao _dao;

  InvoicesRepository(this._dao);

  Stream<List<Invoice>> watchAllInvoices(String tenantId) {
    return _dao.watchAllInvoices(tenantId);
  }

  Future<List<Invoice>> getAllInvoices(String tenantId) {
    return _dao.getAllInvoices(tenantId);
  }

  Future<Invoice?> getInvoiceById(String id, String tenantId) {
    return _dao.getInvoiceById(id, tenantId);
  }

  Future<int> insertInvoice(InvoicesCompanion invoice, String tenantId) {
    return _dao.insertInvoice(invoice, tenantId);
  }

  Future<bool> updateInvoice(Invoice invoice, String tenantId) {
    return _dao.updateInvoice(invoice, tenantId);
  }

  Future<int> deleteInvoice(String id, String tenantId) {
    return _dao.deleteInvoice(id, tenantId);
  }
}