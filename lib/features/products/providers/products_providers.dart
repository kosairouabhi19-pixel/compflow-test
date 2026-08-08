import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../database/products_dao.dart';
import '../repositories/products_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();

  ref.onDispose(db.close);

  return db;
});

final productsDaoProvider = Provider<ProductsDao>((ref) {
  return ProductsDao(ref.watch(appDatabaseProvider));
});

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(ref.watch(productsDaoProvider));
});

final productsProvider = StreamProvider((ref) {
  return ref.watch(productsRepositoryProvider).watchProducts();
});