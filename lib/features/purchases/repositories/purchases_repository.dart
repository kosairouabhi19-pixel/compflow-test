import '../../../core/database/app_database.dart';
import '../database/purchases_dao.dart';

class PurchasesRepository {
  final PurchasesDao _dao;

  PurchasesRepository(this._dao);

  Stream<List<Purchase>> watchAllPurchases() {
    return _dao.watchAllPurchases();
  }

  Future<List<Purchase>> getAllPurchases() {
    return _dao.getAllPurchases();
  }

  Future<Purchase?> getPurchaseById(String id) {
    return _dao.getPurchaseById(id);
  }

  Future<int> insertPurchase(PurchasesCompanion purchase) {
    return _dao.insertPurchase(purchase);
  }

  Future<bool> updatePurchase(Purchase purchase) {
    return _dao.updatePurchase(purchase);
  }

  Future<int> deletePurchase(String id) {
    return _dao.deletePurchase(id);
  }
}