import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../../features/customers/database/customers_table.dart';
import '../../features/products/database/products_table.dart';
import '../../features/sales/database/sales_table.dart';
import '../../features/sales/database/sale_items_table.dart';

/// Pulls remote tenant data into the local database without creating new
/// outbound queue entries. Remote data only wins when it is newer than local
/// data, preventing an older cloud snapshot from overwriting offline edits.
class FirestoreRemoteSync {
  FirestoreRemoteSync({
    required AppDatabase database,
    FirebaseFirestore? firestore,
  })  : _database = database,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final AppDatabase _database;
  final FirebaseFirestore _firestore;

  Future<void> pullTenant(String tenantId) async {
    if (tenantId.trim().isEmpty) {
      throw StateError('Cannot pull remote data without a tenantId.');
    }

    await Future.wait([
      _pullProducts(tenantId),
      _pullCustomers(tenantId),
      _pullSales(tenantId),
      _pullSaleItems(tenantId),
    ]);
  }

  Future<void> _pullProducts(String tenantId) async {
    final snapshot = await _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('products')
        .get();

    final dao = ProductsDao(_database, tenantId);
    for (final document in snapshot.docs) {
      final data = document.data();
      final remote = _productCompanion(document.id, tenantId, data);
      final local = await dao.getProductById(document.id);

      if (local != null && !_isRemoteNewer(data, local.updatedAt, local.version)) {
        continue;
      }

      await _database.into(_database.products).insertOnConflictUpdate(remote);
    }
  }

  Future<void> _pullCustomers(String tenantId) async {
    final snapshot = await _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('customers')
        .get();

    final dao = CustomersDao(_database, tenantId);
    for (final document in snapshot.docs) {
      final data = document.data();
      final remote = _customerCompanion(document.id, tenantId, data);
      final local = await dao.getCustomerById(document.id);

      if (local != null && !_isRemoteNewer(data, local.updatedAt, local.version)) {
        continue;
      }

      await _database.into(_database.customers).insertOnConflictUpdate(remote);
    }
  }

  Future<void> _pullSales(String tenantId) async {
    final snapshot = await _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('sales')
        .get();

    for (final document in snapshot.docs) {
      final data = document.data();
      final remote = _saleCompanion(document.id, tenantId, data);
      final local = await (_database.select(_database.sales)
            ..where((table) => table.id.equals(document.id) & table.tenantId.equals(tenantId)))
          .getSingleOrNull();

      if (local != null && !_isRemoteNewer(data, local.updatedAt, local.version)) {
        continue;
      }

      await _database.into(_database.sales).insertOnConflictUpdate(remote);
    }
  }

  Future<void> _pullSaleItems(String tenantId) async {
    final snapshot = await _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('saleItems')
        .get();

    for (final document in snapshot.docs) {
      final data = document.data();
      final remote = _saleItemCompanion(document.id, tenantId, data);
      final local = await (_database.select(_database.saleItems)
            ..where((table) => table.id.equals(document.id) & table.tenantId.equals(tenantId)))
          .getSingleOrNull();

      if (local != null && !_isRemoteNewer(data, local.updatedAt, local.version)) {
        continue;
      }

      await _database.into(_database.saleItems).insertOnConflictUpdate(remote);
    }
  }

  ProductsCompanion _productCompanion(
    String id,
    String tenantId,
    Map<String, dynamic> data,
  ) {
    return ProductsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      createdAt: Value(_date(data['createdAt']) ?? DateTime.now().toUtc()),
      updatedAt: Value(_date(data['updatedAt']) ?? DateTime.now().toUtc()),
      deletedAt: Value(_date(data['deletedAt'])),
      version: Value(_int(data['version'], 1)),
      syncStatus: const Value('synced'),
      deviceId: Value((data['deviceId'] ?? '').toString()),
      name: Value((data['name'] ?? '').toString()),
      sku: Value((data['sku'] ?? '').toString()),
      barcode: Value(_nullableString(data['barcode'])),
      purchasePrice: Value(_double(data['purchasePrice'])),
      sellingPrice: Value(_double(data['sellingPrice'])),
      quantity: Value(_int(data['quantity'], 0)),
      minimumQuantity: Value(_int(data['minimumQuantity'], 0)),
      categoryId: Value(_nullableString(data['categoryId'])),
      isActive: Value(data['isActive'] != false),
    );
  }

  CustomersCompanion _customerCompanion(
    String id,
    String tenantId,
    Map<String, dynamic> data,
  ) {
    return CustomersCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      createdAt: Value(_date(data['createdAt']) ?? DateTime.now().toUtc()),
      updatedAt: Value(_date(data['updatedAt']) ?? DateTime.now().toUtc()),
      deletedAt: Value(_date(data['deletedAt'])),
      version: Value(_int(data['version'], 1)),
      syncStatus: const Value('synced'),
      deviceId: Value((data['deviceId'] ?? '').toString()),
      fullName: Value((data['fullName'] ?? '').toString()),
      phone: Value((data['phone'] ?? '').toString()),
      email: Value(_nullableString(data['email'])),
      address: Value(_nullableString(data['address'])),
      notes: Value(_nullableString(data['notes'])),
      isActive: Value(data['isActive'] != false),
    );
  }

  SalesCompanion _saleCompanion(
    String id,
    String tenantId,
    Map<String, dynamic> data,
  ) {
    return SalesCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      createdAt: Value(_date(data['createdAt']) ?? DateTime.now().toUtc()),
      updatedAt: Value(_date(data['updatedAt']) ?? DateTime.now().toUtc()),
      deletedAt: Value(_date(data['deletedAt'])),
      version: Value(_int(data['version'], 1)),
      syncStatus: const Value('synced'),
      deviceId: Value((data['deviceId'] ?? '').toString()),
      customerId: Value((data['customerId'] ?? '').toString()),
      invoiceNumber: Value((data['invoiceNumber'] ?? '').toString()),
      total: Value(_double(data['total'])),
      saleDate: Value(_date(data['saleDate']) ?? DateTime.now().toUtc()),
      notes: Value(_nullableString(data['notes'])),
    );
  }

  SaleItemsCompanion _saleItemCompanion(
    String id,
    String tenantId,
    Map<String, dynamic> data,
  ) {
    return SaleItemsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      createdAt: Value(_date(data['createdAt']) ?? DateTime.now().toUtc()),
      updatedAt: Value(_date(data['updatedAt']) ?? DateTime.now().toUtc()),
      deletedAt: Value(_date(data['deletedAt'])),
      version: Value(_int(data['version'], 1)),
      syncStatus: const Value('synced'),
      deviceId: Value((data['deviceId'] ?? '').toString()),
      saleId: Value((data['saleId'] ?? '').toString()),
      productId: Value((data['productId'] ?? '').toString()),
      quantity: Value(_int(data['quantity'], 0)),
      unitPrice: Value(_double(data['unitPrice'])),
      total: Value(_double(data['total'])),
    );
  }

  bool _isRemoteNewer(
    Map<String, dynamic> data,
    DateTime localUpdatedAt,
    int localVersion,
  ) {
    final remoteUpdatedAt = _date(data['updatedAt']);
    final remoteVersion = _int(data['version'], 1);
    if (remoteUpdatedAt == null) return remoteVersion > localVersion;
    if (remoteUpdatedAt.isAfter(localUpdatedAt)) return true;
    if (remoteUpdatedAt.isBefore(localUpdatedAt)) return false;
    return remoteVersion > localVersion;
  }

  DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    return null;
  }

  int _int(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String? _nullableString(dynamic value) {
    final string = value?.toString();
    return string == null || string.isEmpty ? null : string;
  }
}
