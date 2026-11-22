import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/models/series.dart';
import 'package:orbit_3d_flutter/providers/advanced_settings_provider.dart';

class PlayerRouteData {
  const PlayerRouteData({
    required this.streamUrl,
    this.title,
    this.channels = const [],
    this.index = 0,
    this.progressId,
    this.initialPositionMs,
    this.contentType = PlaybackContentType.live,
    this.favorite,
    this.posterUrl,
    this.subtitle,
    this.rating,
    this.genre,
    this.year = 0,
    this.seriesName,
    this.episodeLabel,
    this.series,
    this.episode,
    this.vodId,
    this.consecutiveEpisodes = 1,
    this.isLocalFile = false,
    this.headers,
  });

  final String streamUrl;
  final String? title;
  final List<Channel> channels;
  final int index;
  final String? progressId;
  final int? initialPositionMs;

  /// Identifiant VOD du film (`stream_id`), utilisé pour découvrir les
  /// sous-titres publiés par le panel. `null` pour un flux live ou une série.
  final String? vodId;
  final int consecutiveEpisodes;
  final bool isLocalFile;
  final Map<String, String>? headers;
  final PlaybackContentType contentType;

  /// Favori associé au contenu lancé (utilisé pour la lecture non live).
  /// En live, le favori est déduit de la chaîne courante.
  final FavoriteEntry? favorite;

  final String? posterUrl;
  final String? subtitle;
  final double? rating;
  final String? genre;
  final int year;
  final String? seriesName;
  final String? episodeLabel;

  /// Contexte série (lecture d'un épisode) : permet au player de poser le
  /// statut « vu » quand l'épisode atteint 80 % de progression.
  final Series? series;
  final Episode? episode;
}
