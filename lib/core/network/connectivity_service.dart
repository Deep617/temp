import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((result) {
      return result != ConnectivityResult.none;
    });
  }

  Future<bool> isConnected() async {
    final Connectivity connectivity = Connectivity();

    final result = await connectivity.checkConnectivity();

    return result != ConnectivityResult.none;
  }
}
