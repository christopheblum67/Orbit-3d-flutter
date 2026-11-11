import 'dart:async';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:orbit_3d_flutter/core/utils/epg_day_window.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/epg_buffer_store.dart';

/// Cache partagé du guide EPG brut, avec expiration, pour éviter de
/// re-télécharger l'intégralité du XMLTV à chaque changement de chaîne.
class EPGDataCache {
  EPGDataCache({this.allowedChannelKeys});

  /// Clés (normalisées) des chaînes du catalogue : le dump XMLTV contient des
  /// milliers de chaînes absentes de l'abonnement, inutiles et coûteuses en
  /// mémoire sur une TV de 2 Go. `null` ou vide : aucun filtrage.
  final Set<String>? Function()? allowedChannelKeys;

  static const _ttl = Duration(minutes: 30);

  List<EPGProgram>? _all;
  DateTime? _fetchedAt;
  Future<List<EPGProgram>>? _inFlight;

  /// Vrai pendant qu'un chargement du guide est en cours (l'écran EPG affiche
  /// alors un bandeau d'information).
  final ValueNotifier<bool> loading = ValueNotifier<bool>(false);

  void _setLoading(bool value) {
    if (loading.value == value) return;
    scheduleMicrotask(() => loading.value = value);
  }

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

  static String normalizeKey(String key) =>
      key.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Retourne les programmes (triés par horaire) d'une chaîne, sans aucun
  /// re-parcours de la liste globale. Vide si le cache n'est pas encore chargé
  /// ou si la chaîne n'a pas d'entrées EPG.
  List<EPGProgram> programsForChannel(String channelId) {
    final exact = _byChannel[channelId];
    if (exact != null && exact.isNotEmpty) return exact;
    final trimmed = _byChannel[channelId.trim()];
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    final resolved = _normalizedToChannelId[normalizeKey(channelId)];
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

  /// Charge l'intégralité du guide (filtre 48 h) UNE seule fois à la fois via
  /// un futur partagé : la grille (`_loadAllEpg`) et l'onglet Recherche
  /// (`epgProgramsProvider`) ne déclenchent chacun qu'un seul téléchargement
  /// XMLTV, jamais deux en parallèle.
  Future<List<EPGProgram>> loadFull(
    ApiService api, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && isFresh) return _all!;
    // Stale-while-revalidate : un guide expiré mais du jour reste affichable.
    // On le rend tout de suite et on le renouvelle en tâche de fond, au lieu de
    // bloquer l'écran sur un téléchargement XMLTV de plusieurs dizaines de Mo.
    if (!forceRefresh && _inFlight == null && _isServableStale) {
      _revalidateInBackground(api);
      return _all!;
    }
    final inFlight = _inFlight;
    if (inFlight != null) {
      if (!forceRefresh) return _all ?? await inFlight;
      await inFlight;
      return loadFull(api, forceRefresh: true);
    }
    final future = _fetchAndFilter(api, forceRefresh: forceRefresh);
    _inFlight = future;
    _setLoading(true);
    try {
      return await future;
    } finally {
      _inFlight = null;
      _setLoading(false);
    }
  }

  static const _revalidateCooldown = Duration(minutes: 10);

  /// Appelé quand un renouvellement en arrière-plan vient d'aboutir : les
  /// consommateurs rechargent alors depuis le cache désormais frais.
  void Function()? onRevalidated;

  DateTime? _lastRevalidateAttempt;

  bool get _isServableStale {
    final fetched = _fetchedAt;
    return _all != null &&
        fetched != null &&
        _sameLocalDay(fetched, DateTime.now());
  }

  void _revalidateInBackground(ApiService api) {
    final last = _lastRevalidateAttempt;
    if (last != null && DateTime.now().difference(last) < _revalidateCooldown) {
      return;
    }
    _lastRevalidateAttempt = DateTime.now();
    unawaited(
      loadFull(api, forceRefresh: true).then((_) {
        onRevalidated?.call();
      }).catchError((Object error) {
        LoggerService.instance.warning(
          'EPG: renouvellement en arrière-plan échoué, guide conservé : $error',
        );
      }),
    );
  }

  Future<List<EPGProgram>> _fetchAndFilter(
    ApiService api, {
    required bool forceRefresh,
  }) async {
    // Tampon disque d'abord : le dump fait plusieurs dizaines de Mo et sans
    // cela il était retéléchargé à chaque session pour être jeté à la fermeture.
    final cacheKey = await api.resolveSubscriptionCacheKey();
    if (cacheKey != null && !forceRefresh) {
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

    final allowed = allowedChannelKeys?.call();
    final fetched = await api.fetchEpg();
    final programs = (allowed == null || allowed.isEmpty)
        ? fetched
        : fetched
            .where((p) => allowed.contains(normalizeKey(p.channelId)))
            .toList();
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
        normalizeKey(p.channelId),
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
  }
}
