import 'package:hive/hive.dart';

/// Adaptateur Hive pour [Duration].
///
/// `DownloadProgress.estimatedTimeRemaining` est une `Duration`, et l'adaptateur
/// généré l'écrit tel quel. Or **aucun adaptateur `Duration` n'était
/// enregistré** dans `main.dart` : Hive lève alors
///
/// ```
/// HiveError: Cannot write, unknown type: Duration.
/// ```
///
/// Le défaut a été trouvé par un test qui écrivait une vraie `DownloadTask`
/// dans une vraie boîte.
///
/// La fenêtre d'échec est donc plus étroite qu'un « tout échoue » : une tâche
/// sans progression s'écrit, mais dès que le téléchargement en rapporte une,
/// la sauvegarde échoue. C'est assez pour qu'aucune progression ne soit
/// conservée, et assez pour que l'erreur soit attribuée à la cause visible
/// (le typage de boîte) plutôt qu'à la vraie.
///
/// Le typeId 52 est libre (occupés : 1, 2, 3, 50, 51, 53) et reste dans la
/// famille des téléchargements.
///
/// Format : nombre de microsecondes en `int`. Un `Duration` tient largement
/// dans un `int` 64 bits (~292 000 ans), donc aucune perte.
class DurationAdapter extends TypeAdapter<Duration> {
  @override
  final int typeId = 52;

  @override
  Duration read(BinaryReader reader) =>
      Duration(microseconds: reader.readInt());

  @override
  void write(BinaryWriter writer, Duration obj) {
    writer.writeInt(obj.inMicroseconds);
  }
}
