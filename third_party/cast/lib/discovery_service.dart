import 'dart:async';

import 'package:bonsoir/bonsoir.dart';

import 'device.dart';

const _domain = '_googlecast._tcp';

class CastDiscoveryService {
  static final CastDiscoveryService _instance = CastDiscoveryService._();
  CastDiscoveryService._();

  factory CastDiscoveryService() {
    return _instance;
  }

  Future<List<CastDevice>> search({Duration timeout = const Duration(seconds: 5)}) async {
    final results = <CastDevice>[];

    final discovery = BonsoirDiscovery(type: _domain);
    await discovery.initialize();

    discovery.eventStream!.listen((event) {
      if (event is BonsoirDiscoveryServiceFoundEvent) {
        discovery.serviceResolver.resolveService(event.service);
      } else if (event is BonsoirDiscoveryServiceResolvedEvent) {
        final service = event.service;
        if (service.attributes.isEmpty) {
          return;
        }

        final port = service.port;
        final host = service.hostAddress ?? service.hostname;

        String name = [
          service.attributes['md'],
          service.attributes['fn'],
        ].whereType<String>().join(' - ');
        if (name.isEmpty) {
          name = service.name;
        }

        if (port == null || host == null) {
          return;
        }

        results.add(
          CastDevice(
            serviceName: service.name,
            name: name,
            port: port,
            host: host,
            extras: service.attributes,
          ),
        );
      }
    }, onError: (error) {
      print('[CastDiscoveryService] error ${error.runtimeType} - $error');
    });

    await discovery.start();
    await Future.delayed(timeout);
    await discovery.stop();

    return results.toSet().toList();
  }
}