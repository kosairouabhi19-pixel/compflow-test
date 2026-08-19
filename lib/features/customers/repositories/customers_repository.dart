import '../../../core/database/app_database.dart';
import '../database/customers_dao.dart';

class CustomersRepository {
  final CustomersDao _dao;

  CustomersRepository(this._dao);

  Stream<List<Customer>> watchAllCustomers() => _dao.watchAllCustomers();
  Future<List<Customer>> getAllCustomers() => _dao.getAllCustomers();
  Future<Customer?> getCustomerById(String id) => _dao.getCustomerById(id);
  Future<void> insertCustomer(CustomersCompanion customer) async => _dao.insertCustomer(customer);
  Future<void> updateCustomer(Customer customer) async => _dao.updateCustomer(customer);
  Future<void> deleteCustomer(String id) async => _dao.softDeleteCustomer(id);
  Future<List<Customer>> searchCustomers(String query) => _dao.searchCustomers(query);
}
