/// Retypage profond des structures lues dans un cache Hive.
///
/// ## Le problème
///
/// Hive ne conserve pas les types génériques Dart au round-trip : une map
/// écrite en `Map<String, dynamic>` est relue en `_Map<dynamic, dynamic>`, et
/// ses valeurs imbriquées (maps, listes) sont dans le même état.
///
/// `Map<String, dynamic>.from(...)` ne corrige que la RACINE. C'est une copie
/// superficielle : les valeurs sont transportées telles quelles. Un parseur qui
/// fait ensuite `data['externals'] as Map<String, dynamic>?` lève alors un
/// `TypeError` :
///
/// ```text
/// type '_Map<dynamic, dynamic>' is not a subtype of type 'Map<String, dynamic>?' in type cast
/// ```
///
/// C'est ce qui faisait échouer l'enrichissement des fiches série/film après un
/// CACHE HIT : la réponse réseau est du JSON correctement typé, la copie en
/// cache ne l'est plus, et le même contenu échoue selon qu'il vient du réseau ou
/// du disque — d'où une panne intermittente, difficile à rattacher à sa cause.
///
/// ## La correction
///
/// [deepRetypeMap] reconstruit la structure ENTIÈREMENT : chaque map devient
/// une `Map<String, dynamic>`, chaque liste est parcourue. Les clés non
/// textuelles sont converties en chaîne plutôt que perdues : une réponse JSON
/// n'a que des clés textuelles, donc ce cas ne survient que sur des données
/// construites à la main.
Map<String, dynamic> deepRetypeMap(Map<dynamic, dynamic> source) {
  final out = <String, dynamic>{};
  for (final entry in source.entries) {
    out['${entry.key}'] = deepRetypeValue(entry.value);
  }
  return out;
}

/// Retype une valeur quelconque rencontrée dans une réponse JSON mise en cache.
///
/// Les listes sont retraversées, les maps sont converties récursivement, et tout
/// le reste est renvoyé tel quel : un `String`, un `int` ou un `null` n'a rien
/// à retyper.
dynamic deepRetypeValue(dynamic value) {
  if (value is Map) return deepRetypeMap(value);
  if (value is List) return value.map(deepRetypeValue).toList();
  return value;
}
