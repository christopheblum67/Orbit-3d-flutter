import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/features/epg/replay_utils.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/epg_program.dart';
import 'package:orbit_3d_flutter/models/replay_item.dart';
import 'package:orbit_3d_flutter/services/catchup_url_builder.dart';
import 'package:orbit_3d_flutter/services/global_epg_replay_service.dart';
import 'package:orbit_3d_flutter/services/replay_selection.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart';
import 'package:orbit_3d_flutter/services/xtream_live_catalog_service.dart';
import 'package:orbit_3d_flutter/services/xtream_epg_parser.dart';
import 'package:orbit_3d_flutter/services/xtream_replay_mapper.dart';
import 'package:orbit_3d_flutter/services/xtream_url_builder.dart';

class XtreamReplayService {
  XtreamReplayService({
    required Future<Map<String, String?>> Function() activeSub,
    required Future<Response<dynamic>> Function(String url) get,
    required PlayerApiUrlBuilder buildApiUrl,
    required this.fetchLiveChannels,
  })  : _activeSub = activeSub,
        _get = get,
        _playerApiUrl = buildApiUrl;

  final Future<Map<String, String?>> Function() _activeSub;
  final Future<Response<dynamic>> Function(String url) _get;
  final PlayerApiUrlBuilder _playerApiUrl;
  final Future<List<Channel>> Function() fetchLiveChannels;
  final LoggerService _logger = LoggerService.instance;

  // ---------- Replays ----------

  /// Nombre d'interrogations EPG courtes exécutées en parallèle.
  ///
  /// Abaisse de 8 à 2 après les tempêtes de 429 observées : la sonde
  /// interroge jusqu'à 40 chaînes et le panneau applique un quota GLOBAL —
  /// huit sondes simultanées suffisaient à le faire répondre 429 à toutes les
  /// requêtes de l'app, y compris celles des écrans Films et Séries. Le gain
  /// de temps de la sonde est marginal (l'EPG global alimente le replay
  /// multi-jours) ; le coût d'un catalogue bloqué, lui, est total.
  ///
  /// Le portillon [ApiRequestGate] limite par ailleurs l'ensemble des appels
  /// concurrents à 3 : ce réglage ne gouverne que la sonde.
  static const int _probeConcurrency = 2;

  /// Nombre d'entrées demandées à ``get_short_epg``.
  ///
  /// Un programme TV dure en moyenne 30 à 90 minutes : 48 h de replay
  /// représentent 40 à 100 programmes selon la chaîne. On demande 100 pour
  /// couvrir la fenêtre entière, quitte à ce que le panel en renvoie moins.
  static const int _replayLimit = 100;

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
    return const GlobalEpgReplayService().build(
      programs: programs,
      channels: channels,
      now: DateTime.now(),
      archiveWindow: archiveWindow,
      formatTime: _formatReplayTime,
      buildUrl: (channel, startEpoch, endEpoch) => replayStreamUrl(
        channel: channel,
        baseUrl: baseUrl,
        username: username,
        password: password,
        startEpoch: startEpoch,
        endEpoch: endEpoch,
      ),
    );
  }

  /// Fusionne les replays issus de l'EPG global (autoritaires) avec ceux de
  /// `get_short_epg`, en dédupliquant sur chaîne + début de programme.
  ///
  /// L'EPG global passe en premier : il est plus complet. `get_short_epg` ne
  /// sert qu'à rattraper une chaîne absente du dump XMLTV.
  static List<ReplayItem> mergeReplays(
    List<ReplayItem> fromEpg,
    List<ReplayItem> fromShortEpg,
  ) =>
      ReplaySelection.merge(fromEpg, fromShortEpg);

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
  ) =>
      ReplaySelection.probeSet(channels, flagged);

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
        return const XtreamEpgParser().parseShortGuide(response.data, channel);
      },
      context: 'ApiService.fetchChannelEpgPrograms',
      fallbackValue: const <EPGProgram>[],
    );
    return result.getOrElse(const <EPGProgram>[]);
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
    final items = const XtreamReplayMapper().build(
      entries: entries,
      channel: channel,
      now: now,
      window: window,
      fullGuide: true,
      buildUrl: (start, end) => replayStreamUrl(
        channel: channel,
        baseUrl: baseUrl,
        username: username,
        password: password,
        startEpoch: start,
        endEpoch: end,
      ),
      formatTime: _formatReplayTime,
    );

    _logger.info(
      'Replay ${channel.name}: ${items.length} programme(s) rejouable(s) '
      'sur ${entries.length} de l\'EPG complet '
      '(fenêtre ${window == null ? "non déclarée" : "${window.inDays} j"}, '
      'archive ${channel.archiveDays} j)',
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
    return XtreamUrlBuilder.buildTimeshiftUrl(
      baseUrl,
      username,
      password,
      channel.id,
      start: startEpoch,
      end: endEpoch,
    );
  }

  /// Fenêtre de retroactivité d'une chaîne.
  ///
  /// `catchup-days` / `tv_archive_duration` est la fenêtre **de l'abonnement**
  /// — 48 h, 7 jours, 14 jours selon le compte. Si elle n'est pas déclarée,
  /// les programmes renvoyés par le panel ne sont pas coupés arbitrairement.
  static Duration? archiveWindow(Channel channel) {
    if (channel.archiveDays > 0) return Duration(days: channel.archiveDays);
    return null;
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
          // publie. On demande explicitement davantage de programmes.
          'limit': '$_replayLimit',
        });
        final response = await _get(url);
        final data = response.data;
        final list = data is List
            ? data
            : (data is Map
                ? (data['epg_listings'] as List? ?? const <dynamic>[])
                : const <dynamic>[]);
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
          final s =
              XtreamEpgParser.parseDate(map['start_timestamp'] ?? map['start']);
          final en =
              XtreamEpgParser.parseDate(map['stop_timestamp'] ?? map['end']);
          if (s == null || en == null) {
            sample.add('?');
            continue;
          }
          final delta = now.difference(s);
          final hours = (delta.inMinutes / 60).round();
          final state = en.isBefore(now) ? 'terminé' : 'à venir';
          final tooOld =
              window != null && delta > window ? ', hors fenêtre' : '';
          sample.add(
            '${_formatReplayTime(s, now)} ($hours h, $state$tooOld)',
          );
        }
        if (sample.isNotEmpty) {
          _logger.info(
            'Replay ${channel.name}: entrées = ${sample.join(' | ')} '
            '(fenêtre ${window == null ? "non déclarée" : "${window.inDays} j"})',
            tag: 'replay',
          );
        }
        final items = const XtreamReplayMapper().build(
          entries: list.whereType<Map>(),
          channel: channel,
          now: now,
          window: window,
          fullGuide: false,
          buildUrl: (start, end) => replayStreamUrl(
            channel: channel,
            baseUrl: baseUrl,
            username: username,
            password: password,
            startEpoch: start,
            endEpoch: end,
          ),
          formatTime: _formatReplayTime,
        );
        _logger.info(
          'Replay ${channel.name}: ${items.length} programme(s) rejouable(s) '
          'sur ${list.length} renvoyés par get_short_epg',
        );
        return items;
      },
      context: 'ApiService._fetchChannelReplayPrograms',
      fallbackValue: const <ReplayItem>[],
    );
    return result.getOrElse(const <ReplayItem>[]);
  }

  /// Replay M3U : les chaînes portant un attribut `catchup`/`timeshift`
  /// apparaissent directement comme rejouables.
  Future<List<ReplayItem>> _fetchM3uReplays(Map<String, String?> sub) async {
    // M3U playlists don't carry catch-up program metadata (what aired when).
    // Real catch-up requires an EPG source (XMLTV) to know what aired when.
    // The M3U `catchup`/`catchup-days` attributes only indicate *support*, not
    // program metadata. Returning empty here avoids false "Replay à Channel"
    // entries that just play the live stream.
    return const <ReplayItem>[];
  }

  /// « HH:mm » si même jour, sinon « d mois HH:mm » (ex. « 5 févr. 18:30 »).
  String _formatReplayTime(DateTime dt, DateTime now) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (sameDay) return '$h:$m';
    const months = [
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
    return '${local.day} ${months[local.month - 1]} $h:$m';
  }
}
