# EPG — grille : 2. cache et providers Riverpod

> **Partie 1/2**

> Fiche générée depuis le code source — extraction fidèle, commentaires compris. Chaque bloc est limité à 200 lignes pour rester copiable sans saturer le presse-papier.

Sources : `lib/providers/providers.dart`, `lib/services/short_epg_service.dart`

### 2.1 `EPGDataCache` — le dump XMLTV indexé par chaîne

`lib/providers/providers.dart` · lignes 953–1149

#### `lib/providers/providers.dart` · lignes 953–1149 · partie 1/1

```dart
class EPGDataCache {
  EPGDataCache();

  static const _ttl = Duration(minutes: 30);

  List<EPGProgram>? _all;
  DateTime? _fetchedAt;
  Future<List<EPGProgram>>? _inFlight;

  /// Index par `channelId` → programmes triés par horaire croissant, construit
  /// UNE seule fois au premier chargement complet (O(N)) et réutilisé par tous
  /// les appels `channelEpgProvider` : évite de re-parcourir la liste globale
  /// (48 h) à chaque chaîne demandée.
  final Map<String, List<EPGProgram>> _byChannel = {};

  /// Index de secours sur la clé normalisée (espaces retirés, minuscules).
  ///
  /// Les panels Xtream n'emploient pas toujours le même identifiant dans
  /// l'API et dans le XMLTV : `"TF1"`, `"TF1 "`, `"tf1"` désignent la même
  /// chaîne. Sans cette table, la ligne de la grille restait vide alors que le
  /// guide était disponible — d'où les trous d'affichage dans les grilles.
  final Map<String, String> _normalizedToChannelId = {};

  static String _normalizeKey(String key) =>
      key.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Retourne les programmes (triés par horaire) d'une chaîne, sans aucun
  /// re-parcours de la liste globale. Vide si le cache n'est pas encore chargé
  /// ou si la chaîne n'a pas d'entrées EPG.
  List<EPGProgram> programsForChannel(String channelId) {
    final exact = _byChannel[channelId];
    if (exact != null && exact.isNotEmpty) return exact;
    final trimmed = _byChannel[channelId.trim()];
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    final resolved = _normalizedToChannelId[_normalizeKey(channelId)];
    if (resolved != null) {
      final fallback = _byChannel[resolved];
      if (fallback != null) return fallback;
    }
    return const <EPGProgram>[];
  }

  /// Charge l'intégralité du guide (filtre 48 h) UNE seule fois à la fois via

  bool get isFresh {
    final fetched = _fetchedAt;
    if (_all == null || fetched == null) return false;
    if (DateTime.now().difference(fetched) >= _ttl) return false;
    // Les données sont ancrées sur la JOURNÉE du chargement (`_fetchAndFilter`
    // borne à `[minuit du jour, écriture + 30 h]`). Passé minuit, l'application
    // restée ouverte servirait encore la fenêtre de la veille : la grille
    // n'aurait de programmes que jusqu'au début de matinée, tout le reste
    // comblé en blocs « aucune donnée ». On rejoue donc un chargement au
    // premier appel du nouveau jour — la péremption seule (30 min) ne le
    // détecte pas, la nuit dure moins de 30 min après le dernier chargement.
    return _sameLocalDay(fetched, DateTime.now());
  }

  /// Vrai si [a] et [b] tombent le même jour civil, en heure locale.
  static bool _sameLocalDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Instant du dernier chargement réussi, pour l'indicateur de fraîcheur de
  /// l'écran EPG.
  DateTime? get fetchedAt => _fetchedAt;

  /// Durée de validité du cache, pour que l'UI puisse dire « périmé » sans
  /// dupliquer la constante.
  Duration get ttl => _ttl;

  /// Charge l'intégralité du guide (filtre 48 h) UNE seule fois à la fois via
  /// un futur partagé : la grille (`_loadAllEpg`) et l'onglet Recherche
  /// (`epgProgramsProvider`) ne déclenchent chacun qu'un seul téléchargement
  /// XMLTV, jamais deux en parallèle.
  Future<List<EPGProgram>> loadFull(ApiService api) async {
    if (isFresh) return _all!;
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    final future = _fetchAndFilter(api);
    _inFlight = future;
    try {
      return await future;
    } finally {
      _inFlight = null;
    }
  }

  /// Force un rechargement réseau, en ignorant le cache mémoire ET le tampon
  /// disque.
  ///
  /// « Tirer pour rafraîchir » ne pouvait rien rafraîchir : [loadFull] rendait
  /// le cache mémoire tant qu'il avait moins de 30 min, et relisait le tampon
  /// disque tel quel. L'utilisateur tirait, l'indicateur tournait, et les
  /// données restaient identiques — sans qu'aucun message ne l'explique.
  Future<List<EPGProgram>> forceRefresh(ApiService api) async {
    // Un chargement déjà en vol écrirait son résultat APRÈS le nôtre et
    // remettrait des données plus anciennes dans l'index : on l'attend d'abord.
    final pending = _inFlight;
    if (pending != null) {
      await pending.then<void>((_) {}, onError: (_) {});
    }
    invalidate();
    final cacheKey = await api.resolveSubscriptionCacheKey();
    if (cacheKey != null) {
      await EpgBufferStore.instance.clear(cacheKey);
    }
    return loadFull(api);
  }

  Future<List<EPGProgram>> _fetchAndFilter(ApiService api) async {
    // Tampon disque d'abord : le dump fait plusieurs dizaines de Mo et sans
    // cela il était retéléchargé à chaque session pour être jeté à la fermeture.
    final cacheKey = await api.resolveSubscriptionCacheKey();
    if (cacheKey != null) {
      // Chronométré : c'est le coût RÉEL de la lecture du tampon, et lui seul
      // dira si le format mérite d'être compressé ou allégé. Décider avant de
      // mesurer produirait une optimisation sur une intuition.
      final stopwatch = Stopwatch()..start();
      final buffered = await EpgBufferStore.instance.read(cacheKey);
      stopwatch.stop();
      if (buffered != null && buffered.isNotEmpty) {
        _index(buffered);
        _fetchedAt = DateTime.now();
        LoggerService.instance.info(
          'EPG: ${buffered.length} programmes lus depuis le tampon local en '
          '${stopwatch.elapsedMilliseconds} ms',
        );
        return buffered;
      }
    }

    final programs = await api.fetchEpg();
    // On borne la conservation entre le DÉBUT de la journée en cours et +30 h.
    //
    // La borne basse était « maintenant ». La grille représente une journée
    // entière (minuit → minuit) : tout ce qui s'est terminé ce matin était donc
    // jeté au chargement, et la matinée s'affichait en « aucune donnée » alors
    // que le dump XMLTV la contenait — 93 128 entrées récupérées, aucune
    // affichée. Couper à minuit couvre la journée affichée sans garder les
    // semaines précédentes contenues dans le dump.
    final now = DateTime.now();
    final dayStart = EpgDayWindow.ofNow().start;
    final horizon = now.add(const Duration(hours: EpgBufferStore.horizonHours));
    final projected = EpgBufferStore.project(
      programs,
      windowStart: dayStart,
      horizon: horizon,
    );
    _index(projected);
    _fetchedAt = now;

    // Écriture BEST EFFORT : un tampon non écrit coûte un téléchargement au
    // prochain lancement, rien de plus. On ne fait jamais échouer le
    // chargement pour une écriture.
    if (cacheKey != null) {
      await EpgBufferStore.instance.write(cacheKey, projected);
      LoggerService.instance.info(
        'EPG: ${programs.length} programmes téléchargés, '
        '${projected.length} conservés (fenêtre ${EpgBufferStore.horizonHours} h)',
      );
    }
    return projected;
  }

  /// Indexe une liste de programmes déjà filtrée.
  ///
  /// Partagé par le réseau et le tampon : une seule implémentation, donc aucun
  /// risque que les deux chemins produisent des index différents.
  void _index(List<EPGProgram> programs) {
    _all = programs;
    // Index par chaîne, trié par horaire : recherches dichotomiques O(log N).
    _byChannel.clear();
    _normalizedToChannelId.clear();
    for (final p in programs) {
      (_byChannel[p.channelId] ??= <EPGProgram>[]).add(p);
      // La clé normalisée ne remplace la clé exacte que si elle est libre :
      // deux identifiants distincts ne doivent pas fusionner par accident.
      _normalizedToChannelId.putIfAbsent(
        _normalizeKey(p.channelId),
        () => p.channelId,
      );
    }
    for (final list in _byChannel.values) {
      list.sort((a, b) => a.start.compareTo(b.start));
    }
  }

  void invalidate() {
    _all = null;
    _fetchedAt = null;
    _byChannel.clear();
    // Sans ceci, la table de secours survivait à l'invalidation et pouvait
    // résoudre une chaîne vers des données qui ne sont plus chargées.
    _normalizedToChannelId.clear();
  }
}

```

### 2.2 Caches et providers EPG (court, précharge)

`lib/providers/providers.dart` · lignes 1150–1172

#### `lib/providers/providers.dart` · lignes 1150–1172 · partie 1/1

```dart
final epgDataCacheProvider = Provider<EPGDataCache>((ref) => EPGDataCache());

/// Cache des guides courts (get_short_epg) + service de précharge 7 jours (S4).
final shortEpgCacheProvider = Provider<ShortEpgCache>((ref) => ShortEpgCache());

/// Cache de l'EPG **complet** d'une chaîne (`get_simple_data_table`) pour le
/// rattrapage.
///
/// Volontairement distinct de [shortEpgCacheProvider] : celui-ci reçoit
/// l'aperçu COURT (4 entrées futures) écrit par la barre du lecteur et le
/// zapping. Partager la même instance/clé ferait servir cet aperçu tronqué à la
/// place de l'historique multi-jours dès que le lecteur a été ouvert avant
/// l'écran Replay.
final catchUpEpgCacheProvider = Provider<ShortEpgCache>(
  (ref) => ShortEpgCache(),
);
final epgPreloadServiceProvider = Provider<EpgPreloadService>(
  (ref) => EpgPreloadService(cache: ref.watch(shortEpgCacheProvider)),
);

/// Fenêtre catch-up : on ne montre que les programmes terminés depuis 14 jours.
//plus de kCatchUpWindow global ; on utilise channel.archiveDays

```
