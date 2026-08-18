import 'package:cloud_firestore/cloud_firestore.dart';

import 'sync_queue_repository.dart';

/// Sends persistent local changes to Firestore under the authenticated tenant.
/// Remote documents use: tenants/{tenantId}/{collection}/{entityId}
///
/// The adapter is intentionally idempotent and protects newer remote data from
/// being overwritten by an older queued local operation.
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
        await _upsertIfNewer(reference, _sanitizeMap(item.payload));
        return;
      case 'delete':
        await _deleteIfNewer(reference, _sanitizeMap(item.payload));
        return;
      default:
        throw StateError(
          'Unsupported sync operation type: ${item.operationType}',
        );
    }
  }

  Future<void> _upsertIfNewer(
    DocumentReference<Map<String, dynamic>> reference,
    Map<String, dynamic> payload,
  ) async {
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) {
        transaction.set(reference, payload, SetOptions(merge: true));
        return;
      }

      final remote = snapshot.data() ?? const <String, dynamic>{};
      if (_isRemoteNewer(remote, payload)) {
        return;
      }

      transaction.set(reference, payload, SetOptions(merge: true));
    });
  }

  Future<void> _deleteIfNewer(
    DocumentReference<Map<String, dynamic>> reference,
    Map<String, dynamic> payload,
  ) async {
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) {
        return;
      }

      final remote = snapshot.data() ?? const <String, dynamic>{};
      if (_isRemoteNewer(remote, payload)) {
        return;
      }

      transaction.delete(reference);
    });
  }

  bool _isRemoteNewer(
    Map<String, dynamic> remote,
    Map<String, dynamic> local,
  ) {
    final remoteVersion = _asInt(remote['version']);
    final localVersion = _asInt(local['version']);

    if (remoteVersion != null && localVersion != null) {
      return remoteVersion > localVersion;
    }

    final remoteUpdatedAt = _asMillis(remote['updatedAt']);
    final localUpdatedAt = _asMillis(local['updatedAt']);

    if (remoteUpdatedAt != null && localUpdatedAt != null) {
      return remoteUpdatedAt > localUpdatedAt;
    }

    return false;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  int? _asMillis(dynamic value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return DateTime.tryParse(value?.toString() ?? '')?.millisecondsSinceEpoch;
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
