import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityMonitor extends ChangeNotifier {
  ConnectivityMonitor() {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      _last = results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (kDebugMode) {
        debugPrint('ConnectivityMonitor: connectivity changed to $_last');
      }
      notifyListeners();
    });
    _initLast();
  }

  Future<void> _initLast() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _last = results.isNotEmpty ? results.first : ConnectivityResult.none;
      notifyListeners();
    } catch (_) {
      _last = ConnectivityResult.none;
    }
  }

  ConnectivityResult _last = ConnectivityResult.none;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool get isOnline => _last != ConnectivityResult.none;
  ConnectivityResult get current => _last;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
