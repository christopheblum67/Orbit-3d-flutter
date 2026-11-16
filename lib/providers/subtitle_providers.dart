import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:orbit_3d_flutter/services/subtitle_controller.dart';

/// Contrôleur partagé dont les notifications doivent réveiller les abonnés.
/// ChangeNotifierProvider assure aussi sa destruction, sans second dispose.
final subtitleControllerProvider =
    ChangeNotifierProvider<SubtitleController>((ref) => SubtitleController());

/// Données nécessaires à la découverte des sous-titres du contenu courant.
class SubtitleContext {
  const SubtitleContext({
    required this.contentId,
    required this.isSeries,
    this.streamId = '',
  });

  final String contentId;
  final bool isSeries;

  /// Pour une série, identifiant du flux de l'épisode, distinct de contentId.
  final String streamId;
}

class ActiveSubtitleContextNotifier extends Notifier<SubtitleContext?> {
  @override
  SubtitleContext? build() => null;

  void set(SubtitleContext? ctx) => state = ctx;
}

final activeSubtitleContextProvider =
    NotifierProvider<ActiveSubtitleContextNotifier, SubtitleContext?>(
  ActiveSubtitleContextNotifier.new,
);
