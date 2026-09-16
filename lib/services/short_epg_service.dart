import 'dart:async';

import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';

/// Chargeur d'EPG court pour une chaîne (injectable pour les tests).
typedef ChannelEpgLoader = Future<List<EPGProgram>> Function(Channel channel);

/// Cache en mémoire, borné et horodaté, des guides courts par chaîne (S4).
///
/// La précharge 7 jours passe par `get_short_epg` par chaîne : les résultats
/// sont conservés ici (TTL 30 min, cap de chaînes gardées) pour éviter de
/// marteler le panel à chaque ouverture de l'écran EPG.
class ShortEpgCache {
  ShortEpgCache({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  static const Duration ttl = Duration(minutes: 30);
  static const int maxChannels = 256;

  final Map<String, List<EPGProgram>> _byChannel = {};
  final Map<String, DateTime> _fetchedAt = {};

  /// Programmes en cache et frais d'une chaîne, sinon null.
  List<EPGProgram>? programsFor(String channelId) {
    final at = _fetchedAt[channelId];
    if (at == null || !_byChannel.containsKey(channelId)) return null;
    if (_now().difference(at) >= ttl) {
      _byChannel.remove(channelId);
      _fetchedAt.remove(channelId);
      return null;
    }
    return _byChannel[channelId];
  }

  bool isFresh(String channelId) => programsFor(channelId) != null;

  void put(String channelId, List<EPGProgram> programs, {DateTime? at}) {
    _byChannel[channelId] = programs;
    _fetchedAt[channelId] = at ?? _now();
    // Borne mémoire : évince les chaînes les plus anciennes au-delà du cap.
    while (_byChannel.length > maxChannels) {
      String? oldest;
      DateTime? oldestAt;
      for (final e in _fetchedAt.entries) {
        if (oldestAt == null || e.value.isBefore(oldestAt)) {
          oldest = e.key;
          oldestAt = e.value;
        }
      }
      if (oldest == null) break;
      _byChannel.remove(oldest);
      _fetchedAt.remove(oldest);
    }
  }

  void invalidate(String channelId) {
    _byChannel.remove(channelId);
    _fetchedAt.remove(channelId);
  }

  int get size => _byChannel.length;
}

/// Précharge 7 jours des guides courts par chaîne, exécutée en arrière-plan
/// avec un parallélisme borné (évite de saturer le panel Xtream).
class EpgPreloadService {
  EpgPreloadService({
    ShortEpgCache? cache,
    this.concurrency = 4,
  }) : cache = cache ?? ShortEpgCache();

  final ShortEpgCache cache;
  final int concurrency;

  /// Remplit le cache pour [channels]. Ne refait pas les chaînes déjà fraîches.
  /// Retourne le nombre de chaînes effectivement préchargées.
  Future<int> preload(List<Channel> channels, ChannelEpgLoader loader) async {
    var loaded = 0;
    var index = 0;
    while (index < channels.length) {
      final batch =
          channels.skip(index).take(concurrency).toList();
      await Future.wait([
        for (final channel in batch)
          _preloadOne(channel, loader).then((ok) {
            if (ok) loaded++;
          }),
      ]);
      index += concurrency;
    }
    return loaded;
  }

  Future<bool> _preloadOne(Channel channel, ChannelEpgLoader loader) async {
    if (channel.epgChannelId.isEmpty) return false;
    if (cache.isFresh(channel.epgChannelId)) return false;
    final List<EPGProgram> programs;
    try {
      programs = await loader(channel);
    } catch (_) {
      return false;
    }
    if (programs.isEmpty) return false;
    cache.put(channel.epgChannelId, programs);
    return true;
  }
}