import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/providers/radio_favorites_provider.dart';
import 'package:orbit_3d_flutter/models/channel.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/core/utils/xtream_taxonomy.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

class RadioScreen extends ConsumerStatefulWidget {
  const RadioScreen({super.key});

  @override
  ConsumerState<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends ConsumerState<RadioScreen> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final radiosAsync = ref.watch(radioChannelsProvider);
    final radioService = ref.watch(radioServiceProvider);
    final stationName = _currentStationName;
    final isPlaying = radioService.isPlaying;
    final isLoading = radioService.isLoading;
    final error = radioService.error;
    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => context.pop(),
              )
            : null,
        title: const Text('Radio'),
      ),
      body: radiosAsync.when(
        data: (radios) {
          if (radios.isEmpty) {
            return EmptyState(
              icon: Icons.radio,
              title: l.noStationsAvailable,
              message: l.radioEmptyHint,
            );
          }
          return Column(
            children: [
              if (isLoading)
                LinearProgressIndicator(
                  minHeight: 3,
                  color: Theme.of(context).colorScheme.primary,
                ),
              if (error != null && !isLoading)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            error,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final countries = _countriesOf(radios);
                    final favorites = ref.watch(radioFavoritesProvider);
                    final onlyFavorites =
                        _onlyFavorites && favorites.isNotEmpty;
                    final selected =
                        countries.contains(_country) ? _country : null;
                    final shown = onlyFavorites
                        ? radios
                            .where((r) => favorites.contains(r.name))
                            .toList()
                        : selected == null
                            ? radios
                            : radios
                                .where((r) => _countryOf(r.name) == selected)
                                .toList();
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: shown.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader(
                                icon: Icons.graphic_eq,
                                title: l.radioStations,
                                subtitle: l.radioStationsCount(shown.length),
                              ),
                              if (countries.length > 1) ...[
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      if (favorites.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: ChoiceChip(
                                            avatar: const Icon(Icons.favorite,
                                                size: 16),
                                            label: Text(
                                                '${l.favorites} (${favorites.length})'),
                                            selected: onlyFavorites,
                                            onSelected: (_) => setState(
                                                () => _onlyFavorites = true),
                                          ),
                                        ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: ChoiceChip(
                                          label: Text(l.searchAllCategories),
                                          selected: selected == null &&
                                              !onlyFavorites,
                                          onSelected: (_) => setState(() {
                                            _country = null;
                                            _onlyFavorites = false;
                                          }),
                                        ),
                                      ),
                                      for (final c in countries)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: ChoiceChip(
                                            label: Text(c),
                                            selected:
                                                !onlyFavorites && selected == c,
                                            onSelected: (_) => setState(() {
                                              _country = c;
                                              _onlyFavorites = false;
                                            }),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                            ],
                          );
                        }
                        final radio = shown[index - 1];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TvFocus(
                            autofocus: index == 1,
                            onActivate: () => _toggleStation(radio),
                            onLongPress: () => _toggleFavorite(radio),
                            child: ExcludeFocus(
                              child: ChannelTile(
                                title: radio.name,
                                subtitle: radio.group,
                                icon: Icons.radio,
                                isActive:
                                    stationName == radio.name && isPlaying,
                                trailing: _unavailable.contains(radio.name)
                                    ? Tooltip(
                                        message: l.radioStreamUnavailable,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .errorContainer,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.error_outline_rounded,
                                                size: 16,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onErrorContainer,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                l.subtitleUnavailable,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onErrorContainer,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ExcludeFocus(
                                            child: IconButton(
                                              tooltip:
                                                  favorites.contains(radio.name)
                                                      ? l.favoritesRemove
                                                      : l.favoritesAdd,
                                              icon: Icon(
                                                favorites.contains(radio.name)
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: favorites
                                                        .contains(radio.name)
                                                    ? const Color(0xFFFF5252)
                                                    : null,
                                              ),
                                              onPressed: () =>
                                                  _toggleFavorite(radio),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              stationName == radio.name &&
                                                      isPlaying
                                                  ? Icons.stop_circle_outlined
                                                  : Icons.play_circle_outline,
                                            ),
                                            color: stationName == radio.name &&
                                                    isPlaying
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                            onPressed: () =>
                                                _toggleStation(radio),
                                          ),
                                        ],
                                      ),
                                onTap: () => _toggleStation(radio),
                                onLongPress: () => _toggleFavorite(radio),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => LoadingState(message: l.catalogLoading),
        error: (err, _) => ErrorState(
          icon: Icons.radio,
          title: l.stationsUnavailable,
          message: userFriendlyError(err),
          onRetry: () => ref.invalidate(radioChannelsProvider),
        ),
      ),
    );
  }

  String? _currentStationName;
  String? _country;
  bool _onlyFavorites = false;
  final Set<String> _unavailable = {};

  /// Pays lu dans le préfixe du nom (`|BE| Antipode`), sinon « Autres ».
  static String _countryOf(String name) => XtreamTaxonomy.countryOf(name);

  static List<String> _countriesOf(List<Channel> radios) =>
      XtreamTaxonomy.sortCountries(radios.map((r) => _countryOf(r.name)));

  Future<void> _toggleFavorite(Channel radio) async {
    final wasFavorite = ref.read(radioFavoritesProvider).contains(radio.name);
    await ref.read(radioFavoritesProvider.notifier).toggle(radio.name);
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(wasFavorite
              ? l.removedFromFavorites(radio.name)
              : l.addedToFavorites(radio.name)),
          duration: const Duration(milliseconds: 1200),
        ),
      );
  }

  Future<void> _toggleStation(Channel radio) async {
    final radioService = ref.read(radioServiceProvider);
    if (_currentStationName == radio.name && radioService.isPlaying) {
      await radioService.stop();
      setState(() {
        _currentStationName = null;
        _unavailable.remove(radio.name);
      });
    } else {
      await radioService.play(radio.streamUrl);
      setState(() {
        if (radioService.error != null) {
          _unavailable.add(radio.name);
          _currentStationName = null;
        } else {
          _unavailable.remove(radio.name);
          _currentStationName = radio.name;
        }
      });
    }
  }
}
