import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum NetKind { offline, metered, unmetered }

/// Tracks whether the device is on Wi-Fi (unmetered), mobile data or offline.
class NetworkStatus extends ChangeNotifier {
  NetworkStatus._();
  static final NetworkStatus instance = NetworkStatus._();

  NetKind _kind = NetKind.unmetered;
  NetKind get kind => _kind;
  bool get online => _kind != NetKind.offline;
  bool get unmetered => _kind == NetKind.unmetered;
  StreamSubscription? _sub;

  Future<void> init() async {
    try {
      _apply(await Connectivity().checkConnectivity());
      _sub = Connectivity().onConnectivityChanged.listen(_apply);
    } catch (_) {
      _kind = NetKind.unmetered; // platforms without the plugin: assume online
    }
  }

  void _apply(List<ConnectivityResult> r) {
    final k = r.contains(ConnectivityResult.wifi) || r.contains(ConnectivityResult.ethernet)
        ? NetKind.unmetered
        : r.contains(ConnectivityResult.mobile) || r.contains(ConnectivityResult.vpn) || r.contains(ConnectivityResult.other)
            ? NetKind.metered
            : NetKind.offline;
    if (k != _kind) {
      _kind = k;
      notifyListeners();
    }
  }

  @visibleForTesting
  void debugSet(NetKind k) {
    _kind = k;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
