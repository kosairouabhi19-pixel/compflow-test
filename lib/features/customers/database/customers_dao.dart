import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_queue_writer.dart';
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

  Future<int> insertCustomer(CustomersCompanion customer) async {
    final id = customer.id.value;
    if (id.isEmpty) {
      throw StateError('A customer id is required before insertion.');
    }
    final inserted = await into(customers).insert(
      customer.copyWith(tenantId: Value(tenantId)),
    );
    final created = await (select(customers)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId)))
        .getSingle();
    await _enqueue(created);
    return inserted;
  }

  Future<bool> updateCustomer(Customer customer) async {
    if (customer.tenantId != tenantId || customer.deletedAt != null) {
      return false;
    }
    final updated = await (update(customers)
          ..where((t) => t.id.equals(customer.id) & t.tenantId.equals(tenantId)))
        .write(customer);
    if (updated == 0) return false;
    await _enqueue(customer);
    return true;
  }

  Future<int> softDeleteCustomer(String id) async {
    final now = DateTime.now().toUtc();
    final affected = await (update(customers)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId)))
        .write(CustomersCompanion(
      deletedAt: Value(now),
      updatedAt: Value(now),
    ));
    if (affected > 0) {
      final deleted = await (select(customers)
            ..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId)))
          .getSingleOrNull();
      if (deleted != null) await _enqueue(deleted);
    }
    return affected;
  }

  Future<List<Customer>> searchCustomers(String query) {
    return (select(customers)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.deletedAt.isNull() &
              (t.fullName.like('%$query%') | t.phone.like('%$query%'))))
        .get();
  }

  Future<void> _enqueue(Customer customer) {
    return SyncQueueWriter(db).enqueueUpsert(
      tenantId: tenantId,
      entityType: 'customer',
      entityId: customer.id,
      payload: {
        'id': customer.id,
        'tenantId': customer.tenantId,
        'createdAt': customer.createdAt.toUtc().toIso8601String(),
        'updatedAt': customer.updatedAt.toUtc().toIso8601String(),
        'deletedAt': customer.deletedAt?.toUtc().toIso8601String(),
        'version': customer.version,
        'syncStatus': customer.syncStatus,
        'deviceId': customer.deviceId,
        'fullName': customer.fullName,
        'phone': customer.phone,
        'email': customer.email,
        'address': customer.address,
        'notes': customer.notes,
        'isActive': customer.isActive,
      },
    );
  }
}
