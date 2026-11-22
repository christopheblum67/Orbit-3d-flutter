# EPG — grille : 6. l’écran EPG

> **Partie 2/3**

> Fiche générée depuis le code source — extraction fidèle, commentaires compris. Chaque bloc est limité à 200 lignes pour rester copiable sans saturer le presse-papier.

Sources : `lib/features/epg/epg_screen.dart`

### 6.1 `EpgScreen` — suite 2/3

`lib/features/epg/epg_screen.dart` · lignes 401–800

#### `lib/features/epg/epg_screen.dart` · lignes 401–600 · partie 1/2

```dart
            _chip(
              label: category.name,
              count: category.count,
              selected: selected == category.id,
              onTap: () => onSelected(category.id),
            ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    int count = 0,
  }) {
    final labelled = count > 0 ? '$label ($count)' : label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(labelled),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: const Color(0xFF16181E),
        selectedColor: const Color(0xFF2D224D),
        checkmarkColor: const Color(0xFF8B5CF6),
        labelStyle: TextStyle(
          color: selected ? const Color(0xFF8B5CF6) : Colors.white70,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Wrapper pour la Grille EPG avec chargement EPG par chaîne.
class _EpgGrid2DWrapper extends ConsumerStatefulWidget {
  final List<String> channels;
  final List<Channel> channelObjects;
  final EpgTimelineController timelineController;
  final void Function(EPGProgram program, Channel channel)? onProgramSelected;
  final Set<String> loadingChannels;

  const _EpgGrid2DWrapper({
    super.key,
    required this.channels,
    required this.channelObjects,
    required this.timelineController,
    required this.loadingChannels,
    this.onProgramSelected,
  });

  @override
  ConsumerState<_EpgGrid2DWrapper> createState() => _EpgGrid2DWrapperState();
}

class _EpgGrid2DWrapperState extends ConsumerState<_EpgGrid2DWrapper> {
  final Map<String, List<EPGProgram>> _epgData = {};

  /// Instant du dernier chargement réussi, affiché dans le bandeau de
  /// fraîcheur. `null` tant que rien n'a été chargé.
  DateTime? _lastLoadedAt;

  /// Vrai pendant un rafraîchissement forcé : verrouille le bouton et anime
  /// l'indicateur.
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadAllEpg();
  }

  Future<void> _loadAllEpg() async {
    // 1. Un seul téléchargement XMLTV (le gros morceau), primé une fois via le
    // cache partagé avant de filtrer en parallèle.
    //
    // `ref` est lu ICI, avant toute suspension, comme le veut Riverpod.
    final api = ref.read(apiServiceProvider);
    final cache = ref.read(epgDataCacheProvider);
    final resolved = await safeAsync(
      () => cache.loadFull(api),
      context: '_loadAllEpg cache.loadFull',
    );

    // Le téléchargement XMLTV prend plusieurs secondes. La grille porte un
    // `key: ValueKey(category)`, donc changer de catégorie recrée cet State :
    // l'ancien `_loadAllEpg` se réveillait ici, DEMONTE, et son `ref.read`
    // de la ligne suivante levait « Using ref when a widget is about to or has
    // been unmounted is unsafe ». Chaque `_loadOne` de ce lot échouait, d'où
    // des lignes vides alors que le dump contenait les programmes.
    if (!mounted) return;

    LoggerService.instance.info(
      'EPG: XMLTV chargé (${resolved.isSuccess ? 'ok' : 'échec'}), '
      '$widget.loadingChannels chaînes à résoudre',
    );

    // 2. Filtre en mémoire par lots : un seul setState par lot de chaînes,
    // au lieu d'un rebuild complet de la grille à chaque chaîne (ANR sinon).
    final byName = {for (final c in widget.channelObjects) c.name: c};
    const chunkSize = 8;
    final missingIds = <String>[];

    for (var i = 0; i < widget.channels.length; i += chunkSize) {
      final chunk = widget.channels.skip(i).take(chunkSize);
      final tasks = <Future<void>>[];
      final chunkResults = <String, List<EPGProgram>>{};
      for (final channelName in chunk) {
        if (widget.loadingChannels.contains(channelName)) continue;
        widget.loadingChannels.add(channelName);
        final channel = byName[channelName];
        if (channel == null) {
          widget.loadingChannels.remove(channelName);
          continue;
        }
        // Si le panel n'expose pas d'identifiant EPG, on tente le nom de la
        // chaîne : l'index XMLTV contient souvent cette forme exacte. Sans ce
        // repli, la ligne restait vide dans la grille.
        // `epgChannelId` peut contenir plusieurs candidats séparés par une
        // virgule (« stream_id,num:stream_id ») : le passer en entier comme
        // clé de provider ne pouvait donc jamais correspondre à l'index
        // XMLTV. On ne transmet que le premier candidat — `channelEpgProvider`
        // essaie de lui-même toutes les formes.
        final epgId = channel.primaryEpgChannelId.isNotEmpty
            ? channel.primaryEpgChannelId
            : channelName;
        tasks.add(_loadOne(
          channelName,
          channel,
          epgId,
          chunkResults,
          missingIds,
        ),);
      }
      await Future.wait(tasks);
      if (mounted) {
        setState(() => _epgData.addAll(chunkResults));
      }
    }

    // 2 bis. Bilan mesuré, pas deviné : `inWindow.isEmpty` est la seule source
    // fiable pour distinguer un programme trouvé d'un bloc de trou, car un
    // bloc comblé porte lui aussi un titre.
    final total = widget.channels.length;
    final missing = missingIds.length;
    if (mounted) setState(() {});

    LoggerService.instance.info(
      'EPG: $total chaînes, ${total - missing} avec programmes, '
      '$missing sans (aucun programme dans la fenêtre) — ${_epgData.length} '
      'lignes construites.${missingIds.isEmpty ? '' : ' Sans résultat pour : '
          '${missingIds.take(8).join(', ')}'}',
    );

    if (mounted) {
      // `cache` est lu AVANT toute suspension (règle Riverpod) : on relit son
      // horodatage local plutôt que de repasser par `ref`.
      setState(() => _lastLoadedAt = cache.fetchedAt);
    }
  }

  Future<void> _loadOne(
    String channelName,
    Channel channel,
    String epgId,
    Map<String, List<EPGProgram>> out,
    List<String> missingIds,
  ) async {
    final result = await safeAsync(
      // Variante GRILLE : programmes passés compris. La barre du lecteur ne veut
      // que « en cours / à venir », mais la grille représente une journée
      // entière — lui servir du « à venir » laissait la matinée vide, comblée par
      // des blocs de trou alors que les données existaient dans le dump.
      () => ref.read(channelEpgWindowProvider(epgId).future),
      context: '_loadOne channelEpgWindowProvider',
    );
    if (!mounted) return;
    if (result.isSuccess) {
      // Fenêtre de la journée : minuit → minuit, et une seule définition pour
      // toute l'application.
      //
      // La grille commençait à « maintenant moins 1 h », ce qui décalait tout
      // d'une heure par rapport au Replay (00:00 → 24 h) : deux définitions de la
      // même journée, donc deux heures différentes pour un même programme. La
      // spec est nette — T_start = 00:00, T_end = T_start + 24 h.
      final window = EpgDayWindow.ofNow();
      final windowStart = window.start;
      final windowEnd = window.end;
      final windowStartSec = windowStart.millisecondsSinceEpoch ~/ 1000;
      final windowEndSec = windowEnd.millisecondsSinceEpoch ~/ 1000;
      final inWindow = EPGSearchEngine.getProgramsInWindow(
        result.valueOrNull!,
        windowStartSec,
        windowEndSec,
      );
      // Comblement des trous : l'axe de la grille est continu, donc une absence
      // de données doit être un bloc, pas un blanc. Sans lui, un trou de 40 min
```

#### `lib/features/epg/epg_screen.dart` · lignes 601–800 · partie 2/2

```dart
      // se lisait comme un programme manquant et décalait la lecture de l'axe.
      out[channelName] = EpgGapFiller.fill(
        programs: inWindow,
        windowStart: windowStart,
        windowEnd: windowEnd,
        channelId: channel.id,
      );
      // Programme « vrai » = au moins un programme dans la fenêtre. Un bloc de
      // trou a lui aussi un titre, donc compter les titres non vides
      // compterait les comblements comme des programmes : c'est ce qui donne
      // l'illusion d'une grille « peuplée » alors que rien n'a été trouvé.
      if (inWindow.isEmpty) {
        missingIds.add('${channel.name}→$epgId');
      }
    } else {
      missingIds.add('${channel.name}→$epgId(erreur)');
      LoggerService.instance
          .warning('_loadOne failed', error: result.errorOrNull);
    }
    if (mounted) {
      widget.loadingChannels.remove(channelName);
    }
  }

  /// Rafraîchissement FORCÉ (bouton + tirer-pour-rafraîchir).
  ///
  /// Passe par `EPGDataCache.forceRefresh` : invalide le cache mémoire et
  /// supprime le tampon disque avant de retélécharger. Un simple `_loadAllEpg`
  /// n'aurait rien rafraîchi tant que le cache avait moins de 30 min.
  Future<void> _refreshForced() async {
    if (_refreshing) return;
    final api = ref.read(apiServiceProvider);
    final cache = ref.read(epgDataCacheProvider);
    setState(() => _refreshing = true);
    final result = await safeAsync(
      () => cache.forceRefresh(api),
      context: '_refreshForced forceRefresh',
    );
    if (!mounted) return;
    if (!result.isSuccess) {
      // Jamais d'échec silencieux : sans ce message, l'utilisateur croirait
      // que les données sont à jour alors que le panel n'a pas répondu.
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text(
            'Rafraîchissement EPG impossible : le panel n\'a pas répondu. '
            'Les programmes affichés restent ceux du dernier chargement.',
          ),
        ),
      );
    }
    setState(() => _refreshing = false);
    // Reconstruit `_epgData` depuis le cache (désormais frais).
    await _loadAllEpg();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _EpgFreshnessBar(
          loadedAt: _lastLoadedAt,
          refreshing: _refreshing,
          onRefresh: _refreshForced,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshForced,
            child: EpgGrid2DView(
              channels: widget.channels,
              epgData: _epgData,
              pixelsPerMinute: EpgTimelineController.defaultPixelsPerMinute,
              replayChannels: {
                for (final c in widget.channelObjects)
                  if (c.supportsReplay) c.name,
              },
              loadingChannels: widget.loadingChannels,
              onProgramTap: (program, channelName) {
                final channel = widget.channelObjects
                    .firstWhere((c) => c.name == channelName);
                widget.onProgramSelected?.call(program, channel);
              },
              onChannelTap: (channelName) {
                // Invalidate EPG cache on zap to free memory
                ref.read(epgDataCacheProvider).invalidate();
                final channel = widget.channelObjects
                    .firstWhere((c) => c.name == channelName);
                Navigator.pushNamed(
                  context,
                  '/player',
                  arguments: {
                    'streamUrl': channel.streamUrl,
                    'title': channel.name,
                    'contentType': 'live',
                  },
                );
              },
              onChannelLongPress: (channelName) {
                final channel = widget.channelObjects
                    .firstWhere((c) => c.name == channelName);
                if (channel.supportsReplay) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CatchUpScreen(channel: channel),
                    ),
                  );
                }
              },
              // Use shared timeline controller
              timelineController: widget.timelineController,
            ),
          ),
        ),
      ],
    );
  }
}

/// Bandeau de fraîcheur de l'EPG, avec bouton de rafraîchissement forcé.
///
/// Répond à deux manques constatés : rien n'indiquait QUAND les données
/// avaient été chargées, et « tirer pour rafraîchir » servait le cache mémoire
/// sans jamais retélécharger — donc sans effet visible ni explication.
class _EpgFreshnessBar extends StatelessWidget {
  const _EpgFreshnessBar({
    required this.loadedAt,
    required this.refreshing,
    required this.onRefresh,
  });

  final DateTime? loadedAt;
  final bool refreshing;
  final Future<void> Function() onRefresh;

  static String _two(int v) => v < 10 ? '0$v' : '$v';

  @override
  Widget build(BuildContext context) {
    final at = loadedAt;
    final String label;
    final Color color;
    if (refreshing) {
      label = 'Rafraîchissement de l\'EPG…';
      color = const Color(0xFF8B5CF6);
    } else if (at == null) {
      label = 'EPG non chargé';
      color = Colors.white38;
    } else {
      label = 'EPG mis à jour à ${_two(at.hour)}:${_two(at.minute)}';
      color = Colors.white54;
    }

    return Container(
      height: 32,
      padding: const EdgeInsets.only(left: 12, right: 4),
      color: const Color(0xFF13151B),
      child: Row(
        children: [
          if (refreshing)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(Icons.cloud_done_outlined, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 11),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            color: Colors.white70,
            tooltip: 'Forcer le rechargement de l\'EPG',
            onPressed: refreshing ? null : () => onRefresh(),
          ),
        ],
      ),
    );
  }
}

/// Section en-tête EPG unifiée : affiche [EpgHeadbar] pour la chaîne ciblée
/// dans la grille (row temps + toolbar du bas).
///
/// - Chaîne ciblée : cliquée dans la colonne de gauche de la grille
///   ([EpgTimelineController.targetedChannel]).
/// - Programme en cours / suivant : calculés via la recherche dichotomique
///   (O(log N)) sur l'EPG chargé par [channelEpgProvider].
class _EpgHeadbarSection extends ConsumerWidget {
  const _EpgHeadbarSection({
    required this.channels,
    required this.controller,
  });
```
