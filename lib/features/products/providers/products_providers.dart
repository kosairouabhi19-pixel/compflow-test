import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../auth/providers/auth_providers.dart';
import '../database/products_dao.dart';
import '../repositories/products_repository.dart';

final productsDaoProvider = Provider<ProductsDao>((ref) {
  final tenantId = ref.watch(authControllerProvider).user?.tenantId ?? '';
  return ProductsDao(ref.watch(appDatabaseProvider), tenantId);
});

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(ref.watch(productsDaoProvider));
});

final productsProvider = StreamProvider((ref) {
  return ref.watch(productsRepositoryProvider).watchProducts();
});
