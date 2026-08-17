import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
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

  Future<int> insertPurchase(PurchasesCompanion purchase) {
    return into(purchases).insert(purchase.copyWith(tenantId: Value(tenantId)));
  }

  Future<bool> updatePurchase(Purchase purchase) {
    if (purchase.tenantId != tenantId || purchase.deletedAt != null) {
      return Future.value(false);
    }
    return (update(purchases)
          ..where((t) => t.id.equals(purchase.id) & t.tenantId.equals(tenantId)))
        .write(purchase);
  }

  Future<int> deletePurchase(String id) {
    return (update(purchases)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId)))
        .write(PurchasesCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<List<Purchase>> searchPurchases(String query) {
    return (select(purchases)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.deletedAt.isNull() &
              (t.invoiceNumber.like('%$query%') | t.notes.like('%$query%'))))
        .get();
  }
}