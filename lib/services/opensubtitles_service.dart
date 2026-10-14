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

/// Un contenu indexé par OpenSubtitles : film, série ou épisode.
///
/// Sert à translator un titre de diffusion — souvent traduit, donc absent de
/// l'index — vers l'identifiant que l'API comprend.
@immutable
class OpenSubtitlesFeature {
  const OpenSubtitlesFeature({
    required this.featureId,
    required this.title,
    this.featureType = '',
    this.tmdbId = 0,
    this.imdbId = 0,
    this.year,
  });

  /// Identifiant interne OpenSubtitles, à passer en `parent_feature_id`.
  final int featureId;

  /// Titre tel qu'indexé, généralement en minuscules.
  final String title;

  /// `Movie`, `Tvshow` ou `Episode`.
  final String featureType;

  /// Identifiants externes, absents sur certaines entrées.
  final int tmdbId;
  final int imdbId;
  final int? year;

  @override
  String toString() => 'OpenSubtitlesFeature($featureId, $title)';
}

/// Issue d'une validation de clé API OpenSubtitles.
///
/// Quatre cas possibles, volontairement distincts : ce que l'écran doit
/// afficher diffère pour chacun.
@immutable
class OpenSubtitlesKeyCheck {
  const OpenSubtitlesKeyCheck._(this._kind, [this.detail = '']);

  /// Aucune clé n'est saisie : seule conduite possible, la saisir.
  const OpenSubtitlesKeyCheck.missing()
      : this._(_OpenSubtitlesKeyCheckKind.missing);

  /// La clé est acceptée par le service.
  const OpenSubtitlesKeyCheck.valid()
      : this._(_OpenSubtitlesKeyCheckKind.valid);

  /// La clé est présente mais REFUSÉE (HTTP 401) : la saisir ne suffit pas.
  const OpenSubtitlesKeyCheck.rejected()
      : this._(_OpenSubtitlesKeyCheckKind.rejected);

  /// Le service est injoignable, ou répond autre chose que 200/401.
  const OpenSubtitlesKeyCheck.unreachable(String detail)
      : this._(_OpenSubtitlesKeyCheckKind.unreachable, detail);

  final _OpenSubtitlesKeyCheckKind _kind;

  /// Défaut réseau ou serveur, vide pour les trois autres cas.
  final String detail;

  bool get isMissing => _kind == _OpenSubtitlesKeyCheckKind.missing;
  bool get isValid => _kind == _OpenSubtitlesKeyCheckKind.valid;
  bool get isRejected => _kind == _OpenSubtitlesKeyCheckKind.rejected;
  bool get isUnreachable => _kind == _OpenSubtitlesKeyCheckKind.unreachable;

  @override
  String toString() {
    switch (_kind) {
      case _OpenSubtitlesKeyCheckKind.missing:
        return 'OpenSubtitlesKeyCheck.missing';
      case _OpenSubtitlesKeyCheckKind.valid:
        return 'OpenSubtitlesKeyCheck.valid';
      case _OpenSubtitlesKeyCheckKind.rejected:
        return 'OpenSubtitlesKeyCheck.rejected';
      case _OpenSubtitlesKeyCheckKind.unreachable:
        return 'OpenSubtitlesKeyCheck.unreachable($detail)';
    }
  }
}

/// Les quatre issues possibles d'un [OpenSubtitlesKeyCheck].
enum _OpenSubtitlesKeyCheckKind { missing, valid, rejected, unreachable }

/// Issue d'une vérification de connexion au compte OpenSubtitles.
///
/// Calqué sur [OpenSubtitlesKeyCheck] : quatre cas volontairement distincts,
/// car l'écran des réglages doit afficher une conduite différente pour chacun.
@immutable
class OpenSubtitlesLoginCheck {
  const OpenSubtitlesLoginCheck._(this._kind, [this.detail = '']);

  /// Aucun compte n'est saisi : seule conduite possible, le saisir.
  const OpenSubtitlesLoginCheck.missing()
      : this._(_OpenSubtitlesLoginCheckKind.missing);

  /// Le compte est accepté par le service : un jeton a été émis.
  const OpenSubtitlesLoginCheck.valid()
      : this._(_OpenSubtitlesLoginCheckKind.valid);

  /// Les identifiants sont présents mais REFUSÉS (HTTP 401/403) : vérifier la
  /// saisie, pas le réseau.
  const OpenSubtitlesLoginCheck.rejected()
      : this._(_OpenSubtitlesLoginCheckKind.rejected);

  /// Le service est injoignable, ou répond autre chose que 200/401/403.
  const OpenSubtitlesLoginCheck.unreachable(String detail)
      : this._(_OpenSubtitlesLoginCheckKind.unreachable, detail);

  final _OpenSubtitlesLoginCheckKind _kind;

  /// Défaut réseau ou serveur, vide pour les trois autres cas.
  final String detail;

  bool get isMissing => _kind == _OpenSubtitlesLoginCheckKind.missing;
  bool get isValid => _kind == _OpenSubtitlesLoginCheckKind.valid;
  bool get isRejected => _kind == _OpenSubtitlesLoginCheckKind.rejected;
  bool get isUnreachable => _kind == _OpenSubtitlesLoginCheckKind.unreachable;

  @override
  String toString() {
    switch (_kind) {
      case _OpenSubtitlesLoginCheckKind.missing:
        return 'OpenSubtitlesLoginCheck.missing';
      case _OpenSubtitlesLoginCheckKind.valid:
        return 'OpenSubtitlesLoginCheck.valid';
      case _OpenSubtitlesLoginCheckKind.rejected:
        return 'OpenSubtitlesLoginCheck.rejected';
      case _OpenSubtitlesLoginCheckKind.unreachable:
        return 'OpenSubtitlesLoginCheck.unreachable($detail)';
    }
  }
}

/// Les quatre issues possibles d'un [OpenSubtitlesLoginCheck].
enum _OpenSubtitlesLoginCheckKind { missing, valid, rejected, unreachable }

/// Identifiants refusés par `/login` (HTTP 401 ou 403).
///
/// Distincte de [SubtitlePayloadException] pour le classement interne :
/// `checkLogin` la traduit en `OpenSubtitlesLoginCheck.rejected`, et
/// `_postDownload` la relance comme [SubtitlePayloadException] pour rester
/// homogène aux yeux de l'appelant.
class _OsLoginRejectedException implements Exception {
  const _OsLoginRejectedException(this.message);

  final String message;

  @override
  String toString() => '_OsLoginRejectedException: $message';
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
  const OpenSubtitlesService({
    required this.apiKey,
    this.username = '',
    this.password = '',
  });

  /// Clé API facultative. Vide = recherche anonyme.
  final String apiKey;

  /// Identifiant du compte OpenSubtitles. Vide = aucun compte configuré : les
  /// recherches restent anonymes et `/download` répond 503 (« compte requis »).
  final String username;

  /// Mot de passe du compte. JAMAIS journalisé, ni sa valeur ni une partie.
  final String password;

  static const String baseUrl = 'https://api.opensubtitles.com/api/v1';

  /// Remplace [baseUrl] pour les tests.
  ///
  /// `baseUrl` était un `const` statique, donc aucun test ne pouvait viser un
  /// serveur local : la propagation d'erreur et le 503 de `/download` étaient
  /// hors de portée des 84 tests. Cette couture rend le service testable sans
  /// toucher au code de production.
  @visibleForTesting
  static String baseUrlOverride = baseUrl;

  /// Base effective des requêtes.
  static String get _base => baseUrlOverride;

  /// Rétablit la base réelle. À appeler entre deux tests.
  @visibleForTesting
  static void resetBaseUrl() => baseUrlOverride = baseUrl;

  /// OpenSubtitles refuse les agents génériques : le format `Nom vVersion` est
  /// obligatoire. On réutilise l'agent déjà employé pour les sous-titres du
  /// panel.
  static const String userAgent = 'OrbitIPTV v1.0';

  /// Session d'authentification STATIQUE.
  ///
  /// Le service est `const`-construit — y compris dans les tests — et ne peut
  /// donc pas porter d'état mutable en champ. Une installation n'a qu'un
  /// compte, partagé par toutes les instances : la session vit donc ici, au
  /// niveau de classe.
  ///
  /// Le jeton obtenu via `/login` vaut ~24 h ; on le considère périmé après
  /// [_authTokenLifetime] pour reloguer pendant les heures creuses plutôt
  /// qu'en plein téléchargement.
  static String _authToken = '';
  static String _authUser = '';
  static DateTime _authTokenExpiry = DateTime.fromMillisecondsSinceEpoch(0);
  static Future<String>? _loginInFlight;

  static const Duration _authTokenLifetime = Duration(hours: 23);

  /// Oublie le jeton et la relogin en cours.
  ///
  /// Appelé entre deux tests et — surtout — quand les identifiants changent
  /// dans les réglages : sans cette invalidation, la session statique
  /// rejouerait le jeton de l'ANCIEN compte sur le nouveau.
  static void resetAuth() {
    _authToken = '';
    _authUser = '';
    _authTokenExpiry = DateTime.fromMillisecondsSinceEpoch(0);
    _loginInFlight = null;
  }

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

  /// Vérifie qu'une clé API est disponible avant d'interroger le service.
  ///
  /// `/subtitles` et `/features` exigent tous deux l'en-tête `Api-Key` : sans
  /// clé, la réponse est un 401 dont le corps ne contient pas de champ `data`.
  /// Ce corps était donc lu comme « aucun résultat », et une recherche made
  /// échouée se confondait avec un média absent de la base — plusieurs
  /// diagnostics ont été guidés par cette confusion.
  ///
  /// On refuse donc de partir sans clé, et on le dit explicitement : la
  /// conduite à tenir est de la saisir dans les réglages, pas de chercher un
  /// autre titre.
  void _requireApiKey() {
    if (apiKey.trim().isEmpty) {
      throw const SubtitlePayloadException(
        'Clé API OpenSubtitles absente — à saisir dans les réglages',
      );
    }
  }

  /// Vérifie si la clé API configurée est ACCEPTÉE par le service.
  ///
  /// ## Vraie question : présente ≠ valide
  ///
  /// L'utilisateur saisit une clé puis la recherche échoue. L'écran annonçait
  /// alors « clé API absente » pour tout échec HTTP 401 — or 401 signifie « la
  /// clé a été REJETÉE », ce qui n'est pas la même chose qu'absente : la clé
  /// est là, dans les réglages, mais le service la refuse (copie d'un extrait,
  /// expiration, rôle insuffisant). Confondre les deux envoyait l'utilisateur
  /// « ressaisir la clé » dans les réglages où elle s'affichait déjà : un
  /// cercle vicieux.
  ///
  /// ## Pourquoi `/subtitles` et pas `/infos/user`
  ///
  /// La doc OpenSubtitles le précise : seuls `/infos/user` et `/download`
  /// exigent l'authentification utilisateur (JWT via `/login`). Une clé
  /// consumer valide reçoit donc un 401 de `/infos/user` même en parfaite
  /// santé, ce qui classait la clé « refusée » à tort. `/subtitles` n'exige
  /// QUE l'en-tête `Api-Key` : c'est le seul validateur fiable d'une clé
  /// consumer, et sa recherche est gratuite et illimitée.
  ///
  /// Clé invalide → 401 (docs officielles) ou 403 « You cannot consume this
  /// service » (mesuré en réel) ; clé valide → 200, même sans résultat.
  /// Les deux codes sont donc des rejets.
  ///
  /// Cette méthode distingue la cause exacte : `valid`, `rejected` (401/403)
  /// ou `unreachable` (réseau/serveur, à distinguer des deux autres car la
  /// conduite diffère).
  Future<OpenSubtitlesKeyCheck> checkApiKey() async {
    final key = apiKey.trim();
    if (key.isEmpty) {
      return const OpenSubtitlesKeyCheck.missing();
    }
    // `query` garantit un JSON « data » même vide ; une recherche sans
    // paramètre peut être rejetée en amont pour une autre raison.
    final uri = Uri.parse('$_base/subtitles').replace(
      queryParameters: const {'languages': 'fr', 'query': 'zzzzzzzz'},
    );
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, userAgent);
      request.headers.set('Api-Key', key);
      request.followRedirects = true;
      final response = await request.close().timeout(
            const Duration(seconds: 15),
          );
      final bytes = await _collect(response, uri);
      // 200 = clé reconnue. La réponse peut être vide de résultats, c'est
      // voulu : la validation n'a pas besoin des données.
      if (response.statusCode == HttpStatus.ok) {
        return const OpenSubtitlesKeyCheck.valid();
      }
      if (response.statusCode == HttpStatus.unauthorized ||
          response.statusCode == HttpStatus.forbidden) {
        return const OpenSubtitlesKeyCheck.rejected();
      }
      final body = _messageOf(bytes);
      return OpenSubtitlesKeyCheck.unreachable(
        'http=${response.statusCode}${body.isEmpty ? '' : ' ($body)'}',
      );
    } catch (error) {
      return OpenSubtitlesKeyCheck.unreachable('$error');
    } finally {
      client.close();
    }
  }

  /// Vérifie que les identifiants du compte configuré sont ACCEPTÉS.
  ///
  /// ## Pourquoi un compte en plus de la clé
  ///
  /// `/download` exige DEUX en-têtes : `Api-Key` ET `Authorization: Bearer`
  /// (jeton obtenu via `/login`). La clé seule suffit à la recherche — d'où
  /// l'impression que tout marche — mais le téléchargement répond 503
  /// « Service unavailable ». Le compte est la seconde moitié du dispositif.
  ///
  /// ## Ce que vérifie réellement la méthode
  ///
  /// `_ensureToken()` passe par `/login` : un 200 avec jeton signifie que le
  /// service a reconnu les identifiants. Un 401/403 est un REJET — à
  /// distinguer d'une panne réseau, la conduite n'étant pas la même.
  Future<OpenSubtitlesLoginCheck> checkLogin() async {
    if (username.trim().isEmpty || password.isEmpty) {
      return const OpenSubtitlesLoginCheck.missing();
    }
    try {
      final token = await _ensureToken();
      return token.isNotEmpty
          ? const OpenSubtitlesLoginCheck.valid()
          : const OpenSubtitlesLoginCheck.missing();
    } on _OsLoginRejectedException {
      return const OpenSubtitlesLoginCheck.rejected();
    } on SubtitlePayloadException catch (e) {
      return OpenSubtitlesLoginCheck.unreachable(e.message);
    } catch (_) {
      return const OpenSubtitlesLoginCheck.unreachable('réseau');
    }
  }

  /// Traduit un titre de diffusion vers l'entrée indexée par OpenSubtitles.
  ///
  /// ## Pourquoi cette étape est indispensable
  ///
  /// Un panel francophone nomme les séries avec leur **titre de diffusion** :
  /// « Monstre : l'histoire de Lizzie Borden ». OpenSubtitles indexe sous le
  /// titre original, « Lizzie Borden murders ». Une recherche `/subtitles` sur
  /// le nom français rend donc zéro, sans erreur : impossible de distinguer
  /// « série absente » de « titre non reconnu ».
  ///
  /// `full_search` interroge aussi les titres traduits (`title_aka`), et
  /// `/features` accepte `type` pour ne remonter que des séries. C'est la voie
  /// documentée : « Consider querying /features first ».
  ///
  /// ## Pourquoi plusieurs requêtes
  ///
  /// La recherche plein texte exige que les termes correspondent presque tous.
  /// Le nom de diffusion complet est donc trop long : sur
  /// « Monstre : l'histoire de Lizzie Borden - Une chatte tenace », le titre
  /// de l'épisode et l'accroche d'ouverture ne figurent dans aucune entrée et font
  /// échouer la recherche. On essaie donc des formes de plus en plus courtes,
  /// de la plus spécifique à la plus large, et on s'arrête à la première qui
  /// trouve.
  Future<List<OpenSubtitlesFeature>> searchFeatures(
    String query, {
    String type = '',
  }) async {
    _requireApiKey();
    for (final variant in titleVariants(query)) {
      final params = <String, String>{
        'query': variant.query.toLowerCase(),
        // Inclut les titres traduits : c'est ce paramètre qui fait la
        // différence entre un nom de diffusion et un titre indexé.
        'full_search': 'true',
        if (type.isNotEmpty) 'type': type,
      };

      final result = await safeAsync<List<OpenSubtitlesFeature>>(
        () => _getFeatures(params),
        context: 'OpenSubtitlesService.searchFeatures',
      );

      if (result.isFailure) {
        // Échec HTTP : inutile d'insister sur des variantes plus courtes, la
        // cause n'est pas le titre. Le message remonte à l'utilisateur.
        final error = result.errorOrNull;
        LoggerService.instance.info(
          'opensubtitles /features en échec : ${error?.originalError ?? error?.message}',
        );
        throw error?.originalError ??
            SubtitlePayloadException(error?.message ?? 'Recherche impossible');
      }

      final features = result.valueOrNull ?? const <OpenSubtitlesFeature>[];
      LoggerService.instance.info(
        'opensubtitles /features type=${type.isEmpty ? 'all' : type} '
        'requete="${variant.query.toLowerCase()}" '
        '${variant.trusted ? 'fidèle' : 'tronquée'} → ${features.length} résultat(s)'
        '${features.isEmpty ? '' : ' (${features.take(3).map((f) => f.title).join(' | ')})'}',
      );
      if (features.isEmpty) continue;

      // Un résultat obtenu par une variante tronquée n'est pas retenu : on ne
      // peut pas garantir qu'il s'agit du contenu recherché, et un homonyme
      // produirait des sous-titres décalés — pire que de n'en proposer aucun.
      if (!variant.trusted) {
        LoggerService.instance.info(
          'opensubtitles : résultat ignoré, requête tronquée trop ambiguë '
          '("${features.first.title}")',
        );
        continue;
      }
      return features;
    }
    return const [];
  }

  /// Formes successives d'un nom de release, de la plus précise à la plus large.
  ///
  /// Ordre choisi d'après un titre réel de panel :
  /// `|FR| Monstre : L'histoire de Lizzie Borden 01x02 - Une chatte tenace (MULTI)`
  ///
  /// 1. le titre complet, trop long et donc inopérant ;
  /// 2. sans le titre d'épisode, qui suit le dernier tiret ;
  /// 3. sans l'accroche d'ouverture qui précède le deux-points ;
  /// 4. les derniers mots significatifs, qui portent le plus souvent le nom
  ///    original — « Lizzie Borden » — retrouvé par `full_search`.
  ///
  /// Les variantes trop courtes sont écartées : en dessous de deux mots, la
  /// recherche ramène des contenus homonymes.
  ///
  /// Une variante de requête, et si elle est assez fidèle pour être acceptée.
  ///
  /// Une variante tronquée — les deux derniers mots du nom de série — trouve
  /// facilement un homonyme : « lizzie borden » mène à « The Lizzie Borden
  /// Chronicles », une autre série. Servir ses sous-titres serait pire que de ne
  /// rien proposer : l'utilisateur croirait lire les sous-titres du film qu'il
  /// regarde, et ceux d'une autre œuvre seraient décalés. Une variante tronquée
  /// sert donc à orienter, jamais à valider.
  static List<({String query, bool trusted})> titleVariants(String raw) {
    final full = cleanSearchTitle(raw);
    if (full.isEmpty) return const [];

    final out = <String>{full};

    // Retire ce qui suit le dernier « - » : c'est le titre de l'épisode, sans
    // rapport avec le nom de la série.
    final lastDash = full.lastIndexOf(RegExp(r'\s[-–—]\s'));
    final withoutEpisode =
        lastDash > 0 ? full.substring(0, lastDash).trim() : full;
    if (withoutEpisode != full) out.add(withoutEpisode);

    // Retire l'accroche d'ouverture : les panels préfixent souvent le nom de
    // diffusion d'un nom de chaîne ou d'un genre (« Monstre : … »).
    final colon = withoutEpisode.indexOf(':');
    var base = withoutEpisode;
    if (colon > 0 && colon < withoutEpisode.length - 4) {
      base = withoutEpisode.substring(colon + 1).trim();
      out.add(base);
    }

    final trusted = out
        .map((v) => v.trim())
        .where((v) => v.split(RegExp(r'\s+')).length >= 2)
        .toList();

    // Les derniers mots de `base`, JAMAIS ceux du titre complet : les derniers
    // mots du nom complet sont ceux de l'épisode — « Une chatte tenace » — qui
    // ne mènent nulle part. Ces variantes servent à trouver, pas à valider.
    final words = base.split(RegExp(r'\s+'));
    final tails = <({String query, bool trusted})>[];
    for (final take in [4, 3, 2]) {
      if (words.length > take) {
        final tail = words.sublist(words.length - take).join(' ').trim();
        if (tail.isNotEmpty && !trusted.contains(tail)) {
          tails.add((query: tail, trusted: false));
        }
      }
    }

    return [
      for (final query in trusted) (query: query, trusted: true),
      ...tails,
    ];
  }

  Future<List<OpenSubtitlesFeature>> _getFeatures(
    Map<String, String> params,
  ) async {
    final uri = Uri.parse('$_base/features').replace(queryParameters: params);
    final body = await _read(uri);
    if (body.isEmpty) return const [];
    final decoded = jsonDecode(body);
    if (decoded is! Map) return const [];
    final data = decoded['data'];
    if (data is! List) return const [];

    final out = <OpenSubtitlesFeature>[];
    for (final entry in data) {
      if (entry is! Map) continue;
      final attrs = entry['attributes'];
      if (attrs is! Map) continue;
      final featureId = _asInt(attrs['feature_id']) ?? _asInt(entry['id']);
      if (featureId == null || featureId <= 0) continue;
      out.add(
        OpenSubtitlesFeature(
          featureId: featureId,
          title: (attrs['title'] ?? '').toString(),
          featureType: (attrs['feature_type'] ?? '').toString(),
          tmdbId: _asInt(attrs['tmdb_id']) ?? 0,
          imdbId: _asInt(attrs['imdb_id']) ?? 0,
          year: _asInt(attrs['year']),
        ),
      );
    }
    return out;
  }

  /// Cherche des sous-titres par TEXTE, quand aucun identifiant TMDB n'est
  /// disponible.
  ///
  /// Trois tentatives, de la plus précise à la plus large :
  ///
  /// 1. `/features` résout le titre de diffusion vers la série indexée, puis
  ///    les sous-titres sont demandés par `parent_feature_id` avec saison et
  ///    épisode — la voie recommandée par la documentation ;
  /// 2. à défaut d'identifiant, recherche texte seule, filtrée côté client ;
  /// 3. les deux échouant, une recherche d'épisodes par nom, qui peut trouver
  ///    une entrée indexée sous un titre encore différent.
  Future<List<OpenSubtitlesHit>> searchByTitle(
    String title, {
    int? season,
    int? episode,
    String languages = defaultLanguages,
  }) async {
    if (season != null && episode != null && season > 0 && episode > 0) {
      final scoped = await _searchEpisodeViaFeature(
        title,
        season: season,
        episode: episode,
        languages: languages,
      );
      if (scoped.isNotEmpty) return scoped;
    } else {
      // Film : même problème de titre traduit, même résolution par `/features`.
      // L'identifiant TMDB obtenu est la voie la plus précise pour les films.
      final features = await searchFeatures(title, type: 'movie');
      for (final feature in features.take(3)) {
        if (feature.tmdbId <= 0) continue;
        final hits = await search(tmdbId: feature.tmdbId, languages: languages);
        LoggerService.instance.info(
          'opensubtitles film « ${feature.title} » (tmdb=${feature.tmdbId}) '
          '→ ${hits.length} résultat(s)',
        );
        if (hits.isNotEmpty) return hits;
      }
    }

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

  /// Sous-titres d'un épisode, en passant par la résolution du titre.
  Future<List<OpenSubtitlesHit>> _searchEpisodeViaFeature(
    String title, {
    required int season,
    required int episode,
    required String languages,
  }) async {
    final features = await searchFeatures(title, type: 'tvshow');
    if (features.isEmpty) return const [];

    for (final feature in features.take(3)) {
      // `parent_tmdb_id` est la voie la mieux indexée ; `parent_feature_id`
      // sert de repli quand l'entrée n'expose pas d'identifiant TMDB.
      final params = <String, String>{
        'languages': languages,
        'season_number': '$season',
        'episode_number': '$episode',
        if (feature.tmdbId > 0)
          'parent_tmdb_id': '${feature.tmdbId}'
        else
          'parent_feature_id': '${feature.featureId}',
      };
      final result = await safeAsync<List<OpenSubtitlesHit>>(
        () => _get('/subtitles', params),
        context: 'OpenSubtitlesService._searchEpisodeViaFeature',
      );
      // Même règle que dans `search` : une panne ne doit pas ressembler à
      // « cette série n'a pas de piste pour cet épisode ».
      final hits = _hitsOrThrow(result, '_searchEpisodeViaFeature');
      LoggerService.instance.info(
        'opensubtitles S${season}E$episode via « ${feature.title} » '
        '(tmdb=${feature.tmdbId}) → ${hits.length} résultat(s)',
      );
      if (hits.isNotEmpty) return hits;
    }
    return const [];
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
    _requireApiKey();
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
    // Une recherche ÉCHOUÉE n'est pas une recherche SANS RÉSULTAT.
    //
    // Le code faisait `result.valueOrNull ?? const []` : un 401 (clé
    // refusée), un 429 (quota) ou une panne devenaient une liste vide, donc
    // l'utilisateur lisait « aucun sous-titre trouvé » et n'apprenait jamais
    // que la clé était refusée. Le `catch` de l'appelant existe, il ne se
    // déclenchait simplement jamais.
    final hits = _hitsOrThrow(result, 'search');
    LoggerService.instance.info(
      'opensubtitles tmdb=${tmdbId ?? '-'} '
      'saison=${seasonNumber ?? '-'} episode=${episodeNumber ?? '-'} '
      'requete="${cleaned.isEmpty ? '-' : cleaned.toLowerCase()}" '
      '→ ${hits.length} résultat(s)',
    );
    return hits;
  }

  /// Lève l'erreur d'une recherche ratée, ou rend ses résultats.
  ///
  /// Une liste vide reste un résultat valide — « ce média n'a pas de
  /// sous-titre » — mais une panne doit être remontée : les deux n'ont ni la
  /// même cause ni le même remède, et les confondre rend l'interface muette
  /// au moment où l'utilisateur a besoin d'agir.
  static List<OpenSubtitlesHit> _hitsOrThrow(
    AsyncResult<List<OpenSubtitlesHit>> result,
    String context,
  ) {
    if (result.isFailure) {
      final error = result.errorOrNull;
      final cause = error?.originalError ?? error;
      if (cause != null) {
        Error.throwWithStackTrace(
          cause,
          error?.stackTrace ?? StackTrace.current,
        );
      }
      throw StateError('OpenSubtitles $context: échec sans cause');
    }
    return result.valueOrNull ?? const <OpenSubtitlesHit>[];
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
          const SubtitlePayloadException('Téléchargement impossible');
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
    _requireApiKey();
    // `/download` exige `Authorization: Bearer` en plus de `Api-Key` : sans
    // compte configuré, aucun jeton n'est demandé et le service répond 503,
    // que l'interface traduit en « compte requis ».
    final body = await _postDownload('/download', {
      'file_id': hit.fileId,
      'sub_format': 'srt',
    });
    if (body.isEmpty) {
      throw const SubtitlePayloadException('Réponse de /download vide');
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

  /// POST JSON brut, sans contrôle du statut HTTP.
  ///
  /// Rendu du couple `(statut, octets)` SANS lancer : c'est l'appelant qui
  /// décide de la conduite (un 401 sur `/download` doit déclencher une relogin,
  /// pas un message d'erreur définitif). L'en-tête `Authorization: Bearer` n'est
  /// posé que si un jeton est fourni : sans compte, la requête reste anonyme.
  Future<(int, List<int>)> _postRaw(
    String path,
    Map<String, Object?> payload, {
    String? bearer,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse('$_base$path'));
      request.headers.set(HttpHeaders.userAgentHeader, userAgent);
      request.headers.contentType = ContentType.json;
      if (apiKey.isNotEmpty) {
        request.headers.set('Api-Key', apiKey);
      }
      if (bearer != null && bearer.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearer');
      }
      request.add(utf8.encode(jsonEncode(payload)));

      final response =
          await request.close().timeout(const Duration(seconds: 15));
      final body = await _collect(response, Uri.parse('$_base$path'));
      return (response.statusCode, body);
    } finally {
      client.close();
    }
  }

  /// POST JSON authentifié, avec contrôle du statut HTTP.
  ///
  /// Trajet anonyme (aucun compte configuré) : aucun en-tête `Authorization`
  /// n'est posé, et `/download` répondra 503, que l'interface traduit en
  /// « compte requis ».
  Future<String> _post(String path, Map<String, Object?> payload) async {
    final (status, body) = await _postRaw(path, payload);
    if (status != HttpStatus.ok) {
      // 429 = quota épuisé, 401 = clé refusée : deux causes qu'il ne faut pas
      // confondre avec une panne réseau dans le message affiché.
      throw SubtitlePayloadException(
        'OpenSubtitles $path http=$status${_messageOf(body)}',
      );
    }
    return _decodeMaybeGzip(body);
  }

  /// POST authentifié, avec jeton Bearer et une relance sur jeton périmé.
  ///
  /// ## Pourquoi une relance
  ///
  /// Le jeton s'obtient via `/login` et vaut ~24 h. Entre la mémorisation et
  /// l'appel, il peut expirer : le service répond alors 401 sur `/download`
  /// alors que les identifiants sont bons. On relogue UNE seule fois — pas en
  /// boucle, pour ne pas marteler un compte refusé — et on rejoue la requête.
  ///
  /// Un 401 de `/login` lui-même (identifiants refusés) remonte comme
  /// [SubtitlePayloadException] pour rester homogène avec le reste du service.
  Future<String> _postDownload(
    String path,
    Map<String, Object?> payload,
  ) async {
    try {
      final token = await _ensureToken();
      if (token.isEmpty) {
        // Trajet anonyme historique : le 503 (compte requis) remonte tel quel.
        return await _post(path, payload);
      }
      var (status, body) = await _postRaw(path, payload, bearer: token);
      if (status == HttpStatus.unauthorized) {
        // Jeton périmé : le révoquer, reloguer une fois, rejouer.
        _authToken = '';
        _authUser = '';
        _authTokenExpiry = DateTime.fromMillisecondsSinceEpoch(0);
        final fresh = await _login();
        _rememberToken(fresh);
        (status, body) = await _postRaw(path, payload, bearer: fresh);
      }
      if (status != HttpStatus.ok) {
        throw SubtitlePayloadException(
          'OpenSubtitles $path http=$status${_messageOf(body)}',
        );
      }
      return _decodeMaybeGzip(body);
    } on _OsLoginRejectedException catch (e) {
      throw SubtitlePayloadException(e.message);
    }
  }

  /// Jeton JWT valide pour les requêtes authentifiées, ou '' sans compte.
  ///
  /// ## Pourquoi une session statique
  ///
  /// Le service est `const`-construit, y compris dans les tests : pas d'état
  /// mutable en champ. Et une installation n'a qu'un compte, partagé par toutes
  /// les instances — la session vit donc au niveau de classe.
  ///
  /// Les appels concurrents (plusieurs pistes téléchargées en parallèle) sont
  /// dédupliqués via [_loginInFlight] : un seul `/login` pour tous, les autres
  /// attendent le même futur.
  Future<String> _ensureToken() async {
    if (username.trim().isEmpty || password.isEmpty) return '';
    final now = DateTime.now();
    if (_authToken.isNotEmpty &&
        _authUser == username &&
        now.isBefore(_authTokenExpiry)) {
      return _authToken;
    }
    final inFlight = _loginInFlight;
    if (inFlight != null) return inFlight;
    final login = _login();
    _loginInFlight = login;
    try {
      final token = await login;
      _rememberToken(token);
      return token;
    } finally {
      _loginInFlight = null;
    }
  }

  /// Mémorise un jeton fraîchement émis, pour le compte courant.
  void _rememberToken(String token) {
    _authToken = token;
    _authUser = username;
    _authTokenExpiry = DateTime.now().add(_authTokenLifetime);
  }

  /// POST /login avec les identifiants du compte configuré.
  ///
  /// ## Ce qui est journalisé — et ce qui ne l'est JAMAIS
  ///
  /// Ni le nom du compte ni le mot de passe ne sortent d'aucune façon : pas de
  /// valeur, pas de partie de valeur, pas même de longueur. Seuls comptent
  /// l'existence du compte et le fait qu'un jeton ait (ou non) été émis.
  Future<String> _login() async {
    final (status, body) = await _postRaw('/login', {
      'username': username,
      'password': password,
    });
    if (status == HttpStatus.unauthorized || status == HttpStatus.forbidden) {
      throw _OsLoginRejectedException(
        'Compte OpenSubtitles refusé : identifiants invalides (http=$status)',
      );
    }
    if (status != HttpStatus.ok) {
      throw SubtitlePayloadException(
        'OpenSubtitles /login http=$status${_messageOf(body)}',
      );
    }
    final token = _tokenOf(_decodeMaybeGzip(body));
    LoggerService.instance.info(
      'opensubtitles /login compte_presente=true jeton_obtenu=${token.isNotEmpty}',
    );
    if (token.isEmpty) {
      throw const SubtitlePayloadException('OpenSubtitles /login sans jeton');
    }
    return token;
  }

  /// Extrait le jeton d'une réponse `/login` 200.
  ///
  /// Un corps illisible (JSON absent ou mal formé) ne donne pas de jeton : la
  /// conduite est celle d'un champ `token` manquant.
  static String _tokenOf(String body) {
    if (body.trim().isEmpty) return '';
    try {
      final decoded = jsonDecode(body);
      return decoded is Map ? (decoded['token']?.toString() ?? '') : '';
    } catch (_) {
      return '';
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
    final uri = Uri.parse('$_base$path').replace(queryParameters: query);
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
        // Trace de diagnostic : présence et longueur, jamais la valeur. Un 401
        // avec une clé de longueur inattendue permet de spotting le cas « secret
        // collé à la place de la clé » sans jamais l'exposer.
        LoggerService.instance.info(
          'opensubtitles ${uri.path.replaceFirst('/api/v1', '')} '
          'avec Api-Key (longueur ${apiKey.length})',
        );
      }
      request.followRedirects = true;
      final response =
          await request.close().timeout(const Duration(seconds: 15));
      final bytes = await _collect(response, uri);

      // Sans ce contrôle, un 401 (clé refusée) ou un 429 (quota) se lisaient
      // exactement comme « aucun résultat » : la recherche partait, le
      // diagnostic concluait à tort que le média était absent de la base. On
      // distingue donc l'échec HTTP de l'absence de résultat, qui n'a pas la
      // même cause ni le même remède.
      if (response.statusCode != HttpStatus.ok) {
        final path = _isSignedLink(uri) ? 'lien de téléchargement' : uri.path;
        // Le corps d'erreur est journalisé, tronqué : il ne contient aucune
        // donnée sensible — c'est un message du service. Le 401 en particulier
        // reste muet sinon, et « clé absente » comme « clé refusée » deviennent
        // le même écran.
        throw SubtitlePayloadException(
          'OpenSubtitles $path http=${response.statusCode}'
          '${_messageOf(bytes)}${_bodyExcerpt(bytes)}',
        );
      }
      return bytes;
    } finally {
      client.close();
    }
  }

  /// Extrait court d'un corps d'erreur illisible comme JSON.
  static String _bodyExcerpt(List<int> body) {
    if (body.isEmpty) return '';
    try {
      final text =
          _decodeMaybeGzip(body).trim().replaceAll(RegExp(r'\s+'), ' ');
      if (text.isEmpty) return '';
      return ' corps="${text.length > 160 ? '${text.substring(0, 160)}…' : text}"';
    } catch (_) {
      return '';
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
