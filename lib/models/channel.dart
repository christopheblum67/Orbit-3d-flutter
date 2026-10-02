import 'package:orbit_3d_flutter/core/utils/media_meta.dart';
import 'package:orbit_3d_flutter/core/utils/panel_text.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    as stream_helpers;

class Channel {
  final String id;
  final String name;
  final String logoUrl;
  final String streamUrl;
  final String group;
  final String categoryId;
  final String epgChannelId;
  final int orderNum;
  final double rating;

  /// La chaîne expose un replay/catchup (tv_archive, radio_tv=dvr,
  /// timeshift) : ses programmes passés sont relisibles.
  final bool supportsReplay;
  final Duration timeshift;

  /// Rétroactivité annoncée par le panel (`tv_archive_duration`), en jours.
  ///
  /// Champ standard Xtream Codes. L'imposer à 0 était le pire choix possible :
  /// c'est la valeur par défaut d'une chaîne sans replay, mais aussi celle
  /// qu'un panel renvoie quand il choisit de ne pas déclarer son archive. Avec
  /// ce garde-fou, une chaîne déclarant `tv_archive: 1` reste candidate au
  /// replay et la fenêtre peut s'ouvrir jusqu'à la valeur annoncée.
  final int archiveDays;

  /// Mode de substitution du catch-up, tel que le provider le déclare :
  /// `default`, `append`, `shift`, `flussonic`, `xc`.
  ///
  /// Le mode ne sert pas à piloter le lecteur mais à interpréter
  /// [catchupSource] : `append` construit l'URL à partir du flux live, `shift`
  /// et `xc` attendent `start`/`duration` en secondes, `flussonic` un chemin
  /// horodaté. Ignorer ce champ et toujours fabriquer un `timeshift.php`
  /// produisait des URL que le panel ne reconnaît pas.
  final String catchupMode;

  /// Modèle d'URL du catch-up (`catchup-source`), avec ses variables `{utc}`,
  /// `{duration}`, `{offset}`, `{Y}`… à substituer au moment de la lecture.
  ///
  /// C'est la source de vérité du chemin de replay : l'URL doit venir
  /// d'ici, pas d'une convention devinée.
  final String catchupSource;

  /// Identifiants EPG candidats pour cette chaîne (formes `{stream_id}` et
  /// `{num}:{stream_id}`), déduits de [epgChannelId].
  ///
  /// Les panels Xtream ne fournissent pas de champ EPG explicite : on
  /// essaye donc les deux écritures vues dans les dumps XMLTV plutôt que de
  /// parier sur une seule forme.
  List<String> get epgChannelIds {
    if (epgChannelId.isEmpty) return const <String>[];
    return epgChannelId
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  /// Premier identifiant EPG non vide, ou la chaîne vide.
  String get primaryEpgChannelId =>
      epgChannelIds.isEmpty ? '' : epgChannelIds.first;

  /// La chaîne archive au-delà de 48 h — « grand replay ».
  ///
  /// Le seuil est de **3 jours** : `tv_archive_duration > 2`, soit
  /// `catchup-days > 2` en M3U. 48 h est le cas particulier de 2 jours, pas la
  /// borne haute : un compte à 7 ou 14 jours sort du lot, et c'est cette
  /// information qui décide si l'onglet des jours d'une chaîne mérite
  /// d'exister ou s'il ne peut structurellement contenir que la grille.
  bool get hasExtendedCatchup => supportsReplay && archiveDays > 2;

  /// Rétention annoncée, en jours, ou `null` si le panel ne déclare rien.
  ///
  /// `null` et `0` ne veulent pas dire la même chose : `0` signifie « cette
  /// chaîne n'archive pas », `null` « le panel ne l'a pas dit ». L'écran Replay
  /// distingue les deux dans son message, sinon un vide muet était
  /// indifférenciable d'une fenêtre dépassée.
  int? get catchupDays => archiveDays > 0 ? archiveDays : null;

  Channel({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.streamUrl,
    required this.group,
    this.categoryId = '',
    this.epgChannelId = '',
    this.orderNum = 0,
    this.rating = 0,
    this.supportsReplay = false,
    this.timeshift = Duration.zero,
    this.archiveDays = 0,
    this.catchupMode = '',
    this.catchupSource = '',
  });

  factory Channel.fromMap(Map<String, dynamic> map) {
    // Textes du panel d��codes une fois pour toutes (cf. PanelText) :
    map = PanelText.decodeMap(map);
    final radioTv = map['radio_tv']?.toString().toLowerCase() ?? '';
    final tvArchive = map['tv_archive']?.toString().toLowerCase();
    final hasArchive =
        tvArchive == '1' || tvArchive == 'true' || tvArchive == 'yes';
    final timeshiftSeconds =
        int.tryParse('${map['timeshift_seconds'] ?? '0'}') ?? 0;
    // Certains panels Xtream renvoient les mêmes attributs que le M3U, et
    // d'autres n'en renvoient aucun. On les lit quand ils existent : sans eux
    // la fenêtre retombe sur la valeur par défaut et le chemin de replay reste
    // celui de `timeshift.php`.
    final catchupMode = map['catchup']?.toString().trim().toLowerCase() ?? '';
    final catchupSource = map['catchup_source']?.toString().trim() ?? '';
    final catchupDays = int.tryParse('${map['catchup_days'] ?? ''}') ?? 0;
    final archiveDaysField = int.tryParse('${map['tv_archive_duration'] ?? ''}') ?? 0;
    final streamId = firstNonEmpty([map['stream_id'], map['id']]);
    final channelNum = map['num']?.toString() ?? '';
    // Xtream ne renvoie AUCUN champ `epg_channel_id` : la liaison vers le
    // XMLTV se fait par le `stream_id`. Les dumps XMLTV de ces panels
    // identifient les chaînes par « {num}:{stream_id} » (l'identifiant
    // observé dans le dump est `1:117`), le `stream_id` seul servant pour
    // les panels plus anciens. On renseigne donc les DEUX formes, séparées
    // par une virgule, et `epgChannelIds` les expose pour la recherche.
    // Sans cela `epgChannelId` restait vide et aucun programme n'était
    // jamais trouvé (« aucun programme en cours »).
    final epgCandidates = <String>{};
    if (streamId.isNotEmpty) {
      epgCandidates.add(streamId);
      if (channelNum.isNotEmpty) epgCandidates.add('$channelNum:$streamId');
    }
    final explicitEpg = map['epg_channel_id']?.toString() ?? '';
    if (explicitEpg.isNotEmpty) epgCandidates.add(explicitEpg);
    return Channel(
      id: streamId,
      name: map['name'] ?? '',
      logoUrl: firstNonEmpty([map['stream_icon'], map['logo']]),
      streamUrl: map['url'] ?? '',
      group: firstNonEmpty([map['category_name'], map['group']]),
      categoryId: map['category_id']?.toString() ?? '',
      epgChannelId: epgCandidates.join(','),
      orderNum: _parseNumValue(map['num']),
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      supportsReplay: radioTv == 'dvr' ||
          hasArchive ||
          timeshiftSeconds > 0 ||
          catchupDays > 0 ||
          catchupSource.isNotEmpty,
      timeshift: Duration(seconds: timeshiftSeconds),
      // La fenêtre est prioritairement celle annoncée par le panel. Avant,
      // `hasArchive` à lui seul suffisait à remettre la fenêtre à zéro, et une
      // chaîne qui archive bel et bien se retrouvait filtrée comme si elle
      // n'archivait rien.
      archiveDays: archiveDaysField > 0
          ? archiveDaysField
          : catchupDays > 0
              ? catchupDays
              : 0,
      catchupMode: catchupMode,
      catchupSource: catchupSource,
    );
  }

  static int _parseNumValue(Object? raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString().trim() ?? '') ?? 0;
  }

  Channel copyWith({
    String? streamUrl,
    bool? supportsReplay,
    Duration? timeshift,
  }) {
    return Channel(
      id: id,
      name: name,
      logoUrl: logoUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      group: group,
      categoryId: categoryId,
      epgChannelId: epgChannelId,
      orderNum: orderNum,
      rating: rating,
      supportsReplay: supportsReplay ?? this.supportsReplay,
      timeshift: timeshift ?? this.timeshift,
    );
  }

  String get groupLabel {
    final raw = group.trim();
    if (raw.isEmpty) return '';
    final parts = raw.split(RegExp(r'[|;]'));
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return raw;
  }

  String requireStreamUrl() =>
      stream_helpers.requireStreamUrl(streamUrl, label: name);
}
