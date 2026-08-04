import '../../../core/database/app_database.dart';
import '../database/inventory_dao.dart';

class InventoryRepository {
  final InventoryDao _dao;

  InventoryRepository(this._dao);

  Stream<List<InventoryData>> watchAllInventory() {
    return _dao.watchAllInventory();
  }

  Future<List<InventoryData>> getAllInventory() {
    return _dao.getAllInventory();
  }

  Future<InventoryData?> getById(String id) {
    return _dao.getById(id);
  }

  Future<int> insertItem(InventoryCompanion item) {
    return _dao.insertItem(item);
  }

  Future<bool> updateItem(InventoryData item) {
    return _dao.updateItem(item);
  }

  Future<int> deleteItem(String id) {
    return _dao.deleteItem(id);
  }
}