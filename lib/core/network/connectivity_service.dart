import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._internal() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _connectionStreamController.add(_hasConnection(results));
      },
    );
  }

  static final ConnectivityService _instance = ConnectivityService._internal();

  factory ConnectivityService() => _instance;

  final Connectivity _connectivity = Connectivity();

  late final StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  final StreamController<bool> _connectionStreamController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectionStream => _connectionStreamController.stream;

  Future<bool> isConnected() async {
    final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<void> dispose() async {
    await _connectivitySubscription.cancel();
    await _connectionStreamController.close();
  }
}