import 'package:orbit_3d_flutter/models/channel.dart';

/// Construction de l'URL de replay (catch-up) à partir des attributs
/// déclarés par le provider.
///
/// ## Pourquoi un template
///
/// Le chemin de replay n'est pas une convention : chaque provider le déclare.
/// Un `#EXTINF` porte `catchup` (mode), `catchup-days` (fenêtre) et
/// `catchup-source` (modèle d'URL). Fabriquer soi-même un
/// `timeshift.php?...&start=&duration=` marche sur Xtream Codes et **nulle
/// part ailleurs** : un panel Flussonic ou Shift attend une autre forme, et
/// l'URL obtenue renvoie 404 ou une page d'authentification. Le template est
/// donc la source de vérité, et le mode sert à l'interpréter.
///
/// ## Variables documentées
///
/// | Variable | Sens |
/// |---|---|
/// | `{utc}`, `{start}` | début du programme, timestamp Unix (secondes) |
/// | `{lutc}`, `{now}` | horodatage courant, timestamp Unix (secondes) |
/// | `{duration}` | durée du programme |
/// | `{offset}` | secondes écoulées depuis le début du programme |
/// | `{Y}` `{m}` `{d}` `{H}` `{M}` `{S}` | composantes ISO du début |
///
/// La durée et les timestamps sont en **secondes** : c'est la convention
/// Xtream (`start`/`duration`) et celle des serveurs qui n'acceptent pas le
/// format ISO. Les composantes `{Y}`… couvrent les serveurs qui attendent
/// l'horodatage en `YYYYMMDDHHMMSS`, que [buildCatchupIsoStamp] produit aussi.
class CatchupUrl {
  const CatchupUrl._();

  /// Construit l'URL de replay d'un programme.
  ///
  /// Renvoie `null` si le provider ne déclare aucun template : dans ce cas
  /// l'appelant doit appliquer sa propre convention (Xtream Codes), plutôt que
  /// de voir une URL inventée.
  ///
  /// [offset] vaut 0 par défaut : on ouvre un replay à son début. Il n'est
  /// non nul que si l'utilisateur reprend une lecture en cours.
  static String? build({
    required Channel channel,
    required DateTime start,
    required DateTime end,
    Duration offset = Duration.zero,
  }) {
    final template = channel.catchupSource.trim();
    if (template.isEmpty) return null;
    return resolve(
      template: template,
      mode: channel.catchupMode,
      liveUrl: channel.streamUrl,
      start: start,
      end: end,
      offset: offset,
    );
  }

  /// Substitution pure, sans [Channel], pour être testable directement.
  static String resolve({
    required String template,
    required String mode,
    required String liveUrl,
    required DateTime start,
    required DateTime end,
    Duration offset = Duration.zero,
  }) {
    final startSeconds = start.millisecondsSinceEpoch ~/ 1000;
    final durationSeconds = end.difference(start).inSeconds;
    // `{offset}` est le décalage de LECTURE, pas l'heure courante : un replay
    // s'ouvre à 0, et l'heure du moment n'a rien à y faire. Le confondre
    // produisait une URL pointant 12 h après le début du programme.
    final offsetSeconds = offset.inSeconds < 0 ? 0 : offset.inSeconds;
    final local = start.toLocal();

    final values = <String, String>{
      '{utc}': '$startSeconds',
      '{start}': '$startSeconds',
      // `{lutc}` / `{now}` sont les alias de l'INSTANT D'EXÉCUTION, ceux du
      // décalage de lecture. Ils n'ont pas la même valeur, et les confondre
      // ferait rater la fenêtre de rattrapage.
      '{lutc}': '${startSeconds + offsetSeconds}',
      '{now}': '${startSeconds + offsetSeconds}',
      '{duration}': '$durationSeconds',
      '{offset}': '$offsetSeconds',
      '{Y}': _pad(local.year, 4),
      '{m}': _pad(local.month),
      '{d}': _pad(local.day),
      '{H}': _pad(local.hour),
      '{M}': _pad(local.minute),
      '{S}': _pad(local.second),
    };

    var url = template;
    values.forEach((key, value) {
      url = url.replaceAll(key, value);
    });

    // `append` : le modèle est une chaîne de paramètres à **ajouter** à l'URL
    // du flux live, pas une URL à part entière. Sans ce cas on produisait
    // `?start=…` seul, sans hôte.
    if (mode.trim().toLowerCase() == 'append') {
      final separator = liveUrl.contains('?') ? '&' : '?';
      final trimmed = liveUrl.trim();
      if (url.startsWith('?')) {
        return url.isEmpty ? trimmed : '$trimmed$url';
      }
      if (url.startsWith('&')) {
        return '$trimmed$url';
      }
      return '$trimmed$separator$url';
    }

    // Un modèle qui commence par `/` est un CHEMIN relatif : il se rattache à
    // l'hôte du flux live (cas Flussonic). Un modèle qui commence par `?` ou
    // `&` est un fragment de requête et un modèle sans slash est une valeur
    // nue : les traiter comme des chemins relatifs préfixait l'hôte devant un
    // simple `?start=…`, ce qui donnait une URL sans chemin de flux.
    if (url.startsWith('/') &&
        !url.startsWith('//') &&
        liveUrl.startsWith('http')) {
      final uri = Uri.tryParse(liveUrl);
      if (uri != null && uri.hasAuthority) {
        return '${uri.scheme}://${uri.authority}$url';
      }
    }
    return url;
  }

  /// Horodatage ISO `YYYYMMDDHHMMSS` du début, pour les serveurs qui attendent
  /// ce format plutôt qu'un timestamp Unix.
  static String buildCatchupIsoStamp(DateTime start) {
    final l = start.toLocal();
    return '${_pad(l.year, 4)}${_pad(l.month)}${_pad(l.day)}'
        '${_pad(l.hour)}${_pad(l.minute)}${_pad(l.second)}';
  }

  static String _pad(int value, [int width = 2]) =>
      value.toString().padLeft(width, '0');
}
