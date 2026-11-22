# EPG — grille : 2. cache et providers Riverpod

> **Partie 2/2**

> Fiche générée depuis le code source — extraction fidèle, commentaires compris. Chaque bloc est limité à 200 lignes pour rester copiable sans saturer le presse-papier.

Sources : `lib/providers/providers.dart`, `lib/services/short_epg_service.dart`

### 2.3 `_resolveChannelEpg` — cœur de la résolution (grille + lecteur)

`lib/providers/providers.dart` · lignes 1230–1453

#### `lib/providers/providers.dart` · lignes 1230–1429 · partie 1/2

```dart
/// Cherche une entrée du cache court pour une forme d'identifiant donnée.
///
/// Le cache est écrit sous le `stream_id` nu, alors que l'appelant peut
/// interroger la forme préfixée (`num:stream_id`) ou inversement. On tente donc
/// les deux écritures possibles à partir de l'identifiant demandé.
List<EPGProgram>? _findShortEpgForAnyCandidate(
  ShortEpgCache cache,
  String epgChannelId,
) {
  // Forme préfixée « num:stream_id » -> on tente le stream_id seul.
  final colon = epgChannelId.indexOf(':');
  if (colon > 0) {
    final bare = epgChannelId.substring(colon + 1);
    if (bare.isNotEmpty) {
      final hit = cache.get(bare);
      if (hit != null) return hit;
    }
  }
  return null;
}

/// Programmes à venir, **triés par début croissant**.
///
/// `get_short_epg` n'a aucune garantie d'ordre : certains panels livrent la
/// journée en mélange avec celle d'avant. Or `epgCurrentProgram` et
/// `epgNextProgram` localisent par dichotomie, ce qui suppose un tri. Filtrer
/// seul (`where`) conserve le désordre et la dichotomie renvoie alors un
/// programme arbitraire — souvent vide, d'où une grille EPG « vide » alors que
/// le panel répondait.
List<EPGProgram> _upcomingSorted(List<EPGProgram> programs, DateTime now) {
  return programs.where((p) => p.end.isAfter(now)).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
}

/// Budget de requêtes par chaîne pour le repli réseau de l'EPG.
///
/// Le dump XMLTV global couvre l'essentiel des chaînes en UNE requête. Le
/// repli `get_short_epg` est un appel HTTP par chaîne : sur ~589 chaînes il
/// déclenchait la limitation du panel (429) en quelques secondes, et chaque
/// chaîne échouait. Ce budget borne le repli aux chaînes réellement absentes
/// du dump.
///
/// Volontairement partagé entre les appels concurrents : la grille charge 8
/// chaînes en parallèle, un budget par appel n'aurait rien borné.
class EpgFallbackBudget {
  /// Nombre de requêtes de repli autorisées par session de chargement.
  static const int maxRequests = 40;

  int _remaining = maxRequests;
  int _consumed = 0;

  int get remaining => _remaining;
  int get consumed => _consumed;

  bool tryConsume() {
    if (_remaining <= 0) return false;
    _remaining--;
    _consumed++;
    return true;
  }

  void reset() {
    _remaining = maxRequests;
    _consumed = 0;
  }
}

final epgFallbackBudgetProvider = Provider<EpgFallbackBudget>((ref) {
  // Non `autoDispose` : le budget doit survivre au démontage d'un écran pour
  // rester un budget DE SESSION. Recréé à chaque écran, le compteur repartirait
  // de 40 à chaque navigation et la borne serait illusoire.
  return EpgFallbackBudget();
});

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
  final now = DateTime.now();
  List<EPGProgram> keep(List<EPGProgram> list) => includePast
      ? (list..sort((a, b) => a.start.compareTo(b.start)))
      : _upcomingSorted(list, now);

  // 1. Cache court (aucun réseau).
  //
  // Le cache est indexé par `stream_id` (cf. l'écriture plus bas), mais
  // l'appelant peut demander une autre forme (`num:stream_id`, ou un id
  // XMLTV). Sans cette recherche multi-clés, une requête faite avec la forme
  // préfixée relançait `get_short_epg` à chaque appel et — surtout —
  // ne bénéficiait jamais du cache : l'EPG de la buttonbar du lecteur
  // restait vide malgré un panel qui répondait.
  final cachedShort = cache.get(epgChannelId) ??
      _findShortEpgForAnyCandidate(cache, epgChannelId);
  if (cachedShort != null) {
    final kept = keep(cachedShort);
    if (kept.isNotEmpty) return kept;
  }

  // Tout ce dont le corps a besoin est lu AVANT le premier `await` : ces
  // providers sont `autoDispose`, donc un `ref` touché après une attente peut
  // déjà avoir été détruit si l'appeleur a quitté l'écran entre-temps.
  final api = ref.read(apiServiceProvider);
  final globalCache = ref.watch(epgDataCacheProvider);
  final budget = ref.watch(epgFallbackBudgetProvider);
  final channels = ref.read(liveChannelsProvider).value ?? const <Channel>[];
  Channel? channel;
  for (final c in channels) {
    // On compare sur TOUS les identifiants EPG possibles de la chaîne
    // (`stream_id` et `num:stream_id`) : le XMLTV de ces panels utilise la
    // forme préfixée, et ne tester qu'un seul forme faisait échouer la
    // résolution.
    if (c.id == epgChannelId || c.epgChannelIds.contains(epgChannelId)) {
      channel = c;
      break;
    }
  }
  // 2. Dump XMLTV global : UNE requête pour TOUTES les chaînes.
  //
  // Cet ordre est délibéré, et il a été inversé après mesure. Le dump contient
  // ~208 000 programmes déjà indexés en mémoire ; interroger `get_short_epg`
  // par chaîne revient à faire ~589 requêtes HTTP, que le panel limite
  // immédiatement (429 « Limite de requêtes dépassée »), avec 6 à 8 s de
  // latence unitaire. Résultat mesuré sur le S20 : toutes les chaînes
  // échouaient et la grille se remplissait de blocs de trou — des « cases »
  // sans aucun programme.
  await globalCache.loadFull(api);

  // On essaie chaque identifiant candidat de la chaîne (forme simple et forme
  // préfixée) : le premier qui trouve des programmes gagne.
  final candidates = <String>[epgChannelId];
  final matched = channel;
  if (matched != null) {
    candidates
      ..clear()
      ..addAll(matched.epgChannelIds);
    if (matched.id.isNotEmpty) candidates.add(matched.id);
  }
  for (final candidate in candidates) {
    final found = keep(globalCache.programsForChannel(candidate).toList());
    if (found.isNotEmpty) return found;
  }

  // 3. Repli réseau : UNIQUEMENT pour l'usage « fiche chaîne unique »
  // (barre du lecteur, zapping). La grille NE DOIT PAS déclencher de
  // requête réseau : la doc Xtream dit que `get_short_epg` sert UNE chaîne,
  // pas à balayer la grille. Le dump XMLTV suffit à la grille.
  if (!allowNetworkFallback) return const <EPGProgram>[];

  // 3 bis. Repli réseau pour la fiche chaîne — borné par le budget.
  if (channel != null && budget.tryConsume()) {
    final target = channel;
    final result = await safeAsync<List<EPGProgram>>(
      () => api.fetchChannelEpgPrograms(target),
      context: 'channelEpgProvider',
    );
    final programs = result.valueOrNull;
    if (programs != null && programs.isNotEmpty) {
      cache.put(target.id, programs);
      final kept = keep(programs);
      if (kept.isNotEmpty) return kept;
    }
  }

  return const <EPGProgram>[];
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
```

#### `lib/providers/providers.dart` · lignes 1430–1453 · partie 2/2

```dart
    allowNetworkFallback: true,
  ),
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

```

### 2.4 `EPGProgramsNotifier` — dump global partagé

`lib/providers/providers.dart` · lignes 1454–1477

#### `lib/providers/providers.dart` · lignes 1454–1477 · partie 1/1

```dart
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

```

### 2.5 `ShortEpgCache` + `EpgPreloadService`

`lib/services/short_epg_service.dart` · lignes 1–96

#### `lib/services/short_epg_service.dart` · lignes 1–96 · partie 1/1

```dart
import 'dart:async';

import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';

/// Fenêtre de conservation du cache : 30 minutes.
const Duration kShortEpgTtl = Duration(minutes: 30);

/// Cache mémoire des guides courts (`get_short_epg`) par `stream_id`.
///
/// Évite de re-interroger le panel à chaque ouverture de catch-up ou de grille
/// EPG d'une chaîne. L'entrée est considered périmée après [kShortEpgTtl].
class ShortEpgCache {
  final Map<String, _ShortEpgEntry> _entries = <String, _ShortEpgEntry>{};

  /// Nombre d'entrées en cache (diagnostic/tests).
  int get length => _entries.length;

  /// Retourne la liste en cache si elle est encore valide.
  List<EPGProgram>? get(String streamId) {
    final entry = _entries[streamId];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _entries.remove(streamId);
      return null;
    }
    return entry.programs;
  }

  /// Stocke une liste de programmes pour une chaîne.
  void put(String streamId, List<EPGProgram> programs) {
    _entries[streamId] = _ShortEpgEntry(
      programs: List<EPGProgram>.unmodifiable(programs),
      expiresAt: DateTime.now().add(kShortEpgTtl),
    );
  }

  void invalidate(String streamId) => _entries.remove(streamId);

  void clear() => _entries.clear();
}

class _ShortEpgEntry {
  _ShortEpgEntry({required this.programs, required this.expiresAt});

  final List<EPGProgram> programs;
  final DateTime expiresAt;
}

/// Précharge en tâche de fond le guide court des chaînes de l'abonnement.
///
/// Lançé au démarrage (idle), il évite la latence du premier `get_short_epg`
/// sans jamais bloquer le chargement de l'application.
class EpgPreloadService {
  EpgPreloadService({required this.cache, this.ttl = kShortEpgTtl});

  final ShortEpgCache cache;

  /// Durée maximale de la précharge (garde-fou temps réel).
  final Duration ttl;

  bool _running = false;
  bool get isRunning => _running;

  /// Précharge les [limit] premières chaînes, sans jamais dépasser [ttl].
  Future<int> preload(ApiService api, List<Channel> channels, {int limit = 20}) async {
    if (_running) return 0;
    _running = true;
    final deadline = DateTime.now().add(ttl);
    var loaded = 0;
    try {
      for (final channel in channels.take(limit)) {
        if (DateTime.now().isAfter(deadline)) break;
        if (cache.get(channel.id) != null) continue;
        final result = await safeAsync<List<EPGProgram>>(
          () => api.fetchChannelEpgPrograms(channel),
          context: 'EpgPreloadService.preload',
        );
        final programs = result.valueOrNull;
        if (programs == null || programs.isEmpty) continue;
        cache.put(channel.id, programs);
        loaded++;
      }
    } finally {
      _running = false;
    }
    if (loaded > 0) {
      LoggerService.instance
          .info('EpgPreloadService: $loaded guides courts préchargés');
    }
    return loaded;
  }
}
```
