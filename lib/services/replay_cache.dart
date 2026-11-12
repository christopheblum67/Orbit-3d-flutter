import 'package:orbit_3d_flutter/models/replay_item.dart';

/// Cache partagé des replays, avec expiration : relister les chaînes DVR
/// (get_short_epg) à chaque ouverture de l'écran Replay martèlerait le panel
/// et rendrait l'écran lent (25 chaînes × plusieurs appels).
class ReplaysCache {
  ReplaysCache();

  static const _ttl = Duration(minutes: 5);

  List<ReplayItem>? _all;
  DateTime? _fetchedAt;
  Future<List<ReplayItem>>? _inFlight;
  int _generation = 0;

  bool get isFresh {
    final fetched = _fetchedAt;
    return _all != null &&
        fetched != null &&
        DateTime.now().difference(fetched) < _ttl;
  }

  /// Valeur déjà en cache, SANS déclencher de chargement.
  ///
  /// `replaysProvider` s'en sert pour s'afficher tout de suite avec ce qui a
  /// déjà été sondé, pendant que la sonde tourne en tâche de fond. Appeler
  /// [fetch] ici déclencherait le chargement et rebloquerait l'écran pendant
  /// toute la sonde (jusqu'à 40 chaînes).
  List<ReplayItem>? get peek => isFresh ? _all : null;

  /// Dernière valeur connue, même expirée (stale-while-revalidate) : mieux vaut
  /// afficher des replays un peu anciens que rien pendant le rechargement.
  List<ReplayItem>? get stale => _all;

  /// Renvoie la valeur en cache si fraîche, sinon charge via [loader] (un
  /// seul chargement à la fois, partagé entre tous les appelants).
  Future<List<ReplayItem>> fetch(
    Future<List<ReplayItem>> Function() loader,
  ) {
    if (isFresh) return Future.value(_all!);
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final generation = _generation;
    late final Future<List<ReplayItem>> request;
    request = loader().then(
      (items) {
        if (generation == _generation) {
          _all = items;
          _fetchedAt = DateTime.now();
        }
        if (identical(_inFlight, request)) _inFlight = null;
        return items;
      },
      onError: (Object error, StackTrace stackTrace) {
        if (identical(_inFlight, request)) _inFlight = null;
        throw error;
      },
    );
    _inFlight = request;
    return request;
  }

  void invalidate() {
    _generation++;
    _all = null;
    _fetchedAt = null;
    _inFlight = null;
  }
}

/// Petits cache par chaîne pour le détail Replay.
///
/// Revenir sur une chaîne déjà consultée ne doit pas coûter un appel : le panel
/// est fragile et l'utilisateur alterne entre deux chaînes. TTL court,
/// le cache est vidé au changement d'abonnement.
class ChannelReplaysCache {
  static const _ttl = Duration(minutes: 10);

  final Map<String, List<ReplayItem>> _items = {};
  final Map<String, DateTime> _at = {};
  int _generation = 0;

  int get generation => _generation;

  List<ReplayItem>? peek(String channelId) {
    final at = _at[channelId];
    if (at == null || DateTime.now().difference(at) >= _ttl) return null;
    return _items[channelId];
  }

  void put(String channelId, List<ReplayItem> items) {
    _items[channelId] = items;
    _at[channelId] = DateTime.now();
  }

  void putIfCurrent(
    String channelId,
    List<ReplayItem> items,
    int generation,
  ) {
    if (generation == _generation) put(channelId, items);
  }

  void invalidateChannel(String channelId) {
    _generation++;
    _items.remove(channelId);
    _at.remove(channelId);
  }

  void invalidate() {
    _generation++;
    _items.clear();
    _at.clear();
  }
}
