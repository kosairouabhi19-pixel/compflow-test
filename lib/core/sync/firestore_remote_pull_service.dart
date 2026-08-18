import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Pulls tenant-scoped Firestore data into the local Drift database.
///
/// Remote writes are applied directly to SQLite and marked as `synced`, so a
/// remote change never creates another local sync-queue item.
class FirestoreRemotePullService {
  FirestoreRemotePullService({
    required AppDatabase database,
    FirebaseFirestore? firestore,
  })  : _database = database,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final AppDatabase _database;
  final FirebaseFirestore _firestore;

  static const _collections = <String>[
    'products',
    'customers',
    'sales',
    'sale_items',
    'purchases',
    'expenses',
    'payments',
    'invoices',
    'inventory',
  ];

  Future<void> pullTenant(String tenantId) async {
    final normalizedTenantId = tenantId.trim();
    if (normalizedTenantId.isEmpty) {
      throw StateError('Cannot pull Firestore data without a tenantId.');
    }

    for (final collection in _collections) {
      final snapshot = await _firestore
          .collection('tenants')
          .doc(normalizedTenantId)
          .collection(collection)
          .get();

      for (final document in snapshot.docs) {
        final data = _normalize(document.data());
        data['id'] = document.id;
        data['tenantId'] = normalizedTenantId;
        await _applyDocument(collection, data);
      }
    }
  }

  Future<void> _applyDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    final id = data['id']?.toString();
    final tenantId = data['tenantId']?.toString();
    if (id == null || id.isEmpty || tenantId == null || tenantId.isEmpty) {
      return;
    }

    final local = await _database.customSelect(
      'SELECT version, updated_at FROM $collection '
      'WHERE id = ? AND tenant_id = ? LIMIT 1',
      variables: [Variable.withString(id), Variable.withString(tenantId)],
      readsFrom: {_tableFor(collection)},
    ).getSingleOrNull();

    final remoteVersion = _asInt(data['version']);
    final remoteUpdatedAt = _asDateTime(data['updatedAt']);
    if (local != null) {
      final localVersion = _asInt(local.data['version']);
      final localUpdatedAt = _asDateTime(local.data['updated_at']);
      if (_isLocalNewer(
        localVersion: localVersion,
        remoteVersion: remoteVersion,
        localUpdatedAt: localUpdatedAt,
        remoteUpdatedAt: remoteUpdatedAt,
      )) {
        return;
      }
    }

    final fields = _fieldsFor(collection);
    final values = <Variable>[];
    final placeholders = <String>[];

    for (final field in fields) {
      placeholders.add('?');
      values.add(_variableFor(field, data[_remoteKey(field)]));
    }

    final updates = fields
        .where((field) => field != 'id' && field != 'tenant_id')
        .map((field) => '$field = excluded.$field')
        .join(', ');

    await _database.customStatement(
      'INSERT INTO $collection (${fields.join(', ')}) '
      'VALUES (${placeholders.join(', ')}) '
      'ON CONFLICT(id) DO UPDATE SET $updates '
      'WHERE $collection.tenant_id = excluded.tenant_id',
      values,
    );
  }

  bool _isLocalNewer({
    required int? localVersion,
    required int? remoteVersion,
    required DateTime? localUpdatedAt,
    required DateTime? remoteUpdatedAt,
  }) {
    if (localVersion != null && remoteVersion != null) {
      return localVersion > remoteVersion;
    }
    if (localUpdatedAt != null && remoteUpdatedAt != null) {
      return localUpdatedAt.isAfter(remoteUpdatedAt);
    }
    return false;
  }

  List<String> _fieldsFor(String collection) {
    const base = <String>[
      'id',
      'tenant_id',
      'created_at',
      'updated_at',
      'deleted_at',
      'version',
      'sync_status',
      'device_id',
    ];

    const extras = <String, List<String>>{
      'products': [
        'name', 'sku', 'barcode', 'purchase_price', 'selling_price',
        'quantity', 'minimum_quantity', 'category_id', 'is_active',
      ],
      'customers': [
        'full_name', 'phone', 'email', 'address', 'notes', 'is_active',
      ],
      'sales': [
        'customer_id', 'invoice_number', 'total', 'sale_date', 'notes',
      ],
      'sale_items': [
        'sale_id', 'product_id', 'quantity', 'unit_price', 'total',
      ],
      'purchases': [
        'supplier_id', 'invoice_number', 'total', 'purchase_date', 'notes',
      ],
      'expenses': [
        'title', 'amount', 'expense_date', 'category', 'notes',
      ],
      'payments': [
        'customer_id', 'amount', 'payment_date', 'payment_method', 'notes',
      ],
      'invoices': [
        'customer_id', 'invoice_number', 'total', 'paid', 'remaining',
        'invoice_date', 'status',
      ],
      'inventory': [
        'product_id', 'quantity', 'reserved_quantity', 'minimum_quantity',
        'warehouse',
      ],
    };

    final fields = extras[collection];
    if (fields == null) {
      throw StateError('Unsupported remote collection: $collection');
    }
    return [...base, ...fields];
  }

  String _remoteKey(String field) {
    const keys = <String, String>{
      'id': 'id',
      'tenant_id': 'tenantId',
      'created_at': 'createdAt',
      'updated_at': 'updatedAt',
      'deleted_at': 'deletedAt',
      'version': 'version',
      'sync_status': 'syncStatus',
      'device_id': 'deviceId',
      'purchase_price': 'purchasePrice',
      'selling_price': 'sellingPrice',
      'minimum_quantity': 'minimumQuantity',
      'category_id': 'categoryId',
      'is_active': 'isActive',
      'full_name': 'fullName',
      'customer_id': 'customerId',
      'invoice_number': 'invoiceNumber',
      'sale_date': 'saleDate',
      'sale_id': 'saleId',
      'product_id': 'productId',
      'unit_price': 'unitPrice',
      'supplier_id': 'supplierId',
      'purchase_date': 'purchaseDate',
      'expense_date': 'expenseDate',
      'payment_date': 'paymentDate',
      'payment_method': 'paymentMethod',
      'reserved_quantity': 'reservedQuantity',
      'invoice_date': 'invoiceDate',
    };
    return keys[field] ?? field;
  }

  TableInfo<Table, dynamic> _tableFor(String collection) {
    switch (collection) {
      case 'products':
        return _database.products;
      case 'customers':
        return _database.customers;
      case 'sales':
        return _database.sales;
      case 'sale_items':
        return _database.saleItems;
      case 'purchases':
        return _database.purchases;
      case 'expenses':
        return _database.expenses;
      case 'payments':
        return _database.payments;
      case 'invoices':
        return _database.invoices;
      case 'inventory':
        return _database.inventory;
      default:
        throw StateError('Unsupported remote collection: $collection');
    }
  }

  Variable<Object?> _variableFor(String field, dynamic value) {
    if (value == null) return const Variable(null);
    const dateFields = <String>{
      'created_at', 'updated_at', 'deleted_at', 'sale_date',
      'purchase_date', 'expense_date', 'payment_date', 'invoice_date',
    };
    if (dateFields.contains(field)) {
      final date = _asDateTime(value);
      return Variable.withDateTime(
        date ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    }
    if (value is bool) return Variable.withBool(value);
    if (value is int) return Variable.withInt(value);
    if (value is num) return Variable.withReal(value.toDouble());
    return Variable.withString(value.toString());
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> input) {
    return input.map((key, value) => MapEntry(key, _normalizeValue(value)));
  }

  dynamic _normalizeValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is Map) {
      return value.map(
        (key, nested) => MapEntry(key.toString(), _normalizeValue(nested)),
      );
    }
    if (value is List) return value.map(_normalizeValue).toList();
    return value;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  DateTime? _asDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return DateTime.tryParse(value?.toString() ?? '');
  }
}
