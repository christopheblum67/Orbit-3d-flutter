import 'dart:async';

import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
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
    final result = await safeAsync(
      () => Connectivity().checkConnectivity(),
      context: '_initLast',
      fallbackValue: <ConnectivityResult>[ConnectivityResult.none],
    );
    _last = result.valueOrNull!.isNotEmpty ? result.valueOrNull!.first : ConnectivityResult.none;
    notifyListeners();
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
