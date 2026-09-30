import 'dart:convert';
import 'dart:io';

/// Sonde la Discovery API d'un panel Xtream pour diagnostiquer la section
/// Replay : quelles chaînes exposent `tv_archive` / `radio_tv=dvr` /
/// `timeshift`, et ce que `get_short_epg` renvoie réellement.
///
/// Usage : dart run tool/probe_replay.dart <baseUrl> <user> <pass>
///
/// Les identifiants sont lus depuis les variables d'environnement
/// ORBIT_BASE_URL / ORBIT_USER / ORBIT_PASS pour ne pas les laisser dans
/// l'historique du shell.
Future<void> main(List<String> args) async {
  final base = args.isNotEmpty
      ? args[0]
      : Platform.environment['ORBIT_BASE_URL'] ?? '';
  final user =
      args.length > 1 ? args[1] : Platform.environment['ORBIT_USER'] ?? '';
  final pass =
      args.length > 2 ? args[2] : Platform.environment['ORBIT_PASS'] ?? '';
  if (base.isEmpty || user.isEmpty || pass.isEmpty) {
    stderr.writeln(
        'usage: dart run tool/probe_replay.dart <baseUrl> <user> <pass>');
    exitCode = 2;
    return;
  }

  final root = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  final api = '$root/player_api.php';

  final client = HttpClient();
  Future<dynamic> call(Map<String, String> params) async {
    final uri = Uri.parse(api).replace(queryParameters: {
      'username': user,
      'password': pass,
      ...params,
    });
    final req = await client.getUrl(uri);
    req.headers.set(HttpHeaders.userAgentHeader, 'OrbitIPTV/1.0');
    final res = await req.close();
    final bytes = <int>[];
    await for (final c in res) {
      bytes.addAll(c);
    }
    try {
      return jsonDecode(utf8.decode(bytes));
    } catch (_) {
      try {
        return jsonDecode(latin1.decode(bytes));
      } catch (_) {
        return null;
      }
    }
  }

  final auth = await call({'action': 'get_live_streams'});
  if (auth is! List) {
    stderr.writeln('Echec get_live_streams (verifiez identifiants / URL).');
    client.close();
    return;
  }
  final channels = auth.whereType<Map>().toList();
  stdout.writeln('Chaines live : ${channels.length}');

  var tvArchive = 0;
  var radioDvr = 0;
  var timeshift = 0;
  var withRealtime = 0;
  final flagged = <Map>[];
  for (final c in channels) {
    final archive = '${c['tv_archive']}'.toLowerCase();
    final radio = '${c['radio_tv']}'.toLowerCase();
    final ts = int.tryParse('${c['timeshift_seconds'] ?? 0}') ?? 0;
    final isArchive = archive == '1' || archive == 'true' || archive == 'yes';
    final isDvr = radio == 'dvr';
    if (isArchive) tvArchive++;
    if (isDvr) radioDvr++;
    if (ts > 0) {
      timeshift++;
      flagged.add(c);
    }
    if (isArchive || isDvr || ts > 0) withRealtime++;
    if (c['realtime_duration'] != null) withRealtime++;
  }
  stdout.writeln('tv_archive       : $tvArchive');
  stdout.writeln('radio_tv=dvr     : $radioDvr');
  stdout.writeln('timeshift>0      : $timeshift');
  stdout.writeln('realtime (idx)   : $withRealtime');

  if (flagged.isEmpty) {
    // Aucune chaine marque le DVR : on teste un echantillon, car beaucoup de
    // panels exposent le timeshift sans le declarer.
    for (final c in channels.take(3)) {
      final listing = await call({
        'action': 'get_short_epg',
        'stream_id': '${c['stream_id']}',
      });
      final n = listing is Map && listing['epg_listings'] is List
          ? (listing['epg_listings'] as List).length
          : 0;
      stdout.writeln('  sonde stream ${c['stream_id']} '
          '(${c['name']}) -> $n programmes');
    }
  } else {
    for (final c in flagged.take(3)) {
      final listing = await call({
        'action': 'get_short_epg',
        'stream_id': '${c['stream_id']}',
      });
      final n = listing is Map && listing['epg_listings'] is List
          ? (listing['epg_listings'] as List).length
          : 0;
      stdout.writeln('  DVR stream ${c['stream_id']} '
          '(${c['name']}) -> $n programmes');
    }
  }
  client.close();
}
