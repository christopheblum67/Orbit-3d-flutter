// Fusionne des clés de traduction dans les fichiers .arb, puis vérifie que les
// 6 locales restent synchronisées.
//
// Usage : dart run tool/apply_i18n_additions.dart <fichier.json>
//
// Le JSON est un objet `clé -> { locale -> texte }`. Les locales absentes d'une
// entrée sont ignorées, ce qui permet d'ajouter une clé d'abord en français et
// anglais seulement, sans casser la génération.
import 'dart:convert';
import 'dart:io';

const locales = ['fr', 'en', 'de', 'es', 'it', 'ar'];

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('usage: dart run tool/apply_i18n_additions.dart <additions.json>');
    exit(2);
  }

  final additions = (jsonDecode(File(args.first).readAsStringSync()) as Map)
      .cast<String, Map<String, dynamic>>();

  var added = 0;
  for (final locale in locales) {
    final path = 'lib/l10n/app_$locale.arb';
    final data = _read(locale);
    for (final entry in additions.entries) {
      final value = entry.value[locale];
      if (value is! String) continue;
      // Une clé existante n'est pas écrasée : cet outil ajoute, il ne corrige
      // pas. Une clé déjà présente est presque toujours une faute de frappe
      // dans le JSON d'entrée, et l'écraser en silence masquerait le doublon.
      if (data.containsKey(entry.key)) {
        stderr.writeln('cle deja presente, ignoree : ${entry.key} ($locale)');
        continue;
      }
      data[entry.key] = value;
      added++;
    }
    File(path).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(data)}\n',
      encoding: utf8,
    );
  }

  // Les fichiers .arb sont triés par clé : sans cela, chaque ajout réécrit
  // l'intégralité du fichier et le diff devient illisible.
  stderr.writeln('$added entrees ajoutees sur ${locales.length} locales');
}

Map<String, dynamic> _read(String locale) {
  final raw = File('lib/l10n/app_$locale.arb').readAsStringSync();
  return (jsonDecode(raw) as Map).cast<String, dynamic>();
}