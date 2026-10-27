import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/providers/providers.dart' show EPGDataCache;

/// Service de résolution EPG optimisé avec cache partagé et résolution parallèle.
///
/// Améliorations vs _resolveChannelEpg :
/// - Cache global XMLTV chargé une seule fois au démarrage
/// - Résolution parallèle de toutes les chaînes (pas séquentielle)
/// - Cache LRU des EPG résolus par chaîne
/// - Invalidation intelligente (TTL 30 min)
class EpgResolverService {
  EpgResolverService._();
  static final EpgResolverService instance = EpgResolverService._();

  final Map<String, List<EPGProgram>> _resolvedCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheTtl = Duration(minutes: 30);

  bool _globalCacheLoaded = false;
  Future<void>? _globalLoadFuture;
  ApiService? _api;
  EPGDataCache? _epgCache;

  /// Initialise le service (à appeler au démarrage de l'app).
  Future<void> initialize(ProviderContainer container) async {
    _api = container.read(apiServiceProvider);
    final epgCache = container.read(epgDataCacheProvider);
    _epgCache = epgCache;

    // Pré-charge le cache XMLTV global en arrière-plan
    _globalLoadFuture = epgCache.loadFull(container.read(apiServiceProvider));
    await _globalLoadFuture;
    _globalCacheLoaded = true;
    LoggerService.instance.info('EPG Resolver: global cache pre-loaded');
  }

  /// Télécharge le dump XMLTV complet depuis le fournisseur si nécessaire.
  Future<void> downloadXmltvIfNeeded({required String baseUrl}) async {
    try {
      final url = '$baseUrl/xmltv.xml';
      final resp = await _api.get(url);
      if (resp.statusCode == 200) {
        await _epgCache!.saveFull(resp.data);
        LoggerService.instance.info('XMLTV téléchargé: $url');
      }
    } catch (e) {
      LoggerService.instance.warn('XMLTV download skipped: $e');
    }
  }

  /// Résout l'EPG pour une liste de chaînes en parallèle.
  ///
  /// Retourne un Map epgChannelId -> List<EPGProgram>.
  Future<Map<String, List<EPGProgram>>> resolveBatch({
    required List<Channel> channels,
    required bool includePast,
    bool allowNetworkFallback = false,
  }) async {
    if (!_globalCacheLoaded) {
      // Si pas encore chargé, on force le chargement
      await _ensureGlobalCache();
    }

    final now = DateTime.now();
    final results = <String, List<EPGProgram>>{};
    final missing = <Channel>[];

    // 1. Vérification rapide du cache mémoire
    for (final channel in channels) {
      final cached = _getCached(channel.primaryEpgChannelId);
      if (cached != null) {
        final filtered = _filterByTime(cached, now, includePast);
        if (filtered.isNotEmpty) {
          results[channel.primaryEpgChannelId] = filtered;
          continue;
        }
      }
      missing.add(channel);
    }

    if (missing.isEmpty) {
      return results;
    }

    // 2. Charge le cache XMLTV global si nécessaire
    await _ensureGlobalCache();

    // 3. Résolution parallèle pour les chaînes manquantes
    final futures = missing.map((channel) => _resolveSingle(
      channel,
      includePast: true,
      allowNetworkFallback: false, // Grille = pas de fallback réseau
    ));

    final resolved = await Future.wait(futures);
    
    for (var i = 0; i < missing.length; i++) {
      final channel = missing[i];
      final programs = resolved[i];
      if (programs.isNotEmpty) {
        _cache(channel.primaryEpgChannelId, programs);
        results[channel.primaryEpgChannelId] = programs;
      }
    }

    return results;
  }

  /// Résout l'EPG pour une seule chaîne (utilisé par la barre de lecture).
  Future<List<EPGProgram>> resolveSingle(String epgChannelId, {
    required bool includePast,
    bool allowNetworkFallback = true,
  }) async {
    if (!_globalCacheLoaded) {
      await _ensureGlobalCache();
    }

    // Vérification cache
    final cached = _getCached(epgChannelId);
    if (cached != null) {
      final now = DateTime.now();
      final filtered = _filterByTime(cached, now, true);
      if (filtered.isNotEmpty) return filtered;
    }

    // Résolution complète
    final channels = _getChannels(); // À implémenter selon le contexte
    final channel = channels.firstWhere(
      (c) => c.primaryEpgChannelId == epgChannelId || c.epgChannelIds.contains(epgChannelId),
      orElse: () => throw ArgumentError('Channel not found for $epgChannelId'),
    );

    return _resolveSingle(
      channel,
      includePast: true,
      allowNetworkFallback: true,
    );
  }

  /// Résolution pour une seule chaîne (interne).
  Future<List<EPGProgram>> _resolveSingle(
    Channel channel, {
    required bool includePast,
    bool allowNetworkFallback = false,
  }) async {
    final epgChannelId = channel.primaryEpgChannelId;

    // 1. Cache mémoire
    final cached = _getCached(epgChannelId);
    if (cached != null) {
      final now = DateTime.now();
      final filtered = _filterByTime(cached, DateTime.now(), includePast);
      if (filtered.isNotEmpty) {
        LoggerService.instance.debug('EPG: cache hit for $epgChannelId');
        return filtered;
      }
    }

    // 2. Cache XMLTV global
    final globalCache = _epgCache;
    if (globalCache != null && globalCache.isFresh) {
      for (final candidate in [channel.id, ...channel.epgChannelIds]) {
        final programs = globalCache.programsForChannel(candidate).toList();
        if (programs.isNotEmpty) {
          final filtered = _filterByTime(programs, DateTime.now(), includePast);
          if (filtered.isNotEmpty) {
            _cache(channel.primaryEpgChannelId, filtered);
            return filtered;
          }
        }
      }
    }

    // 3. Fallback réseau (uniquement si autorisé)
    if (allowNetworkFallback) {
      // TODO: Implémenter fallback réseau get_short_epg si nécessaire
      LoggerService.instance.debug('EPG: network fallback not implemented yet for ${channel.name}');
    }

    return const <EPGProgram>[];
  }

  // --- Cache interne ---

  List<EPGProgram>? _getCached(String epgChannelId) {
    final programs = _resolvedCache[epgChannelId];
    final timestamp = _cacheTimestamps[epgChannelId];
    if (programs != null && timestamp != null) {
      if (DateTime.now().difference(timestamp) < _cacheTtl) {
        return programs;
      }
      // Expiré
      _resolvedCache.remove(epgChannelId);
      _cacheTimestamps.remove(epgChannelId);
    }
    return null;
  }

  void _cache(String epgChannelId, List<EPGProgram> programs) {
    _resolvedCache[epgChannelId] = programs;
    _cacheTimestamps[epgChannelId] = DateTime.now();
  }

  List<EPGProgram> _filterByTime(List<EPGProgram> programs, DateTime now, bool includePast) {
    if (includePast) return programs;
    return programs.where((p) => p.end.isAfter(DateTime(now.year, now.month, now.day))).toList();
  }

  Future<void> _ensureGlobalCache() async {
    if (_globalCacheLoaded) return;
    if (_globalLoadFuture != null) {
      await _globalLoadFuture;
      return;
    }
    // Fallback: charge si pas encore fait
    final epgCache = _epgCache;
    if (epgCache != null) {
      _globalLoadFuture = epgCache.loadFull(_api!);
      await _globalLoadFuture;
      _globalCacheLoaded = true;
    }
  }

  // TODO: À connecter au provider liveChannelsProvider
  List<Channel> _getChannels() => [];

  /// Invalide le cache pour un canal spécifique.
  void invalidate(String epgChannelId) {
    _resolvedCache.remove(epgChannelId);
    _cacheTimestamps.remove(epgChannelId);
  }

  /// Invalide tout le cache.
  void invalidateAll() {
    _resolvedCache.clear();
    _cacheTimestamps.clear();
  }
}

/// Provider pour le service de résolution EPG optimisé.
final epgResolverServiceProvider = Provider<EpgResolverService>((ref) {
  return EpgResolverService.instance;
});

/// Provider pour la résolution par lot (grille EPG).
final epgBatchProvider = FutureProvider.autoDispose.family<
    Map<String, List<EPGProgram>>,
    ({List<Channel> channels, bool includePast})>(
  (ref, params) async {
    final service = ref.read(epgResolverServiceProvider);
    return service.resolveBatch(
      channels: params.channels,
      includePast: params.includePast,
      allowNetworkFallback: false,
    );
  },
);

/// Provider pour une chaîne unique (barre de lecture).
final epgSingleProvider = FutureProvider.autoDispose.family<
    List<EPGProgram>,
    String>(
  (ref, epgChannelId) async {
    final service = ref.read(epgResolverServiceProvider);
    return service.resolveSingle(epgChannelId, includePast: false, allowNetworkFallback: true);
  },
);