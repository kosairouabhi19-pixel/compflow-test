import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/providers/current_tenant_provider.dart';
import '../database/purchases_dao.dart';
import '../repositories/purchases_repository.dart';

final purchasesDaoProvider = Provider<PurchasesDao>((ref) {
  final tenantId = ref.watch(currentTenantProvider);
  if (tenantId == null) {
    throw StateError('لا يوجد متجر حالي للمستخدم');
  }
  return PurchasesDao(ref.watch(appDatabaseProvider), tenantId);
});

final purchasesRepositoryProvider = Provider<PurchasesRepository>((ref) {
  return PurchasesRepository(ref.watch(purchasesDaoProvider));
});