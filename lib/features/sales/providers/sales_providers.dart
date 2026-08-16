import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../database/sales_dao.dart';
import '../database/sale_items_dao.dart';
import '../repositories/sales_repository.dart';

final salesDaoProvider = Provider<SalesDao>((ref) {
  return SalesDao(ref.watch(appDatabaseProvider));
});

final saleItemsDaoProvider = Provider<SaleItemsDao>((ref) {
  return SaleItemsDao(ref.watch(appDatabaseProvider));
});

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository(
    ref.watch(salesDaoProvider),
  );
});
