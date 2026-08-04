import '../../../core/database/app_database.dart';
import '../database/customers_dao.dart';

class CustomersRepository {
  final CustomersDao _dao;

  CustomersRepository(this._dao);

  Stream<List<Customer>> watchAllCustomers() {
    return _dao.watchAllCustomers();
  }

  Future<List<Customer>> getAllCustomers() {
    return _dao.getAllCustomers();
  }

  Future<Customer?> getCustomerById(String id) {
    return _dao.getCustomerById(id);
  }

  Future<void> insertCustomer(CustomersCompanion customer) async {
    await _dao.insertCustomer(customer);
  }

  Future<void> updateCustomer(Customer customer) async {
    await _dao.updateCustomer(customer);
  }

  Future<void> deleteCustomer(String id) async {
    await _dao.deleteCustomer(id);
  }

  Future<List<Customer>> searchCustomers(String query) {
    return _dao.searchCustomers(query);
  }
}