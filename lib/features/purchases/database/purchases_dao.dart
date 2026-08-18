import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_queue_writer.dart';
import 'purchases_table.dart';

part 'purchases_dao.g.dart';

@DriftAccessor(tables: [Purchases])
class PurchasesDao extends DatabaseAccessor<AppDatabase>
    with _$PurchasesDaoMixin {
  PurchasesDao(super.db, this.tenantId);

  final String tenantId;

  Future<List<Purchase>> getAllPurchases() {
    return (select(purchases)
          ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull()))
        .get();
  }

  Stream<List<Purchase>> watchAllPurchases() {
    return (select(purchases)
          ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull()))
        .watch();
  }

  Future<Purchase?> getPurchaseById(String id) {
    return (select(purchases)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId) & t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<int> insertPurchase(PurchasesCompanion purchase) async {
    final id = purchase.id.value;
    if (id.isEmpty) throw StateError('A purchase id is required before insertion.');
    final inserted = await into(purchases).insert(
      purchase.copyWith(tenantId: Value(tenantId)),
    );
    final created = await (select(purchases)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId)))
        .getSingle();
    await _enqueue(created);
    return inserted;
  }

  Future<bool> updatePurchase(Purchase purchase) async {
    if (purchase.tenantId != tenantId || purchase.deletedAt != null) return false;
    final updated = await (update(purchases)
          ..where((t) => t.id.equals(purchase.id) & t.tenantId.equals(tenantId)))
        .write(purchase);
    if (updated == 0) return false;
    await _enqueue(purchase);
    return true;
  }

  Future<int> deletePurchase(String id) async {
    final now = DateTime.now().toUtc();
    final affected = await (update(purchases)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId)))
        .write(PurchasesCompanion(
      deletedAt: Value(now),
      updatedAt: Value(now),
    ));
    if (affected > 0) {
      final deleted = await (select(purchases)
            ..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId)))
          .getSingleOrNull();
      if (deleted != null) await _enqueue(deleted);
    }
    return affected;
  }

  Future<List<Purchase>> searchPurchases(String query) {
    return (select(purchases)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.deletedAt.isNull() &
              (t.invoiceNumber.like('%$query%') | t.notes.like('%$query%'))))
        .get();
  }

  Future<void> _enqueue(Purchase purchase) {
    return SyncQueueWriter(db).enqueueUpsert(
      tenantId: tenantId,
      entityType: 'purchase',
      entityId: purchase.id,
      payload: {
        'id': purchase.id,
        'tenantId': purchase.tenantId,
        'createdAt': purchase.createdAt.toUtc().toIso8601String(),
        'updatedAt': purchase.updatedAt.toUtc().toIso8601String(),
        'deletedAt': purchase.deletedAt?.toUtc().toIso8601String(),
        'version': purchase.version,
        'syncStatus': purchase.syncStatus,
        'deviceId': purchase.deviceId,
        'supplierId': purchase.supplierId,
        'invoiceNumber': purchase.invoiceNumber,
        'total': purchase.total,
        'purchaseDate': purchase.purchaseDate.toUtc().toIso8601String(),
        'notes': purchase.notes,
      },
    );
  }
}
