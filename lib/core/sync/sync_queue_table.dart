import 'package:drift/drift.dart';

class SyncQueueTable extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();

  TextColumn get tenantId => text()();

  TextColumn get entityType => text()();

  TextColumn get entityId => text()();

  TextColumn get operationType => text()();

  TextColumn get payload => text()();

  TextColumn get status => text().withDefault(const Constant('pending'))();

  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}