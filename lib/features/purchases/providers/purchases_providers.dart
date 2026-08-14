import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/providers/products_providers.dart';
import '../database/purchases_dao.dart';
import '../repositories/purchases_repository.dart';

final purchasesDaoProvider = Provider<PurchasesDao>((ref) {
  return PurchasesDao(ref.watch(appDatabaseProvider));
});

final purchasesRepositoryProvider = Provider<PurchasesRepository>((ref) {
  return PurchasesRepository(ref.watch(purchasesDaoProvider));
});