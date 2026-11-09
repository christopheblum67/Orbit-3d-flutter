import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart';

/// Choisit uniquement la chaîne suivante lorsque la lecture est établie.
({int index, String url})? preloadCandidate({
  required List<Channel> channels,
  required int currentIndex,
  required bool hasCachedNext,
  required int? pendingIndex,
  required bool currentInitialized,
  required bool currentPlaying,
}) {
  final target = currentIndex + 1;
  if (target < 0 || target >= channels.length) return null;
  if (hasCachedNext || pendingIndex == target) return null;
  final url = channels[target].streamUrl;
  if (!isLikelyStreamUrl(url)) return null;
  if (!currentInitialized || !currentPlaying) return null;
  return (index: target, url: url);
}
