import 'dart:convert';
import 'dart:io';

/// Vérifie que les fichiers .arb restent synchronisés entre locales.
///
/// Une clé présente dans une locale et absente d'une autre produit un getter qui
/// renvoie la chaîne du modèle (le français) : l'application affiche du français
/// à un utilisateur allemand, sans le moindre signe à l'écran. C'est invisible
/// dans l'analyse statique, d'où ce contrôle explicite.
void main() {
  const locales = ['fr', 'en', 'de', 'es', 'it', 'ar'];
  final data = <String, Map<String, dynamic>>{};
  for (final locale in locales) {
    final raw = File('lib/l10n/app_$locale.arb').readAsStringSync();
    data[locale] = (jsonDecode(raw) as Map).cast<String, dynamic>();
  }

  final template = data['fr']!;
  // Les métadonnées `@key` ne sont pas des messages.
  final messages =
      template.keys.where((k) => !k.startsWith('@')).toSet();

  var problems = 0;
  for (final locale in locales) {
    if (locale == 'fr') continue;
    final missing = messages.where((k) => !data[locale]!.containsKey(k));
    for (final key in missing) {
      problems++;
      // La sortie est ASCII volontaire : la console Windows n'affiche pas l'arabe
      // et un '?' trompeur ferait croire a une corruption.
      stderr.writeln('MANQUE $locale : $key');
    }
  }

  // Clés présentes dans une locale mais absentes du modèle : elles ne seront
  // jamais générées, et l'appel site ne compilera pas.
  for (final locale in locales) {
    final extra = data[locale]!.keys
        .where((k) => !k.startsWith('@') && !messages.contains(k));
    for (final key in extra) {
      problems++;
      stderr.writeln('INCONNUE $locale : $key');
    }
  }

  stderr.writeln(
      '${messages.length} messages, $problems probleme(s) sur ${locales.length} locales');
  exit(problems == 0 ? 0 : 1);
}