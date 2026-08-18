import 'package:cloud_firestore/cloud_firestore.dart';

import '../database/app_database.dart';
import '../network/connectivity_service.dart';
import 'firestore_remote_sync.dart';
import 'firestore_sync_adapter.dart';
import 'sync_engine.dart';

/// Owns the application-level sync dependencies.
///
/// The database and connectivity service are singletons for the lifetime of
/// the process, while the engine remains the existing singleton engine.
class SyncBootstrap {
  SyncBootstrap._();

  static final SyncBootstrap instance = SyncBootstrap._();

  AppDatabase? _database;
  ConnectivityService? _connectivity;
  FirestoreSyncAdapter? _adapter;

  Future<void> start() async {
    if (_database != null) {
      return;
    }

    final database = AppDatabase();
    final connectivity = ConnectivityService();
    final adapter = FirestoreSyncAdapter(
      firestore: FirebaseFirestore.instance,
    );

    _database = database;
    _connectivity = connectivity;
    _adapter = adapter;

    final engine = SyncEngine();
    await engine.initialize(
      database: database,
      connectivity: connectivity,
      processor: adapter.process,
    );
    await engine.start();
  }

  Future<void> pullTenant(String tenantId) async {
    final database = _database;
    if (database == null) {
      await start();
    }

    await FirestoreRemoteSync(
      database: _database!,
      firestore: FirebaseFirestore.instance,
    ).pullTenant(tenantId);
  }

  Future<void> stop() async {
    await SyncEngine().dispose();
    _database = null;
    _connectivity = null;
    _adapter = null;
  }
}
