import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../database/customers_dao.dart';
import '../repositories/customers_repository.dart';

final customersDaoProvider = Provider<CustomersDao>((ref) {
  return CustomersDao(ref.watch(appDatabaseProvider));
});

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  return CustomersRepository(
    ref.watch(customersDaoProvider),
  );
});

final customersProvider = StreamProvider<List<Customer>>((ref) {
  return ref.watch(customersRepositoryProvider).watchAllCustomers();
});
