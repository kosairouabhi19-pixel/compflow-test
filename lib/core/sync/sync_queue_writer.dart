import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import 'sync_queue_repository.dart';

class SyncQueueWriter {
  SyncQueueWriter(this.db);

  final AppDatabase db;
  static const Uuid _uuid = Uuid();

  Future<void> enqueueUpsert({
    required String tenantId,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) {
    return SyncQueueRepository(db).enqueue(
      id: _uuid.v4(),
      tenantId: tenantId,
      entityType: entityType,
      entityId: entityId,
      operationType: 'upsert',
      payload: payload,
    );
  }

  Future<void> enqueueDelete({
    required String tenantId,
    required String entityType,
    required String entityId,
  }) {
    return SyncQueueRepository(db).enqueue(
      id: _uuid.v4(),
      tenantId: tenantId,
      entityType: entityType,
      entityId: entityId,
      operationType: 'delete',
      payload: const {},
    );
  }
}
