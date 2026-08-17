import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/providers/current_tenant_provider.dart';
import '../database/sales_dao.dart';
import '../database/sale_items_dao.dart';
import '../repositories/sales_repository.dart';

final salesDaoProvider = Provider<SalesDao>((ref) {
  final tenantId = ref.watch(currentTenantProvider);
  if (tenantId == null) {
    throw StateError('لا يمكن الوصول إلى المبيعات بدون متجر حالي');
  }
  return SalesDao(ref.watch(appDatabaseProvider), tenantId);
});

final saleItemsDaoProvider = Provider<SaleItemsDao>((ref) {
  final tenantId = ref.watch(currentTenantProvider);
  if (tenantId == null) {
    throw StateError('لا يمكن الوصول إلى عناصر المبيعات بدون متجر حالي');
  }
  return SaleItemsDao(ref.watch(appDatabaseProvider), tenantId);
});

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository(
    ref.watch(salesDaoProvider),
  );
});
