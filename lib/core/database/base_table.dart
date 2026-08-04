import 'package:drift/drift.dart';

abstract class BaseTable extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();

  TextColumn get tenantId => text()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get deletedAt => dateTime().nullable()();

  IntColumn get version => integer().withDefault(const Constant(1))();

  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  TextColumn get deviceId => text()();

  @override
  Set<Column> get primaryKey => {id};
}