import 'package:orbit_3d_flutter/services/stream_helpers.dart'
    as stream_helpers;
import 'package:orbit_3d_flutter/core/utils/panel_text.dart';

class ReplayItem {
  final String id;
  final String title;
  final String streamUrl;
  final String startTime;
  final String endTime;
  final String categoryId;

  /// Chaîne qui diffuse ce replay (identification + affichage groupé).
  final String channelId;
  final String channelName;

  /// Début du programme en temps réel (tri, regroupement) ; null pour les
  /// replays sans horaire (repli live/M3U).
  final DateTime? startDate;

  /// Résumé du programme, affiché sous le titre.
  final String description;

  /// Présentation / credited (présentateur, journaliste, production).
  final String host;

  /// Horaires machine, pour l'affichage du créneau et le regroupement par jour.
  final DateTime? startAt;
  final DateTime? endAt;

  ReplayItem({
    required this.id,
    required this.title,
    required this.streamUrl,
    required this.startTime,
    required this.endTime,
    this.categoryId = '',
    this.channelId = '',
    this.channelName = '',
    this.startDate,
    this.description = '',
    this.host = '',
    this.startAt,
    this.endAt,
  });

  factory ReplayItem.fromMap(Map<String, dynamic> map) {
    // Textes du panel décodés une fois pour toutes (cf. PanelText) :
    map = PanelText.decodeMap(map);
    return ReplayItem(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      streamUrl: map['url'] ?? '',
      startTime: map['start'] ?? '',
      endTime: map['end'] ?? '',
      categoryId: map['category_id']?.toString() ?? '',
      channelId: map['channel_id']?.toString() ?? '',
      channelName: map['channel_name']?.toString() ?? '',
    );
  }

  ReplayItem copyWith({String? streamUrl}) {
    return ReplayItem(
      id: id,
      title: title,
      streamUrl: streamUrl ?? this.streamUrl,
      startTime: startTime,
      endTime: endTime,
      categoryId: categoryId,
      channelId: channelId,
      channelName: channelName,
      startDate: startDate,
      description: description,
      host: host,
      startAt: startAt,
      endAt: endAt,
    );
  }

  String requireStreamUrl() =>
      stream_helpers.requireStreamUrl(streamUrl, label: title);
}
