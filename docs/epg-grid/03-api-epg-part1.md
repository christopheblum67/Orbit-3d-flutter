# EPG — grille : 3. récupération (ApiService) et parseurs

> **Partie 1/3**

> Fiche générée depuis le code source — extraction fidèle, commentaires compris. Chaque bloc est limité à 200 lignes pour rester copiable sans saturer le presse-papier.

Sources : `lib/services/api_service.dart`, `lib/services/epg_stream_parser.dart`, `lib/services/epg_buffer_store.dart`

### 3.1 `fetchEpg` — dump XMLTV global (+ décodage)

`lib/services/api_service.dart` · lignes 2280–2320

#### `lib/services/api_service.dart` · lignes 2280–2320 · partie 1/1

```dart
  // ---------- EPG (XMLTV) ----------
  Future<List<EPGProgram>> fetchEpg() async {
    final sub = await _activeSub();
    if (sub['type'] == 'xtream') {
      final baseUrl = sub['baseUrl']!;
      final username = sub['username']!;
      final password = sub['password']!;
      final url = _playerApiUrl(baseUrl, 'xmltv.php', {
        'username': username,
        'password': password,
      });
      // `responseType: bytes` : on veut les octets bruts, pas une String déjà
      // décodée par Dio selon un charset HTTP souvent absent => accents
      // cassés. Le décodage réel est fait par [_decodeXmltvPayload].
      final response = await _get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      // Le dump XMLTV est massivement en UTF-8 alors que le panel_Xtream sert
      // souvent `Content-Type: text/xml` SANS charset : Dio applique alors son
      // défaut (latin1), ce qui transformait chaque accent en « é ». On
      // décode donc les octets bruts nous-mêmes, en suivant la déclaration
      // `encoding=` du prologue XML quand elle existe.
      final content = _decodeXmltvPayload(response);
      // Le parse complet (~94 000 entrées) est lourd : déporté sur un isolate
      // pour ne pas figer le thread UI (évite l'ANR sur les box TV/phones).
      final programs = await compute(_parseXmltvIsolate, content);
      debugPrint('Orbit3D epg fetched=${programs.length} '
          'first=${programs.isEmpty ? '<none>' : programs.first.channelId} '
          'url=${url.split('?').first}');
      return programs;
    }
    // Les flux M3U ne fournissent pas de guide XMLTV : pas de programme,
    // plutôt que de lever une erreur technique à l'écran.
    return const <EPGProgram>[];
  }

  /// Entrée isolate : `compute` exige une fonction top-level.
  static List<EPGProgram> _parseXmltvIsolate(String content) =>
      ApiService().parseXmltv(content);

```

### 3.2 Décodage XMLTV (`_decodeXmltvPayload`, `_decodeCharset`)

`lib/services/api_service.dart` · lignes 2350–2412

#### `lib/services/api_service.dart` · lignes 2350–2412 · partie 1/1

```dart
  static String _decodeXmltvPayload(Response<dynamic> response) {
    final dynamic data = response.data;
    final List<int> bytes;
    if (data is List<int>) {
      bytes = data;
    } else if (data is String) {
      // Dio a déjà décodé : on ne peut plus rattraper l'encodage, on réencode
      // en UTF-8 pour uniformiser la suite du traitement.
      return data;
    } else {
      return data?.toString() ?? '';
    }

    // 1. Déclaration XML du prologue (les 4 premiers Ko suffisent).
    final head = latin1.decode(bytes.take(4096).toList(), allowInvalid: true);
    final match = RegExp(
      "encoding\\s*=\\s*['\"]([A-Za-z0-9_.\\-]+)['\"]",
      caseSensitive: false,
    ).firstMatch(head);
    final declared = match?.group(1)?.toLowerCase();

    // 2. En-tête HTTP.
    final header = response.headers.value('content-type')?.toLowerCase() ?? '';
    final headerCharset =
        RegExp('charset=([A-Za-z0-9_.\\-]+)').firstMatch(header)?.group(1);

    final candidates = <String>[
      if (declared != null) declared,
      if (headerCharset != null) headerCharset,
      'utf-8',
      'iso-8859-1',
    ];

    for (final charset in candidates) {
      final decoded = _decodeCharset(bytes, charset);
      if (decoded != null) return decoded;
    }
    // `iso-8859-1` ne lève jamais : cette ligne est donc inatteignable en
    // pratique, mais garantit un String non-null.
    return latin1.decode(bytes, allowInvalid: true);
  }

  /// Décode [bytes] avec [charset]. Retourne null si l'encodage est inconnu ou
  /// si le décodage strict échoue (ce qui permet d'essayer le suivant).
  static String? _decodeCharset(List<int> bytes, String charset) {
    final name = charset.toLowerCase().trim();
    try {
      if (name == 'utf-8' || name == 'utf8') {
        return utf8.decode(bytes);
      }
      if (name == 'iso-8859-1' ||
          name == 'latin1' ||
          name == 'iso8859-1' ||
          name == 'windows-1252' ||
          name == 'cp1252') {
        return latin1.decode(bytes, allowInvalid: true);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

```

### 3.3 `parseXmltv` — délégation au parseur de flux

`lib/services/api_service.dart` · lignes 2618–2618

#### `lib/services/api_service.dart` · lignes 2618–2618 · partie 1/1

```dart
  List<EPGProgram> parseXmltv(String content) => EpgStreamParser.parse(content);
```

### 3.4 EPG d’une chaîne — aperçu court + parseur commun

`lib/services/api_service.dart` · lignes 1715–1784

#### `lib/services/api_service.dart` · lignes 1715–1784 · partie 1/1

```dart
  /// Programmes EPG d'une chaîne via `get_short_epg` (JSON).
  ///
  /// Complément au XMLTV global : renseigne le guide d'une chaîne en direct sans
  /// télécharger l'intégralité du dump. Échec ⇒ liste vide, le flux principal
  /// (XMLTV) reste la référence.
  ///
  /// Les titres et synopsis de certains panels arrivent encodés en base64 ; le
  /// décodage passe désormais par [PanelText], qui porte les garde-fous.
  Future<List<EPGProgram>> fetchChannelEpgPrograms(Channel channel) async {
    final sub = await _activeSub();
    if (sub['type'] != 'xtream') return const <EPGProgram>[];
    final result = await safeAsync<List<EPGProgram>>(
      () async {
        final url = _playerApiUrl(sub['baseUrl']!, 'player_api.php', {
          'username': sub['username']!,
          'password': sub['password']!,
          'action': 'get_short_epg',
          'stream_id': channel.id,
        });
        final response = await _get(url);
        final data = response.data;
        final list = data is List
            ? data
            : (data is Map
                ? (data['epg_listings'] as List? ?? const <dynamic>[])
                : const <dynamic>[]);
        final programs = <EPGProgram>[];
        for (final e in list.whereType<Map>()) {
          final program =
              _epgProgramFromMap(Map<String, dynamic>.from(e), channel);
          if (program != null) programs.add(program);
        }
        return programs;
      },
      context: 'ApiService.fetchChannelEpgPrograms',
      fallbackValue: const <EPGProgram>[],
    );
    return result.getOrElse(const <EPGProgram>[]);
  }

  /// Convertit une entrée brute d'EPG (JSON panel) en [EPGProgram].
  ///
  /// Source unique de la lecture des champs, partagée par
  /// [fetchChannelEpgPrograms] (aperçu court) et [fetchChannelCatchUpPrograms]
  /// (EPG complet). Les deux chemins divergeaient sur le nom du champ de fin
  /// (`stop` vs `end`) et sur le décodage des titres, ce qui produisait deux
  /// listes différentes pour une même chaîne.
  EPGProgram? _epgProgramFromMap(Map<String, dynamic> map, Channel channel) {
    final start = _parseReplayDate(map['start_timestamp'] ?? map['start']);
    final end = _parseReplayDate(
      map['stop_timestamp'] ?? map['stop'] ?? map['end'],
    );
    if (start == null || end == null || !end.isAfter(start)) return null;
    final title = PanelText.decode(map['title']?.toString().trim() ?? '');
    if (title.isEmpty) return null;
    return EPGProgram(
      // `epgChannelId` peut contenir plusieurs candidats séparés par une
      // virgule : on retient le premier, sinon l'id de la chaîne.
      channelId: channel.primaryEpgChannelId.isNotEmpty
          ? channel.primaryEpgChannelId
          : channel.id,
      title: title,
      description: PanelText.decode(
        _firstString(map, const ['description', 'plot', 'desc', 'summary']),
      ),
      start: start,
      end: end,
    );
  }

```

### 3.5 EPG complet d’une chaîne — source du rattrapage

`lib/services/api_service.dart` · lignes 1785–1820

#### `lib/services/api_service.dart` · lignes 1785–1820 · partie 1/1

```dart
  /// EPG **complet** d'une chaîne (passé compris) via `get_simple_data_table`.
  ///
  /// C'est la source du rattrapage multi-jours. `get_short_epg`, utilisé
  /// jusqu'ici pour le catch-up, ne renvoie que 4 entrées — presque toutes
  /// futures — et ne peut donc pas décrire l'historique : l'écran restait
  /// bloqué sur le dernier programme passé, quelle que soit la durée annoncée
  /// par l'abonnement. `get_simple_data_table` renvoie tout ce que le serveur
  /// conserve, et c'est cette source qu'exploite XCIPTV pour son Replay.
  ///
  /// Repli sur l'aperçu court si le panel ne sert pas cet appel, pour ne pas
  /// régresser sur les panels qui l'ignorent.
  Future<List<EPGProgram>> fetchChannelCatchUpPrograms(Channel channel) async {
    final sub = await _activeSub();
    if (sub['type'] != 'xtream') return const <EPGProgram>[];
    final baseUrl = sub['baseUrl']!;
    final username = sub['username']!;
    final password = sub['password']!;

    final entries = await _fetchChannelFullEpg(
      baseUrl: baseUrl,
      username: username,
      password: password,
      channel: channel,
    );
    if (entries.isEmpty) return fetchChannelEpgPrograms(channel);

    final programs = <EPGProgram>[];
    for (final e in entries) {
      final program = _epgProgramFromMap(e, channel);
      if (program != null) programs.add(program);
    }
    // Repli uniquement si l'EPG complet ne produit aucun programme exploitable.
    if (programs.isEmpty) return fetchChannelEpgPrograms(channel);
    return programs;
  }

```
