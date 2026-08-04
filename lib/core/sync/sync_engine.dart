class SyncEngine {
  SyncEngine._internal();

  static final SyncEngine _instance = SyncEngine._internal();

  factory SyncEngine() => _instance;

  bool _isRunning = false;
  bool _isInitialized = false;

  bool get isRunning => _isRunning;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _isInitialized = true;
  }

  Future<void> start() async {
    if (!_isInitialized) {
      throw StateError(
        'SyncEngine is not initialized. Call initialize() before start().',
      );
    }

    if (_isRunning) {
      return;
    }

    _isRunning = true;
  }

  Future<void> stop() async {
    if (!_isRunning) {
      return;
    }

    _isRunning = false;
  }

  Future<void> syncNow() async {
    if (!_isInitialized) {
      throw StateError(
        'SyncEngine is not initialized. Call initialize() before syncNow().',
      );
    }
  }
}