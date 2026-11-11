import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/epg_fallback_budget_provider.dart';
import 'package:orbit_3d_flutter/providers/catalog_providers.dart';
import 'package:orbit_3d_flutter/providers/core_providers.dart';
import 'package:orbit_3d_flutter/providers/subscription_provider.dart';
import 'package:orbit_3d_flutter/services/channel_epg_resolver.dart';
import 'package:orbit_3d_flutter/services/epg_data_cache.dart';
import 'package:orbit_3d_flutter/services/progressive_epg.dart';
import 'package:orbit_3d_flutter/services/short_epg_service.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    as stream_helpers;

final epgProgramsProvider =
    AsyncNotifierProvider<EPGProgramsNotifier, List<EPGProgram>>(
  EPGProgramsNotifier.new,
);

final epgDataCacheProvider = Provider<EPGDataCache>((ref) {
  final cache = EPGDataCache(
    allowedChannelKeys: () {
      final channels = ref.read(liveChannelsProvider).value;
      if (channels == null || channels.isEmpty) return null;
      return <String>{
        for (final c in channels) ...[
          EPGDataCache.normalizeKey(c.id),
          for (final id in c.epgChannelIds) EPGDataCache.normalizeKey(id),
        ],
      };
    },
  );
  var disposed = false;
  ref.onDispose(() => disposed = true);
  cache.onRevalidated = () {
    if (!disposed) ref.invalidate(epgProgramsProvider);
  };
  return cache;
});

/// Cache des guides courts (get_short_epg) + service de précharge 7 jours (S4).
final shortEpgCacheProvider = Provider<ShortEpgCache>((ref) => ShortEpgCache());
final epgPreloadServiceProvider = Provider<EpgPreloadService>(
  (ref) => EpgPreloadService(cache: ref.watch(shortEpgCacheProvider)),
);

/// EPG d'une chaîne (par son `epg_channel_id` ou son `stream_id`).
///
/// Hydratation à la demande : on interroge `get_short_epg` pour **cette**
/// chaîne au lieu de télécharger le dump XMLTV global (~48 h, plusieurs Mo).
/// Le résultat est mis en cache 30 min par [ShortEpgCache].
/// Renvoie une liste vide si aucun programme à venir n'est disponible.
/// Corps de résolution de l'EPG d'une chaîne, partagé par deux providers.
///
/// [includePast] change ce que l'on garde, pas la SOURCE :
/// - `false` (barre du lecteur, bouton de zapping) : uniquement ce qui est en
///   cours ou à venir ;
/// - `true` (grille EPG) : tout, passé compris.
///
/// [allowNetworkFallback] autorise le repli réseau (`get_short_epg`) **uniquement
/// pour l'usage « fiche chaîne unique »** (barre du lecteur, zapping).
/// La grille (`channelEpgWindowProvider`) passe `false` : elle ne doit JAMAIS
/// déclencher de requête réseau, l'index XMLTV suffit. Cela évite les 429 qui
/// saturaient le panel et cassaient l'expiration / les catégories.
Future<List<EPGProgram>> _resolveChannelEpg(
  Ref ref,
  String epgChannelId, {
  required bool includePast,
  bool allowNetworkFallback = true,
}) async {
  if (epgChannelId.isEmpty) return const <EPGProgram>[];

  final cache = ref.watch(shortEpgCacheProvider);
  return const ChannelEpgResolver().resolve(
    channelId: epgChannelId,
    includePast: includePast,
    allowNetworkFallback: allowNetworkFallback,
    cache: cache,
    prepareSources: () {
      // Capture synchrone avant toute attente : le provider est autoDispose.
      final api = ref.read(apiServiceProvider);
      final globalCache = ref.watch(epgDataCacheProvider);
      final budget = ref.watch(epgFallbackBudgetProvider);
      final channels =
          ref.read(liveChannelsProvider).value ?? const <Channel>[];
      return ChannelEpgSources(
        channels: channels,
        budget: budget,
        loadFull: () async {
          await globalCache.loadFull(api);
        },
        programsForChannel: globalCache.programsForChannel,
        fetchShort: api.fetchChannelEpgPrograms,
      );
    },
  );
}

/// EPG d'une chaîne pour la barre du lecteur : uniquement « en cours » et
/// « à venir ». Voir [channelEpgWindowProvider] pour la grille.
///
/// Cette entrée **autorise le repli réseau** : c'est l'usage « fiche chaîne
/// unique » pour lequel `get_short_epg` a été conçu (une chaîne, 4 entrées).
final channelEpgProvider =
    FutureProvider.autoDispose.family<List<EPGProgram>, String>(
  (ref, epgChannelId) => _resolveChannelEpg(
    ref,
    epgChannelId,
    includePast: false,
    allowNetworkFallback: true,
  ),
);

final _shortEpgRequestGateProvider = Provider<ShortEpgRequestGate>(
  (ref) => ShortEpgRequestGate(),
);

/// Aperçu de la chaîne sélectionnée : guide court puis guide global complet.
final channelPreviewEpgProvider =
    StreamProvider.autoDispose.family<List<EPGProgram>, Channel>(
  (ref, channel) {
    final api = ref.read(apiServiceProvider);
    final subscription = ref.watch(activeSubscriptionProvider);
    final cache = ref.watch(epgDataCacheProvider);
    final shortCache = ref.watch(shortEpgCacheProvider);
    final budget = ref.watch(epgFallbackBudgetProvider);
    final gate = ref.read(_shortEpgRequestGateProvider);
    final cached = shortCache.get(channel.id);
    final now = DateTime.now();
    final cachedUpcoming =
        cached == null ? null : upcomingEpgPrograms(cached, now);
    final candidates = <String>{
      ...channel.epgChannelIds,
      if (channel.id.isNotEmpty) channel.id,
    };

    return progressiveEpg(
      cachedShort: cache.isFresh &&
              candidates.any(
                (id) => upcomingEpgPrograms(
                  cache.programsForChannel(id),
                  now,
                ).isNotEmpty,
              )
          ? null
          : cachedUpcoming,
      loadFull: () async {
        await cache.loadFull(api);
        for (final id in candidates) {
          final programs = upcomingEpgPrograms(
            cache.programsForChannel(id),
            DateTime.now(),
          );
          if (programs.isNotEmpty) return programs;
        }
        return const <EPGProgram>[];
      },
      startShort: (shouldStart) {
        if (subscription?.type != SubscriptionType.xtream) return null;
        return gate.start(
          () async {
            if (!budget.tryConsume()) return const <EPGProgram>[];
            final programs = await api.fetchChannelEpgPrograms(channel);
            if (programs.isNotEmpty) shortCache.put(channel.id, programs);
            return upcomingEpgPrograms(programs, DateTime.now());
          },
          shouldStart,
        );
      },
    );
  },
);

/// EPG d'une chaîne pour la GRILLE : programmes passés compris.
///
/// La grille représente une journée entière ; lui fournir seulement « à venir »
/// laissait la matinée entière vide, comblée par des blocs de trou alors que le
/// dump XMLTV contenait bel et bien ces programmes.
///
/// **Aucun repli réseau** : la grille doit se contenter du dump XMLTV.
/// `get_short_epg` est documenté comme « pour UNE chaîne » — balayer une
/// catégorie entière le ferait bloquer par le rate limiter du panel (429),
/// ce qui cassait l'expiration, les catégories, etc.
final channelEpgWindowProvider =
    FutureProvider.autoDispose.family<List<EPGProgram>, String>(
  (ref, epgChannelId) => _resolveChannelEpg(
    ref,
    epgChannelId,
    includePast: true,
    allowNetworkFallback: false,
  ),
);

class EPGProgramsNotifier extends AsyncNotifier<List<EPGProgram>> {
  @override
  Future<List<EPGProgram>> build() async {
    final api = ref.watch(apiServiceProvider);
    final cache = ref.watch(epgDataCacheProvider);
    final result = await safeAsync<List<EPGProgram>>(
      // Passe par le cache partagé : aucune redondance avec la grille EPG
      // (un seul fetch XMLTV global). La mise en garde retry garde la
      // robustesse anti-leech draap.
      () => stream_helpers.retryStream(
        () => cache.loadFull(api),
        attempts: 2,
      ),
      context: 'EPGProgramsNotifier.build',
    );
    return result.getOrThrow();
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}
