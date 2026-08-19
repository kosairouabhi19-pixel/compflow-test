import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../../features/customers/database/customers_dao.dart';
import '../../features/customers/database/customers_table.dart';
import '../../features/expenses/database/expenses_table.dart';
import '../../features/inventory/database/inventory_table.dart';
import '../../features/invoices/database/invoices_table.dart';
import '../../features/payments/database/payments_table.dart';
import '../../features/products/database/products_dao.dart';
import '../../features/products/database/products_table.dart';
import '../../features/purchases/database/purchases_table.dart';
import '../../features/sales/database/sales_table.dart';
import '../../features/sales/database/sale_items_table.dart';

class FirestoreRemoteSync {
  FirestoreRemoteSync({required AppDatabase database, FirebaseFirestore? firestore}) : _database = database, _firestore = firestore ?? FirebaseFirestore.instance;
  final AppDatabase _database;
  final FirebaseFirestore _firestore;

  Future<void> pullTenant(String tenantId) async {
    final id = tenantId.trim();
    if (id.isEmpty) throw StateError('Cannot pull remote data without a tenantId.');
    await Future.wait([
      _pullProducts(id), _pullCustomers(id), _pullSales(id), _pullSaleItems(id),
      _pullPurchases(id), _pullExpenses(id), _pullPayments(id), _pullInvoices(id), _pullInventory(id),
    ]);
  }

  CollectionReference<Map<String, dynamic>> _collection(String tenantId, String name) => _firestore.collection('tenants').doc(tenantId).collection(name);

  bool _shouldAcceptRemote(dynamic local) {
    // Never overwrite a local change that has not reached Firestore yet.
    // The outbound sync queue owns pending/failed changes; remote pull must
    // not silently destroy them just because the remote version is newer.
    return local == null || local.syncStatus == 'synced';
  }

  Future<void> _pullProducts(String tenantId) async {
    final snapshot = await _collection(tenantId, 'products').get();
    final dao = ProductsDao(_database, tenantId);
    for (final d in snapshot.docs) {
      final data = d.data(); final local = await dao.getProductById(d.id);
      if (!_shouldAcceptRemote(local)) continue;
      if (local != null && !_isRemoteNewer(data, local.updatedAt, local.version)) continue;
      await _database.into(_database.products).insertOnConflictUpdate(_productCompanion(d.id, tenantId, data));
    }
  }

  Future<void> _pullCustomers(String tenantId) async {
    final snapshot = await _collection(tenantId, 'customers').get();
    final dao = CustomersDao(_database, tenantId);
    for (final d in snapshot.docs) {
      final data = d.data(); final local = await dao.getCustomerById(d.id);
      if (!_shouldAcceptRemote(local)) continue;
      if (local != null && !_isRemoteNewer(data, local.updatedAt, local.version)) continue;
      await _database.into(_database.customers).insertOnConflictUpdate(_customerCompanion(d.id, tenantId, data));
    }
  }

  Future<void> _pullSales(String tenantId) async {
    final snapshot = await _collection(tenantId, 'sales').get();
    for (final d in snapshot.docs) {
      final data = d.data(); final local = await (_database.select(_database.sales)..where((t) => t.id.equals(d.id) & t.tenantId.equals(tenantId))).getSingleOrNull();
      if (!_shouldAcceptRemote(local)) continue;
      if (local != null && !_isRemoteNewer(data, local.updatedAt, local.version)) continue;
      await _database.into(_database.sales).insertOnConflictUpdate(_saleCompanion(d.id, tenantId, data));
    }
  }

  Future<void> _pullSaleItems(String tenantId) async {
    final snapshot = await _collection(tenantId, 'saleItems').get();
    for (final d in snapshot.docs) {
      final data = d.data(); final local = await (_database.select(_database.saleItems)..where((t) => t.id.equals(d.id) & t.tenantId.equals(tenantId))).getSingleOrNull();
      if (!_shouldAcceptRemote(local)) continue;
      if (local != null && !_isRemoteNewer(data, local.updatedAt, local.version)) continue;
      await _database.into(_database.saleItems).insertOnConflictUpdate(_saleItemCompanion(d.id, tenantId, data));
    }
  }

  Future<void> _pullPurchases(String tenantId) async {
    final snapshot = await _collection(tenantId, 'purchases').get();
    for (final d in snapshot.docs) {
      final data = d.data(); final local = await (_database.select(_database.purchases)..where((t) => t.id.equals(d.id) & t.tenantId.equals(tenantId))).getSingleOrNull();
      if (!_shouldAcceptRemote(local)) continue;
      if (local != null && !_isRemoteNewer(data, local.updatedAt, local.version)) continue;
      await _database.into(_database.purchases).insertOnConflictUpdate(PurchasesCompanion(id: Value(d.id), tenantId: Value(tenantId), createdAt: Value(_date(data['createdAt']) ?? DateTime.now().toUtc()), updatedAt: Value(_date(data['updatedAt']) ?? DateTime.now().toUtc()), deletedAt: Value(_date(data['deletedAt'])), version: Value(_int(data['version'], 1)), syncStatus: const Value('synced'), deviceId: Value(_string(data['deviceId'])), supplierId: Value(_string(data['supplierId'])), invoiceNumber: Value(_string(data['invoiceNumber'])), total: Value(_double(data['total'])), purchaseDate: Value(_date(data['purchaseDate']) ?? DateTime.now().toUtc()), notes: Value(_nullableString(data['notes']))));
    }
  }

  Future<void> _pullExpenses(String tenantId) async {
    final snapshot = await _collection(tenantId, 'expenses').get();
    for (final d in snapshot.docs) {
      final data = d.data(); final local = await (_database.select(_database.expenses)..where((t) => t.id.equals(d.id) & t.tenantId.equals(tenantId))).getSingleOrNull();
      if (!_shouldAcceptRemote(local)) continue;
      if (local != null && !_isRemoteNewer(data, local.updatedAt, local.version)) continue;
      await _database.into(_database.expenses).insertOnConflictUpdate(ExpensesCompanion(id: Value(d.id), tenantId: Value(tenantId), createdAt: Value(_date(data['createdAt']) ?? DateTime.now().toUtc()), updatedAt: Value(_date(data['updatedAt']) ?? DateTime.now().toUtc()), deletedAt: Value(_date(data['deletedAt'])), version: Value(_int(data['version'], 1)), syncStatus: const Value('synced'), deviceId: Value(_string(data['deviceId'])), title: Value(_string(data['title'])), amount: Value(_double(data['amount'])), expenseDate: Value(_date(data['expenseDate']) ?? DateTime.now().toUtc()), category: Value(_nullableString(data['category'])), notes: Value(_nullableString(data['notes']))));
    }
  }

  Future<void> _pullPayments(String tenantId) async {
    final snapshot = await _collection(tenantId, 'payments').get();
    for (final d in snapshot.docs) {
      final data = d.data(); final local = await (_database.select(_database.payments)..where((t) => t.id.equals(d.id) & t.tenantId.equals(tenantId))).getSingleOrNull();
      if (!_shouldAcceptRemote(local)) continue;
      if (local != null && !_isRemoteNewer(data, local.updatedAt, local.version)) continue;
      await _database.into(_database.payments).insertOnConflictUpdate(PaymentsCompanion(id: Value(d.id), tenantId: Value(tenantId), createdAt: Value(_date(data['createdAt']) ?? DateTime.now().toUtc()), updatedAt: Value(_date(data['updatedAt']) ?? DateTime.now().toUtc()), deletedAt: Value(_date(data['deletedAt'])), version: Value(_int(data['version'], 1)), syncStatus: const Value('synced'), deviceId: Value(_string(data['deviceId'])), customerId: Value(_string(data['customerId'])), amount: Value(_double(data['amount'])), paymentDate: Value(_date(data['paymentDate']) ?? DateTime.now().toUtc()), paymentMethod: Value(_string(data['paymentMethod'])), notes: Value(_nullableString(data['notes']))));
    }
  }

  Future<void> _pullInvoices(String tenantId) async {
    final snapshot = await _collection(tenantId, 'invoices').get();
    for (final d in snapshot.docs) {
      final data = d.data(); final local = await (_database.select(_database.invoices)..where((t) => t.id.equals(d.id) & t.tenantId.equals(tenantId))).getSingleOrNull();
      if (!_shouldAcceptRemote(local)) continue;
      if (local != null && !_isRemoteNewer(data, local.updatedAt, local.version)) continue;
      await _database.into(_database.invoices).insertOnConflictUpdate(InvoicesCompanion(id: Value(d.id), tenantId: Value(tenantId), createdAt: Value(_date(data['createdAt']) ?? DateTime.now().toUtc()), updatedAt: Value(_date(data['updatedAt']) ?? DateTime.now().toUtc()), deletedAt: Value(_date(data['deletedAt'])), version: Value(_int(data['version'], 1)), syncStatus: const Value('synced'), deviceId: Value(_string(data['deviceId'])), customerId: Value(_string(data['customerId'])), invoiceNumber: Value(_string(data['invoiceNumber'])), total: Value(_double(data['total'])), paid: Value(_double(data['paid'])), remaining: Value(_double(data['remaining'])), invoiceDate: Value(_date(data['invoiceDate']) ?? DateTime.now().toUtc()), status: Value(_string(data['status'], 'unpaid'))));
    }
  }

  Future<void> _pullInventory(String tenantId) async {
    final snapshot = await _collection(tenantId, 'inventory').get();
    for (final d in snapshot.docs) {
      final data = d.data(); final local = await (_database.select(_database.inventory)..where((t) => t.id.equals(d.id) & t.tenantId.equals(tenantId))).getSingleOrNull();
      if (!_shouldAcceptRemote(local)) continue;
      if (local != null && !_isRemoteNewer(data, local.updatedAt, local.version)) continue;
      await _database.into(_database.inventory).insertOnConflictUpdate(InventoryCompanion(id: Value(d.id), tenantId: Value(tenantId), createdAt: Value(_date(data['createdAt']) ?? DateTime.now().toUtc()), updatedAt: Value(_date(data['updatedAt']) ?? DateTime.now().toUtc()), deletedAt: Value(_date(data['deletedAt'])), version: Value(_int(data['version'], 1)), syncStatus: const Value('synced'), deviceId: Value(_string(data['deviceId'])), productId: Value(_string(data['productId'])), quantity: Value(_int(data['quantity'], 0)), reservedQuantity: Value(_int(data['reservedQuantity'], 0)), minimumQuantity: Value(_int(data['minimumQuantity'], 0)), warehouse: Value(_nullableString(data['warehouse']))));
    }
  }

  ProductsCompanion _productCompanion(String id, String tenantId, Map<String, dynamic> data) => ProductsCompanion(id: Value(id), tenantId: Value(tenantId), createdAt: Value(_date(data['createdAt']) ?? DateTime.now().toUtc()), updatedAt: Value(_date(data['updatedAt']) ?? DateTime.now().toUtc()), deletedAt: Value(_date(data['deletedAt'])), version: Value(_int(data['version'], 1)), syncStatus: const Value('synced'), deviceId: Value(_string(data['deviceId'])), name: Value(_string(data['name'])), sku: Value(_string(data['sku'])), barcode: Value(_nullableString(data['barcode'])), purchasePrice: Value(_double(data['purchasePrice'])), sellingPrice: Value(_double(data['sellingPrice'])), quantity: Value(_int(data['quantity'], 0)), minimumQuantity: Value(_int(data['minimumQuantity'], 0)), categoryId: Value(_nullableString(data['categoryId'])), isActive: Value(data['isActive'] != false));
  CustomersCompanion _customerCompanion(String id, String tenantId, Map<String, dynamic> data) => CustomersCompanion(id: Value(id), tenantId: Value(tenantId), createdAt: Value(_date(data['createdAt']) ?? DateTime.now().toUtc()), updatedAt: Value(_date(data['updatedAt']) ?? DateTime.now().toUtc()), deletedAt: Value(_date(data['deletedAt'])), version: Value(_int(data['version'], 1)), syncStatus: const Value('synced'), deviceId: Value(_string(data['deviceId'])), fullName: Value(_string(data['fullName'])), phone: Value(_string(data['phone'])), email: Value(_nullableString(data['email'])), address: Value(_nullableString(data['address'])), notes: Value(_nullableString(data['notes'])), isActive: Value(data['isActive'] != false));
  SalesCompanion _saleCompanion(String id, String tenantId, Map<String, dynamic> data) => SalesCompanion(id: Value(id), tenantId: Value(tenantId), createdAt: Value(_date(data['createdAt']) ?? DateTime.now().toUtc()), updatedAt: Value(_date(data['updatedAt']) ?? DateTime.now().toUtc()), deletedAt: Value(_date(data['deletedAt'])), version: Value(_int(data['version'], 1)), syncStatus: const Value('synced'), deviceId: Value(_string(data['deviceId'])), customerId: Value(_string(data['customerId'])), invoiceNumber: Value(_string(data['invoiceNumber'])), total: Value(_double(data['total'])), saleDate: Value(_date(data['saleDate']) ?? DateTime.now().toUtc()), notes: Value(_nullableString(data['notes'])));
  SaleItemsCompanion _saleItemCompanion(String id, String tenantId, Map<String, dynamic> data) => SaleItemsCompanion(id: Value(id), tenantId: Value(tenantId), createdAt: Value(_date(data['createdAt']) ?? DateTime.now().toUtc()), updatedAt: Value(_date(data['updatedAt']) ?? DateTime.now().toUtc()), deletedAt: Value(_date(data['deletedAt'])), version: Value(_int(data['version'], 1)), syncStatus: const Value('synced'), deviceId: Value(_string(data['deviceId'])), saleId: Value(_string(data['saleId'])), productId: Value(_string(data['productId'])), quantity: Value(_int(data['quantity'], 0)), unitPrice: Value(_double(data['unitPrice'])), total: Value(_double(data['total'])));

  bool _isRemoteNewer(Map<String, dynamic> data, DateTime localUpdatedAt, int localVersion) { final remoteUpdatedAt = _date(data['updatedAt']); final remoteVersion = _int(data['version'], 1); if (remoteUpdatedAt == null) return remoteVersion > localVersion; if (remoteUpdatedAt.isAfter(localUpdatedAt)) return true; if (remoteUpdatedAt.isBefore(localUpdatedAt)) return false; return remoteVersion > localVersion; }
  DateTime? _date(dynamic value) { if (value is Timestamp) return value.toDate().toUtc(); if (value is DateTime) return value.toUtc(); if (value is String) return DateTime.tryParse(value)?.toUtc(); return null; }
  int _int(dynamic value, int fallback) { if (value is int) return value; if (value is num) return value.toInt(); return int.tryParse(value?.toString() ?? '') ?? fallback; }
  double _double(dynamic value) { if (value is num) return value.toDouble(); return double.tryParse(value?.toString() ?? '') ?? 0; }
  String _string(dynamic value, [String fallback = '']) => value?.toString() ?? fallback;
  String? _nullableString(dynamic value) { final s = value?.toString(); return s == null || s.isEmpty ? null : s; }
}
