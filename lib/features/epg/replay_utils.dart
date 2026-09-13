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

/// Construit l'URL Xtream timeshift d'un programme EPG passé
/// (`/streaming/timeshift.php?...`) à partir des champs Xtream.
///
/// Renvoie `null` si le type d'abonnement n'est pas Xtream (cas M3U/catchup :
/// la construction dépend du fournisseur et est gérée par l'écran Replay).
String? buildXtreamReplayUrl({
  required String baseUrl,
  required String username,
  required String password,
  required String channelId,
  required DateTime start,
  required DateTime end,
}) {
  final uri = Uri.tryParse(baseUrl);
  if (uri == null) return null;
  final startEpoch = start.millisecondsSinceEpoch ~/ 1000;
  final duration = (end.difference(start)).inSeconds;
  if (duration <= 0) return null;
  final trimmed = baseUrl.replaceAll(RegExp(r'/+$'), '');
  return '$trimmed/streaming/timeshift.php'
      '?username=${Uri.encodeComponent(username)}'
      '&password=${Uri.encodeComponent(password)}'
      '&stream=${Uri.encodeComponent(channelId)}'
      '&start=$startEpoch&duration=$duration';
}