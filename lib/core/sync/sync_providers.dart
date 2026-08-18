import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_providers.dart';
import '../database/database_provider.dart';
import '../network/connectivity_service.dart';
import 'firestore_sync_adapter.dart';
import 'sync_engine.dart';

final syncEngineBootstrapProvider = Provider<void>((ref) {
  final user = ref.watch(authControllerProvider).user;
  if (user == null || user.tenantId.trim().isEmpty) {
    return;
  }

  final database = ref.watch(appDatabaseProvider);
  final connectivity = ConnectivityService();
  final adapter = FirestoreSyncAdapter();
  final engine = SyncEngine();

  unawaited(
    engine
        .initialize(
          database: database,
          connectivity: connectivity,
          processor: adapter.process,
        )
        .then((_) => engine.start()),
  );

  ref.onDispose(() {
    unawaited(engine.stop());
  });
});
