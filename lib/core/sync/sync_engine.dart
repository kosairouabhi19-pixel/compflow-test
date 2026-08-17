import 'dart:async';

import '../database/app_database.dart';
import '../network/connectivity_service.dart';
import 'sync_queue_repository.dart';

class SyncEngine {
  SyncEngine._internal();

  static final SyncEngine _instance = SyncEngine._internal();

  factory SyncEngine() => _instance;

  bool _isRunning = false;
  bool _isInitialized = false;
  Timer? _timer;
  AppDatabase? _database;
  ConnectivityService? _connectivity;
  StreamSubscription<bool>? _connectionSubscription;
  Future<void> Function(SyncQueueItem item)? _processor;
  Future<void>? _currentSync;

  bool get isRunning => _isRunning;
  bool get isInitialized => _isInitialized;

  Future<void> initialize({
    required AppDatabase database,
    required ConnectivityService connectivity,
    Future<void> Function(SyncQueueItem item)? processor,
  }) async {
    if (_isInitialized) {
      if (processor != null) {
        _processor = processor;
      }
      return;
    }

    _database = database;
    _connectivity = connectivity;
    _processor = processor;

    await SyncQueueRepository(database).resetProcessing();

    _connectionSubscription = connectivity.connectionStream.listen((connected) {
      if (connected && _isRunning) {
        unawaited(syncNow());
      }
    });

    _isInitialized = true;
  }

  Future<void> start({Duration interval = const Duration(seconds: 30)}) async {
    if (!_isInitialized) {
      throw StateError(
        'SyncEngine is not initialized. Call initialize() before start().',
      );
    }

    if (_isRunning) {
      return;
    }

    _isRunning = true;
    _timer = Timer.periodic(interval, (_) => unawaited(syncNow()));
    unawaited(syncNow());
  }

  Future<void> stop() async {
    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    await _currentSync;
  }

  Future<void> syncNow() async {
    if (!_isInitialized) {
      throw StateError(
        'SyncEngine is not initialized. Call initialize() before syncNow().',
      );
    }

    if (_currentSync != null) {
      return _currentSync!;
    }

    final future = _runSync();
    _currentSync = future;

    try {
      await future;
    } finally {
      if (identical(_currentSync, future)) {
        _currentSync = null;
      }
    }
  }

  Future<void> _runSync() async {
    final connected = await _connectivity!.isConnected();
    if (!connected) {
      return;
    }

    final processor = _processor;
    if (processor == null) {
      return;
    }

    final queue = SyncQueueRepository(_database!);
    final items = await queue.getPending();

    for (final item in items) {
      try {
        await queue.markProcessing(item.id);
        await processor(item);
        await queue.markCompleted(item.id);
      } catch (error) {
        await queue.markFailed(item.id, error);
      }
    }
  }

  Future<void> dispose() async {
    await stop();
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _isInitialized = false;
    _database = null;
    _connectivity = null;
    _processor = null;
  }
}
