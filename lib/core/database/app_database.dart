import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/products/database/products_table.dart';
import '../../features/customers/database/customers_table.dart';
import '../../features/invoices/database/invoices_table.dart';
import '../sync/sync_queue_table.dart';
import '../../features/inventory/database/inventory_table.dart';
import '../../features/purchases/database/purchases_table.dart';
import '../../features/sales/database/sales_table.dart';
import '../../features/expenses/database/expenses_table.dart';
import '../../features/payments/database/payments_table.dart';
import '../../features/sales/database/sale_items_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    SyncQueueTable,
    Products,
    Customers,
    Invoices,
    Inventory,
    Purchases,
    Sales,
    Expenses,
    Payments,
    SaleItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final Directory directory =
          await getApplicationDocumentsDirectory();

      final File file = File(
        p.join(directory.path, 'compflow.sqlite'),
      );

      return NativeDatabase.createInBackground(file);
    });
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(saleItems);
          }
        },
      );
}