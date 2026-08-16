import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Shared Drift database instance for the whole application.
///
/// Feature providers must use this provider instead of creating their own
/// AppDatabase instance. Multiple database instances can point at the same
/// SQLite file and cause duplicated connections, stale streams, and locking
/// problems.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();

  ref.onDispose(db.close);

  return db;
});
