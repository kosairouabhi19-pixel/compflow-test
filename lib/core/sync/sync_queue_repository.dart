import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';

class SyncQueueRepository {
  SyncQueueRepository(this._database);

  final AppDatabase _database;

  static const int maxRetryCount = 8;
  static const int _baseRetryDelaySeconds = 30;
  static const int _maxRetryDelaySeconds = 30 * 60;

  Future<void> enqueue({
    required String id,
    required String tenantId,
    required String entityType,
    required String entityId,
    required String operationType,
    required Map<String, dynamic> payload,
  }) async {
    final now = DateTime.now().toUtc();

    await _database.customStatement(
      '''
      INSERT OR REPLACE INTO sync_queue_table
      (id, tenant_id, entity_type, entity_id, operation_type, payload,
       status, retry_count, created_at, updated_at, last_error)
      VALUES (?, ?, ?, ?, ?, ?, 'pending', 0, ?, ?, NULL)
      ''',
      [
        id,
        tenantId,
        entityType,
        entityId,
        operationType,
        jsonEncode(payload),
        now.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      ],
    );
  }

  Future<List<SyncQueueItem>> getPending({int limit = 25}) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final rows = await _database.customSelect(
      '''
      SELECT id, tenant_id, entity_type, entity_id, operation_type,
             payload, status, retry_count, created_at, updated_at, last_error
      FROM sync_queue_table
      WHERE status IN ('pending', 'failed')
        AND retry_count < ?
        AND (
          status = 'pending'
          OR updated_at <= ?
        )
      ORDER BY created_at ASC
      LIMIT ?
      ''',
      variables: [
        Variable.withInt(maxRetryCount),
        Variable.withInt(now),
        Variable.withInt(limit),
      ],
    ).get();

    final items = rows.map(SyncQueueItem.fromRow).toList();
    return items.where((item) {
      if (item.status != 'failed') return true;
      final delaySeconds = _retryDelaySeconds(item.retryCount);
      return DateTime.now().toUtc().difference(item.updatedAt).inSeconds >=
          delaySeconds;
    }).toList();
  }

  int _retryDelaySeconds(int retryCount) {
    if (retryCount <= 0) return _baseRetryDelaySeconds;
    final exponent = retryCount - 1;
    final delay = _baseRetryDelaySeconds * (1 << exponent);
    return delay > _maxRetryDelaySeconds ? _maxRetryDelaySeconds : delay;
  }

  Future<void> markProcessing(String id) async {
    await _updateStatus(id, 'processing');
  }

  Future<void> markCompleted(String id) async {
    await _database.customStatement(
      '''
      UPDATE sync_queue_table
      SET status = 'completed', updated_at = ?, last_error = NULL
      WHERE id = ?
      ''',
      [DateTime.now().toUtc().millisecondsSinceEpoch, id],
    );
  }

  Future<void> markFailed(String id, Object error) async {
    await _database.customStatement(
      '''
      UPDATE sync_queue_table
      SET status = 'failed', retry_count = retry_count + 1,
          updated_at = ?, last_error = ?
      WHERE id = ?
      ''',
      [DateTime.now().toUtc().millisecondsSinceEpoch, error.toString(), id],
    );
  }

  Future<void> resetProcessing() async {
    await _database.customStatement(
      '''
      UPDATE sync_queue_table
      SET status = 'pending', updated_at = ?
      WHERE status = 'processing'
      ''',
      [DateTime.now().toUtc().millisecondsSinceEpoch],
    );
  }

  Future<int> pendingCount() async {
    final row = await _database.customSelect(
      '''
      SELECT COUNT(*) AS count
      FROM sync_queue_table
      WHERE status IN ('pending', 'failed')
        AND retry_count < ?
      ''',
      variables: [Variable.withInt(maxRetryCount)],
    ).getSingle();

    return row.read<int>('count');
  }

  Future<void> _updateStatus(String id, String status) async {
    await _database.customStatement(
      'UPDATE sync_queue_table SET status = ?, updated_at = ? WHERE id = ?',
      [status, DateTime.now().toUtc().millisecondsSinceEpoch, id],
    );
  }
}

class SyncQueueItem {
  const SyncQueueItem({
    required this.id,
    required this.tenantId,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.payload,
    required this.status,
    required this.retryCount,
    required this.createdAt,
    required this.updatedAt,
    this.lastError,
  });

  final String id;
  final String tenantId;
  final String entityType;
  final String entityId;
  final String operationType;
  final Map<String, dynamic> payload;
  final String status;
  final int retryCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastError;

  factory SyncQueueItem.fromRow(TypedResult row) {
    final payloadString = row.read<String>('payload');

    return SyncQueueItem(
      id: row.read<String>('id'),
      tenantId: row.read<String>('tenant_id'),
      entityType: row.read<String>('entity_type'),
      entityId: row.read<String>('entity_id'),
      operationType: row.read<String>('operation_type'),
      payload: Map<String, dynamic>.from(
        jsonDecode(payloadString) as Map,
      ),
      status: row.read<String>('status'),
      retryCount: row.read<int>('retry_count'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('created_at'),
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('updated_at'),
        isUtc: true,
      ),
      lastError: row.readNullable<String>('last_error'),
    );
  }
}
