import 'package:drift/drift.dart';

import '../../../core/database/base_table.dart';

class Customers extends BaseTable {
  TextColumn get fullName => text()();

  TextColumn get phone => text()();

  TextColumn get email => text().nullable()();

  TextColumn get address => text().nullable()();

  TextColumn get notes => text().nullable()();

  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();
}