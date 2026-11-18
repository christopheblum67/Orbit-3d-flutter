import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orbit_3d_flutter/core/widgets/orbit_cached_image.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/cast.dart';
import 'package:orbit_3d_flutter/models/person.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// Page de détail d'un acteur : bio, infos personnelles et filmographie TMDB.
class ActorDetailScreen extends ConsumerWidget {
  const ActorDetailScreen({super.key, required this.actor});

  final Actor actor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final knownId =
        actor.source == ActorSource.tmdb ? int.tryParse(actor.id) ?? 0 : 0;
    final personAsync =
        knownId > 0 ? ref.watch(tmdbPersonDetailProvider(knownId)) : null;
    final searchAsync =
        knownId > 0 ? null : ref.watch(tmdbPersonSearchProvider(actor.name));

    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Retour',
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(actor.name.isEmpty ? 'Acteur' : actor.name),
      ),
      body: _buildBody(context, ref, personAsync, searchAsync),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<PersonDetail?>? personAsync,
    AsyncValue<int>? searchAsync,
  ) {
    if (personAsync != null) {
      return personAsync.when(
        data: (person) => person != null
            ? _ActorDetailBody(actor: actor, person: person)
            : const _ActorUnavailable(),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _buildError(context, err),
      );
    }
    return searchAsync!.when(
      data: (id) => id > 0
          ? ref.watch(tmdbPersonDetailProvider(id)).when(
                data: (person) => person != null
                    ? _ActorDetailBody(actor: actor, person: person)
                    : const _ActorUnavailable(),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => _buildError(context, err),
              )
          : const _ActorUnavailable(),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _buildError(context, err),
    );
  }

  Widget _buildError(BuildContext context, Object err) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(l.errorLoading(err.toString())),
        ],
      ),
    );
  }
}

class _ActorDetailBody extends ConsumerStatefulWidget {
  const _ActorDetailBody({required this.actor, required this.person});

  final Actor actor;
  final PersonDetail person;

  @override
  ConsumerState<_ActorDetailBody> createState() => _ActorDetailBodyState();
}

class _ActorDetailBodyState extends ConsumerState<_ActorDetailBody> {
  final _pageScroll = ScrollController();
  final _creditsScroll = ScrollController();
  final _detailsFocus = FocusNode();
  late List<FocusNode> _creditFocus;

  List<MovieCredit> get _credits => widget.person.credits.isNotEmpty
      ? widget.person.credits
      : widget.person.movieCredits.isNotEmpty
          ? widget.person.movieCredits
          : widget.person.knownFor;

  @override
  void initState() {
    super.initState();
    _creditFocus = List.generate(_credits.length, (_) => FocusNode());
  }

  @override
  void didUpdateWidget(covariant _ActorDetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.person != widget.person) {
      for (final node in _creditFocus) {
        node.dispose();
      }
      _creditFocus = List.generate(_credits.length, (_) => FocusNode());
    }
  }

  @override
  void dispose() {
    _pageScroll.dispose();
    _creditsScroll.dispose();
    _detailsFocus.dispose();
    for (final node in _creditFocus) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _focusCredit(int index) async {
    if (index < 0 || index >= _creditFocus.length) return;
    final focus = _creditFocus[index];
    await _creditsScroll.animateTo(
      (index * 142.0).clamp(0, _creditsScroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
    if (!mounted ||
        index >= _creditFocus.length ||
        _creditFocus[index] != focus) return;
    final target = focus.context;
    if (target != null && target.mounted) {
      await Scrollable.ensureVisible(target,
          duration: const Duration(milliseconds: 180));
      if (mounted &&
          index < _creditFocus.length &&
          _creditFocus[index] == focus) focus.requestFocus();
    }
  }

  void _scrollDetails(bool down) {
    final position = _pageScroll.position;
    if (down &&
        position.pixels >= position.maxScrollExtent &&
        _credits.isNotEmpty) {
      _focusCredit(0);
      return;
    }
    _pageScroll.animateTo(
      (position.pixels + (down ? 220 : -220))
          .clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final actor = widget.actor;
    final person = widget.person;
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final infoParts = <String>[
      if (person.birthday.isNotEmpty)
        'Né(e) le ${_formatBirthDate(person.birthday)}',
      if (person.placeOfBirth.isNotEmpty) person.placeOfBirth,
      if (person.genderLabel.isNotEmpty) person.genderLabel,
    ];
    final info = infoParts.join('  •  ');

    return Focus(
      autofocus: _credits.isEmpty,
      onKeyEvent: (node, event) {
        if (node.hasPrimaryFocus &&
            (event is KeyDownEvent || event is KeyRepeatEvent) &&
            (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                event.logicalKey == LogicalKeyboardKey.arrowUp)) {
          _scrollDetails(event.logicalKey == LogicalKeyboardKey.arrowDown);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: SingleChildScrollView(
        controller: _pageScroll,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_credits.isNotEmpty) ...[
              Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onKeyEvent: (_, event) {
                  if (event is KeyDownEvent || event is KeyRepeatEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                        event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      _scrollDetails(
                          event.logicalKey == LogicalKeyboardKey.arrowDown);
                      return KeyEventResult.handled;
                    }
                  }
                  return KeyEventResult.ignored;
                },
                child: OutlinedButton.icon(
                  autofocus: true,
                  focusNode: _detailsFocus,
                  onPressed: () => _focusCredit(0),
                  icon: const Icon(Icons.movie_outlined),
                  label: Text(l.actorShowFilmography),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 140,
                    height: 210,
                    child: person.profileUrl.isNotEmpty
                        ? OrbitCachedImage(
                            imageUrl: person.profileUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Icon(Icons.person_outline,
                                color: scheme.primary),
                            errorWidget: (_, __, ___) => Icon(
                                Icons.person_outline,
                                color: scheme.primary),
                          )
                        : Icon(Icons.person_outline, color: scheme.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.name,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (actor.character.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          actor.character,
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (person.knownForDepartment.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          person.knownForDepartment,
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (info.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.cake_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                info,
                                style: textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (person.alsoKnownAs.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.badge_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                person.alsoKnownAs.take(3).join(', '),
                                style: textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (person.biography.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Biographie',
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                person.biography,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
            if (_credits.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Filmographie',
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 280,
                child: ListView.separated(
                  controller: _creditsScroll,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: _credits.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final credit = _credits[index];
                    return Focus(
                      canRequestFocus: false,
                      skipTraversal: true,
                      onKeyEvent: (_, event) {
                        if (event is KeyDownEvent || event is KeyRepeatEvent) {
                          final isRtl =
                              Directionality.of(context) == TextDirection.rtl;
                          if (event.logicalKey ==
                              LogicalKeyboardKey.arrowRight) {
                            _focusCredit(index + (isRtl ? -1 : 1));
                            return KeyEventResult.handled;
                          }
                          if (event.logicalKey ==
                              LogicalKeyboardKey.arrowLeft) {
                            _focusCredit(index + (isRtl ? 1 : -1));
                            return KeyEventResult.handled;
                          }
                          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                            final target = _detailsFocus.context;
                            if (target != null) {
                              Scrollable.ensureVisible(target);
                              _detailsFocus.requestFocus();
                            }
                            return KeyEventResult.handled;
                          }
                        }
                        return KeyEventResult.ignored;
                      },
                      child: _FilmographyCard(
                        credit: credit,
                        focusNode: _creditFocus[index],
                        onTap: () => _openMovie(context, credit),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              const SizedBox(height: 24),
              Text(l.actorFilmographyUnavailable),
            ],
          ],
        ),
      ),
    );
  }

  void _openMovie(BuildContext context, MovieCredit credit) {
    showDialog<void>(
      context: context,
      builder: (_) => _FilmographyDetails(credit: credit),
    );
  }

  static String _formatBirthDate(String date) {
    final parts = date.split('-');
    if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    return date;
  }
}

class _FilmographyDetails extends ConsumerStatefulWidget {
  const _FilmographyDetails({required this.credit});

  final MovieCredit credit;

  @override
  ConsumerState<_FilmographyDetails> createState() =>
      _FilmographyDetailsState();
}

class _FilmographyDetailsState extends ConsumerState<_FilmographyDetails> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final credit = widget.credit;
    final l = AppLocalizations.of(context);
    final detail = credit.tmdbId > 0
        ? ref.watch(tmdbFilmographySynopsisProvider(credit))
        : const AsyncData(null);
    final movies = credit.isTv ? null : ref.watch(moviesProvider);
    final series = credit.isTv ? ref.watch(seriesProvider) : null;
    final movieMatches = movies?.value
        ?.where((movie) =>
            movie.title.trim().toLowerCase() ==
                credit.title.trim().toLowerCase() &&
            credit.year > 0 &&
            movie.year == credit.year)
        .toList();
    final seriesMatches = series?.value
        ?.where((series) =>
            series.title.trim().toLowerCase() ==
                credit.title.trim().toLowerCase() &&
            credit.year > 0 &&
            series.year == credit.year)
        .toList();
    final loadingCatalog =
        movies?.isLoading == true || series?.isLoading == true;
    final catalogError = movies?.error ?? series?.error;
    final found = movieMatches?.length == 1 || seriesMatches?.length == 1;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, event) {
        if ((event is KeyDownEvent || event is KeyRepeatEvent) &&
            (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                event.logicalKey == LogicalKeyboardKey.arrowUp) &&
            _scroll.hasClients &&
            _scroll.position.maxScrollExtent > 0) {
          final position = _scroll.position;
          _scroll.animateTo(
            (position.pixels +
                    (event.logicalKey == LogicalKeyboardKey.arrowDown
                        ? 180
                        : -180))
                .clamp(position.minScrollExtent, position.maxScrollExtent),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          );
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AlertDialog(
        title: Text(credit.title),
        content: SingleChildScrollView(
          controller: _scroll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (credit.year > 0) Text('${credit.year}'),
              Text(credit.isTv ? l.actorCreditSeries : l.actorCreditFilm),
              if (credit.character.isNotEmpty)
                Text(l.actorCreditRole(credit.character)),
              if (credit.voteAverage > 0)
                Text('★ ${credit.voteAverage.toStringAsFixed(1)}'),
              const SizedBox(height: 12),
              detail.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text(l.errorLoading(error.toString())),
                data: (synopsis) => synopsis == null
                    ? Text(l.actorCreditTmdbUnavailable)
                    : Text(synopsis.isEmpty
                        ? l.actorCreditSynopsisUnavailable
                        : synopsis),
              ),
              const SizedBox(height: 12),
              if (loadingCatalog)
                const CircularProgressIndicator()
              else if (catalogError != null)
                Text(l.errorLoading(catalogError.toString()))
              else if (!found)
                Text(l.actorCreditCatalogUnconfirmed),
            ],
          ),
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.close),
          ),
          if (found)
            FilledButton(
              onPressed: () {
                final router = GoRouter.of(context);
                Navigator.of(context).pop();
                if (credit.isTv) {
                  final match = seriesMatches!.single;
                  router.push(
                      '/series/detail?id=${Uri.encodeComponent(match.id)}',
                      extra: match);
                } else {
                  router.push('/vod/detail', extra: movieMatches!.single);
                }
              },
              child: Text(l.actorCreditOpenCatalog),
            ),
        ],
      ),
    );
  }
}

class _FilmographyCard extends StatelessWidget {
  const _FilmographyCard({
    required this.credit,
    required this.focusNode,
    required this.onTap,
  });

  final MovieCredit credit;
  final FocusNode focusNode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TvFocus(
      focusNode: focusNode,
      onActivate: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 130,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: credit.posterUrl.isNotEmpty
                    ? OrbitCachedImage(
                        imageUrl: credit.posterUrl,
                        width: 130,
                        height: 195,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _placeholder(scheme),
                        errorWidget: (_, __, ___) => _placeholder(scheme),
                      )
                    : _placeholder(scheme),
              ),
              const SizedBox(height: 8),
              Text(
                credit.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.star, size: 12, color: Colors.amber),
                  const SizedBox(width: 3),
                  Text(
                    credit.voteAverage > 0
                        ? credit.voteAverage.toStringAsFixed(1)
                        : '—',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (credit.year > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${credit.year}',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme) => Container(
        width: 130,
        height: 195,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.movie_outlined, color: scheme.primary, size: 44),
      );
}

class _ActorUnavailable extends StatelessWidget {
  const _ActorUnavailable();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_search, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Acteur non disponible',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'La fiche de cet acteur est introuvable sur TMDB',
            style:
                textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
