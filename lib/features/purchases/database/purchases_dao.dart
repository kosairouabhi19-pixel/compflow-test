import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'purchases_table.dart';

part 'purchases_dao.g.dart';

@DriftAccessor(tables: [Purchases])
class PurchasesDao extends DatabaseAccessor<AppDatabase>
    with _$PurchasesDaoMixin {
  PurchasesDao(super.db);

  Future<List<Purchase>> getAllPurchases() {
    return select(purchases).get();
  }

  Stream<List<Purchase>> watchAllPurchases() {
    return select(purchases).watch();
  }

  Future<Purchase?> getPurchaseById(String id) {
    return (select(purchases)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertPurchase(PurchasesCompanion purchase) {
    return into(purchases).insert(purchase);
  }

  Future<bool> updatePurchase(Purchase purchase) {
    return update(purchases).replace(purchase);
  }

  Future<int> deletePurchase(String id) {
    return (delete(purchases)..where((t) => t.id.equals(id))).go();
  }
}