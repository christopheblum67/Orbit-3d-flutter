import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/services/subtitle_discovery.dart';
import 'package:orbit_3d_flutter/services/xtream_live_catalog_service.dart';

class XtreamSubtitleService {
  XtreamSubtitleService({
    required Future<Map<String, String?>> Function() activeSub,
    required Future<Response<dynamic>> Function(String url) get,
    required PlayerApiUrlBuilder buildApiUrl,
  })  : _activeSub = activeSub,
        _get = get,
        _playerApiUrl = buildApiUrl;

  final Future<Map<String, String?>> Function() _activeSub;
  final Future<Response<dynamic>> Function(String url) _get;
  final PlayerApiUrlBuilder _playerApiUrl;
  final LoggerService _logger = LoggerService.instance;

  /// Découvre les pistes de sous-titres publiées pour un contenu.
  ///
  /// Interroge `get_vod_info` (film) ou `get_series_info` (série) et en
  /// extrait les sous-titres. Aucun standard n'impose le format de retour, les
  /// panels divergent : l'extraction est déléguée à [SubtitleDiscovery], qui
  /// accepte les variantes courantes et ne lève jamais.
  ///
  /// Retourne une liste vide si le panel n'en publie pas ou si l'appel échoue :
  /// l'absence de sous-titres ne doit pas être une erreur.
  /// Découvre les sous-titres d'un contenu.
  ///
  /// Renvoie les pistes trouvées, si elles sont DÉDUITES — des panels ne
  /// déclarent rien et servent les fichiers par convention d'URL, et
  /// l'interface doit le dire plutôt que présenter une supposition comme une
  /// certitude.
  Future<({List<SubtitleTrackRef> tracks, bool guessed})> discoverSubtitles(
    String contentId, {
    required bool isSeries,
    String? streamId,
  }) async {
    const nothing = (tracks: <SubtitleTrackRef>[], guessed: false);
    if (contentId.isEmpty) return nothing;
    final sub = await _activeSub();
    if (sub['type'] != 'xtream') return nothing;

    final url = _playerApiUrl(sub['baseUrl']!, 'player_api.php', {
      'username': sub['username']!,
      'password': sub['password']!,
      'action': isSeries ? 'get_series_info' : 'get_vod_info',
      if (isSeries) 'series_id': contentId else 'vod_id': contentId,
    });

    // Contexte de synthèse d'URL, pour le format le plus répandu : une liste de
    // codes langue sans URL. Pour un film, `vod_id` EST le stream id. Pour une
    // série, `series_id` ne l'est PAS : la convention de nommage attend le
    // stream id de l'ÉPISODE, que l'appelant doit fournir. Sans lui, on ne
    // synthétise rien — une piste déduite sur le mauvais identifiant pointe
    // vers le média d'une autre série.
    final context = SubtitleDiscoveryContext(
      baseUrl: sub['baseUrl']!,
      username: sub['username']!,
      password: sub['password']!,
      streamId: isSeries ? streamId : contentId,
    );

    final result =
        await safeAsync<({List<SubtitleTrackRef> tracks, bool guessed})>(
      () async {
        final response = await _get(url);
        // Relevé de la charge utile : « aucune piste disponible » est
        // indifférenciable entre un panel qui ne publie rien et un câblage
        // cassé de notre côté.
        _logSubtitlePayload(
          action: isSeries ? 'get_series_info' : 'get_vod_info',
          contentId: contentId,
          streamId: context.streamId ?? '',
          data: response.data,
        );

        final declared =
            SubtitleDiscovery.parse(response.data, context: context);
        if (declared.isNotEmpty) {
          return (tracks: declared, guessed: false);
        }

        // Aucune piste adressable dans la réponse. Deuxième voie : les codes
        // langue peuvent être déclarés PLUS PROFOND, notamment dans les objets
        // épisode d'une série, où le parseur ne va pas les chercher.
        var codes =
            SubtitleDiscovery.collectLanguageCodes(response.data).toList();
        var guessed = false;
        if (codes.isEmpty) {
          // Troisième voie : le panel ne déclare rien du tout — mesuré sur deux
          // contenus d'un même panel, `get_vod_info` comme `get_series_info`.
          // Ses fichiers existent pourtant, servis par convention d'URL. Sans
          // candidates, l'app ne peut rien proposer alors que la piste existe.
          codes = SubtitleDiscovery.defaultConventionLanguages(
            deviceLanguageCode: PlatformDispatcher.instance.locale.languageCode,
          );
          guessed = true;
        }

        // L'URL d'une piste se construit avec le stream id de l'épisode lu, pas
        // avec celui de l'épisode qui porte la déclaration.
        final synthesized = SubtitleDiscovery.synthesizeFromConvention(
          context: context,
          languages: codes,
        );
        _logger.info(
          'Sous-titres $contentId : ${synthesized.length} piste(s) '
          '${guessed ? 'CONVENTIONNELLES (le panel ne déclare rien)' : 'déclarées'} '
          '-> ${(codes.toList()..sort()).join(', ')}',
          tag: 'subtitle',
        );
        return (
          tracks: synthesized,
          guessed: guessed,
        );
      },
      context: 'ApiService.discoverSubtitles',
      fallbackValue: (
        tracks: const <SubtitleTrackRef>[],
        guessed: false,
      ),
    );
    final found = result.valueOrNull ??
        (tracks: const <SubtitleTrackRef>[], guessed: false);
    final effectiveStreamId = context.streamId ?? '';
    _logger.info(
      'Sous-titres ${isSeries ? 'série' : 'film'} $contentId : '
      '${found.tracks.length} piste(s), stream id « $effectiveStreamId »'
      '${effectiveStreamId.isEmpty ? ' (AUCUN : URL non synthétisable)' : ''}',
      tag: 'subtitle',
    );
    return found;
  }

  /// Journalise la forme de la réponse `subtitles` renvoyée par le panel.
  void _logSubtitlePayload({
    required String action,
    required String contentId,
    required String streamId,
    required Object? data,
  }) {
    Map<String, dynamic>? found;
    var depth = 0;
    void walk(Object? node) {
      if (depth > 4 || found != null) return;
      depth++;
      if (node is Map) {
        final map = Map<String, dynamic>.from(node);
        for (final key in const [
          'subtitles',
          'subtitle',
        ]) {
          if (map.containsKey(key)) {
            found = {'$action.$key': map[key]};
            return;
          }
        }
        walk(map['info']);
      }
    }

    walk(data);
    if (found == null) {
      _logger.info(
        'Sous-titres $action $contentId : aucun champ « subtitles » dans la '
        'réponse (stream id « $streamId »)',
        tag: 'subtitle',
      );
      return;
    }
    final raw = found!.values.first;
    final summary = raw is List
        ? '${raw.length} entrée(s) : ${raw.take(3).join(' | ')}'
        : '$raw';
    _logger.info(
      'Sous-titres $action $contentId : $summary',
      tag: 'subtitle',
    );
  }
}
