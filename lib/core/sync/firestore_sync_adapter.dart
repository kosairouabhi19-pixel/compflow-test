import 'package:cloud_firestore/cloud_firestore.dart';

import 'sync_queue_repository.dart';

/// Bridges the local persistent sync queue to Firestore.
///
/// Remote documents are always scoped below the tenant document:
/// tenants/{tenantId}/{collection}/{entityId}
class FirestoreSyncAdapter {
  FirestoreSyncAdapter({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const Map<String, String> _collections = {
    'product': 'products',
    'products': 'products',
    'customer': 'customers',
    'customers': 'customers',
    'sale': 'sales',
    'sales': 'sales',
    'sale_item': 'sale_items',
    'sale_items': 'sale_items',
    'purchase': 'purchases',
    'purchases': 'purchases',
    'expense': 'expenses',
    'expenses': 'expenses',
    'payment': 'payments',
    'payments': 'payments',
    'invoice': 'invoices',
    'invoices': 'invoices',
    'inventory': 'inventory',
  };

  Future<void> process(SyncQueueItem item) async {
    final collection = _collections[item.entityType.toLowerCase()];
    if (collection == null) {
      throw StateError('Unsupported sync entity type: ${item.entityType}');
    }

    if (item.tenantId.trim().isEmpty) {
      throw StateError('Cannot sync without a tenantId.');
    }

    if (item.entityId.trim().isEmpty) {
      throw StateError('Cannot sync without an entityId.');
    }

    final reference = _firestore
        .collection('tenants')
        .doc(item.tenantId)
        .collection(collection)
        .doc(item.entityId);

    switch (item.operationType.toLowerCase()) {
      case 'create':
      case 'insert':
      case 'update':
      case 'upsert':
        await reference.set(
          _sanitizeMap(item.payload),
          SetOptions(merge: true),
        );
        return;
      case 'delete':
        await reference.delete();
        return;
      default:
        throw StateError(
          'Unsupported sync operation type: ${item.operationType}',
        );
    }
  }

  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> input) {
    return input.map((key, value) => MapEntry(key, _sanitizeValue(value)));
  }

  dynamic _sanitizeValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(key.toString(), _sanitizeValue(nestedValue)),
      );
    }
    if (value is List) {
      return value.map(_sanitizeValue).toList();
    }
    return value;
  }
}
