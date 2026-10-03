import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' show BytesBuilder;

import 'package:flutter/foundation.dart';
import 'package:orbit_3d_flutter/core/utils/language_label.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/services/subtitle_parser.dart';

/// Un sous-titre trouvé en ligne, prêt à être téléchargé.
@immutable
class OpenSubtitlesHit {
  const OpenSubtitlesHit({
    required this.fileId,
    required this.language,
    this.release = '',
    this.isForced = false,
    this.isHearingImpaired = false,
    this.downloadCount = 0,
    this.rating = 0,
  });

  /// Identifiant du fichier chez OpenSubtitles.
  ///
  /// L'API le renvoie comme **chaîne** dans le champ `id` de l'enveloppe. Le
  /// champ `attributes.file_id` n'existe plus : le lire renvoyait une chaîne
  /// vide, et le téléchargement répondait 0 octet.
  final int fileId;

  /// Code langue renvoyé par le service (`fr`, `en`).
  final String language;

  /// Édition (« Director's Cut », « VOSTFR »…).
  ///
  /// Remplace le nom de fichier, que l'API ne renvoie plus. C'est ce qui
  /// distingue deux sous-titres de la même langue : sans lui, deux entrées
  /// françaises seraient indiscernables.
  final String release;

  final bool isForced;
  final bool isHearingImpaired;
  final int downloadCount;
  final double rating;

  /// Libellé affichable.
  ///
  /// On réutilise [LanguageLabel] : la table de traduction est unique dans
  /// l'application. L'édition est ajoutée à la suite quand elle existe, sinon
  /// deux pistes de la même langue seraient impossibles à distinguer.
  String get label {
    final base = LanguageLabel.of(language, fallback: language);
    final trimmed = release.trim();
    return trimmed.isEmpty ? base : '$base — $trimmed';
  }

  @override
  String toString() => 'OpenSubtitlesHit($fileId, $label)';
}

/// Client OpenSubtitles, pour les sous-titres absents de l'abonnement.
///
/// ## Pourquoi
///
/// Certains panels ne publient aucun sous-titre et ne servent pas le chemin
/// `/subtitles/...` (qui n'appartient d'ailleurs pas à la spécification
/// Xtream Codes). On a mesuré une réponse VIDE : il n'y a rien à extraire,
/// quelle que soit la forme d'URL essayée. La seule voie restante est une
/// source externe, que font déjà TiviMate et XCIPTV.
///
/// ## Authentification
///
/// L'API accepte les recherches **anonymes** (5 téléchargements par IP et par
/// 24 h). Une clé API, lue depuis les réglages, lève ce plafond et permet le
/// `/login` pour aller jusqu'à 20 par jour. La clé n'est JAMAIS codée en dur :
/// elle vit dans les préférences de l'application.
class OpenSubtitlesService {
  const OpenSubtitlesService({required this.apiKey});

  /// Clé API facultative. Vide = recherche anonyme.
  final String apiKey;

  static const String baseUrl = 'https://api.opensubtitles.com/api/v1';

  /// OpenSubtitles refuse les agents génériques : le format `Nom vVersion` est
  /// obligatoire. On réutilise l'agent déjà employé pour les sous-titres du
  /// panel.
  static const String userAgent = 'OrbitIPTV v1.0';

  /// Langues demandées par défaut : le français et l'anglais, dans les deux
  /// sens du nom.
  static const String defaultLanguages = 'fr,en';

  /// Cherche des sous-titres pour un film (identifiant TMDB).
  ///
  /// Préférable au MovieHash quand l'identifiant est connu : le hash exige que
  /// le panel accepte les requêtes `Range`, ce que refuses beaucoup de
  /// serveurs, alors que TMDB est déjà résolu pour l'affichage des détails.
  Future<List<OpenSubtitlesHit>> searchMovie(
    int tmdbId, {
    String languages = defaultLanguages,
  }) =>
      search(tmdbId: tmdbId, languages: languages);

  /// Cherche des sous-titres pour un épisode de série.
  ///
  /// OpenSubtitles n'a pas de hash d'épisode : l'identifiant doit être
  /// accompagné de la saison et du numéro d'épisode, tous deux déjà présents
  /// dans notre modèle `Episode`.
  Future<List<OpenSubtitlesHit>> searchEpisode(
    int tmdbId, {
    required int season,
    required int episode,
    String languages = defaultLanguages,
  }) {
    if (season <= 0 || episode <= 0) {
      // Sans ces deux nombres, la recherche renverrait les sous-titres d'une
      // série entière : c'est pire que de ne rien proposer.
      return Future<List<OpenSubtitlesHit>>.value(const []);
    }
    return search(
      tmdbId: tmdbId,
      seasonNumber: season,
      episodeNumber: episode,
      languages: languages,
    );
  }

  Future<List<OpenSubtitlesHit>> search({
    required int tmdbId,
    String languages = defaultLanguages,
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    if (tmdbId <= 0) return const [];

    final query = <String, String>{
      'tmdb_id': '$tmdbId',
      'languages': languages,
      if (seasonNumber != null) 'season_number': '$seasonNumber',
      if (episodeNumber != null) 'episode_number': '$episodeNumber',
    };

    final result = await safeAsync<List<OpenSubtitlesHit>>(
      () => _get('/subtitles', query),
      context: 'OpenSubtitlesService.search',
    );
    final hits = result.valueOrNull ?? const <OpenSubtitlesHit>[];
    LoggerService.instance.info(
      'opensubtitles tmdb=$tmdbId '
      'saison=${seasonNumber ?? '-'} episode=${episodeNumber ?? '-'} '
      '→ ${hits.length} résultat(s)',
    );
    return hits;
  }

  /// Télécharge le sous-titre et le convertit en piste exploitable.
  ///
  /// Le service renvoie le fichier **compressé en gzip** : sans décompression,
  /// le corps binaire ne produit aucun cue et la piste est muette — exactement
  /// le symptôme que nous cherchions à expliquer.
  Future<SubtitleTrack> download(
    OpenSubtitlesHit hit, {
    String language = 'fr',
  }) async {
    final result = await safeAsync<SubtitleTrack>(
      () async {
        final bytes = await _getBytes(
          Uri.parse('$baseUrl/subtitle/${hit.fileId}'),
        );
        final text = _decodeMaybeGzip(bytes);
        final track = SubtitleParser.parse(
          text,
          language: language,
          label: hit.label,
        );
        if (!SubtitleParser.isUsable(text, track)) {
          throw SubtitlePayloadException(
            'Sous-titre en ligne vide pour « ${hit.label} » '
            '(${track.cues.length} cue(s))',
          );
        }
        return track;
      },
      context: 'OpenSubtitlesService.download',
    );
    final track = result.valueOrNull;
    if (track == null) {
      throw result.errorOrNull?.originalError ??
          SubtitlePayloadException('Téléchargement impossible');
    }
    return track;
  }

  /// Lecture d'une réponse JSON, avec les deux codes de sortie de l'API.
  Future<List<OpenSubtitlesHit>> _get(
    String path,
    Map<String, String> query,
  ) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final body = await _read(uri);
    if (body.isEmpty) return const [];

    final decoded = jsonDecode(body);
    if (decoded is! Map) return const [];
    final data = decoded['data'];
    if (data is! List) return const [];

    final out = <OpenSubtitlesHit>[];
    for (final entry in data) {
      if (entry is! Map) continue;
      final attrs = entry['attributes'];
      if (attrs is! Map) continue;
      // `id` est une CHAINE dans l'API actuelle ; on accepte les deux formes
      // pour ne pas casser si elle redevient numérique.
      final id = _asInt(entry['id']);
      if (id == null) continue;
      out.add(
        OpenSubtitlesHit(
          fileId: id,
          language: (attrs['language'] ?? 'und').toString(),
          release: (attrs['release'] ?? '').toString(),
          isForced: attrs['foreign_parts_only'] == 1,
          isHearingImpaired: attrs['hearing_impaired'] == 1,
          downloadCount: _asInt(attrs['download_count']) ??
              _asInt(attrs['new_download_count']) ??
              0,
          rating: _asRating(attrs['ratings']),
        ),
      );
    }
    // Les plus téléchargés d'abord : c'est le meilleur proxy de fiabilité
    // quand l'API ne renvoie plus le nom du fichier.
    out.sort((a, b) => b.downloadCount.compareTo(a.downloadCount));
    return out;
  }

  /// Note moyenne du sous-titre, sur 10.
  ///
  /// Le champ est un tableau de votes par source, pas un nombre : le lire
  /// comme un nombre donnait 0 et un classement faux.
  static double _asRating(Object? value) {
    if (value is num) return value.toDouble();
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map) {
        final average = first['average'];
        if (average is num) return average.toDouble();
      }
    }
    return 0;
  }

  Future<String> _read(Uri uri) async => _decodeMaybeGzip(await _getBytes(uri));

  Future<List<int>> _getBytes(Uri uri) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, userAgent);
      if (apiKey.isNotEmpty) {
        request.headers.set('Api-Key', apiKey);
      }
      request.followRedirects = true;
      final response =
          await request.close().timeout(const Duration(seconds: 15));
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } finally {
      client.close();
    }
  }

  /// Décompresse le gzip quand le corps en est un.
  ///
  /// `Content-Encoding` n'est pas toujours annoncé par ce service : on
  /// recognise donc le gzip sur sa signature binaire (`1f 8b`), pas sur un
  /// en-tête.
  static String _decodeMaybeGzip(List<int> bytes) {
    if (bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      try {
        final decoded = GZipCodec().decode(bytes);
        return _decodeSubtitleBytes(decoded);
      } catch (_) {
        // Corps gzip illisible : on tente le texte brut plutôt que d'échouer.
      }
    }
    return _decodeSubtitleBytes(bytes);
  }

  /// Même tolérance d'encodage que le parser : UTF-8 d'abord, repli Latin-1.
  static String _decodeSubtitleBytes(List<int> bytes) {
    if (bytes.isEmpty) return '';
    final relaxed = utf8.decode(bytes, allowMalformed: true);
    for (final rune in relaxed.runes) {
      if (rune == 0xFFFD) {
        return const Latin1Decoder(allowInvalid: true).convert(bytes);
      }
    }
    return relaxed;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
