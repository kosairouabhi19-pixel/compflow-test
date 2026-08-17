import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'customers_table.dart';

part 'customers_dao.g.dart';

@DriftAccessor(tables: [Customers])
class CustomersDao extends DatabaseAccessor<AppDatabase>
    with _$CustomersDaoMixin {
  CustomersDao(super.db, this.tenantId);

  final String tenantId;

  Future<List<Customer>> getAllCustomers() {
    return (select(customers)
          ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull()))
        .get();
  }

  Stream<List<Customer>> watchAllCustomers() {
    return (select(customers)
          ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull()))
        .watch();
  }

  Future<Customer?> getCustomerById(String id) {
    return (select(customers)
          ..where((t) =>
              t.id.equals(id) &
              t.tenantId.equals(tenantId) &
              t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<int> insertCustomer(CustomersCompanion customer) {
    return into(customers).insert(customer.copyWith(tenantId: Value(tenantId)));
  }

  Future<bool> updateCustomer(Customer customer) {
    if (customer.tenantId != tenantId || customer.deletedAt != null) {
      return Future.value(false);
    }

    return (update(customers)
          ..where((t) => t.id.equals(customer.id) & t.tenantId.equals(tenantId)))
        .write(customer);
  }

  Future<int> softDeleteCustomer(String id) {
    return (update(customers)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId)))
        .write(CustomersCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<List<Customer>> searchCustomers(String query) {
    return (select(customers)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.deletedAt.isNull() &
              (t.fullName.like('%$query%') | t.phone.like('%$query%'))))
        .get();
  }
}
