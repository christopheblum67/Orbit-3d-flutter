# Replay / Catch-up — de la récupération des données à l’affichage

Document de référence généré depuis le code source (extraction fidèle, commentaires compris).

## 0. Vue d’ensemble du pipeline

```text
DONNÉES (panneau)                     CODE                                    AFFICHAGE
─────────────────────────────────────────────────────────────────────────────────────────
XMLTV global (dump) ─┐
                     ├─► ApiService.buildReplaysFromGlobalEpg ─┐
get_live_streams ────┘   (programmes TERMINÉS + supportsReplay) │
                                                                ├─► mergeReplays ─► replaysProvider ─► (cache)
get_short_epg ─► _fetchChannelReplayPrograms ─► replaysCache ───┘        │
  (sonde en tâche de fond : replaysProbeProvider)                       ▼
                                                                ReplayScreen (niveau 1 : chaînes)
                                                                        │  (tap chaîne)
get_simple_data_table ─► _fetchChannelFullEpg ─► fetchChannelReplays ─► channelReplaysProvider
      (repli) get_short_epg ─► _fetchChannelReplayPrograms                  │
                                                                            ▼
                                                                ReplayScreen (niveau 2 : jours + programmes)
                                                                        │  (tap programme)
replayStreamUrl : catchup-source (template) sinon /timeshift/…          ▼
                                                                /player (lecture)

Chemin EPG (rattrapage depuis la grille) :
  EPG grille ─(appui long chaîne)─► CatchUpScreen ─► channelCatchUpProvider
             ─► fetchChannelEpgPrograms (get_short_epg) ─► _pastPrograms ─► tap ─► replayStreamUrl ─► /player
```

## 1. Modèles de données

### 1.1 `Channel` — attributs de replay (reçus de `get_live_streams`)

`lib/models/channel.dart`  (lignes 1-163)

```dart
import 'package:orbit_3d_flutter/core/utils/media_meta.dart';
import 'package:orbit_3d_flutter/core/utils/panel_text.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    as stream_helpers;

class Channel {
  final String id;
  final String name;
  final String logoUrl;
  final String streamUrl;
  final String group;
  final String categoryId;
  final String epgChannelId;
  final int orderNum;
  final double rating;

  /// La chaîne expose un replay/catchup (tv_archive, radio_tv=dvr,
  /// timeshift) : ses programmes passés sont relisibles.
  final bool supportsReplay;
  final Duration timeshift;

  /// Rétroactivité annoncée par le panel (`tv_archive_duration`), en jours.
  ///
  /// Champ standard Xtream Codes. L'imposer à 0 était le pire choix possible :
  /// c'est la valeur par défaut d'une chaîne sans replay, mais aussi celle
  /// qu'un panel renvoie quand il choisit de ne pas déclarer son archive. Avec
  /// ce garde-fou, une chaîne déclarant `tv_archive: 1` reste candidate au
  /// replay et la fenêtre peut s'ouvrir jusqu'à la valeur annoncée.
  final int archiveDays;

  /// Mode de substitution du catch-up, tel que le provider le déclare :
  /// `default`, `append`, `shift`, `flussonic`, `xc`.
  ///
  /// Le mode ne sert pas à piloter le lecteur mais à interpréter
  /// [catchupSource] : `append` construit l'URL à partir du flux live, `shift`
  /// et `xc` attendent `start`/`duration` en secondes, `flussonic` un chemin
  /// horodaté. Ignorer ce champ et toujours fabriquer un `timeshift.php`
  /// produisait des URL que le panel ne reconnaît pas.
  final String catchupMode;

  /// Modèle d'URL du catch-up (`catchup-source`), avec ses variables `{utc}`,
  /// `{duration}`, `{offset}`, `{Y}`… à substituer au moment de la lecture.
  ///
  /// C'est la source de vérité du chemin de replay : l'URL doit venir
  /// d'ici, pas d'une convention devinée.
  final String catchupSource;

  /// Identifiants EPG candidats pour cette chaîne (formes `{stream_id}` et
  /// `{num}:{stream_id}`), déduits de [epgChannelId].
  ///
  /// Les panels Xtream ne fournissent pas de champ EPG explicite : on
  /// essaye donc les deux écritures vues dans les dumps XMLTV plutôt que de
  /// parier sur une seule forme.
  List<String> get epgChannelIds {
    if (epgChannelId.isEmpty) return const <String>[];
    return epgChannelId
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  /// Premier identifiant EPG non vide, ou la chaîne vide.
  String get primaryEpgChannelId =>
      epgChannelIds.isEmpty ? '' : epgChannelIds.first;

  /// La chaîne archive au-delà de 48 h — « grand replay ».
  ///
  /// Le seuil est de **3 jours** : `tv_archive_duration > 2`, soit
  /// `catchup-days > 2` en M3U. 48 h est le cas particulier de 2 jours, pas la
  /// borne haute : un compte à 7 ou 14 jours sort du lot, et c'est cette
  /// information qui décide si l'onglet des jours d'une chaîne mérite
  /// d'exister ou s'il ne peut structurellement contenir que la grille.
  bool get hasExtendedCatchup => supportsReplay && archiveDays > 2;

  /// Rétention annoncée, en jours, ou `null` si le panel ne déclare rien.
  ///
  /// `null` et `0` ne veulent pas dire la même chose : `0` signifie « cette
  /// chaîne n'archive pas », `null` « le panel ne l'a pas dit ». L'écran Replay
  /// distingue les deux dans son message, sinon un vide muet était
  /// indifférenciable d'une fenêtre dépassée.
  int? get catchupDays => archiveDays > 0 ? archiveDays : null;

  Channel({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.streamUrl,
    required this.group,
    this.categoryId = '',
    this.epgChannelId = '',
    this.orderNum = 0,
    this.rating = 0,
    this.supportsReplay = false,
    this.timeshift = Duration.zero,
    this.archiveDays = 0,
    this.catchupMode = '',
    this.catchupSource = '',
  });

  factory Channel.fromMap(Map<String, dynamic> map) {
    // Textes du panel décodés une fois pour toutes (cf. PanelText) :
    map = PanelText.decodeMap(map);
    final radioTv = map['radio_tv']?.toString().toLowerCase() ?? '';
    final tvArchive = map['tv_archive']?.toString().toLowerCase();
    final hasArchive =
        tvArchive == '1' || tvArchive == 'true' || tvArchive == 'yes';
    final timeshiftSeconds =
        int.tryParse('${map['timeshift_seconds'] ?? '0'}') ?? 0;
    // Certains panels Xtream renvoient les mêmes attributs que le M3U, et
    // d'autres n'en renvoient aucun. On les lit quand ils existent : sans eux
    // la fenêtre retombe sur la valeur par défaut et le chemin de replay reste
    // celui de `timeshift.php`.
    final catchupMode = map['catchup']?.toString().trim().toLowerCase() ?? '';
    final catchupSource = map['catchup_source']?.toString().trim() ?? '';
    final catchupDays = int.tryParse('${map['catchup_days'] ?? ''}') ?? 0;
    final archiveDaysField = int.tryParse('${map['tv_archive_duration'] ?? ''}') ?? 0;
    final streamId = firstNonEmpty([map['stream_id'], map['id']]);
    final channelNum = map['num']?.toString() ?? '';
    // Xtream ne renvoie AUCUN champ `epg_channel_id` : la liaison vers le
    // XMLTV se fait par le `stream_id`. Les dumps XMLTV de ces panels
    // identifient les chaînes par « {num}:{stream_id} » (l'identifiant
    // observé dans le dump est `1:117`), le `stream_id` seul servant pour
    // les panels plus anciens. On renseigne donc les DEUX formes, séparées
    // par une virgule, et `epgChannelIds` les expose pour la recherche.
    // Sans cela `epgChannelId` restait vide et aucun programme n'était
    // jamais trouvé (« aucun programme en cours »).
    final epgCandidates = <String>{};
    if (streamId.isNotEmpty) {
      epgCandidates.add(streamId);
      if (channelNum.isNotEmpty) epgCandidates.add('$channelNum:$streamId');
    }
    final explicitEpg = map['epg_channel_id']?.toString() ?? '';
    if (explicitEpg.isNotEmpty) epgCandidates.add(explicitEpg);
    return Channel(
      id: streamId,
      name: map['name'] ?? '',
      logoUrl: firstNonEmpty([map['stream_icon'], map['logo']]),
      streamUrl: map['url'] ?? '',
      group: firstNonEmpty([map['category_name'], map['group']]),
      categoryId: map['category_id']?.toString() ?? '',
      epgChannelId: epgCandidates.join(','),
      orderNum: _parseNumValue(map['num']),
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      supportsReplay: radioTv == 'dvr' ||
          hasArchive ||
          timeshiftSeconds > 0 ||
          catchupDays > 0 ||
          catchupSource.isNotEmpty,
      timeshift: Duration(seconds: timeshiftSeconds),
      // La fenêtre est prioritairement celle annoncée par le panel. Avant,
      // `hasArchive` à lui seul suffisait à remettre la fenêtre à zéro, et une
      // chaîne qui archive bel et bien se retrouvait filtrée comme si elle
      // n'archivait rien.
      archiveDays: archiveDaysField > 0
          ? archiveDaysField
          : catchupDays > 0
              ? catchupDays
              : 0,
      catchupMode: catchupMode,
      catchupSource: catchupSource,
    );
  }
```

### 1.2 `ReplayItem` — un programme rejouable

`lib/models/replay_item.dart`  (lignes 1-82)

```dart
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    as stream_helpers;
import 'package:orbit_3d_flutter/core/utils/panel_text.dart';

class ReplayItem {
  final String id;
  final String title;
  final String streamUrl;
  final String startTime;
  final String endTime;
  final String categoryId;

  /// Chaîne qui diffuse ce replay (identification + affichage groupé).
  final String channelId;
  final String channelName;

  /// Début du programme en temps réel (tri, regroupement) ; null pour les
  /// replays sans horaire (repli live/M3U).
  final DateTime? startDate;

  /// Résumé du programme, affiché sous le titre.
  final String description;

  /// Présentation / credited (présentateur, journaliste, production).
  final String host;

  /// Horaires machine, pour l'affichage du créneau et le regroupement par jour.
  final DateTime? startAt;
  final DateTime? endAt;

  ReplayItem({
    required this.id,
    required this.title,
    required this.streamUrl,
    required this.startTime,
    required this.endTime,
    this.categoryId = '',
    this.channelId = '',
    this.channelName = '',
    this.startDate,
    this.description = '',
    this.host = '',
    this.startAt,
    this.endAt,
  });

  factory ReplayItem.fromMap(Map<String, dynamic> map) {
    // Textes du panel décodés une fois pour toutes (cf. PanelText) :
    map = PanelText.decodeMap(map);
    return ReplayItem(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      streamUrl: map['url'] ?? '',
      startTime: map['start'] ?? '',
      endTime: map['end'] ?? '',
      categoryId: map['category_id']?.toString() ?? '',
      channelId: map['channel_id']?.toString() ?? '',
      channelName: map['channel_name']?.toString() ?? '',
    );
  }

  ReplayItem copyWith({String? streamUrl}) {
    return ReplayItem(
      id: id,
      title: title,
      streamUrl: streamUrl ?? this.streamUrl,
      startTime: startTime,
      endTime: endTime,
      categoryId: categoryId,
      channelId: channelId,
      channelName: channelName,
      startDate: startDate,
      description: description,
      host: host,
      startAt: startAt,
      endAt: endAt,
    );
  }

  String requireStreamUrl() =>
      stream_helpers.requireStreamUrl(streamUrl, label: title);
}
```

### 1.3 `EPGProgram` — un programme EPG

`lib/models/epg_program.dart`  (lignes 1-139)

```dart
import 'package:flutter/material.dart';

enum ProgramCategory {
  movie,
  series,
  sport,
  news,
  documentary,
  other,
}

extension ProgramCategoryX on ProgramCategory {
  int get colorValue {
    switch (this) {
      case ProgramCategory.movie:
        return 0xFF7C4DFF;
      case ProgramCategory.series:
        return 0xFF00E676;
      case ProgramCategory.sport:
        return 0xFFFF5252;
      case ProgramCategory.news:
        return 0xFF448AFF;
      case ProgramCategory.documentary:
        return 0xFFFFAB00;
      case ProgramCategory.other:
        return 0xFF424242;
    }
  }

  int get accentColorValue {
    switch (this) {
      case ProgramCategory.movie:
        return 0xFFB388FF;
      case ProgramCategory.series:
        return 0xFFB9F6CA;
      case ProgramCategory.sport:
        return 0xFFFF8A80;
      case ProgramCategory.news:
        return 0xFF82B1FF;
      case ProgramCategory.documentary:
        return 0xFFFFD740;
      case ProgramCategory.other:
        return 0xFF757575;
    }
  }

  String get displayName {
    switch (this) {
      case ProgramCategory.movie:
        return 'Film';
      case ProgramCategory.series:
        return 'Série';
      case ProgramCategory.sport:
        return 'Sport';
      case ProgramCategory.news:
        return 'Info';
      case ProgramCategory.documentary:
        return 'Docu';
      case ProgramCategory.other:
        return 'Général';
    }
  }

  static ProgramCategory fromString(String? s) {
    switch (s?.toLowerCase()) {
      case 'movie':
      case 'film':
        return ProgramCategory.movie;
      case 'series':
      case 'série':
        return ProgramCategory.series;
      case 'sport':
        return ProgramCategory.sport;
      case 'news':
      case 'info':
        return ProgramCategory.news;
      case 'documentary':
      case 'documentaire':
        return ProgramCategory.documentary;
      default:
        return ProgramCategory.other;
    }
  }
}

class EPGProgram {
  final String channelId;
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;
  final ProgramCategory category;

  /// Programme factice, généré pour combler un trou de l'EPG.
  ///
  /// Les panels laissent des trous entre deux émissions. Sans bloc de
  /// remplacement, la grille affichait un vide et surtout décalait la lecture :
  /// l'axe horaire étant continu, un trou de 40 min se lisait comme une
  /// absence de programme alors que c'en était un de données. Un bloc
  /// explicite rend le trou visible **et** dit pourquoi.
  final bool isDummy;

  EPGProgram({
    required this.channelId,
    required this.title,
    required this.description,
    required this.start,
    required this.end,
    this.category = ProgramCategory.other,
    this.isDummy = false,
  });

  DateTime get startTime => start;
  DateTime get endTime => end;
  int get durationMinutes => end.difference(start).inMinutes;
  bool get isLive {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }
}

extension EPGProgramX on EPGProgram {
  int get durationSec => end.difference(start).inSeconds;

  bool get isLiveNow {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  double get progress {
    if (!isLiveNow) return 0.0;
    final now = DateTime.now();
    return (now.difference(start).inSeconds / durationSec).clamp(0.0, 1.0);
  }

  Color get categoryColor => Color(category.colorValue);
  Color get accentColor => Color(category.accentColorValue);
  String get categoryDisplayName => category.name.toUpperCase();
}
```

### 1.4 `isReplayableProgram` — la règle « rejouable »

`lib/features/epg/replay_utils.dart`  (lignes 1-14)

```dart
import 'package:orbit_3d_flutter/models/epg_program.dart';

/// Un programme EPG est rejouable quand sa chaîne propose le replay/DVR
/// (timeshift) ET que le programme est déjà terminé (pas en cours de
/// diffusion, pas à venir).
bool isReplayableProgram(
  EPGProgram program, {
  required DateTime now,
  required bool channelSupportsReplay,
}) {
  if (!channelSupportsReplay) return false;
  if (program.isLive) return false;
  return program.end.isBefore(now);
}
```

## 2. Récupération des données — `ApiService`


### 2.1 Constantes de la fenêtre de replay

`lib/services/api_service.dart`  (lignes 1415-1430)

```dart
  /// de temps de la sonde est marginal (l'EPG global alimente le replay
  /// multi-jours) ; le coût d'un catalogue bloqué, lui, est total.
  ///
  /// Le portillon [_ApiGate] limite par ailleurs l'ensemble des appels
  /// concurrents à 3 : ce réglage ne gouverne que la sonde.
  static const int _probeConcurrency = 2;

  /// Fenêtre de repli quand le panneau ne déclare aucune durée d'archive
  /// (`catchup-days` / `tv_archive_duration` absents).
  static const Duration _replayWindow = Duration(hours: 48);

  /// Nombre d'entrées demandées à ``get_short_epg``.
  ///
  /// Un programme TV dure en moyenne 30 à 90 minutes : 48 h de replay
  /// représentent 40 à 100 programmes selon la chaîne. On demande 100 pour
  /// couvrir la fenêtre entière, quitte à ce que le panel en renvoie moins.
```

### 2.2 Source 1 — EPG global : `buildReplaysFromGlobalEpg` + `mergeReplays`

`lib/services/api_service.dart`  (lignes 1432-1543)

```dart

  /// Construit les replays à partir de l'**EPG global** déjà téléchargé.
  ///
  /// ## Pourquoi cette source et pas `get_short_epg`
  ///
  /// Le paramètre `limit` de `get_short_epg` n'est pas respecté par les
  /// panels : les logs du 29/09 montrent `limit=100` renvoyé **4 entrées**, et
  /// quatre programmes en pleine journée sont presque tous *futurs*. Cet appel
  /// ne peut donc pas alimenter un replay multi-jours — au mieux il donne le
  /// dernier programme passé, d'où les écrans à une seule date, un seul
  /// programme à la fois.
  ///
  /// L'EPG global, lui, couvre plusieurs jours et fait déjà authority pour le
  /// guide. On le croise donc avec les chaînes marquées `supportsReplay` et on
  /// ne conserve que les programmes **terminés** : c'est exactement la
  /// définition de [isReplayableProgram].
  ///
  /// [fetchReplays] reste utilisé en complément, pour les chaînes absentes de
  /// l'EPG global.
  Future<List<ReplayItem>> buildReplaysFromGlobalEpg({
    required List<EPGProgram> programs,
    required List<Channel> channels,
  }) async {
    final sub = await _activeSub();
    if (sub['type'] != 'xtream') return const <ReplayItem>[];
    final baseUrl = sub['baseUrl']!;
    final username = sub['username']!;
    final password = sub['password']!;
    final now = DateTime.now();

    // Index des chaînes rejouables sous TOUS leurs identifiants EPG possibles
    // (`{stream_id}` et `{num}:{stream_id}`) : le XMLTV et le panel ne
    // s'accordent pas toujours sur la même forme.
    final byEpgId = <String, Channel>{};
    for (final c in channels) {
      if (!c.supportsReplay) continue;
      for (final id in c.epgChannelIds) {
        if (id.isNotEmpty) byEpgId[id] = c;
      }
      if (c.id.isNotEmpty) byEpgId[c.id] = c;
    }
    if (byEpgId.isEmpty) return const <ReplayItem>[];

    final items = <ReplayItem>[];
    final seen = <String>{};
    for (final p in programs) {
      final channel = byEpgId[p.channelId];
      if (channel == null) continue;
      if (!isReplayableProgram(p, now: now, channelSupportsReplay: true)) {
        continue;
      }
      // Fenêtre propre à la chaîne : `catchup-days` de l'abonnement quand le
      // provider le déclare, 48 h sinon.
      if (now.difference(p.start) > archiveWindow(channel)) continue;

      final startEpoch = p.start.millisecondsSinceEpoch ~/ 1000;
      final endEpoch = p.end.millisecondsSinceEpoch ~/ 1000;
      final key = '${channel.id}_$startEpoch';
      if (!seen.add(key)) continue;

      final title = p.title.trim();
      if (title.isEmpty) continue;
      items.add(
        ReplayItem(
          id: key,
          title: title,
          streamUrl: replayStreamUrl(
            channel: channel,
            baseUrl: baseUrl,
            username: username,
            password: password,
            startEpoch: startEpoch,
            endEpoch: endEpoch,
          ),
          startTime: _formatReplayTime(p.start, now),
          endTime: _formatReplayTime(p.end, now),
          categoryId: channel.groupLabel,
          channelId: channel.id,
          channelName: channel.name,
          startDate: p.start,
          description: p.description.trim(),
          startAt: p.start,
          endAt: p.end,
        ),
      );
    }

    _logger.info(
      'Replay EPG global: ${items.length} programme(s) rejouable(s) '
      'sur ${programs.length} entrées, ${byEpgId.length} chaîne(s) DVR',
    );
    return items;
  }

  /// Fusionne les replays issus de l'EPG global (autoritaires) avec ceux de
  /// `get_short_epg`, en dédupliquant sur chaîne + début de programme.
  ///
  /// L'EPG global passe en premier : il est plus complet. `get_short_epg` ne
  /// sert qu'à rattraper une chaîne absente du dump XMLTV.
  static List<ReplayItem> mergeReplays(
    List<ReplayItem> fromEpg,
    List<ReplayItem> fromShortEpg,
  ) {
    final seen = <String>{};
    final merged = <ReplayItem>[];
    for (final r in [...fromEpg, ...fromShortEpg]) {
      final start = r.startAt?.millisecondsSinceEpoch ??
          r.startDate?.millisecondsSinceEpoch ??
          0;
      if (seen.add('${r.channelId}_$start')) merged.add(r);
    }
    return merged;
```

### 2.3 Source 2 — sonde : `fetchReplays`, `_fetchXtreamReplays`, `replayProbeSet`

`lib/services/api_service.dart`  (lignes 1545-1701)

```dart

  Future<List<ReplayItem>> fetchReplays() async {
    final sub = await _activeSub();

    if (sub['type'] == 'xtream') {
      return _fetchXtreamReplays(sub);
    }
    if (sub['type'] == 'm3u') {
      return _fetchM3uReplays(sub);
    }
    throw StreamNetworkException('Aucun abonnement configuré.');
  }

  /// Replay Xtream : les chaînes DVR (tv_archive / timeshift) exposent leurs
  /// programmes passés via l'EPG court ; chaque programme est joué avec une
  /// URL timeshift (start/end en secondes Unix) sur le flux de la chaîne.
  Future<List<ReplayItem>> _fetchXtreamReplays(
    Map<String, String?> sub,
  ) async {
    final baseUrl = sub['baseUrl']!;
    final username = sub['username']!;
    final password = sub['password']!;

    final channelsResult = await safeAsync<List<Channel>>(
      () => fetchLiveChannels(),
      context: 'ApiService._fetchChannelReplayPrograms',
      fallbackValue: const <Channel>[],
    );
    final channels = channelsResult.getOrElse(const <Channel>[]);

    final flagged = channels
        .where(
          (c) => c.supportsReplay || c.name.toLowerCase().contains('replay'),
        )
        .toList();

    // Découverte large : beaucoup de panels ne marquent `tv_archive` que sur
    // une poignée de chaînes (ex. une catégorie) alors que le timeshift est
    // global. On sonde donc TOUJOURS un échantillon diversifié :
    //   1. toutes les chaînes explicitement DVR (« Seulement France HD » est
    //      le symptôme typique d'une marque partielle) ;
    //   2. complété par un échantillon STRATIFIÉ par catégorie (un même
    //      groupe n'apparaîtra qu'en petit nombre dans la sonde) pour couvrir
    //      le reste de la grille, sans marteler le panel (budget plafonné).
    final probeChannels = replayProbeSet(channels, flagged);
    if (probeChannels.isEmpty) return const <ReplayItem>[];

    final now = DateTime.now();
    final results = List<List<ReplayItem>?>.filled(probeChannels.length, null);
    var nextIndex = 0;
    final workerCount = probeChannels.length < _probeConcurrency
        ? probeChannels.length
        : _probeConcurrency;
    final workers = <Future<void>>[
      for (var w = 0; w < workerCount; w++)
        () async {
          while (true) {
            final i = nextIndex++;
            if (i >= probeChannels.length) break;
            results[i] = await _fetchChannelReplayPrograms(
              baseUrl: baseUrl,
              username: username,
              password: password,
              channel: probeChannels[i],
              now: now,
            );
          }
        }(),
    ];
    await Future.wait(workers);

    final replayItems = <ReplayItem>[];
    for (var i = 0; i < probeChannels.length; i++) {
      final programs = results[i] ?? const <ReplayItem>[];
      if (programs.isNotEmpty) {
        replayItems.addAll(programs);
      }
      // Pas de fallback live TV : on n'affiche que les vrais programmes catch-up
      // issus de l'EPG (get_short_epg). Si aucun programme terminé n'est exposé
      // par le panel pour cette chaîne, on ne l'affiche pas.
    }

    // Programmes les plus récents d'abord.
    replayItems.sort((a, b) {
      final ta = a.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = b.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });

    debugPrint('Orbit3D replays=${replayItems.length} '
        'probed=${probeChannels.length} '
        'flagged=${flagged.length}');
    return replayItems;
  }

  /// Constitution de l'ensemble des chaînes à sonder pour le replay.
  ///
  /// Le budget est GLOBAL ([budget]) : certains panels marquent TOUT le
  /// catalogue DVR (tv_archive partout) — sonder les ~200 chaînes martèlerait
  /// le panel et déclencherait l'anti-leech (blocage IP temporaire qui fait
  /// ensuite échouer le catalogue VOD). Le budget est donc réparti en
  /// round-robin PAR CATÉGORIE (au plus [perGroup] chaînes par groupe), en
  /// donnant la priorité aux chaînes explicitement DVR afin que toutes les
  /// catégories soient couvertes (pas de cluster « Seulement France HD » : le
  /// `take(25)` brut ne garderait que la première catégorie).
  static List<Channel> replayProbeSet(
    List<Channel> channels,
    List<Channel> flagged,
  ) {
    const budget = 40;
    const perGroup = 3;
    if (channels.isEmpty) return const <Channel>[];

    final flaggedIds = flagged.map((c) => c.id).toSet();
    final candidates = <Channel>[];
    final seen = <String>{};
    final takenByGroup = <String, int>{};

    void fillRoundRobin(List<Channel> source) {
      final byGroup = <String, List<Channel>>{};
      for (final c in source) {
        final g = c.groupLabel.isNotEmpty ? c.groupLabel : _unknownGroupLabel;
        byGroup.putIfAbsent(g, () => []).add(c);
      }
      final groupNames = byGroup.keys.toList();
      var allExhausted = false;
      while (candidates.length < budget && !allExhausted) {
        allExhausted = true;
        for (final group in groupNames) {
          if (candidates.length >= budget) break;
          final list = byGroup[group]!;
          final taken = takenByGroup[group] ?? 0;
          if (taken >= perGroup) continue;
          Channel? next;
          for (final c in list) {
            if (!seen.contains(c.id)) {
              next = c;
              break;
            }
          }
          if (next == null) continue;
          seen.add(next.id);
          candidates.add(next);
          takenByGroup[group] = taken + 1;
          allExhausted = false;
        }
      }
    }

    // 1. Chaînes explicitement DVR d'abord — réparties par catégorie pour
    //    ne jamais dépasser le budget total (anti-leech) ni clusteriser.
    fillRoundRobin(flagged);
    if (candidates.length >= budget) return candidates;
    // 2. Complétion du budget avec le reste de la grille (marquage partiel :
    //    le DVR du panel est souvent global, la marque elle ne l'est pas).
    fillRoundRobin(channels.where((c) => !flaggedIds.contains(c.id)).toList());
    return candidates;
```

### 2.4 `_fetchChannelReplayPrograms` (get_short_epg)

`lib/services/api_service.dart`  (lignes 1991-2136)

```dart

  /// URL de lecture d'un programme de replay.
  ///
  /// Le template `catchup-source` déclaré par le provider, s'il y en a un,
  /// **prime sur tout** : c'est lui qui décrit le chemin de replay réel. En
  /// son absence on applique la convention Xtream Codes
  /// (`/timeshift/user/pass/durée/date/id.ext`), qui est celle de ce panel —
  /// `get_live_streams` n'y expose pas de `catchup-source`, contrairement aux
  /// playlists M3U qui en déclarent toujours un.
  ///
  /// Inventer une URL alors qu'un template est disponible donnait des liens
  /// morts : le programme était listé, puis la lecture échouait.
  String replayStreamUrl({
    required Channel channel,
    required String baseUrl,
    required String username,
    required String password,
    required int startEpoch,
    required int endEpoch,
  }) {
    final fromTemplate = CatchupUrl.build(
      channel: channel,
      start: DateTime.fromMillisecondsSinceEpoch(startEpoch * 1000),
      end: DateTime.fromMillisecondsSinceEpoch(endEpoch * 1000),
    );
    if (fromTemplate != null && fromTemplate.isNotEmpty) return fromTemplate;
    return buildXtreamTimeshiftUrl(
      baseUrl,
      username,
      password,
      channel.id,
      start: startEpoch,
      end: endEpoch,
    );
  }

  /// Fenêtre de rétroactivité d'une chaîne.
  ///
  /// `catchup-days` / `tv_archive_duration` est la durée réelle annoncée par
  /// l'abonnement — 48 h, 7 jours, 14 jours selon le compte. On la respecte
  /// telle quelle : la plafonner en dur à 48 h bridait le Replay des comptes
  /// 7/14 j alors que le serveur sert bel et bien l'historique (constat terrain,
  /// et c'est ce que fait XCIPTV). Le 48 h ne sert plus que de repli quand le
  /// panel ne déclare aucune durée — ce qui explique l'écart entre les deux :
  /// le vrai plafond était la SOURCE d'EPG (`get_short_epg`), pas cette fenêtre.
  static Duration archiveWindow(Channel channel) {
    if (channel.archiveDays > 0) return Duration(days: channel.archiveDays);
    return _replayWindow;
  }

  /// Programmes terminés et rejouables d'une chaîne DVR (get_short_epg).
  Future<List<ReplayItem>> _fetchChannelReplayPrograms({
    required String baseUrl,
    required String username,
    required String password,
    required Channel channel,
    required DateTime now,
  }) async {
    final result = await safeAsync<List<ReplayItem>>(
      () async {
        final url = _playerApiUrl(baseUrl, 'player_api.php', {
          'username': username,
          'password': password,
          'action': 'get_short_epg',
          'stream_id': channel.id,
          // `get_short_epg` plafonne à 4 entrées par défaut. Quatre programmes
          // en pleine journée couvrent à peine deux heures, tous FUTURS : le
          // filtre « terminé uniquement » les supprimait tous et l'écran
          // finissait sur « aucun replay disponible », alors que le panel en
          // publie. On demande explicitement une fenêtre couvrant les
          // `_replayWindow`.
          'limit': '$_replayLimit',
        });
        final response = await _get(url);
        final data = response.data;
        final list = data is List
            ? data
            : (data is Map
                ? (data['epg_listings'] as List? ?? const <dynamic>[])
                : const <dynamic>[]);
        final items = <ReplayItem>[];
        // Diagnostic : `get_short_epg` plafonne par défaut à 4 entrées, et un
        // panel peut en renvoyer 0 malgré `tv_archive: 1`. Sans ce log, un
        // « aucun replay disponible » est indiscernable d'un vrai panel vide.
        _logger.info(
          'Replay ${channel.name} (${channel.id}): short_epg limit=$_replayLimit '
          '-> ${list.length} entrées brutes',
        );
        // Relevé des entrées brutes : sans lui, « 0 programme rejouable sur 4 »
        // est indécidable. Les 4 peuvent être toutes futures (le panel ne
        // publie pas d'historique par cet appel), ou des passées rejetées par
        // notre filtre — et les deux appellent des corrections opposées.
        final window = archiveWindow(channel);
        final sample = <String>[];
        for (final e in list.whereType<Map>().take(6)) {
          final map = Map<String, dynamic>.from(e);
          final s = _parseReplayDate(map['start_timestamp'] ?? map['start']);
          final en = _parseReplayDate(map['stop_timestamp'] ?? map['end']);
          if (s == null || en == null) {
            sample.add('?');
            continue;
          }
          final delta = now.difference(s);
          final hours = (delta.inMinutes / 60).round();
          final state = en.isBefore(now) ? 'terminé' : 'à venir';
          final tooOld = delta > window ? ', hors fenêtre' : '';
          sample.add(
            '${_formatReplayTime(s, now)} ($hours h, $state$tooOld)',
          );
        }
        if (sample.isNotEmpty) {
          _logger.info(
            'Replay ${channel.name}: entrées = ${sample.join(' | ')} '
            '(fenêtre ${window.inDays} j)',
            tag: 'replay',
          );
        }
        for (final e in list.whereType<Map>()) {
          final map = Map<String, dynamic>.from(e);
          final start =
              _parseReplayDate(map['start_timestamp'] ?? map['start']);
          final end = _parseReplayDate(map['stop_timestamp'] ?? map['end']);
          if (start == null || end == null) continue;
          if (!end.isBefore(now)) continue; // programme pas encore terminé
          // Fenêtre de rétroactivité : `catchup-days` de l'abonnement quand le
          // provider le déclare (48 h, 7 j, 14 j selon le compte), 48 h sinon.
          // Fixer 48 h en dur éliminait à tort les replays d'un compte
          // annonçant 7 jours : le programme était bien servi, il était
          // filtré de notre côté.
          if (now.difference(start) > archiveWindow(channel)) {
            continue; // trop ancien
          }
          // Même décodage que le chemin `get_simple_data_table` : ce panel
          // encode les titres en base64 sur les deux appels. Sans lui, les
          // chaînes servies par ce repli affichaient « QWxsZSwgbGUgbG9pciI »
          // alors que les autres étaient lisibles.
          final title = PanelText.decode(
            map['title']?.toString().trim() ?? '',
          );
          if (title.isEmpty) continue;
          final startEpoch = start.millisecondsSinceEpoch ~/ 1000;
          final endEpoch = end.millisecondsSinceEpoch ~/ 1000;
          items.add(
            ReplayItem(
              id: '${channel.id}_$startEpoch',
              title: title,
```

### 2.5 Source 3 — EPG complet d’une chaîne : `fetchChannelReplays`, `_fetchChannelFullEpg`, `replayStreamUrl`, `archiveWindow`

`lib/services/api_service.dart`  (lignes 1769-1990)

```dart
    if (title.isEmpty) return null;
    return EPGProgram(
      // `epgChannelId` peut contenir plusieurs candidats séparés par une
      // virgule : on retient le premier, sinon l'id de la chaîne.
      channelId: channel.primaryEpgChannelId.isNotEmpty
          ? channel.primaryEpgChannelId
          : channel.id,
      title: title,
      description: PanelText.decode(
        _firstString(map, const ['description', 'plot', 'desc', 'summary']),
      ),
      start: start,
      end: end,
    );
  }

  /// EPG **complet** d'une chaîne (passé compris) via `get_simple_data_table`.
  ///
  /// C'est la source du rattrapage multi-jours. `get_short_epg`, utilisé
  /// jusqu'ici pour le catch-up, ne renvoie que 4 entrées — presque toutes
  /// futures — et ne peut donc pas décrire l'historique : l'écran restait
  /// bloqué sur le dernier programme passé, quelle que soit la durée annoncée
  /// par l'abonnement. `get_simple_data_table` renvoie tout ce que le serveur
  /// conserve, et c'est cette source qu'exploite XCIPTV pour son Replay.
  ///
  /// Repli sur l'aperçu court si le panel ne sert pas cet appel, pour ne pas
  /// régresser sur les panels qui l'ignorent.
  Future<List<EPGProgram>> fetchChannelCatchUpPrograms(Channel channel) async {
    final sub = await _activeSub();
    if (sub['type'] != 'xtream') return const <EPGProgram>[];
    final baseUrl = sub['baseUrl']!;
    final username = sub['username']!;
    final password = sub['password']!;

    final entries = await _fetchChannelFullEpg(
      baseUrl: baseUrl,
      username: username,
      password: password,
      channel: channel,
    );
    if (entries.isEmpty) return fetchChannelEpgPrograms(channel);

    final programs = <EPGProgram>[];
    for (final e in entries) {
      final program = _epgProgramFromMap(e, channel);
      if (program != null) programs.add(program);
    }
    // Repli uniquement si l'EPG complet ne produit aucun programme exploitable.
    if (programs.isEmpty) return fetchChannelEpgPrograms(channel);
    return programs;
  }

  /// Programmes rejouables d'**une seule** chaîne : un appel.
  ///
  /// ## L'endpoint qui compte
  ///
  /// `get_short_epg` ne sert **pas** à ça. Sa documentation le dit : « aperçu
  /// rapide des **prochains** programmes ». Il renvoie 4 entrées, toutes
  /// futures, et le filtre « terminé » les élimine toutes — d'où un Replay vide
  /// alors que le panel archive bien. Mesuré le 30/09 : `0 programme(s)
  /// rejouable(s) sur 4 renvoyés par get_short_epg`.
  ///
  /// L'EPG complet d'une chaîne, celui qui est « nécessaire pour calculer le
  /// Replay », vient de `get_simple_data_table&stream_id=…`. Cet appel n'était
  /// fait nulle part dans l'application.
  ///
  /// Un seul appel par chaîne, comme le niveau 1 de l'écran : le catalogue
  /// compte plus de 1400 chaînes rejouables, et les sonder toutes déclencherait
  /// la tempête de 429 qui vide l'EPG, les Films et le Live TV.
  Future<List<ReplayItem>> fetchChannelReplays(Channel channel) async {
    final sub = await _activeSub();
    if (sub['type'] != 'xtream') return const <ReplayItem>[];
    final baseUrl = sub['baseUrl']!;
    final username = sub['username']!;
    final password = sub['password']!;
    final now = DateTime.now();

    final entries = await _fetchChannelFullEpg(
      baseUrl: baseUrl,
      username: username,
      password: password,
      channel: channel,
    );

    // Repli : certains panels ne servent pas l'EPG complet par cet appel. On
    // retente alors avec l'aperçu court, qui ne donnera que les rares
    // programmes déjà diffusés — moins de résultats, mais mieux que rien.
    if (entries.isEmpty) {
      return _fetchChannelReplayPrograms(
        baseUrl: baseUrl,
        username: username,
        password: password,
        channel: channel,
        now: now,
      );
    }

    // Fenêtre de l'abonnement pour CETTE chaîne (`tv_archive_duration`). Le tri
    // par jour est fait par l'écran ; on renvoie du plus récent au plus ancien,
    // qui est l'ordre de lecture attendu.
    final window = archiveWindow(channel);
    final items = <ReplayItem>[];
    final seen = <int>{};
    for (final e in entries) {
      final map = Map<String, dynamic>.from(e);
      final start = _parseReplayDate(map['start_timestamp'] ?? map['start']);
      final end = _parseReplayDate(
        map['stop_timestamp'] ?? map['stop'] ?? map['end'],
      );
      if (start == null || end == null) continue;
      if (!end.isBefore(now)) continue; // pas encore terminé
      if (now.difference(start) > window) continue; // hors fenêtre du compte
      // Ce panel encode les titres et descriptifs en base64 : sans décodage,
      // la table affichait « TxkgTWlsbGlvbg== » là où il faut lire
      // « Le Bulletin ». Le décodage est prudent (longueur, alphabet, contrôle
      // de caractères) : un titre en clair qui ressemblerait à du base64 n'est
      // jamais altéré.
      final title = PanelText.decode(
        map['title']?.toString().trim() ?? '',
      );
      if (title.isEmpty) continue;
      final startEpoch = start.millisecondsSinceEpoch ~/ 1000;
      if (!seen.add(startEpoch)) continue;
      items.add(
        ReplayItem(
          id: '${channel.id}_$startEpoch',
          title: title,
          streamUrl: replayStreamUrl(
            channel: channel,
            baseUrl: baseUrl,
            username: username,
            password: password,
            startEpoch: startEpoch,
            endEpoch: end.millisecondsSinceEpoch ~/ 1000,
          ),
          startTime: _formatReplayTime(start, now),
          endTime: _formatReplayTime(end, now),
          categoryId: channel.groupLabel,
          channelId: channel.id,
          channelName: channel.name,
          startDate: start,
          description: PanelText.decode(
            _firstString(map, const [
              'description',
              'plot',
              'desc',
              'summary',
            ]),
          ),
          host: PanelText.decode(
            _firstString(map, const [
              'name',
              'presenter',
              'host',
              'director',
              'actor',
            ]),
          ),
          startAt: start,
          endAt: end,
        ),
      );
    }
    items.sort(
      (a, b) => (b.startAt ?? b.startDate ?? DateTime(1900))
          .compareTo(a.startAt ?? a.startDate ?? DateTime(1900)),
    );

    _logger.info(
      'Replay ${channel.name}: ${items.length} programme(s) rejouable(s) '
      'sur ${entries.length} de l\'EPG complet '
      '(fenêtre ${window.inDays} j, archive ${channel.archiveDays} j)',
      tag: 'replay',
    );
    return items;
  }

  /// EPG complet d'une chaîne (`get_simple_data_table&stream_id=…`).
  ///
  /// Séparé de [fetchChannelReplays] pour que le tri, le filtre et la
  /// construction d'URL soient testables sans réseau.
  Future<List<Map<String, dynamic>>> _fetchChannelFullEpg({
    required String baseUrl,
    required String username,
    required String password,
    required Channel channel,
  }) async {
    final result = await safeAsync<List<Map<String, dynamic>>>(
      () async {
        final url = _playerApiUrl(baseUrl, 'player_api.php', {
          'username': username,
          'password': password,
          'action': 'get_simple_data_table',
          'stream_id': channel.id,
        });
        final response = await _get(url);
        final data = response.data;
        // Trois formes rencontrées : liste nue, `epg_listings` (variante
        // get_short_epg) et `epg_programmes` (variante get_simple_data_table).
        final list = data is List
            ? data
            : (data is Map
                ? (data['epg_programmes'] as List? ??
                    data['epg_listings'] as List? ??
                    const <dynamic>[])
                : const <dynamic>[]);
        final entries = <Map<String, dynamic>>[];
        for (final e in list.whereType<Map>()) {
          entries.add(Map<String, dynamic>.from(e));
        }
        _logger.info(
          'EPG complet ${channel.name} (${channel.id}): ${entries.length} '
          'programme(s) via get_simple_data_table',
          tag: 'replay',
        );
        return entries;
      },
      context: 'ApiService._fetchChannelFullEpg',
      fallbackValue: const <Map<String, dynamic>>[],
    );
    return result.getOrElse(const <Map<String, dynamic>>[]);
  }
```

### 2.6 EPG d’une chaîne : `fetchChannelEpgPrograms`

`lib/services/api_service.dart`  (lignes 1714-1773)

```dart

  /// Programmes EPG d'une chaîne via `get_short_epg` (JSON).
  ///
  /// Complément au XMLTV global : renseigne le guide d'une chaîne en direct sans
  /// télécharger l'intégralité du dump. Échec ⇒ liste vide, le flux principal
  /// (XMLTV) reste la référence.
  ///
  /// Les titres et synopsis de certains panels arrivent encodés en base64 ; le
  /// décodage passe désormais par [PanelText], qui porte les garde-fous.
  Future<List<EPGProgram>> fetchChannelEpgPrograms(Channel channel) async {
    final sub = await _activeSub();
    if (sub['type'] != 'xtream') return const <EPGProgram>[];
    final result = await safeAsync<List<EPGProgram>>(
      () async {
        final url = _playerApiUrl(sub['baseUrl']!, 'player_api.php', {
          'username': sub['username']!,
          'password': sub['password']!,
          'action': 'get_short_epg',
          'stream_id': channel.id,
        });
        final response = await _get(url);
        final data = response.data;
        final list = data is List
            ? data
            : (data is Map
                ? (data['epg_listings'] as List? ?? const <dynamic>[])
                : const <dynamic>[]);
        final programs = <EPGProgram>[];
        for (final e in list.whereType<Map>()) {
          final program =
              _epgProgramFromMap(Map<String, dynamic>.from(e), channel);
          if (program != null) programs.add(program);
        }
        return programs;
      },
      context: 'ApiService.fetchChannelEpgPrograms',
      fallbackValue: const <EPGProgram>[],
    );
    return result.getOrElse(const <EPGProgram>[]);
  }

  /// Convertit une entrée brute d'EPG (JSON panel) en [EPGProgram].
  ///
  /// Source unique de la lecture des champs, partagée par
  /// [fetchChannelEpgPrograms] (aperçu court) et [fetchChannelCatchUpPrograms]
  /// (EPG complet). Les deux chemins divergeaient sur le nom du champ de fin
  /// (`stop` vs `end`) et sur le décodage des titres, ce qui produisait deux
  /// listes différentes pour une même chaîne.
  EPGProgram? _epgProgramFromMap(Map<String, dynamic> map, Channel channel) {
    final start = _parseReplayDate(map['start_timestamp'] ?? map['start']);
    final end = _parseReplayDate(
      map['stop_timestamp'] ?? map['stop'] ?? map['end'],
    );
    if (start == null || end == null || !end.isAfter(start)) return null;
    final title = PanelText.decode(map['title']?.toString().trim() ?? '');
    if (title.isEmpty) return null;
    return EPGProgram(
      // `epgChannelId` peut contenir plusieurs candidats séparés par une
      // virgule : on retient le premier, sinon l'id de la chaîne.
      channelId: channel.primaryEpgChannelId.isNotEmpty
```

### 2.7 Replay M3U + `_parseReplayDate`

`lib/services/api_service.dart`  (lignes 2138-2159)

```dart
                channel: channel,
                baseUrl: baseUrl,
                username: username,
                password: password,
                startEpoch: startEpoch,
                endEpoch: endEpoch,
              ),
              startTime: _formatReplayTime(start, now),
              endTime: _formatReplayTime(end, now),
              categoryId: channel.groupLabel,
              channelId: channel.id,
              channelName: channel.name,
              startDate: start,
              // Résumé et présentation : `get_short_epg` les fournit sous
              // des noms de champs variables selon les panels. On les lit
              // tous, et l'affichage masque ce qui est vide.
              description: PanelText.decode(
                _firstString(map, const [
                  'description',
                  'plot',
                  'desc',
                  'summary',
```

### 2.8 `_formatReplayTime`

`lib/services/api_service.dart`  (lignes 2204-2228)

```dart
    final seconds = int.tryParse(trimmed);
    if (seconds != null && seconds > 0) {
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
    return DateTime.tryParse(trimmed.replaceFirst(' ', 'T'));
  }

  /// Première clé non vide parmi [keys], normalisée en texte brut.
  ///
  /// Les panels n'utilisent pas les mêmes noms de champs d'une installation à
  /// l'autre : `description` / `plot` / `desc`, `name` / `presenter` /
  /// `director`... On essaie donc une liste ordonnée par fréquence décroissante
  /// plutôt que de coder un nom unique, sinon la moitié des replays
  /// s'afficheraient sans résumé ni présentateur.
  ///
  /// Les balises HTML éventuelles sont retirées : le texte est rendu dans un
  /// `Text` Flutter, où du markup apparaissait littéralement.
  static String _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final raw = map[k];
      if (raw == null) continue;
      var v = raw.toString().trim();
      if (v.isEmpty) continue;
      // Le XMLTV échappe l'apostrophe en `&apos;` : sans cette correction le
      // titre s'affichait littéralement « C dans l&apos;achat ».
```

## 3. Construction de l’URL de replay (catch-up)


### 3.1 `CatchupUrl` — template `catchup-source`

`lib/services/catchup_url_builder.dart`  (lignes 1-140)

```dart
import 'package:orbit_3d_flutter/models/channel.dart';

/// Construction de l'URL de replay (catch-up) à partir des attributs
/// déclarés par le provider.
///
/// ## Pourquoi un template
///
/// Le chemin de replay n'est pas une convention : chaque provider le déclare.
/// Un `#EXTINF` porte `catchup` (mode), `catchup-days` (fenêtre) et
/// `catchup-source` (modèle d'URL). Fabriquer soi-même un
/// `timeshift.php?...&start=&duration=` marche sur Xtream Codes et **nulle
/// part ailleurs** : un panel Flussonic ou Shift attend une autre forme, et
/// l'URL obtenue renvoie 404 ou une page d'authentification. Le template est
/// donc la source de vérité, et le mode sert à l'interpréter.
///
/// ## Variables documentées
///
/// | Variable | Sens |
/// |---|---|
/// | `{utc}`, `{start}` | début du programme, timestamp Unix (secondes) |
/// | `{lutc}`, `{now}` | horodatage courant, timestamp Unix (secondes) |
/// | `{duration}` | durée du programme |
/// | `{offset}` | secondes écoulées depuis le début du programme |
/// | `{Y}` `{m}` `{d}` `{H}` `{M}` `{S}` | composantes ISO du début |
///
/// La durée et les timestamps sont en **secondes** : c'est la convention
/// Xtream (`start`/`duration`) et celle des serveurs qui n'acceptent pas le
/// format ISO. Les composantes `{Y}`… couvrent les serveurs qui attendent
/// l'horodatage en `YYYYMMDDHHMMSS`, que [buildCatchupIsoStamp] produit aussi.
class CatchupUrl {
  const CatchupUrl._();

  /// Construit l'URL de replay d'un programme.
  ///
  /// Renvoie `null` si le provider ne déclare aucun template : dans ce cas
  /// l'appelant doit appliquer sa propre convention (Xtream Codes), plutôt que
  /// de voir une URL inventée.
  ///
  /// [offset] vaut 0 par défaut : on ouvre un replay à son début. Il n'est
  /// non nul que si l'utilisateur reprend une lecture en cours.
  static String? build({
    required Channel channel,
    required DateTime start,
    required DateTime end,
    Duration offset = Duration.zero,
  }) {
    final template = channel.catchupSource.trim();
    if (template.isEmpty) return null;
    return resolve(
      template: template,
      mode: channel.catchupMode,
      liveUrl: channel.streamUrl,
      start: start,
      end: end,
      offset: offset,
    );
  }

  /// Substitution pure, sans [Channel], pour être testable directement.
  static String resolve({
    required String template,
    required String mode,
    required String liveUrl,
    required DateTime start,
    required DateTime end,
    Duration offset = Duration.zero,
  }) {
    final startSeconds = start.millisecondsSinceEpoch ~/ 1000;
    final durationSeconds = end.difference(start).inSeconds;
    // `{offset}` est le décalage de LECTURE, pas l'heure courante : un replay
    // s'ouvre à 0, et l'heure du moment n'a rien à y faire. Le confondre
    // produisait une URL pointant 12 h après le début du programme.
    final offsetSeconds = offset.inSeconds < 0 ? 0 : offset.inSeconds;
    final local = start.toLocal();

    final values = <String, String>{
      '{utc}': '$startSeconds',
      '{start}': '$startSeconds',
      // `{lutc}` / `{now}` sont les alias de l'INSTANT D'EXÉCUTION, ceux du
      // décalage de lecture. Ils n'ont pas la même valeur, et les confondre
      // ferait rater la fenêtre de rattrapage.
      '{lutc}': '${startSeconds + offsetSeconds}',
      '{now}': '${startSeconds + offsetSeconds}',
      '{duration}': '$durationSeconds',
      '{offset}': '$offsetSeconds',
      '{Y}': _pad(local.year, 4),
      '{m}': _pad(local.month),
      '{d}': _pad(local.day),
      '{H}': _pad(local.hour),
      '{M}': _pad(local.minute),
      '{S}': _pad(local.second),
    };

    var url = template;
    values.forEach((key, value) {
      url = url.replaceAll(key, value);
    });

    // `append` : le modèle est une chaîne de paramètres à **ajouter** à l'URL
    // du flux live, pas une URL à part entière. Sans ce cas on produisait
    // `?start=…` seul, sans hôte.
    if (mode.trim().toLowerCase() == 'append') {
      final separator = liveUrl.contains('?') ? '&' : '?';
      final trimmed = liveUrl.trim();
      if (url.startsWith('?')) {
        return url.isEmpty ? trimmed : '$trimmed$url';
      }
      if (url.startsWith('&')) {
        return '$trimmed$url';
      }
      return '$trimmed$separator$url';
    }

    // Un modèle qui commence par `/` est un CHEMIN relatif : il se rattache à
    // l'hôte du flux live (cas Flussonic). Un modèle qui commence par `?` ou
    // `&` est un fragment de requête et un modèle sans slash est une valeur
    // nue : les traiter comme des chemins relatifs préfixait l'hôte devant un
    // simple `?start=…`, ce qui donnait une URL sans chemin de flux.
    if (url.startsWith('/') &&
        !url.startsWith('//') &&
        liveUrl.startsWith('http')) {
      final uri = Uri.tryParse(liveUrl);
      if (uri != null && uri.hasAuthority) {
        return '${uri.scheme}://${uri.authority}$url';
      }
    }
    return url;
  }

  /// Horodatage ISO `YYYYMMDDHHMMSS` du début, pour les serveurs qui attendent
  /// ce format plutôt qu'un timestamp Unix.
  static String buildCatchupIsoStamp(DateTime start) {
    final l = start.toLocal();
    return '${_pad(l.year, 4)}${_pad(l.month)}${_pad(l.day)}'
        '${_pad(l.hour)}${_pad(l.minute)}${_pad(l.second)}';
  }

  static String _pad(int value, [int width = 2]) =>
      value.toString().padLeft(width, '0');
}
```

### 3.2 `buildXtreamTimeshiftUrl` — convention Xtream (repli)

`lib/services/api_service.dart`  (lignes 2446-2474)

```dart
  }) {
    if (streamId == null || streamId.isEmpty) return '';
    final uri = Uri.parse(_trimBaseUrl(baseUrl));
    final mediaType = type.toLowerCase();
    // Live et Radio : `/u/p/{id}`, redirigé vers un CDN signé.
    // Movie/Séries : chemin Xtream standard `/movie/{u}/{p}/{id}` ou
    // `/series/{u}/{p}/{id}` — c'est la seule forme que draap.online sert
    // (302 → CDN) ; `/u/p/movie/{id}` renvoyait 401/406.
    final segments = <String>[];
    if (mediaType == 'movie' || mediaType == 'series') {
      segments.add(mediaType);
    }
    segments.addAll(<String>[
      ...uri.pathSegments.where((s) => s.isNotEmpty),
      username,
      password,
    ]);
    var mediaId = streamId;
    // Les serveurs Xtream récents (ex. draap.online) servent le fichier
    // /movie/{id} et /series/{id} sans extension ; forcer ".mp4" renvoie
    // un 404. On ne l'ajoute que si l'appelant le demande explicitement
    // (withExtension) pour les serveurs legacy qui l'exigent.
    if ((mediaType == 'movie' || mediaType == 'series') && withExtension) {
      final ext = _normalizeExtension(extension);
      mediaId = '$streamId.$ext';
    }
    segments.add(mediaId);
    final query = extra.isEmpty ? null : extra;
    return uri
```

## 4. Providers Riverpod (caches + états)


### 4.1 `ReplaysCache`, `replaysProvider`, `replaysProbeProvider`, `channelReplaysProvider`

`lib/providers/providers.dart`  (lignes 762-944)

```dart
/// Cache partagé des replays, avec expiration : relister les chaînes DVR
/// (get_short_epg) à chaque ouverture de l'écran Replay martèlerait le panel
/// et rendrait l'écran lent (25 chaînes × plusieurs appels).
class ReplaysCache {
  ReplaysCache();

  static const _ttl = Duration(minutes: 5);

  List<ReplayItem>? _all;
  DateTime? _fetchedAt;
  Future<List<ReplayItem>>? _inFlight;

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

  /// Renvoie la valeur en cache si fraîche, sinon charge via [loader] (un
  /// seul chargement à la fois, partagé entre tous les appelants).
  Future<List<ReplayItem>> fetch(
    Future<List<ReplayItem>> Function() loader,
  ) {
    if (isFresh) return Future.value(_all!);
    return _inFlight ??= loader().then(
      (items) {
        _all = items;
        _fetchedAt = DateTime.now();
        _inFlight = null;
        return items;
      },
      onError: (Object error, StackTrace stackTrace) {
        // Un échec n'est pas mis en cache : la prochaine ouverture retenté.
        _inFlight = null;
        throw error;
      },
    );
  }

  void invalidate() {
    _all = null;
    _fetchedAt = null;
  }
}

final ReplaysCache replaysCache = ReplaysCache();

/// Replays — source RAPIDE.
///
/// `get_short_epg` est plafonné à 4 entrées par les panels : il ne peut pas
/// alimenter seul un replay multi-jours. L'EPG global (XMLTV) est donc la
/// source complète, et `get_short_epg` ne sert qu'à rattraper les chaînes
/// absentes du dump — d'où la sonde séparée [replaysProbeProvider].
///
/// Cette provider n'attend QUE des données déjà chargées (EPG global, grille
/// des chaînes, cache de sonde) : elle ne déclenche aucune requête par
/// chaîne. C'est délibéré — la sonde porte sur 40 chaînes et, sérialisée par
/// [_ApiGate], elle prenait une à deux minutes. Le provider attendait cette sonde
/// avant d'afficher quoi que ce soit, donc l'écran restait en chargement
/// indéfiniment (et chaque relance relançait la sonde).
///
/// L'EPG global et la grille restent « best effort » : un 429 du panneau ne
/// doit pas faire couler l'écran, il doit le priver d'enrichissement.
final replaysProvider = FutureProvider<List<ReplayItem>>((ref) async {
  final filter = ref.watch(contentFilterProvider);
  final api = ref.watch(apiServiceProvider);
  // Changement d'abonnement actif => le cache n'est plus valable
  // (dépendance de re-fetch, la valeur elle-même ne nous sert pas ici).
  ref.watch(activeSubscriptionProvider);

  // Ce qui a déjà été sondé, sans déclencher de chargement. `null` au premier
  // lancement : l'affichage part alors de l'EPG global seul, ce qui est déjà
  // exploitable, et la sonde viendra l'enrichir.
  final shortEpg = replaysCache.peek ?? const <ReplayItem>[];

  final epgResult = await safeAsync<List<EPGProgram>>(
    () => ref.watch(epgProgramsProvider.future),
    context: 'replaysProvider.epg',
    fallbackValue: const <EPGProgram>[],
  );
  final channelsResult = await safeAsync<List<Channel>>(
    () => ref.watch(liveChannelsProvider.future),
    context: 'replaysProvider.channels',
    fallbackValue: const <Channel>[],
  );

  final fromEpg = await api.buildReplaysFromGlobalEpg(
    programs: epgResult.valueOrNull ?? const <EPGProgram>[],
    channels: channelsResult.valueOrNull ?? const <Channel>[],
  );

  final merged = ApiService.mergeReplays(fromEpg, shortEpg);
  if (merged.isEmpty) {
    // Aucun programme, mais on a peut-être été refusé par le panneau : on le
    // dit, plutôt que d'afficher un vide muet que rien n'explique.
    LoggerService.instance.warning(
      'Replay vide court=${shortEpg.length} epg=${fromEpg.length}',
      tag: 'replay',
    );
  }
  return filter.visibleList(merged);
});

/// Replays — sonde `get_short_epg`, en TÂCHE DE FOND.
///
/// Personne ne l'attend pour afficher quoi que ce soit : l'écran se rend avec
/// [replaysProvider], puis cette sonde complète. Son résultat alimente
/// [replaysCache], et c'est l'appelant (l'écran Replay, à l'ouverture) qui
/// invalide ensuite [replaysProvider] pour que la fusion se refasse avec les
/// programmes ajoutés.
///
/// Le cache a un TTL de 5 min et une déduction en vol : la relançer à chaque
/// ouverture ne refait pas la sonde si elle vient d'aboutir.
final replaysProbeProvider = FutureProvider<List<ReplayItem>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  ref.watch(activeSubscriptionProvider);
  return replaysCache.fetch(api.fetchReplays);
});

/// Petits cache par chaîne pour le détail Replay.
///
/// Revenir sur une chaîne déjà consultée ne doit pas coûter un appel : le panel
/// est fragile et l'utilisateur alterne entre deux chaînes. TTL court,
/// le cache est vidé au changement d'abonnement.
class _ChannelReplaysCache {
  static const _ttl = Duration(minutes: 10);

  final Map<String, List<ReplayItem>> _items = {};
  final Map<String, DateTime> _at = {};

  List<ReplayItem>? peek(String channelId) {
    final at = _at[channelId];
    if (at == null || DateTime.now().difference(at) >= _ttl) return null;
    return _items[channelId];
  }

  void put(String channelId, List<ReplayItem> items) {
    _items[channelId] = items;
    _at[channelId] = DateTime.now();
  }

  void invalidate() {
    _items.clear();
    _at.clear();
  }
}

final channelReplaysCache = _ChannelReplaysCache();

/// Replays d'**une** chaîne, chargés à la demande.
///
/// Un appel par chaîne, et un seul : c'est le point délicat du Replay. Le
/// catalogue compte plus de 1400 chaînes réplayables, donc tout ce qui sonde en
/// bloc (ce que faisait la sonde de 40 chaînes au démarrage) sature le quota du
/// panel — le 429 qui suit ne fait pas que ralentir le Replay, il vide aussi
/// l'EPG et les Films.
///
/// `autoDispose` : quitter le détail rend l'entrée au cache et libère le
/// provider, sans jamais déclencher de requête tout seul.
final channelReplaysProvider = FutureProvider.autoDispose
    .family<List<ReplayItem>, String>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  ref.watch(activeSubscriptionProvider);
  final channels = await ref.watch(liveChannelsProvider.future);
  final channel = channels.where((c) => c.id == id).firstOrNull;
  if (channel == null) return const <ReplayItem>[];

  final cached = channelReplaysCache.peek(id);
  if (cached != null) return cached;

  final items = await api.fetchChannelReplays(channel);
  channelReplaysCache.put(id, items);
  return items;
});
```

### 4.2 `channelCatchUpProvider` (+ `_pastPrograms`)

`lib/providers/providers.dart`  (lignes 1119-1179)

```dart
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

/// Programmes **terminés** d'une chaîne pour le rattrapage (catch-up).
///
/// Diffère de [channelEpgProvider] : l'EPG décrit l'avenir, le catch-up
/// décrit le passé. Seuls les programmes dont la fin est passée et pas trop
/// anciens ([kCatchUpWindow]) sont retournés, du plus récent au plus ancien.
final channelCatchUpProvider =
    FutureProvider.autoDispose.family<List<EPGProgram>, String>(
```

## 5. Affichage


### 5.1 `ReplayScreen` (niveau 1 : chaînes · niveau 2 : programmes)

`lib/features/replay/replay_screen.dart`  (lignes 1-806)

```dart
import 'package:flutter/material.dart';

import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/widgets/categories_rail.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/features/favorites/widgets/favorite_toggle.dart';
import 'package:orbit_3d_flutter/features/live_tv/channel_groups.dart';
import 'package:orbit_3d_flutter/features/live_tv/widgets/channel_grid_card.dart';
import 'package:orbit_3d_flutter/features/player/player_screen.dart';
import 'package:orbit_3d_flutter/models/category.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/providers/recently_watched_provider.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';

/// Replay (catch-up) — navigation à deux niveaux.
///
/// ## Ce que le Replay n'est pas
///
/// Le Replay n'est pas la grille des programmes lue à l'envers. La grille
/// ([EPG (grille)]) décrit ce qui passe et ce qui va passer ; le Replay décrit
/// ce que le panel permet **de rattraper**, et cette information ne vit pas
/// dans la grille. Mesuré sur le panel du 30/09 : l'EPG global ne fournit
/// **aucun** programme rejouable (`epg=0`), parce qu'un guide TV est tourné
/// vers l'avenir. Confondre les deux donnait un écran vide.
///
/// ## Pourquoi deux écrans
///
/// Le catalogue annonce plus de 1400 chaînes réplayables, et le panel ne
/// publie le catch-up que chaîne par chaîne (`get_short_epg`, un appel). Tout
/// sonder en bloc — ce que faisait la sonde de 40 chaînes au démarrage —
/// déclenche une tempête de 429 qui fait échouer l'EPG, les Films et le Live
/// TV au passage. Le découpage en deux niveaux est donc une contrainte du
/// panel, pas un choix de présentation :
///
/// - **niveau 1** : les chaînes replayables, lues dans le catalogue déjà
///   chargé, groupées par pays. Aucun appel réseau ;
/// - **niveau 2** : les programmes d'une chaîne, un seul appel, au choix.
///
/// Le niveau 1 réutilise la tuile de chaîne du Live TV : c'est le même objet,
/// il doit avoir la même taille et la même apparence.
class ReplayScreen extends ConsumerStatefulWidget {
  const ReplayScreen({super.key});

  @override
  ConsumerState<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends ConsumerState<ReplayScreen> {
  /// Chaîne ouverte au niveau 2, ou `null` au niveau 1.
  Channel? _selected;

  void _open(Channel channel) => setState(() => _selected = channel);

  void _close() => setState(() => _selected = null);

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(liveChannelsProvider);
    final selected = _selected;

    return Scaffold(
      appBar: AppBar(
        // Le retour remonte d'un cran : du niveau 2 vers la grille des
        // chaînes, et de la grille vers l'écran précédent.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Retour',
          onPressed: () {
            if (selected != null) {
              _close();
            } else {
              context.canPop() ? context.pop() : context.go('/home');
            }
          },
        ),
        title: Text(selected?.name ?? 'Replay'),
        actions: [
          if (selected != null)
            IconButton(
              tooltip: 'Rafraîchir',
              icon: const Icon(Icons.refresh),
              // On recharge CETTE chaîne, pas tout le catalogue : c'est le
              // seul appel que l'écran est autorisé à faire.
              onPressed: () =>
                  ref.invalidate(channelReplaysProvider(selected.id)),
            ),
        ],
      ),
      body: channelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(userFriendlyError(err))),
        data: (channels) {
          // Le catalogue est la seule source du niveau 1 : `supportsReplay`
          // vient de `get_live_streams`, déjà chargé pour le Live TV. Aucun
          // appel supplémentaire.
          final replayable = channels.where((c) => c.supportsReplay).toList();
          final open = selected;
          if (open == null) {
            if (replayable.isEmpty) {
              return const _NoReplayAtAll();
            }
            return _ChannelGrid(channels: replayable, onOpen: _open);
          }
          return _ChannelReplaysView(channel: open);
        },
      ),
    );
  }
}

/// AucunReplay : le panel ne publie de catch-up sur aucune chaîne du
/// catalogue.
class _NoReplayAtAll extends StatelessWidget {
  const _NoReplayAtAll();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.replay_rounded,
                size: 56, color: theme.colorScheme.outline,),
            const SizedBox(height: 12),
            Text('Aucun replay disponible', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              "Aucune chaîne de cet abonnement ne déclare de catch-up.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Niveau 1 : les chaînes replayables, groupées par pays.
class _ChannelGrid extends ConsumerStatefulWidget {
  const _ChannelGrid({required this.channels, required this.onOpen});

  final List<Channel> channels;
  final ValueChanged<Channel> onOpen;

  @override
  ConsumerState<_ChannelGrid> createState() => _ChannelGridState();
}

class _ChannelGridState extends ConsumerState<_ChannelGrid> {
  /// Catégorie du rail ; vide = toutes.
  String _selectedGroup = '';

  @override
  Widget build(BuildContext context) {
    final favoriteEntries = ref.watch(favoritesProvider);
    final recentEntries = ref.watch(recentlyWatchedProvider);

    final favIds = favoriteEntries.values
        .where((e) => e.type == ContentType.live)
        .map((e) => e.id)
        .toSet();
    final recentIds = recentEntries.values
        .where((e) => e.type == ContentType.live)
        .map((e) => e.id)
        .toSet();

    // Les groupes viennent du catalogue live, mais on ne retient que les
    // chaînes qui ont du replay : le rail ne propose pas de groupe vide.
    final groups = buildLiveChannelGroups(widget.channels);
    final grouped =
        groups.length > 1 || groups.firstOrNull?.name.isNotEmpty == true;

    final visible = _visible(
      widget.channels,
      groups: groups,
      favIds: favIds,
      recentIds: recentIds,
    );
    final categories = _categories(
      groups,
      replayIds: {for (final c in widget.channels) c.id},
      favIds: favIds,
      recentIds: recentIds,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (grouped && categories.isNotEmpty)
          CategoriesRail(
            categories: categories,
            selectedId: _selectedGroup,
            onSelected: (id) => setState(() => _selectedGroup = id),
          ),
        Expanded(
          child: visible.isEmpty
              ? _EmptyCategory(groupId: _selectedGroup)
              : GridView.builder(
                  padding: channelGridPadding,
                  // Même tuile que le Live TV : le Replay montre des chaînes,
                  // il doit les montrer comme le Live TV.
                  gridDelegate: channelGridDelegate,
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final channel = visible[index];
                    return ChannelGridCard(
                      name: channel.name,
                      logoUrl: channel.logoUrl,
                      badgeNumber: channel.orderNum,
                      favoriteEntry: FavoriteEntry(
                        type: ContentType.live,
                        id: channel.id,
                        title: channel.name,
                        posterUrl: channel.logoUrl,
                        subtitle: channel.groupLabel,
                        streamUrl: channel.streamUrl,
                      ),
                      onTap: () => widget.onOpen(channel),
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<Channel> _visible(
    List<Channel> channels, {
    required List<ChannelGroup> groups,
    required Set<String> favIds,
    required Set<String> recentIds,
  }) {
    final List<Channel> visible;
    if (_selectedGroup == 'fav') {
      visible = channels.where((c) => favIds.contains(c.id)).toList();
    } else if (_selectedGroup == 'recent') {
      visible = channels.where((c) => recentIds.contains(c.id)).toList();
    } else if (_selectedGroup.startsWith('g')) {
      final index = int.tryParse(_selectedGroup.substring(1));
      if (index != null && index >= 0 && index < groups.length) {
        final ids = groups[index].channels.map((c) => c.id).toSet();
        visible = channels.where((c) => ids.contains(c.id)).toList();
      } else {
        visible = const [];
      }
    } else {
      visible = channels;
    }
    return visible
      ..sort((a, b) {
        final numA = a.orderNum > 0 ? a.orderNum : 1 << 30;
        final numB = b.orderNum > 0 ? b.orderNum : 1 << 30;
        return numA.compareTo(numB);
      });
  }

  /// Rail « Tous / Favoris / Récemment / pays », décompté sur les chaînes
  /// rejouables et non sur le catalogue complet.
  static List<MediaCategory> _categories(
    List<ChannelGroup> groups, {
    required Set<String> replayIds,
    required Set<String> favIds,
    required Set<String> recentIds,
  }) {
    return [
      MediaCategory(id: '', name: 'Tous', count: replayIds.length),
      MediaCategory(
        id: 'fav',
        name: 'Favoris',
        count: replayIds.where(favIds.contains).length,
      ),
      MediaCategory(
        id: 'recent',
        name: 'Récemment',
        count: replayIds.where(recentIds.contains).length,
      ),
      for (var i = 0; i < groups.length; i++)
        MediaCategory(
          id: 'g$i',
          name: groups[i].name.isEmpty ? 'Non groupé' : groups[i].name,
          count:
              groups[i].channels.where((c) => replayIds.contains(c.id)).length,
        ),
    ];
  }
}

/// Niveau 2 : les programmes rejouables d'UNE chaîne.
///
/// Un seul appel réseau, au montage ([channelReplaysProvider]). Le détail est
/// donc indisponible tant que la réponse n'est pas là, ce qui est le prix de
/// la fenêtre par compte : on ne peut pas lister 14 jours de toutes les chaînes
/// sans que le panel nous coupe.
class _ChannelReplaysView extends ConsumerWidget {
  const _ChannelReplaysView({required this.channel});

  final Channel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(channelReplaysProvider(channel.id));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                userFriendlyError(err),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () =>
                    ref.invalidate(channelReplaysProvider(channel.id)),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
      data: (items) => _ReplayDayView(channel: channel, items: items),
    );
  }
}

/// Bandeau de chaîne : numéro et nom brut, comme sur la maquette.
///
/// L'AppBar porte le même nom, mais le bandeau identifie la ligne dans le flux
/// du programme et reste visible quand la liste défile.
class _ChannelBand extends StatelessWidget {
  const _ChannelBand({required this.channel});

  final Channel channel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = AppLocalizations.of(context);
    return Container(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          if (channel.orderNum > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '.${channel.orderNum}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSecondaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channel.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (channel.supportsReplay)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _archiveBadgeLabel(l, channel),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fenêtre de replay du compte, en clair.
  ///
  /// `catchup-days` / `tv_archive_duration` décrit ce que le compte permet
  /// réellement. Sans elle à l'écran, un programme absent semblait cassé alors
  /// que la limite venait du compte : l'utilisateur ne pouvait pas distinguer
  /// « le panel ne publie rien » de « c'est plus vieux que mon abonnement ».
  static String _archiveBadgeLabel(
    AppLocalizations l,
    Channel channel,
  ) {
    // Fenêtre EFFECTIVE : on suit la durée annoncée par l'abonnement (7/14 j
    // compris), plus de plafond à 48 h.
    final days = channel.archiveDays;
    if (days > 0) return l.replayWindowBadge(days);
    final hours = ApiService.archiveWindow(channel).inHours;
    return l.replayWindowBadgeHours(hours);
  }
}

/// Le détail : bandeau de chaîne, onglets de jours, puis les programmes du
/// jour en lignes de table.
class _ReplayDayView extends StatefulWidget {
  const _ReplayDayView({required this.channel, required this.items});

  final Channel channel;
  final List<ReplayItem> items;

  @override
  State<_ReplayDayView> createState() => _ReplayDayViewState();
}

class _ReplayDayViewState extends State<_ReplayDayView> {
  /// Jour sélectionné. `null` tant que l'utilisateur n'a pas choisi : on part
  /// alors sur le jour le plus récent, qui est le cas d'usage dominant.
  DateTime? _selectedDay;

  static const _months = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Ordre chronologique ASCENDANT : la journée se lit comme une grille TV,
    // de 00:00 en haut à 23:59 en bas. L'ordre inverse (20:50, 20:45, 20:00…)
    // imposait de remonter la liste pour suivre l'heure.
    final sorted = [...widget.items]..sort(
        (a, b) => (a.startAt ?? a.startDate ?? DateTime(1900))
            .compareTo(b.startAt ?? b.startDate ?? DateTime(1900)),
      );

    // Regroupement par jour local.
    final byDay = <DateTime, List<ReplayItem>>{};
    for (final item in sorted) {
      final d = (item.startAt ?? item.startDate)?.toLocal();
      if (d == null) continue;
      byDay
          .putIfAbsent(DateTime(d.year, d.month, d.day), () => <ReplayItem>[])
          .add(item);
    }

    if (byDay.isEmpty) {
      // Le bandeau reste affiché même sans programme : c'est lui qui dit de
      // quelle chaîne il s'agit, et l'utilisateur vient de choisir cette
      // chaîne. Le faire disparaître avec la liste rendait l'écran vide sans
      // sujet.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChannelBand(channel: widget.channel),
          const Divider(height: 1),
          Expanded(child: _noProgram(theme, scheme)),
        ],
      );
    }

    // Le jour le plus récent reste le jour affiché par défaut (c'est le cas
    // d'usage dominant), mais les onglets se lisent de gauche à droite dans le
    // sens du temps : le plus ancien à gauche, aujourd'hui à droite. L'ordre
    // inverse — aujourd'hui, hier, avant-hier — se lisait à l'envers.
    final newestFirst = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final active =
        newestFirst.contains(_selectedDay) ? _selectedDay! : newestFirst.first;
    final tabs = newestFirst.reversed.toList(growable: false);
    final items = byDay[active] ?? const <ReplayItem>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Bandeau de chaîne ──────────────────────────────────────────────
        _ChannelBand(channel: widget.channel),
        const Divider(height: 1),
        // ── Onglets de jours ─────────────────────────────────────────────
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final day = tabs[i];
              final isActive = day == active;
              return ChoiceChip(
                label: Text(_tabLabel(day)),
                selected: isActive,
                onSelected: (_) => setState(() => _selectedDay = day),
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  color: isActive ? scheme.onSecondaryContainer : null,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                ),
                selectedColor: scheme.secondaryContainer,
                backgroundColor: scheme.surfaceContainerHighest,
                side: BorderSide(
                  color: isActive
                      ? scheme.primary
                      : scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        // ── Lignes du jour sélectionné ───────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: items.length,
            // Un filet entre les lignes : la lecture est verticale et continue,
            // comme les bandes de la grille des programmes.
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _ReplaySlotRow(
              slot: items[i],
              dayStamp: _stampPrefix(active),
            ),
          ),
        ),
      ],
    );
  }

  /// Préfixe de date commun à toutes les lignes d'un même jour : « sept. 12 ».
  String _stampPrefix(DateTime day) => '${day.day} ${_months[day.month - 1]}';

  /// Message quand la chaîne n'a rien de rejouable.
  ///
  /// Les deux causes sont distinguées dans le texte : soit le panel ne publie
  /// rien pour cette chaîne, soit la fenêtre du compte ne couvre pas ce
  /// programme. Un « aucun replay » nu ne permettait aucune de ces réponses.
  Widget _noProgram(ThemeData theme, ColorScheme scheme) {
    final l = AppLocalizations.of(context);
    // La distinction « le panel ne publie rien » / « au-delà de la fenêtre »
    // reste portée par ce que l'abonnement annonce.
    final days = widget.channel.archiveDays;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.replay_rounded, size: 48, color: scheme.outline),
            const SizedBox(height: 12),
            Text(l.replayNoAvailable, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              days > 0
                  ? l.replayNoneInArchiveDays(days)
                  : l.replayNonePublished,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _tabLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return 'Hier';
    return '${_months[day.month - 1].toUpperCase()} ${day.day}';
  }
}

/// Une ligne de la table : titre, intervalle daté, description.
class _ReplaySlotRow extends StatelessWidget {
  const _ReplaySlotRow({required this.slot, this.dayStamp});

  final ReplayItem slot;

  /// Date du jour, préfixée aux horaires (« sept. 12, 10:45 »).
  final String? dayStamp;

  String _hhmm(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }

  /// « sept. 12, 10:45 - sept. 12, 11:25 », ou l'intervalle court si la date
  /// n'est pas connue.
  String get _range {
    final start = slot.startAt;
    final end = slot.endAt;
    if (start == null || end == null) {
      if (slot.startTime.isEmpty) return 'Replay disponible';
      return '${slot.startTime} - ${slot.endTime}';
    }
    final day = dayStamp ?? '';
    final s = day.isEmpty ? _hhmm(start) : '$day, ${_hhmm(start)}';
    final e = day.isEmpty ? _hhmm(end) : '$day, ${_hhmm(end)}';
    return '$s - $e';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TvFocus(
      onActivate: () => _play(context),
      // Ligne de table : ni carte ni ombre. Le relief faisait lire ces
      // programmes comme des objets empilés, alors que la maquette les veut en
      // bandes successives.
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _play(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre d'abord, puis l'intervalle : l'ordre de la maquette.
                // L'inverser donnait l'horaire comme une ligne d'en-tête et le
                // titre comme une légende.
                Text(
                  slot.title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  _range,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (slot.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    slot.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (slot.host.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          slot.host,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.play_circle_outline_rounded,
                        size: 26,
                      ),
                      const SizedBox(width: 8),
                      FavoriteToggle(entry: _favoriteEntry),
                    ],
                  ),
                ] else
                  Row(
                    children: [
                      const Spacer(),
                      const Icon(Icons.play_circle_outline_rounded, size: 26),
                      const SizedBox(width: 8),
                      FavoriteToggle(entry: _favoriteEntry),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Libellé de l'intervalle, repris par le bouton favori et par la lecture.
  String get _slotSubtitle => slot.startTime.isEmpty
      ? 'Replay disponible'
      : '${slot.startTime} - ${slot.endTime}';

  /// Entrée favorite du créneau.
  ///
  /// L'onglet Replay des favoris était vide : rien ne permetait d'y ajouter
  /// un replay, `ContentType.replay` n'étant créé que pour l'historique de
  /// lecture. Ce bouton est ce qui manquait.
  FavoriteEntry get _favoriteEntry => FavoriteEntry(
        type: ContentType.replay,
        id: slot.id,
        title: slot.title,
        subtitle: _slotSubtitle,
        streamUrl: slot.streamUrl,
      );

  void _play(BuildContext context) {
    final subtitle = _slotSubtitle;
    context.push(
      '/player',
      extra: PlayerRouteData(
        streamUrl: slot.streamUrl,
        title: slot.title,
        contentType: PlaybackContentType.replay,
        subtitle: subtitle,
        favorite: FavoriteEntry(
          type: ContentType.replay,
          id: slot.id,
          title: slot.title,
          subtitle: subtitle,
          streamUrl: slot.streamUrl,
        ),
      ),
    );
  }
}

/// État vide d'une catégorie du rail (favoris, récents, groupe vide).
class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (icon, title, message) = switch (groupId) {
      'fav' => (
          Icons.favorite_border_rounded,
          'Aucune chaîne favorite',
          "Appuie sur le cœur d'une chaîne pour la retrouver ici.",
        ),
      'recent' => (
          Icons.history_rounded,
          'Aucune chaîne récente',
          'Les chaînes regardées s\'afficheront ici.',
        ),
      _ => (
          Icons.live_tv_outlined,
          'Aucune chaîne dans ce groupe',
          'Ce groupe ne contient aucune chaîne rejouable.',
        ),
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: scheme.outline),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
```

### 5.2 `CatchUpScreen` (rattrapage depuis l’EPG)

`lib/features/epg/widgets/catch_up_screen.dart`  (lignes 1-451)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/features/epg/replay_utils.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';
import 'package:orbit_3d_flutter/core/widgets/cached_image.dart';

/// Écran Catch-up (rattrapage) pour une chaîne spécifique.
///
/// Affiche :
/// - Header avec logo/nom de la chaîne
/// - Barre horizontale de dates (7-14 jours glissants)
/// - Liste verticale des programmes EPG du jour sélectionné
///   avec titre, horaire, description complète, et bouton Replay si disponible.
class CatchUpScreen extends ConsumerWidget {
  const CatchUpScreen({
    super.key,
    required this.channel,
  });

  final Channel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    // Programmes passés + à venir via l'EPG COMPLET de la chaîne
    // (`get_simple_data_table`), source du rattrapage multi-jours.
    final catchUpAsync = ref.watch(channelCatchUpProvider(channel.id));

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12141C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            if (channel.logoUrl.isNotEmpty)
              CachedImage(
                imageUrl: channel.logoUrl,
                height: 28,
                width: 28,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.tv, color: Colors.white70, size: 28),
              )
            else
              const Icon(Icons.tv, color: Colors.white70, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                channel.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: catchUpAsync.when(
        data: (programs) {
          if (programs.isEmpty) {
            return Center(
              child: Text(
                l.noProgramInfoAvailable,
                style: const TextStyle(color: Colors.white38, fontSize: 16),
              ),
            );
          }
          // Grouper par date (clé yyyy-MM-dd)
          final byDate = <String, List<EPGProgram>>{};
          for (final p in programs) {
            final key = _dateKey(p.start);
            (byDate[key] ??= <EPGProgram>[]).add(p);
          }
          // Trier les dates : plus récent d'abord
          final dates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));
          // Date sélectionnée par défaut : aujourd'hui si présent, sinon la plus récente
          final now = DateTime.now();
          final todayKey = _dateKey(now);
          final defaultDate = dates.contains(todayKey)
              ? todayKey
              : (dates.isNotEmpty ? dates.first : null);

          return _CatchUpContent(
            channel: channel,
            byDate: byDate,
            dates: dates,
            initialDateKey: defaultDate,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(userFriendlyError(e))),
      ),
    );
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Contenu avec état (date sélectionnée)
class _CatchUpContent extends ConsumerStatefulWidget {
  const _CatchUpContent({
    required this.channel,
    required this.byDate,
    required this.dates,
    this.initialDateKey,
  });

  final Channel channel;
  final Map<String, List<EPGProgram>> byDate;
  final List<String> dates;
  final String? initialDateKey;

  @override
  ConsumerState<_CatchUpContent> createState() => _CatchUpContentState();
}

class _CatchUpContentState extends ConsumerState<_CatchUpContent> {
  late String? _selectedDateKey;

  @override
  void initState() {
    super.initState();
    _selectedDateKey = widget.initialDateKey;
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedDateKey == null || widget.dates.isEmpty) {
      return const SizedBox.shrink();
    }

    final programs = widget.byDate[_selectedDateKey!] ?? [];
    final now = DateTime.now();

    return Column(
      children: [
        // Barre de dates horizontale (scrollable)
        _DatePickerBar(
          availableDateKeys: widget.dates,
          selectedDateKey: _selectedDateKey!,
          onDateSelected: (key) => setState(() => _selectedDateKey = key),
        ),
        // Liste des programmes
        Expanded(
          child: programs.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context).noProgramInfoAvailable,
                    style: const TextStyle(color: Colors.white38, fontSize: 16),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: programs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final program = programs[index];
                    final replayable = isReplayableProgram(
                      program,
                      now: now,
                      channelSupportsReplay: widget.channel.supportsReplay,
                    );
                    return _ProgramTile(
                      program: program,
                      channel: widget.channel,
                      replayable: replayable,
                      onReplayTap:
                          replayable ? () => _playReplay(program) : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _playReplay(EPGProgram program) async {
    final sub = ref.read(activeSubscriptionProvider);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    if (sub == null ||
        sub.type != SubscriptionType.xtream ||
        sub.baseUrl == null ||
        sub.username == null ||
        sub.password == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
              'Replay indisponible : non pris en charge par cet abonnement (M3U).',),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Un seul constructeur d'URL de replay pour toute l'application.
    //
    // Cet écran construisait l'URL lui-même, au format
    // `/streaming/timeshift.php?...`, alors que le Replay passait par
    // `replayStreamUrl`, qui essaie d'abord le `catchup-source` du panel puis la
    // convention `/timeshift/...`. Deux formats pour la même chose, dont un seul
    // fonctionne sur ce panel : le rattrapage depuis l'EPG échouait là où le
    // Replay aboutissait.
    final url = ref.read(apiServiceProvider).replayStreamUrl(
          channel: widget.channel,
          baseUrl: sub.baseUrl!,
          username: sub.username!,
          password: sub.password!,
          startEpoch: program.start.millisecondsSinceEpoch ~/ 1000,
          endEpoch: program.end.millisecondsSinceEpoch ~/ 1000,
        );

    if (url.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(userFriendlyError(Exception('URL replay invalide'))),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    context.pushNamed(
      'player',
      extra: {
        'streamUrl': url,
        'title': '${program.title} (replay)',
        'contentType': 'replay',
        'channelId': widget.channel.id,
      },
    );
  }
}

/// Barre horizontale scrollable de boutons de date (JJ MMM)
class _DatePickerBar extends StatelessWidget {
  const _DatePickerBar({
    required this.availableDateKeys,
    required this.selectedDateKey,
    required this.onDateSelected,
  });

  final List<String> availableDateKeys;
  final String selectedDateKey;
  final ValueChanged<String> onDateSelected;

  @override
  Widget build(BuildContext context) {
    if (availableDateKeys.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: availableDateKeys.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final key = availableDateKeys[index];
          final parts = key.split('-');
          final day = int.tryParse(parts[2]) ?? 1;
          final month = int.tryParse(parts[1]) ?? 1;
          final isSelected = key == selectedDateKey;
          final label = '$day ${_monthShortFr(month)}';
          return ChoiceChip(
            label: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onDateSelected(key),
            selectedColor: const Color(0xFF6EE7B7),
            backgroundColor: const Color(0xFF1A1D26),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            side: BorderSide(
              color: isSelected ? Colors.transparent : Colors.white12,
              width: 1,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }

  String _monthShortFr(int m) {
    const months = [
      '',
      'JANV',
      'FÉVR',
      'MARS',
      'AVR',
      'MAI',
      'JUIN',
      'JUIL',
      'AOÛT',
      'SEPT',
      'OCT',
      'NOV',
      'DÉC',
    ];
    return months[m];
  }
}

/// Tuile programme : titre, horaire, description, badge replay + bouton
class _ProgramTile extends StatelessWidget {
  const _ProgramTile({
    required this.program,
    required this.channel,
    required this.replayable,
    this.onReplayTap,
  });

  final EPGProgram program;
  final Channel channel;
  final bool replayable;
  final VoidCallback? onReplayTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final timeStr = '${_fmt(program.start)} - ${_fmt(program.end)}';
    final catColor = program.categoryColor;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16181E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: catColor.withValues(alpha: 0.3), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne titre + badge catégorie + badge replay
          Row(
            children: [
              Expanded(
                child: Text(
                  program.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (program.categoryDisplayName.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: catColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    program.categoryDisplayName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,),
                  ),
                ),
              if (replayable) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6EE7B7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'REPLAY',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Horaire
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text(timeStr,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),),
            ],
          ),
          // Description
          if (program.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              program.description,
              style: const TextStyle(
                  color: Colors.white60, fontSize: 13, height: 1.4,),
            ),
          ],
          // Bouton Replay
          if (replayable && onReplayTap != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.replay, size: 18),
                label: Text(l.epgStartReplay),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6EE7B7),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),),
                ),
                onPressed: onReplayTap,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
```

## 6. Points d’entrée et routes


### 6.1 Route `/replay`

`lib/main.dart`  (lignes 663-673)

```dart
        GoRoute(
          path: '/replay',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            restorationId: 'replay',
            child: const WithBackHandling(
              meta: RouteMeta.popOrFallback('/home', restorationId: 'replay'),
              child: ReplayScreen(),
            ),
          ),
        ),
```

### 6.2 Depuis la grille EPG (appui long sur une chaîne)

`lib/features/epg/epg_screen.dart`  (lignes 620-655)

```dart
    if (mounted) {
      widget.loadingChannels.remove(channelName);
    }
  }

  /// Rafraîchissement FORCÉ (bouton + tirer-pour-rafraîchir).
  ///
  /// Passe par `EPGDataCache.forceRefresh` : invalide le cache mémoire et
  /// supprime le tampon disque avant de retélécharger. Un simple `_loadAllEpg`
  /// n'aurait rien rafraîchi tant que le cache avait moins de 30 min.
  Future<void> _refreshForced() async {
    if (_refreshing) return;
    final api = ref.read(apiServiceProvider);
    final cache = ref.read(epgDataCacheProvider);
    setState(() => _refreshing = true);
    final result = await safeAsync(
      () => cache.forceRefresh(api),
      context: '_refreshForced forceRefresh',
    );
    if (!mounted) return;
    if (!result.isSuccess) {
      // Jamais d'échec silencieux : sans ce message, l'utilisateur croirait
      // que les données sont à jour alors que le panel n'a pas répondu.
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text(
            'Rafraîchissement EPG impossible : le panel n\'a pas répondu. '
            'Les programmes affichés restent ceux du dernier chargement.',
          ),
        ),
      );
    }
    setState(() => _refreshing = false);
    // Reconstruit `_epgData` depuis le cache (désormais frais).
    await _loadAllEpg();
  }
```

## 7. Points de vigilance (résumé des commentaires du code)

- **Deux formats d’URL** : le template `catchup-source` du provider prime ; `buildXtreamTimeshiftUrl` n’est qu’un repli (durée en minutes, date `YYYY-MM-DD:HH-mm`).
- **`get_short_epg` n’est pas la source du Replay** : il plafonne à 4 entrées futures ; la source complète est l’EPG global (XMLTV) et, par chaîne, `get_simple_data_table`.
- **Fenêtre** : `archiveWindow(channel)` = `tv_archive_duration` / `catchup-days` sinon 48 h. Un 48 h en dur filtrait à tort les replays d’un compte à 7/14 jours.
- **Budget anti-429** : la sonde est plafonnée (`replayProbeSet` : budget 40, 3 par groupe, concurrence 2) — sonder tout le catalogue déclenche l’anti-leech et vide EPG/Films.
- **Décodage base64** : titres et synopsis passent par `PanelText.decode` (les deux appels d’EPG encodent en base64 sur ce panneau).
- **Lecture** : l’URL finale passe par `replayStreamUrl` (template d’abord), puis `/player` avec `contentType: replay`.
