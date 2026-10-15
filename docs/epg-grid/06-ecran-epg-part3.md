# EPG — grille : 6. l’écran EPG

> **Partie 3/3**

> Fiche générée depuis le code source — extraction fidèle, commentaires compris. Chaque bloc est limité à 200 lignes pour rester copiable sans saturer le presse-papier.

Sources : `lib/features/epg/epg_screen.dart`

### 6.1 `EpgScreen` — suite 3/3

`lib/features/epg/epg_screen.dart` · lignes 801–998

#### `lib/features/epg/epg_screen.dart` · lignes 801–998 · partie 1/1

```dart

  final List<Channel> channels;
  final EpgTimelineController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return ValueListenableBuilder<String?>(
      valueListenable: controller.targetedChannel,
      builder: (context, channelName, _) {
        if (channelName == null) {
          // Aucune chaîne ciblée : bandeau discret au lieu d'une headbar vide.
          return Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: const Color(0xFF13151B),
            alignment: Alignment.centerLeft,
            child: const Row(
              children: [
                Icon(
                  Icons.live_tv,
                  color: Colors.white38,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'Sélectionnez une chaîne pour voir son programme',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          );
        }

        final channel = _byName[channelName];
        if (channel == null) {
          return const SizedBox.shrink();
        }
        return EpgHeadbar(
          key: ValueKey(channel.id),
          type: EpgHeadbarType.live,
          channel: channel,
          isLive: true,
          isFavorite: _isFavorite(ref, 'live', channel),
          currentProgram: ref
              .watch(channelEpgProvider(channel.primaryEpgChannelId))
              .maybeWhen(
                data: (programs) => epgCurrentProgram(programs, DateTime.now()),
                orElse: () => null,
              ),
          nextProgram: ref
              .watch(channelEpgProvider(channel.primaryEpgChannelId))
              .maybeWhen(
                data: (programs) => epgNextProgram(programs, DateTime.now()),
                orElse: () => null,
              ),
          onPlay: () {
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
          onFavoriteToggle: () {
            final entry = FavoriteEntry(
              type: ContentType.live,
              id: channel.id,
              title: channel.name,
              posterUrl: channel.logoUrl,
              subtitle: channel.groupLabel,
              streamUrl: channel.streamUrl,
            );
            ref.read(favoritesProvider.notifier).toggle(entry);
          },
          onInfo: () {
            final programs =
                ref.read(channelEpgProvider(channel.primaryEpgChannelId)).value;
            final current = programs == null
                ? null
                : epgCurrentProgram(programs, DateTime.now());
            if (current != null) {
              _showProgramBottomSheet(context, current, channel);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l.noProgramInfoAvailable),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        );
      },
    );
  }

  Map<String, Channel> get _byName => {for (final c in channels) c.name: c};

  bool _isFavorite(WidgetRef ref, String type, Channel channel) {
    final favorites = ref.watch(favoritesProvider);
    // Clé canonique alignée sur FavoritesNotifier (profil courant).
    final profile = ref.watch(currentProfileProvider);
    final key = profile == null || profile.id.isEmpty
        ? '$type:${channel.id}'
        : '${profile.id}:$type:${channel.id}';
    return favorites.containsKey(key);
  }

  Future<void> _showProgramBottomSheet(
    BuildContext context,
    EPGProgram program,
    Channel channel,
  ) async {
    final scheme = Theme.of(context).colorScheme;
    final watchFocus = FocusNode();

    void watch() {
      Navigator.pop(context);
      Navigator.pushNamed(
        context,
        '/player',
        arguments: {
          'streamUrl': channel.streamUrl,
          'title': channel.name,
          'contentType': 'live',
          'channelId': channel.id,
        },
      );
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16181E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              program.title,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_hhmm(program.start)} - ${_hhmm(program.end)}',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
            ),
            if (program.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                program.description,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Focus(
              focusNode: watchFocus,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    (event.logicalKey == LogicalKeyboardKey.enter ||
                        event.logicalKey == LogicalKeyboardKey.select ||
                        event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                  watch();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: FilledButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: Text('Regarder ${channel.name}'),
                onPressed: watch,
              ),
            ),
          ],
        ),
      ),
    );
    watchFocus.dispose();
  }

  String _hhmm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}
```
