/// Fenêtre d'une journée de guide TV : minuit → minuit.
///
/// ## Pourquoi une seule définition
///
/// La grille EPG et le Replay doivent partager la même notion de « la journée »
/// : c'est le même programme, donc la même heure. On avait d'un côté
/// « maintenant moins 1 h → plus 24 h » et de l'autre « 00:00 → 23:59 », soit
/// deux emplacements différents pour un même programme selon l'écran où on le
/// regarde — et la grille ne pouvait pas non plus afficher la matinée si la
/// fenêtre ne couvrait pas minuit.
///
/// L'implémentation de la grille demande `gridStartTime` en `DateTime` et une
/// largeur totale fixe (`24 h × échelle`), donc la fenêtre est calée sur minuit
/// local. C'est le fuseau de l'appareil, ce qui est le comportement attendu :
/// « 20 h » dans un guide doit être l'heure locale de la personne qui regarde.
class EpgDayWindow {
  const EpgDayWindow({required this.start, required this.end});

  /// Début de la journée (minuit, heure locale).
  final DateTime start;

  /// Fin de la journée (minuit du lendemain, exclusive).
  final DateTime end;

  /// Longueur de la fenêtre : 24 h, sans exception.
  int get minutes => end.difference(start).inMinutes;

  /// La journée qui contient [moment].
  factory EpgDayWindow.of(DateTime moment) {
    final day = DateTime(moment.year, moment.month, moment.day);
    return EpgDayWindow(start: day, end: day.add(const Duration(days: 1)));
  }

  /// La journée en cours.
  factory EpgDayWindow.ofNow() => EpgDayWindow.of(DateTime.now());

  /// La fenêtre d'un jour de calendrier donné, pour le Replay.
  factory EpgDayWindow.ofDay(DateTime day) => EpgDayWindow(
        start: DateTime(day.year, day.month, day.day),
        end: DateTime(day.year, day.month, day.day + 1),
      );

  @override
  String toString() =>
      'EpgDayWindow(${start.toIso8601String()} → ${end.toIso8601String()})';
}