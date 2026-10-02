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
