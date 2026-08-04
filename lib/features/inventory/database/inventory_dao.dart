import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'inventory_table.dart';

part 'inventory_dao.g.dart';

@DriftAccessor(tables: [Inventory])
class InventoryDao extends DatabaseAccessor<AppDatabase>
    with _$InventoryDaoMixin {
  InventoryDao(super.db);

  Future<List<InventoryData>> getAllInventory() {
    return select(inventory).get();
  }

  Stream<List<InventoryData>> watchAllInventory() {
    return select(inventory).watch();
  }

  Future<InventoryData?> getById(String id) {
    return (select(inventory)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertItem(InventoryCompanion item) {
    return into(inventory).insert(item);
  }

  Future<bool> updateItem(InventoryData item) {
    return update(inventory).replace(item);
  }

  Future<int> deleteItem(String id) {
    return (delete(inventory)..where((t) => t.id.equals(id))).go();
  }
}