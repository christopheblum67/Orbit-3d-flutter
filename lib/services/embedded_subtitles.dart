import 'package:flutter/services.dart';
import 'package:orbit_3d_flutter/core/utils/language_label.dart';
import 'package:video_player/video_player.dart';

/// Identifiant natif du lecteur (texture handle côté fork media3).
///
/// `VideoPlayerController.playerId` est annoté `@visibleForTesting` depuis
/// video_player 2.14 : il n'existe aucun accesseur public. Notre pont
/// sous-titres dialogue néanmoins avec les canaux natifs du fork, qui indexent
/// les players par CET identifiant — la même valeur que `getAudioTracks()`
/// utilise en interne. L'accès est donc centralisé ici (un seul `ignore`).
// ignore: invalid_use_of_visible_for_testing_member
int embeddedPlayerId(VideoPlayerController controller) => controller.playerId;

/// Piste de sous-titres intégrée au contenu (VOD/Série), telle que le lecteur
/// media3 (fork `video_player_android`) l'expose via le canal
/// `flutter.io/videoPlayer/tracks`.
class EmbeddedSubtitleTrack {
  const EmbeddedSubtitleTrack({
    required this.id,
    required this.label,
    required this.language,
    required this.isSelected,
    required this.isForced,
    required this.mimeType,
  });

  /// Id `<group>_<track>`, compris du côté natif.
  final String id;
  final String label;
  final String? language;

  /// Piste sélectionnée par media3 (auto : souvent la piste « forced »).
  final bool isSelected;

  /// Piste « forced » (sous-titres forcés, typiquement « VFF : Forced »).
  final bool isForced;
  final String? mimeType;

  static EmbeddedSubtitleTrack fromMap(Map<Object?, Object?> map) {
    return EmbeddedSubtitleTrack(
      id: map['id']! as String,
      label: (map['label'] as String?) ?? 'Sous-titres',
      language: map['language'] as String?,
      isSelected: map['isSelected'] == true,
      isForced: map['isForced'] == true,
      mimeType: map['mimeType'] as String?,
    );
  }

  @override
  String toString() => '$id:$label';
}

/// Sous-titres actuellement rendus par le pipeline (instantané).
///
/// media3 1.9 n'expose qu'un groupe de cues courant (`Player.getCurrentCues`) :
/// il est ré-émis à chaque cue affichée et vidé dès que la piste est
/// désactivée. L'affichage est donc asservi au contenu reçu — il n'y a pas de
/// début/fin par cue à recaler sur la position.
class EmbeddedSubtitleCues {
  const EmbeddedSubtitleCues({
    required this.presentationTimeUs,
    required this.texts,
  });

  /// Position (µs) de la première cue du groupe.
  final int presentationTimeUs;
  final List<String> texts;

  bool get isEmpty => texts.isEmpty;

  static EmbeddedSubtitleCues fromMap(Map<Object?, Object?> map) {
    final cues = (map['cues'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<Object?, Object?>>()
        .map((c) => c['text'])
        .whereType<String>()
        .where((t) => t.trim().isNotEmpty)
        .toList();
    return EmbeddedSubtitleCues(
      presentationTimeUs: (map['presentationTimeUs'] as int?) ?? 0,
      texts: cues,
    );
  }

  /// Contenu identique ? Le contrôleur s'en sert pour ne pas notifier les
  /// listeners à chaque tick de polling quand rien n'a changé.
  bool sameContent(EmbeddedSubtitleCues other) {
    if (presentationTimeUs != other.presentationTimeUs) return false;
    if (texts.length != other.texts.length) return false;
    for (var i = 0; i < texts.length; i++) {
      if (texts[i] != other.texts[i]) return false;
    }
    return true;
  }

  @override
  String toString() => '$presentationTimeUsµs ${texts.join(' / ')}';
}

/// Signature d'un ensemble de pistes intégrées, pour comparer deux sondes.
///
/// Volontairement réduite à `id:label` : la sélection automatique de media3
/// change sans que la liste change, et l'inclure ferait perdre la main sur le
/// choix de l'utilisateur à chaque adaptation du flux.
String embeddedTracksSignature(List<EmbeddedSubtitleTrack> tracks) =>
    tracks.map((t) => '${t.id}:${t.label}').join(',');

/// Sentinelle de signature : elle ne correspond à AUCUNE sonde réelle, et
/// signifie « rien n'a encore été propagé pour ce lecteur ».
const String kEmbeddedSigUnset = '<unset>';

/// Faut-il propager une liste de pistes intégrée au contrôleur ?
///
/// ## Pourquoi cette règle existe
///
/// Une liste **vide** n'est pas une information : c'est un artefact de
/// chargement. Media3 reconstruit ses groupes de pistes à chaque adaptation du
/// flux — entre deux `onTracksChanged`, `getCurrentTracks()` peut rendre une
/// liste vide alors que le contenu en contient six. Propager cet état efface la
/// section « Sous-titres intégrés » déjà affichée : l'utilisateur voit les
/// pistes disparaître sans avoir rien fait.
///
/// Seule la **première** sonde peut conclure « ce contenu n'a pas de piste
/// intégrée » : elle précède tout état hérité, y compris celui du contenu
/// précédent quand la texture est réutilisée (préchauffage, zapping).
bool shouldPropagateEmbeddedTracks({
  required List<EmbeddedSubtitleTrack> tracks,
  required String previousSignature,
}) {
  if (tracks.isNotEmpty) return true;
  return previousSignature.isEmpty || previousSignature == kEmbeddedSigUnset;
}

/// Choisit la piste intégrée correspondant à [language] (code langue, comparé
/// sans tenir compte de la casse), ou `null` si aucune ne correspond.
///
/// ## Pourquoi préférer une piste NON forcée
///
/// Un même flux porte souvent DEUX pistes pour la même langue : la piste
/// complète et sa variante « forced » (quelques cues, dialogues en langue
/// originale). Quand l'utilisateur choisit « Français » pour toute une série,
/// il veut les dialogues traduits en entier — pas les deux ou trois lignes
/// forcées. On privilégie donc une piste non forcée quand elle existe, et on ne
/// retombe sur la variante forcée que si c'est la seule disponible.
EmbeddedSubtitleTrack? pickEmbeddedSubtitleTrackForLanguage(
  List<EmbeddedSubtitleTrack> tracks,
  String language,
) {
  final wanted = language.trim().toLowerCase();
  if (wanted.isEmpty) return null;
  EmbeddedSubtitleTrack? forcedFallback;
  for (final track in tracks) {
    final code = track.language?.trim().toLowerCase();
    if (code != wanted) continue;
    if (!track.isForced) return track;
    forcedFallback ??= track;
  }
  return forcedFallback;
}

/// Choisit la piste intégrée désignée par [preference] (menu « Langue des
/// sous-titres par défaut » d'une série).
///
/// [preference] peut être :
///  - le **libellé** d'une piste (« Français (SDH) ») : c'est ce que mémorise le
///    menu, désormais construit « une entrée par piste » (comme le lecteur) ;
///  - un **code langue** (« fr ») : préférences enregistrées avant ce changement,
///    et repli quand la sonde n'a pas encore publié les variantes.
///
/// L'ordre des essais va du plus précis au plus large : libellé exact, puis nom
/// de langue traduit (« Français »), puis code langue. Un libellé non reconnu ne
/// doit pas empêcher la langue de s'appliquer.
EmbeddedSubtitleTrack? pickEmbeddedSubtitleTrackForPreference(
  List<EmbeddedSubtitleTrack> tracks,
  String preference,
) {
  final wanted = preference.trim().toLowerCase();
  if (wanted.isEmpty) return null;

  for (final track in tracks) {
    if (track.label.trim().toLowerCase() == wanted) return track;
  }
  for (final track in tracks) {
    final name = LanguageLabel.of(track.language).trim().toLowerCase();
    if (name.isNotEmpty && name == wanted) return track;
  }
  return pickEmbeddedSubtitleTrackForLanguage(tracks, preference);
}

///
/// Le `VideoPlayerController` standard n'expose pas d'API sous-titres : on
/// dialogue ici directement avec les canaux natifs du fork
/// (`flutter.io/videoPlayer/tracks`), en passant le texture handle du lecteur
/// comme `playerId`. Aucune modification du Dart du fork n'est nécessaire.
class EmbeddedSubtitleBridge {
  EmbeddedSubtitleBridge(this.playerId);

  /// Texture handle du lecteur vidéo — l'identifiant de player côté natif.
  final int playerId;

  static const MethodChannel _tracksChannel =
      MethodChannel('flutter.io/videoPlayer/tracks');

  Future<List<EmbeddedSubtitleTrack>> getTracks() async {
    final raw = await _tracksChannel.invokeListMethod<dynamic>(
      'getSubtitleTracks',
      <String, dynamic>{'playerId': playerId},
    );
    return [
      for (final entry in raw ?? const <dynamic>[])
        EmbeddedSubtitleTrack.fromMap((entry as Map).cast<Object?, Object?>()),
    ];
  }

  Future<void> selectTrack(String trackId) {
    return _tracksChannel.invokeMethod<void>(
      'selectSubtitleTrack',
      <String, dynamic>{'playerId': playerId, 'trackId': trackId},
    );
  }

  Future<void> clearTracks() {
    return _tracksChannel.invokeMethod<void>(
      'clearSubtitleTracks',
      <String, dynamic>{'playerId': playerId},
    );
  }

  /// Coupe la sortie audio du lecteur (type « audio » désactivé côté media3).
  ///
  /// Vit sur ce pont parce qu'il est le SEUL à porter le canal partagé
  /// `flutter.io/videoPlayer/tracks` côté Flutter : aucune autre passerelle ne
  /// parle au sélecteur de pistes du fork. Sert l'entrée « Aucun » de la
  /// section audio ; sélectionner ensuite une piste réactive le type côté
  /// natif (cf. `applyTrackSelection`).
  static Future<void> clearAudioFor(int playerId) {
    return _tracksChannel.invokeMethod<void>(
      'clearAudioTracks',
      <String, dynamic>{'playerId': playerId},
    );
  }

  Future<EmbeddedSubtitleCues> currentCues() async {
    final raw = await _tracksChannel.invokeMapMethod<Object?, Object?>(
      'getCurrentCues',
      <String, dynamic>{'playerId': playerId},
    );
    return EmbeddedSubtitleCues.fromMap(raw ?? const <Object?, Object?>{});
  }
}
