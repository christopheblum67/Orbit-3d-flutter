import 'dart:async';

import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityMonitor extends ChangeNotifier {
  ConnectivityMonitor() {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      if (_disposed) return;
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
    // Le moniteur a pu être détruit pendant l'appel asynchrone (sortie d'écran,
    // tests) : notifier alors levait
    // « A ConnectivityMonitor was used after being disposed ».
    if (_disposed) return;
    final values = result.valueOrNull ?? const <ConnectivityResult>[];
    _last = values.isNotEmpty ? values.first : ConnectivityResult.none;
    notifyListeners();
  }

  ConnectivityResult _last = ConnectivityResult.none;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _disposed = false;

  bool get isOnline => _last != ConnectivityResult.none;
  ConnectivityResult get current => _last;

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _sub = null;
    super.dispose();
  }
}
