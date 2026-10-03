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
    this.fileName = '',
    this.season,
    this.episode,
    this.isForced = false,
    this.isHearingImpaired = false,
    this.downloadCount = 0,
    this.rating = 0,
  });

  /// Identifiant du FICHIER chez OpenSubtitles, exigé par `/download`.
  ///
  /// Point delicate de l'API : l'enveloppe porte un `id` qui identifie le
  /// SOUS-TITRE, pas le fichier. Le `/download` attend le `file_id` Ranges dans
  /// `attributes.files[]`. Utiliser l'`id` de l'enveloppe ne renvoyait pas une
  /// erreur mais un corps vide : aucun statut HTTP ne distinguait les deux.
  final int fileId;

  /// Code langue renvoyé par le service (`fr`, `en`).
  final String language;

  /// Édition (« Director's Cut », « VOSTFR »…).
  final String release;

  /// Nom du fichier téléposable, tel que publié par le contributeur.
  ///
  /// C'est la seule source fiable des qualificatifs : l'API a un champ
  /// `foreign_parts_only`, mais il est souvent absent alors que le nom, lui,
  /// dit « forced » ou « sdh ».
  final String fileName;

  /// Numéro de saison et d'épisode déclarés par l'entrée.
  ///
  /// Indispensables pour filtrer une recherche texte : sans identifiant de
  /// série parent, `/subtitles` ne sait pas restreindre à un épisode et
  /// ramène tout ce qui porte un nom approchant. `null` sur un saison pack,
  /// qui couvre plusieurs épisodes.
  final int? season;
  final int? episode;

  final bool isForced;
  final bool isHearingImpaired;
  final int downloadCount;
  final double rating;

  /// Libellé affichable.
  ///
  /// La langue et ses qualificateurs sortent de [LanguageLabel] : la table de
  /// traduction est unique dans l'application, et le nom de fichier est passé
  /// avec pour que « forced » / « sdh » soient détectés sans les dupliquer.
  String get label {
    final base = LanguageLabel.of('$language $fileName', fallback: language);
    final detail = release.trim().isNotEmpty ? release.trim() : '';
    return detail.isEmpty ? base : '$base — $detail';
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

  /// Cherche des sous-titres par TEXTE, quand aucun identifiant TMDB n'est
  /// disponible.
  ///
  /// C'est le chemin de secours qui fonctionne sans clé API : la plupart des
  /// panels ne publient pas de `tmdb_id`, et l'enrichissement TMDB demande une
  /// clé que l'utilisateur n'a pas saisie. `/subtitles` accepte un `query`, ce
  /// qui évite les deux.
  ///
  /// ## Pourquoi le filtrage se fait ici, et pas dans la requête
  ///
  /// La documentation est explicite : `season_number` ne s'emploie
  /// **qu'avec** `parent_imdb_id` ou `parent_tmdb_id`. Envoyé avec un simple
  /// `query`, le service répond 0 résultat sans erreur — combinaison ignorée,
  /// donc une recherche qui ne visait plus rien. On interroge donc par texte
  /// seul, puis on retient l'épisode voulu sur les champs `season_number` et
  /// `episode_number` de chaque réponse.
  ///
  /// Un saison pack (saison sans numéro d'épisode) est conservé en dernier :
  /// il couvre l'épisode, mais moins bien qu'un sous-titre ciblé.
  Future<List<OpenSubtitlesHit>> searchByTitle(
    String title, {
    int? season,
    int? episode,
    String languages = defaultLanguages,
  }) async {
    final found = await search(query: title, languages: languages);
    if (season == null || episode == null || found.isEmpty) return found;

    final exact = <OpenSubtitlesHit>[];
    final packs = <OpenSubtitlesHit>[];
    for (final hit in found) {
      if (hit.season == season && hit.episode == episode) {
        exact.add(hit);
      } else if (hit.episode == null && hit.season == season) {
        packs.add(hit);
      }
    }
    LoggerService.instance.info(
      'opensubtitles filtrage S${season}E$episode : '
      '${exact.length} ciblé(s), ${packs.length} pack(s) de la saison',
    );
    return [...exact, ...packs];
  }

  /// Interroge `/subtitles`.
  ///
  /// `season_number` et `episode_number` ne sont transmis que si un
  /// identifiant de la série parent est présent : sans lui, l'API ignore
  /// silencieusement la combinaison et ne renvoie rien.
  Future<List<OpenSubtitlesHit>> search({
    int? tmdbId,
    String? query,
    String languages = defaultLanguages,
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    final cleaned = cleanSearchTitle(query ?? '');
    // Sans identifiant, il ne reste qu'un texte à interroger : sans titre
    // exploitable, la requête ne viserait aucun média en particulier.
    if ((tmdbId == null || tmdbId <= 0) && cleaned.isEmpty) return const [];

    final params = buildSearchParams(
      tmdbId: tmdbId,
      cleanedTitle: cleaned,
      languages: languages,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );

    final result = await safeAsync<List<OpenSubtitlesHit>>(
      () => _get('/subtitles', params),
      context: 'OpenSubtitlesService.search',
    );
    final hits = result.valueOrNull ?? const <OpenSubtitlesHit>[];
    LoggerService.instance.info(
      'opensubtitles tmdb=${tmdbId ?? '-'} '
      'saison=${seasonNumber ?? '-'} episode=${episodeNumber ?? '-'} '
      'requete="${cleaned.isEmpty ? '-' : cleaned.toLowerCase()}" '
      '→ ${hits.length} résultat(s)',
    );
    return hits;
  }

  /// Paramètres de `/subtitles`, isolés pour être testables.
  ///
  /// Deux règles de la documentation y sont appliquées, chacune vérifiée par un
  /// test :
  ///
  /// - `season_number` et `episode_number` ne voyagent qu'avec un identifiant
  ///   de la série parent. Sans lui, l'API ignore la combinaison et ne renvoie
  ///   rien, sans signaler d'erreur ;
  /// - `query` part en minuscules, l'index comparant sensiblement à la casse.
  static Map<String, String> buildSearchParams({
    int? tmdbId,
    String cleanedTitle = '',
    String languages = defaultLanguages,
    int? seasonNumber,
    int? episodeNumber,
  }) {
    final scoped = tmdbId != null && tmdbId > 0;
    return <String, String>{
      if (scoped) 'tmdb_id': '$tmdbId',
      if (cleanedTitle.trim().isNotEmpty)
        'query': cleanedTitle.trim().toLowerCase(),
      'languages': languages,
      if (seasonNumber != null && scoped) 'season_number': '$seasonNumber',
      if (episodeNumber != null && scoped) 'episode_number': '$episodeNumber',
    };
  }

  /// Ne garde d'un nom de release que la partie utile à une recherche texte.
  ///
  /// Les panels Servent des noms d'episode bruts, faits de ILLUSTRATIONs :
  /// `|FR| Monstre : L'histoire de Lizzie Borden 01x02 - Une chatte tenace
  /// (MULTI)`. Envoyé tel quel à `query`, il ne matche aucun index : les
  /// parenthèses de diffusion et le numéro d'épisode font office de bruit.
  ///
  /// On retire donc, dans cet ordre : le marqueur de diffusion `|XX|`, les
  /// métadonnées de fin entre parenthèses, le couple `SxxEyy` — dont on a déjà
  /// l'équivalent en `season_number`/`episode_number` — et le reste des
  /// marqueurs techniques (`1080p`, `WEB-DL`, `x264`…).
  static String cleanSearchTitle(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return '';

    // 0. Année conservée avant tout nettoyage : « (1979) » ou « - 1979 » est
    // souvent le seul élément discriminant entre deux contenus au même titre,
    // et les parenthèses sont retirées juste après.
    final year = RegExp(r'\b(19\d{2}|20\d{2})\b').firstMatch(text)?.group(0);

    // 1. Marqueur de diffusion en tête : |FR|, |VF|, |HD|…
    text = text.replaceAll(RegExp(r'^\s*\|[^|]{1,6}\|\s*'), '');

    // 2. Épisode « S01E02 » ou « 1x02 ».
    //
    // On ne retire PAS les nombres de trois chiffres isolés : le motif visait
    // les numéros d'épisode à trois chiffres (« 102 »), mais il dévorait
    // aussi les codecs — « x265 » devenait « x », un mot parasite qui faussait
    // la requête. Les deux formes ci-dessus suffisent en pratique.
    text = text
        .replaceAll(
          RegExp(r'\bS\d{1,2}[\s._-]?E\d{1,3}\b', caseSensitive: false),
          ' ',
        )
        .replaceAll(RegExp(r'\b\d{1,2}x\d{2}\b'), ' ');

    // 3. Métadonnées entre parenthèses : (MULTI), (VF), (1080p), [FR]…
    text = text
        .replaceAll(RegExp(r'[\(\[\{][^\)\]\}]*[\)\]\}]'), ' ')
        // 4. Tirets de séparation laissés par les retraits ci-dessus.
        .replaceAll(RegExp(r'\s*[-–—]\s*$'), '')
        .replaceAll(RegExp(r'^\s*[-–—]\s*'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();

    // 5. Marqueurs techniques restants, sans toucher aux mots du titre.
    const noise = [
      '1080p',
      '720p',
      '480p',
      '2160p',
      '4k',
      'fhd',
      'hd',
      'sd',
      'web-dl',
      'webrip',
      'web',
      'bluray',
      'blu-ray',
      'bdrip',
      'brrip',
      'dvdrip',
      'hdtv',
      'remux',
      'x264',
      'x265',
      'h264',
      'h265',
      'hevc',
      'aac',
      'ac3',
      'eac3',
      'dts',
      'mp3',
      'truehd',
      'atmos',
      'hdr',
      'sdr',
      'dolby',
      'vision',
      'hq',
      'cam',
      'hdcam',
      'telesync',
      'workprint',
      'dubbed',
      'stereo',
      'mono',
      '5.1',
      'vostfr',
      'vo',
      'vf',
      'fr',
      'multi',
      'vff',
      'hd',
      'sdt',
    ];
    var words = text
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w.replaceAll(RegExp("[^A-Za-z0-9À-ɏ:'’\\- ]"), '').trim())
        .where((w) => w.isNotEmpty)
        .toList();
    words = words.where((w) => !noise.contains(w.toLowerCase())).toList();

    text = words.join(' ').trim();
    if (year != null && !text.contains(year)) {
      text = '$text $year';
    }
    // Un mot unique est trop ambigu : OpenSubtitles renverrait les sous-titres
    // d'un contenu homonyme, ce que l'utilisateur lirait comme un bug.
    return words.length >= 2 ? text : '';
  }

  /// Télécharge le sous-titre et le convertit en piste exploitable.
  ///
  /// ## Pourquoi deux requêtes
  ///
  /// L'API ne sert pas le fichier sur `/download` : elle renvoie une **URL
  /// temporaire** qu'il faut aller chercher ensuite. On avait supposé un
  /// `GET /subtitle/{id}` renvoyant le contenu — d'où un corps vide sans
  /// erreur visible, le pire des deux mondes pour un diagnostic.
  ///
  /// `sub_format: srt` est demandé explicitement : la base regorge de
  /// MicroDVD (`.sub`) que notre parser ne sait pas lire, et convertir coûte
  /// plus de temps que de demander directement le bon format.
  Future<SubtitleTrack> download(
    OpenSubtitlesHit hit, {
    String language = 'fr',
  }) async {
    final result = await safeAsync<SubtitleTrack>(
      () async {
        final link = await _requestDownloadLink(hit);
        final bytes = await _getBytes(link);
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

  /// Demande l'URL temporaire de téléchargement d'un fichier.
  ///
  /// Répond `{"url": "...", "remaining": N, "message": ...}`. `url` est un
  /// lien signé à usage unique : il n'est jamais journalisé. Seul le compteur
  /// de quota restant est tracé, pour que « quota épuisé » soit distinguable
  /// d'une panne réseau.
  Future<Uri> _requestDownloadLink(OpenSubtitlesHit hit) async {
    final body = await _post('/download', {
      'file_id': hit.fileId,
      'sub_format': 'srt',
    });
    if (body.isEmpty) {
      throw SubtitlePayloadException('Réponse de /download vide');
    }

    final decoded = jsonDecode(body);
    final map = decoded is Map ? decoded : const <String, Object?>{};
    final remaining = map['remaining'];
    final message = map['message']?.toString();
    final url = map['url']?.toString() ?? '';

    LoggerService.instance.info(
      'opensubtitles /download file=${hit.fileId} '
      'quota_restant=$remaining url_presente=${url.isNotEmpty}',
    );
    if (url.isEmpty) {
      throw SubtitlePayloadException(
        message ?? 'OpenSubtitles n\'a pas fourni de lien de téléchargement',
      );
    }
    return Uri.parse(url);
  }

  /// POST JSON authentifié, avec contrôle du statut HTTP.
  Future<String> _post(String path, Map<String, Object?> payload) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse('$baseUrl$path'));
      request.headers.set(HttpHeaders.userAgentHeader, userAgent);
      request.headers.contentType = ContentType.json;
      if (apiKey.isNotEmpty) {
        request.headers.set('Api-Key', apiKey);
      }
      request.add(utf8.encode(jsonEncode(payload)));

      final response =
          await request.close().timeout(const Duration(seconds: 15));
      final body = await _collect(response, Uri.parse('$baseUrl$path'));
      if (response.statusCode != HttpStatus.ok) {
        // 429 = quota épuisé, 401 = clé refusée : deux causes qu'il ne faut pas
        // confondre avec une panne réseau dans le message affiché.
        throw SubtitlePayloadException(
          'OpenSubtitles $path http=${response.statusCode}${_messageOf(body)}',
        );
      }
      return _decodeMaybeGzip(body);
    } finally {
      client.close();
    }
  }

  /// Champ `message` d'une réponse d'erreur, mis en forme pour l'affichage.
  ///
  /// 429 = quota épuisé, 401 = clé refusée : sans ce texte, l'utilisateur ne
  /// verrait qu'un « http=429 » qui ne lui dit rien sur ce qu'il peut faire.
  static String _messageOf(List<int> body) {
    if (body.isEmpty) return '';
    try {
      final decoded = jsonDecode(_decodeMaybeGzip(body));
      if (decoded is Map) {
        final message = decoded['message']?.toString() ?? '';
        if (message.isNotEmpty) return ' ($message)';
      }
    } catch (_) {
      // Corps non JSON : le statut HTTP suffira au diagnostic.
    }
    return '';
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

      final files = attrs['files'];
      final first = files is List && files.isNotEmpty ? files.first : null;
      final file = first is Map ? first : const <String, Object?>{};
      final fileName = (file['file_name'] ?? '').toString();

      // Le `/download` attend le `file_id` du FICHIER, rangé dans
      // `attributes.files[]`. L'`id` de l'enveloppe est celui de la fiche et
      // produit une réponse vide sans erreur — c'est ce qui a fait croire
      // longtemps à un blocage réseau. On garde l'`id` en repli, pour les
      // entrées atypiques où `files` serait absent.
      final fileId = _asInt(file['file_id']) ?? _asInt(entry['id']) ?? 0;
      if (fileId <= 0) continue;

      // Le nom de fichier est plus fiable que `foreign_parts_only`, souvent
      // absent : « forced » et « sdh » n'apparaissent que là.
      final forced = _flag(attrs['foreign_parts_only']) ||
          LanguageLabel.isForced(fileName);
      final hearing = _flag(attrs['hearing_impaired']) ||
          LanguageLabel.isHearingImpaired(fileName);

      out.add(
        OpenSubtitlesHit(
          fileId: fileId,
          language: (attrs['language'] ?? 'und').toString(),
          release: (attrs['release'] ?? '').toString(),
          fileName: fileName,
          season: _asInt(attrs['season_number']),
          episode: _asInt(attrs['episode_number']),
          isForced: forced,
          isHearingImpaired: hearing,
          downloadCount: _asInt(attrs['download_count']) ??
              _asInt(attrs['new_download_count']) ??
              0,
          rating: _asRating(attrs['ratings']),
        ),
      );
    }
    // Les plus téléchargés d'abord : c'est le meilleur proxy de fiabilité
    // quand deux entrées de même langue ne sont distinguées que par leur nom.
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
      if (apiKey.isNotEmpty && !_isSignedLink(uri)) {
        // Le lien signé de `/download` porte sa propre authentification ;
        // lui réinjecter la clé n'a rien créé et peut faire rejeter la requête.
        request.headers.set('Api-Key', apiKey);
      }
      request.followRedirects = true;
      final response =
          await request.close().timeout(const Duration(seconds: 15));
      return await _collect(response, uri);
    } finally {
      client.close();
    }
  }

  /// Un lien temporaire porte-t-il déjà ses identifiants ?
  static bool _isSignedLink(Uri uri) =>
      uri.queryParameters.containsKey('signature') ||
      uri.host != Uri.parse(OpenSubtitlesService.baseUrl).host;

  /// Lit tout le corps d'une reponse.
  Future<List<int>> _collect(HttpClientResponse response, Uri uri) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in response) {
      builder.add(chunk);
    }
    return builder.takeBytes();
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

  /// Booleen d'API, tolérant aux trois formes rencontrées.
  ///
  /// L'API renvoie `1`, `"1"` ou `true` selon l'endpoint et la version : un
  /// `== 1` laissait passer à `false` le drapeau `foreign_parts_only`, ce qui
  /// faisait classer un sous-titre forcé comme une sous-titre normal.
  static bool _flag(Object? value) =>
      value == true || value == 1 || value == '1';

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
