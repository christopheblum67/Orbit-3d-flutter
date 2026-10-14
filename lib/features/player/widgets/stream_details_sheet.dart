import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:orbit_3d_flutter/core/utils/language_label.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/providers/opensubtitles_service_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/opensubtitles_service.dart';
import 'package:orbit_3d_flutter/services/embedded_subtitles.dart';
import 'package:orbit_3d_flutter/services/subtitle_discovery.dart';
import 'package:orbit_3d_flutter/services/player_track_prefs.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Nature d'une erreur de recherche en ligne, telle qu'elle se présente à
/// l'utilisateur.
///
/// La distinction qui compte — **clé absente ≠ clé refusée** — est extraite du
/// widget pour être verrouillée par un test : c'est elle qui décidait si
/// l'utilisateur devait saisir une clé (absente) ou vérifier celle qu'il a
/// déjà saisie (refusée). Les confondre envoyait « ressaisir la clé » à
/// quelqu'un qui venait de la saisir.
enum SubtitleOnlineErrorKind {
  noApiKey,
  keyRejected,
  quota,
  needsLogin,
  unknown
}

/// Classe une erreur OpenSubtitles par la conduite à tenir.
SubtitleOnlineErrorKind classifySubtitleOnlineError(String text) {
  // L'absence de clé est levée par `_requireApiKey` AVANT toute requête : son
  // message ne porte aucun code HTTP, il faut donc le tester avant les codes.
  if (text.contains('Clé API OpenSubtitles absente')) {
    return SubtitleOnlineErrorKind.noApiKey;
  }
  if (text.contains('http=401') || text.contains('http=403')) {
    return SubtitleOnlineErrorKind.keyRejected;
  }
  if (text.contains('http=429')) return SubtitleOnlineErrorKind.quota;
  if (text.contains('http=503')) return SubtitleOnlineErrorKind.needsLogin;
  return SubtitleOnlineErrorKind.unknown;
}

/// Sous-fenêtre « Détails du flux » ouverte depuis la footerbar (icône ⚙️).
///
/// Liste les pistes audio, les qualités vidéo et les sous-titres détectés, et
/// permet de les sélectionner.
Future<void> showStreamDetailsSheet(
  BuildContext context,
  VideoPlayerController controller,
  String mediaKey,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => StreamDetailsSheet(
      controller: controller,
      mediaKey: mediaKey,
    ),
  );
}

class StreamDetailsSheet extends ConsumerStatefulWidget {
  const StreamDetailsSheet({
    super.key,
    required this.controller,
    required this.mediaKey,
  });

  final VideoPlayerController controller;
  final String mediaKey;

  @override
  ConsumerState<StreamDetailsSheet> createState() => _StreamDetailsSheetState();
}

class _StreamDetailsSheetState extends ConsumerState<StreamDetailsSheet> {
  List<VideoAudioTrack> _audioTracks = const [];
  List<VideoTrack> _videoTracks = const [];
  String? _audioSelection;
  String? _videoSelection;

  /// L'audio a-t-il été coupé par l'entrée « Aucun » ?
  ///
  /// Recalculé à chaque [_load] : le sélecteur media3 ne désigne alors
  /// aucune piste (`isSelected` faux partout), ce qui rend l'état lisible après
  /// une réouverture du panneau.
  bool _audioDisabled = false;
  bool _loading = true;
  String? _error;

  /// Pistes de sous-titre découvertes sur le panel, et état de la requête.
  List<SubtitleTrackRef> _subtitleTracks = const [];
  bool _subtitleLoading = false;
  bool _subtitleGuessed = false;

  /// Nombre de pistes encore à vérifier (section « Pistes déduites »).
  /// 0 = aucune vérification en cours.
  int _subtitleVerifying = 0;

  /// Recherche en ligne : résultats, état d'avancement, erreur.
  ///
  /// Volontairement déclenchée par un bouton et non au chargement : une
  /// requête externe à l'ouverture du panneau coûterait de la latence et du
  /// quota pour rien, quand le panel fournit déjà ses pistes.
  List<OpenSubtitlesHit> _onlineHits = const [];
  bool _onlineSearching = false;
  int? _onlineBusyId;
  String? _onlineError;

  /// Identifiant TMDB fourni par le panel pour ce contenu.
  ///
  /// Recoveru de la reponse get_vod_info / get_series_info. Prefere a
  /// notre propre recherche TMDB : elle ne demande aucune cle API, alors que
  /// l'utilisateur n'en saisit pas toujours une.
  int _panelTmdbId = 0;

  /// Une recherche a-t-elle déjà été lancée ? Sert à distinguer « pas encore
  /// cherché » de « cherché, rien trouvé ».
  bool _onlineSearched = false;
  String? _subtitleError;

  @override
  void initState() {
    super.initState();
    _load();
    _discoverSubtitles();
  }

  /// Interroge le panel sur les sous-titres du contenu lu.
  ///
  /// L'échec n'est pas silencieux : sans message, un 429 ou un panel sans
  /// piste affichent la même chose, et l'utilisateur ne peut pas savoir s'il
  /// doit réessayer ou attendre.
  Future<void> _discoverSubtitles() async {
    final ctx = ref.read(activeSubtitleContextProvider);
    if (ctx == null || ctx.contentId.isEmpty) return;
    if (mounted) {
      setState(() {
        _subtitleLoading = true;
        _subtitleError = null;
      });
    }
    final result = await safeAsync<
        ({List<SubtitleTrackRef> tracks, bool guessed, int tmdbId})>(
      () => ref.read(apiServiceProvider).discoverSubtitles(
            ctx.contentId,
            isSeries: ctx.isSeries,
            streamId: ctx.streamId,
          ),
      context: 'StreamDetailsSheet _discoverSubtitles',
    );
    if (!mounted) return;
    final found = result.valueOrNull ??
        (tracks: const <SubtitleTrackRef>[], guessed: false, tmdbId: 0);

    // Identifiant TMDB publié par le panel : il épargne la recherche TMDB, et
    // donc une clé API que l'utilisateur n'a pas forcément saisie.
    if (found.tmdbId > 0) _panelTmdbId = found.tmdbId;

    if (!result.isSuccess) {
      setState(() {
        _subtitleLoading = false;
        _subtitleTracks = const <SubtitleTrackRef>[];
        _subtitleGuessed = false;
        _subtitleVerifying = 0;
        _subtitleError = AppLocalizations.of(context).subtitleProviderNoAnswer;
      });
      return;
    }

    if (found.guessed || SubtitleDiscovery.needsVerification(found.tracks)) {
      // Pistes dont l'URL est DÉDUITE : on ne les affiche qu'après avoir vérifié
      // que le fichier existe. Sans cela, la section annonçait des pistes dont
      // l'utilisateur découvrait l'inexistance en les sélectionnant une à une.
      //
      // La condition NE REPOSE PLUS sur `guessed` seul. Un panel qui déclare
      // `subtitles: ['fr']` fournit un CODE, pas une URL : l'URL reste
      // déduite par convention, donc tout autant suspecte. `guessed` répond à
      // une autre question — « le panel a-t-il déclaré quelque chose ? » — et ne
      // suffit donc pas à décider qu'une piste est fiable.
      setState(() {
        _subtitleLoading = false;
        _subtitleGuessed = found.guessed;
        _subtitleTracks = const <SubtitleTrackRef>[];
        _subtitleVerifying = found.tracks.length;
      });
      final verified =
          await ref.read(subtitleControllerProvider).verifyTracks(found.tracks);
      if (!mounted) return;
      setState(() {
        _subtitleVerifying = 0;
        _subtitleTracks = verified;
        _subtitleError = verified.isEmpty
            ? AppLocalizations.of(context).subtitleNoneServedByPanel
            : null;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _subtitleLoading = false;
      _subtitleGuessed = found.guessed;
      _subtitleTracks = found.tracks;
      _subtitleVerifying = 0;
      _subtitleError = null;
    });
  }

  String get _selectedAudioId => _audioSelection ?? '';
  String get _selectedVideoId => _videoSelection ?? 'auto';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await safeAsync(
      () async {
        final audio = await widget.controller.getAudioTracks();
        final video = await widget.controller.getVideoTracks();
        return (audio: audio, video: video);
      },
      context: 'StreamDetailsSheet _load',
    );

    if (!mounted) return;

    if (result.isSuccess) {
      final data = result.valueOrNull!;
      setState(() {
        _audioTracks = data.audio;
        _videoTracks = data.video;
        _audioSelection = data.audio.indexWhere((t) => t.isSelected) >= 0
            ? data.audio.firstWhere((t) => t.isSelected).id
            : null;
        // Aucune piste désignée alors que le flux en publie : l'audio a été
        // coupé par « Aucun ».
        _audioDisabled =
            data.audio.isNotEmpty && data.audio.every((t) => !t.isSelected);
        _videoSelection = data.video.indexWhere((t) => t.isSelected) >= 0
            ? data.video.firstWhere((t) => t.isSelected).id
            : 'auto';
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = result.errorOrNull?.message ?? 'Unknown error';
      });
    }
  }

  Future<void> _selectAudio(String id) async {
    setState(() {
      _audioSelection = id;
      _audioDisabled = false;
    });
    // Mémorise la piste pour la prochaine lecture de ce contenu.
    await PlayerTrackPrefs.setAudioTrack(widget.mediaKey, id);
    await safeAsync(
      () => widget.controller.selectAudioTrack(id),
      context: 'StreamDetailsSheet _selectAudio',
    );
  }

  /// Coupe la sortie audio (« Aucun »).
  ///
  /// Désactivation *séparée* de celle des sous-titres : le type « audio » du
  /// sélecteur media3 est éteint côté natif, et la piste mémorisée est oubliée
  /// pour que la lecture suivante ne réactive pas le son.
  Future<void> _selectAudioNone() async {
    setState(() {
      _audioDisabled = true;
      _audioSelection = null;
    });
    await PlayerTrackPrefs.clearAudioTrack(widget.mediaKey);
    await safeAsync(
      () => EmbeddedSubtitleBridge.clearAudioFor(
        embeddedPlayerId(widget.controller),
      ),
      context: 'StreamDetailsSheet _selectAudioNone',
    );
  }

  Future<void> _selectVideo(String? id) async {
    setState(() => _videoSelection = id ?? 'auto');
    await safeAsync(
      () => widget.controller
          .selectVideoTrack(id == null ? null : _videoTrackFor(id)),
      context: 'StreamDetailsSheet _selectVideo',
    );
  }

  /// Recherche un sous-titre EN LIGNE, quand le panel n'en propose aucun.
  ///
  /// Le panel peut ne publier aucun sous-titre et ne pas servir le chemin
  /// `/subtitles/...` — mesuré : réponse vide. OpenSubtitles est alors la seule
  /// source restante. On ne l'interroge que sur action explicite, jamais au
  /// chargement, pour ne pas consommer de quota ni introduire de latence à
  /// l'ouverture du panneau.
  Future<void> _searchOnline() async {
    final ctx = ref.read(activeSubtitleContextProvider);
    final l = AppLocalizations.of(context);
    // `setState` est indispensable : sans lui, l'erreur est écrite dans le
    // champ mais l'écran ne se redessine pas, et l'utilisateur voit un bouton
    // qui ne semble ne faire rien.
    if (ctx == null || ctx.title.trim().isEmpty) {
      setState(() {
        _onlineError = l.subtitleOnlineNoTmdb;
        _onlineSearched = true;
      });
      return;
    }
    setState(() {
      _onlineSearching = true;
      _onlineError = null;
    });

    // Service fourni par le graphe Riverpod : il porte la clé courante, et la
    // remplace quand l'utilisateur en enregistre une nouvelle. Le construire
    // ici à partir d'un `ref.read` figerait la clé au moment de la recherche.
    final service = ref.read(openSubtitlesServiceProvider);

    try {
      // Deux voies, dans cet ordre :
      //
      // 1. l'identifiant que le panel a lui-même publié dans sa réponse. Il est
      //    déjà connu, donc gratuit et instantané ;
      // 2. à défaut, notre recherche par titre, qui exige une clé API TMDB.
      //
      // La 2e voie échouait sur un message « impossible d'identifier le
      // contenu » alors que la 1e avait la réponse sous les yeux depuis le
      // chargement du panneau.
      final resolved = _panelTmdbId;
      if (resolved <= 0) {
        final cleaned = OpenSubtitlesService.cleanSearchTitle(ctx.title);
        if (cleaned.isEmpty) {
          if (!mounted) return;
          LoggerService.instance.info(
            'opensubtitles : aucun identifiant TMDB et titre inexploitable',
          );
          setState(() {
            _onlineSearching = false;
            _onlineSearched = true;
            _onlineError = l.subtitleOnlineNoTmdb;
          });
          return;
        }
        final hits = await service.searchByTitle(
          cleaned,
          season: ctx.isSeries ? ctx.season : null,
          episode: ctx.isSeries ? ctx.episode : null,
        );
        if (!mounted) return;
        setState(() {
          _onlineSearching = false;
          _onlineSearched = true;
          _onlineHits = hits;
        });
        if (hits.isEmpty) {
          setState(() => _onlineError = l.subtitleOnlineEmpty);
        }
        return;
      }

      final hits = ctx.isSeries
          ? await service.searchEpisode(
              resolved,
              season: ctx.season,
              episode: ctx.episode,
            )
          : await service.searchMovie(resolved);
      if (!mounted) return;
      setState(() {
        _onlineSearching = false;
        _onlineSearched = true;
        _onlineHits = hits;
      });
      if (hits.isEmpty) {
        // Ce chemin ne posait AUCUN message : la recherche par identifiant
        // pouvait échouer ou ne rien trouver, et l'utilisateur ne lisait rien
        // du tout — ni résultat, ni explication.
        setState(() => _onlineError = l.subtitleOnlineEmpty);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _onlineSearching = false;
        _onlineSearched = true;
        _onlineError = _onlineErrorText(error, l);
      });
    }
  }

  /// Message d'erreur conceived pour l'utilisateur, pas pour un journal.
  ///
  /// Un 401 sans clé se traduisait par une suite de messages techniques
  /// (« SubtitlePayloadException : … http=401 ») qui ne disait pas ce qu'il
  /// fallait faire. La conduite à tenir est une seule : saisir la clé dans les
  /// réglages.
  ///
  /// Un 401 AVEC clé se traduisait par le même message « clé absente » alors
  /// que la clé est là mais refusée : l'utilisateur se retrouvait face à un
  /// messsage qui le priait de saisir une clé déjà saisie. Depuis, les deux
  /// cas sont distincts : absente ≠ refusée.
  String _onlineErrorText(Object error, AppLocalizations l) {
    final text = '$error';
    // Le 503 de `/download` a une cause documentée et unique : OpenSubtitles
    // exige DEUX en-têtes sur cet endpoint, `Api-Key` ET `Authorization: Bearer`
    // (obtenu via `/login`). La clé seule suffit à la recherche, d'où la
    // confusion : la recherche fonctionne, le téléchargement échoue.
    //
    // Et contre-intuitif : l'en-tête manquant ne renvoie pas 401 mais 503
    // « Service unavailable » — d'où l'absence de piste côté clé.
    switch (classifySubtitleOnlineError(text)) {
      case SubtitleOnlineErrorKind.noApiKey:
        return l.subtitleOnlineNoApiKey;
      case SubtitleOnlineErrorKind.keyRejected:
        return l.subtitleOnlineKeyRejected;
      case SubtitleOnlineErrorKind.quota:
        return l.subtitleOnlineQuota;
      case SubtitleOnlineErrorKind.needsLogin:
        return l.subtitleOnlineNeedsLogin;
      case SubtitleOnlineErrorKind.unknown:
        return text;
    }
  }

  /// Télécharge un sous-titre en ligne et l'active.
  Future<void> _selectOnline(OpenSubtitlesHit hit) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _onlineBusyId = hit.fileId);
    final service = ref.read(openSubtitlesServiceProvider);
    try {
      final track = await service.download(hit, language: hit.language);
      if (!mounted) return;
      ref.read(subtitleControllerProvider).adoptTrack(track, hit.label);
      setState(() => _onlineBusyId = null);
      messenger.showSnackBar(
        SnackBar(content: Text(hit.label)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _onlineBusyId = null);
      final l = AppLocalizations.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text('${l.subtitleUnavailableToast} : $error')),
      );
    }
  }

  VideoTrack? _videoTrackFor(String id) {
    for (final track in _videoTracks) {
      if (track.id == id) return track;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.streamDetails,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l.close,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _error != null
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sync_problem,
                                size: 32,
                                color: scheme.error,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l.streamTracksError,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: _load,
                                child: Text(l.retry),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          children: [
                            _sectionTitle(l.audioSection),
                            if (_audioTracks.isEmpty)
                              _EmptyRow(label: l.noAudioTrackDetected)
                            else ...[
                              // « Aucun » en tête : coupe la sortie audio.
                              _TrackTile(
                                title: l.noneOption,
                                subtitle: null,
                                selected: _audioDisabled,
                                onTap: _selectAudioNone,
                              ),
                              for (final track in _audioTracks)
                                _TrackTile(
                                  title: _audioLabel(context, track, l),
                                  // Pas de ligne de métadonnées : les pistes
                                  // audio s'identifient par leur langue, et
                                  // les canaux/codecs n'aidaient pas à choisir.
                                  subtitle: null,
                                  selected: _selectedAudioId == track.id,
                                  onTap: () => _selectAudio(track.id),
                                ),
                            ],
                            const SizedBox(height: 12),
                            _sectionTitle(l.videoSection),
                            _TrackTile(
                              title: l.autoQuality,
                              subtitle: l.autoQualityDescription,
                              selected: _selectedVideoId == 'auto',
                              onTap: () => _selectVideo(null),
                            ),
                            if (_videoTracks.isEmpty)
                              _EmptyRow(label: l.noVideoQualityDetected)
                            else
                              for (final track in _videoTracks)
                                _TrackTile(
                                  title: _videoLabel(track, l),
                                  subtitle: _videoMeta(track),
                                  selected: _selectedVideoId == track.id,
                                  onTap: () => _selectVideo(track.id),
                                ),
                            const SizedBox(height: 12),
                            _sectionTitle(l.subtitleSection),
                            ..._buildSubtitleNoneTiles(),
                            ..._buildEmbeddedSection(l),
                            ..._buildSubtitleSection(),
                            const SizedBox(height: 16),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  /// Entrée « Aucun » de la section sous-titres — cas « sous-titres du panel ».
  ///
  /// Quand le flux publie des pistes **intégrées**, l'entrée « Aucun » vit DANS
  /// la sous-section « Sous-titres intégrés » (première ligne, cf.
  /// [_buildEmbeddedSection]) : c'est là que l'utilisateur la cherche, au même
  /// niveau que les pistes qu'elle éteint. Ici, on ne la rend donc QUE dans le
  /// cas où le flux n'apporte aucune piste intégrée et où il reste des
  /// sous-titres externes (panel) à couper — sinon elle apparaîtrait deux fois.
  ///
  /// C'est le seul moyen d'éteindre un sous-titre, quelle qu'en soit la source
  /// (intégrée au flux ou externe). Désactivation **séparée** de celle de
  /// l'audio : chaque section a son propre « Aucun ».
  ///
  /// La ligne n'apparaît que s'il y a quelque chose à éteindre : un « Aucun »
  /// sans piste à couper serait un bouton mort.
  List<Widget> _buildSubtitleNoneTiles() {
    final l = AppLocalizations.of(context);
    final ctrl = ref.watch(subtitleControllerProvider);
    // Pistes intégrées présentes : « Aucun » est déjà offert par la
    // sous-section dédiée, ne pas le dupliquer ici.
    if (ctrl.embeddedTracks.isNotEmpty) return const [];
    final somethingToDisable = ctrl.hasActiveEmbedded ||
        ctrl.activeTrack != null ||
        _subtitleTracks.isNotEmpty;
    if (!somethingToDisable) return const [];
    final none = !ctrl.hasActiveEmbedded && ctrl.activeTrack == null;
    return [
      _TrackTile(
        title: l.noneOption,
        subtitle: null,
        selected: none,
        onTap: _selectNoSubtitle,
      ),
    ];
  }

  /// Éteint tous les sous-titres (intégrés ET externes).
  Future<void> _selectNoSubtitle() async {
    ref.read(subtitleControllerProvider).disable();
    if (mounted) setState(() {});
  }

  /// Section « Sous-titres intégrés au flux » (pistes media3 du contenu).
  ///
  /// Détectées et maintenues par `player_screen` (scan périodique) puis
  /// exposées par le contrôleur. L'overlay dédié les attache à la vidéo dès
  /// qu'une piste est active — c'est aussi pour ça que la liste est montrée
  /// ici, et nulle part ailleurs : la feuille conçue pour les lister
  /// (`SubtitleControlsSheet`) n'est branchée à AUCUN bouton, tout passait
  /// par « Détails du flux », qui ne les affichait pas. L'utilisateur lisait
  /// « indisponible » alors que les pistes étaient là, portées par le flux.
  List<Widget> _buildEmbeddedSection(AppLocalizations l) {
    final subtitleCtrl = ref.watch(subtitleControllerProvider);
    final tracks = subtitleCtrl.embeddedTracks;
    if (tracks.isEmpty) return const [];
    final activeId = subtitleCtrl.activeEmbeddedTrackId;
    final scheme = Theme.of(context).colorScheme;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          'Sous-titres intégrés',
          style: TextStyle(
            color: scheme.primary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
      // « Aucun » en tête de la sous-section : coupe TOUS les sous-titres
      // (intégrés comme externes). L'utilisateur le cherche au même niveau que
      // les pistes qu'il voit — 6 options = 5 pistes intégrées + « Aucun ».
      _TrackTile(
        title: l.noneOption,
        subtitle: null,
        selected:
            !subtitleCtrl.hasActiveEmbedded && subtitleCtrl.activeTrack == null,
        onTap: _selectNoSubtitle,
      ),
      for (final track in tracks)
        _TrackTile(
          title: track.label,
          subtitle: [
            track.language?.toUpperCase() ?? '—',
            if (track.isForced) 'Forcé',
            'Intégré',
          ].join(' · '),
          selected: activeId == track.id,
          onTap: () => _selectEmbeddedTrack(track.id),
        ),
      const Divider(height: 12, indent: 16, endIndent: 16),
    ];
  }

  /// Sélectionne une piste intégrée au flux.
  ///
  /// Best-effort : le rendu suit les cues que le pipeline publie pour la piste
  /// choisie. Le `ref.watch` de [_buildEmbeddedSection] rafraîchit déjà la
  /// coche ; le `setState` est là pour que la feuille reflète aussi l'état
  /// d'autres sections (pistes externes coupées par l'exclusivité).
  Future<void> _selectEmbeddedTrack(String trackId) async {
    await ref.read(subtitleControllerProvider).selectEmbeddedTrack(trackId);
    if (mounted) setState(() {});
  }

  /// Section « Sous-titres » : la liste réelle, ou la raison exacte du vide.
  ///
  /// Elle était auparavant un texte fixe — « le lecteur embarqué ne gère pas
  /// les sous-titres sur ce flux » — affiché quelle que soit la chaîne. C'est
  /// ce texte, et non une requête, qui produisait le « indisponible » que
  /// l'utilisateur voyait sur TOUT contenu, y compris des films dont le panel
  /// publie des pistes. Le vide muet rendait la découverte inutilisable : on ne
  /// pouvait pas distinguer un panel qui ne publie rien d'un pansement de
  /// l'interface.
  List<Widget> _buildSubtitleSection() {
    final l = AppLocalizations.of(context);
    final ctx = ref.read(activeSubtitleContextProvider);
    final active = ref.watch(subtitleControllerProvider).activeTrack;

    if (ctx == null || ctx.contentId.isEmpty) {
      // Flux live : aucun identifiant de contenu, donc aucune découverte
      // possible. Dit explicitement, plutôt qu'un « indisponible » qui
      // ressemble à un défaut.
      return [
        _EmptyRow(
          label: l.subtitleNotApplicable,
          info: l.subtitleNotApplicableInfo,
        ),
      ];
    }

    if (_subtitleLoading) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ];
    }

    if (_subtitleVerifying > 0) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.subtitleVerifying(_subtitleVerifying),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    if (_subtitleError != null) {
      // L'explication ne doit pas fermer la porte : quand le panel ne sert
      // rien, la recherche en ligne est la seule voie restante. Ce retour
      // anticipé la masquait — l'utilisateur lisait « indisponible » sans
      // aucun moyen d'agir, ce qui est le pire des deux mondes.
      return [
        _EmptyRow(label: l.subtitleUnavailable, info: _subtitleError!),
        ..._buildOnlineRow(l),
      ];
    }

    final tracks = _subtitleTracks;
    if (tracks.isEmpty) {
      // Aucune piste du panel : on propose la recherche en ligne, qui est la
      // seule source restante quand le panel ne sert rien.
      return [
        _EmptyRow(label: l.subtitleNoTrack, info: l.subtitleNoTrackInfo),
        ..._buildOnlineRow(l),
      ];
    }

    return [
      if (_subtitleGuessed)
        _EmptyRow(
          label: l.subtitleGuessed,
          info: l.subtitleGuessedInfo,
        ),
      for (final track in tracks)
        _TrackTile(
          // Langue seule. L'URL de la piste n'a aucun intérêt pour
          // l'utilisateur et occupait la ligne du dessous, où l'on attendait
          // l'intitulé.
          title: LanguageLabel.of(
            track.language,
            fallback: track.label,
            localeCode: Localizations.localeOf(context).languageCode,
          ),
          subtitle: null,
          // La piste active est un `SubtitleTrack` (des cues), pas une
          // référence : l'identité se lit donc sur le libellé, le seul champ
          // commun aux deux.
          selected: active?.label == track.label,
          onTap: () => _selectSubtitle(track),
        ),
    ];
  }

  Future<void> _selectSubtitle(SubtitleTrackRef track) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);
    // Une piste est une LANGUE, pas une URL : on essaie la forme principale
    // puis ses variantes (`12345_fr.srt`, puis `12345_fre.srt`). Le panel n'en
    // sert en général qu'une, et l'autre répond 200 avec une page d'erreur —
    // sans cet essai, l'utilisateur tombait sur « sous-titre indisponible » en
    // choisissant « Français », alors que la piste existait.
    //
    // L'erreur retenue est celle de la DERNIÈRE tentative : c'est la seule qui
    // dit quelque chose d'utile quand aucune forme ne marche.
    Object? lastError;
    var loaded = false;
    for (final candidate in track.candidates) {
      final result = await safeAsync(
        () => ref.read(subtitleControllerProvider).loadAndSetTrack(
              candidate.url,
              // La langue manquait : la piste chargée était étiquetée « und ».
              language: candidate.language,
              label: candidate.label,
            ),
        context: 'StreamDetailsSheet _selectSubtitle',
      );
      if (result.isSuccess) {
        loaded = true;
        break;
      }
      lastError = result.errorOrNull;
    }
    if (!mounted) return;
    if (loaded) {
      setState(() {});
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          lastError == null
              ? l.subtitleUnavailableToast
              : l.subtitleUnavailableDetail('$lastError'),
        ),
      ),
    );
  }

  /// Recherche en ligne : bouton, état d'avancement, résultats.
  ///
  /// Toujours en BAS de la liste, jamais à la place des pistes du panel : la
  /// source de l'abonnement reste prioritaire, et une source externe n'est
  /// proposée que lorsque le panel n'a rien donné.
  List<Widget> _buildOnlineRow(AppLocalizations l) {
    if (_onlineSearching) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.subtitleSearchOnlineRunning,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    if (_onlineError != null) {
      return [
        _EmptyRow(label: l.subtitleUnavailable, info: _onlineError!),
        _onlineButton(l),
      ];
    }

    if (_onlineHits.isEmpty) {
      return [
        if (_onlineSearched) _EmptyRow(label: '', info: l.subtitleOnlineEmpty),
        _onlineButton(l),
      ];
    }

    return [
      _EmptyRow(label: l.subtitleOnlineResults, info: ''),
      for (final hit in _onlineHits)
        _TrackTile(
          title: hit.label,
          // Le nombre de téléchargements est le meilleur proxy de fiabilité,
          // l'API ne renvoyant plus le nom du fichier.
          subtitle: l.subtitleOnlineDownloads(hit.downloadCount),
          selected: false,
          onTap: _onlineBusyId == hit.fileId ? () {} : () => _selectOnline(hit),
        ),
    ];
  }

  Widget _onlineButton(AppLocalizations l) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: OutlinedButton.icon(
          onPressed: _searchOnline,
          icon: const Icon(Icons.travel_explore, size: 18),
          label: Text(l.subtitleSearchOnline),
        ),
      );

  Widget _sectionTitle(String label) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.primary,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Nom affichable d'une piste audio.
  ///
  /// Le libellé du lecteur est prioritaire quand il est lisible ; sinon on
  /// traduit le code langue (`en` → English, `fr` → Français, `es`/`sp` →
  /// Español, et toutes les autres formesCourantes). Sans cela la liste
  /// affichait « eng » ou « fre », ce qui n'est pas une information pour
  /// l'utilisateur.
  static String _audioLabel(
    BuildContext context,
    VideoAudioTrack track,
    AppLocalizations l,
  ) {
    final locale = Localizations.localeOf(context).languageCode;
    final label = track.label;
    if (label != null && label.isNotEmpty && label != 'Audio') {
      return LanguageLabel.of(label, fallback: label, localeCode: locale);
    }
    return LanguageLabel.of(
      track.language,
      fallback: l.audioTrackFallback,
      localeCode: locale,
    );
  }

  static String _videoLabel(VideoTrack track, AppLocalizations l) {
    final label = track.label;
    if (label != null && label.isNotEmpty) return label;
    if (track.width != null && track.height != null) {
      return '${track.width}×${track.height}';
    }
    return l.videoQualityFallback;
  }

  static String _videoMeta(VideoTrack track) {
    final parts = <String>[
      if (track.codec != null && track.codec!.isNotEmpty) track.codec!,
      if (track.frameRate != null && track.frameRate! > 0)
        '${track.frameRate!.round()} fps',
      if (track.bitrate != null && track.bitrate! > 0)
        '${(track.bitrate! / 1000).round()} kbps',
    ];
    return parts.join(' · ');
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? scheme.primary : scheme.onSurface,
        ),
      ),
      subtitle: subtitle != null && subtitle!.isNotEmpty
          ? Text(subtitle!, style: const TextStyle(fontSize: 11))
          : null,
      onTap: onTap,
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.label, this.info});

  final String label;
  final String? info;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (info != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    info!,
                    style:
                        TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
