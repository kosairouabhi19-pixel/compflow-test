import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'customers_table.dart';

part 'customers_dao.g.dart';

@DriftAccessor(tables: [Customers])
class CustomersDao extends DatabaseAccessor<AppDatabase>
    with _$CustomersDaoMixin {
  CustomersDao(super.db);

  Future<List<Customer>> getAllCustomers() {
    return select(customers).get();
  }

  Stream<List<Customer>> watchAllCustomers() {
    return select(customers).watch();
  }

  Future<Customer?> getCustomerById(String id) {
    return (select(customers)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertCustomer(CustomersCompanion customer) {
    return into(customers).insert(customer);
  }

  Future<bool> updateCustomer(Customer customer) {
    return update(customers).replace(customer);
  }

  Future<int> deleteCustomer(String id) {
    return (delete(customers)..where((t) => t.id.equals(id))).go();
  }

  Future<List<Customer>> searchCustomers(String query) {
    return (select(customers)
          ..where((t) => t.fullName.like('%$query%')))
        .get();
  }
}