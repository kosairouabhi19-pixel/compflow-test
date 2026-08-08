import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'sale_items_table.dart';

part 'sale_items_dao.g.dart';

@DriftAccessor(tables: [SaleItems])
class SaleItemsDao extends DatabaseAccessor<AppDatabase>
    with _$SaleItemsDaoMixin {
  SaleItemsDao(super.db);

  Future<int> insertSaleItem(SaleItemsCompanion item) {
    return into(saleItems).insert(item);
  }

  Future<List<SaleItem>> getItemsBySaleId(String saleId) {
    return (select(saleItems)
          ..where((t) => t.saleId.equals(saleId)))
        .get();
  }
}