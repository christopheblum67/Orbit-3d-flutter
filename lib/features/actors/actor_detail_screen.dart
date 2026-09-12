import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/widgets/orbit_cached_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/models/cast.dart';
import 'package:orbit_3d_flutter/models/movie.dart';
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
        error: (err, _) => _buildError(err),
      );
    }
    return searchAsync!.when(
      data: (id) => id > 0
          ? ref.watch(tmdbPersonDetailProvider(id)).when(
                data: (person) => person != null
                    ? _ActorDetailBody(actor: actor, person: person)
                    : const _ActorUnavailable(),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => _buildError(err),
              )
          : const _ActorUnavailable(),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _buildError(err),
    );
  }

  Widget _buildError(Object err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Erreur de chargement: $err'),
        ],
      ),
    );
  }
}

class _ActorDetailBody extends ConsumerWidget {
  const _ActorDetailBody({required this.actor, required this.person});

  final Actor actor;
  final PersonDetail person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final infoParts = <String>[
      if (person.birthday.isNotEmpty)
        'Né(e) le ${_formatBirthDate(person.birthday)}',
      if (person.placeOfBirth.isNotEmpty) person.placeOfBirth,
      if (person.genderLabel.isNotEmpty) person.genderLabel,
    ];
    final info = infoParts.join('  •  ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                          placeholder: (_, __) =>
                              Icon(Icons.person_outline, color: scheme.primary),
                          errorWidget: (_, __, ___) =>
                              Icon(Icons.person_outline, color: scheme.primary),
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
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
          if (person.knownFor.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Filmographie',
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: person.knownFor.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final credit = person.knownFor[index];
                  return _FilmographyCard(
                    credit: credit,
                    onTap: () => _openMovie(context, ref, credit),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openMovie(BuildContext context, WidgetRef ref, MovieCredit credit) {
    if (credit.tmdbId <= 0) return;
    final normalized = credit.title.trim().toLowerCase();
    final movies = ref.read(moviesProvider).value ?? const <Movie>[];
    Movie? match;
    for (final m in movies) {
      if (m.title.trim().toLowerCase() == normalized) {
        match = m;
        break;
      }
    }
    if (match != null) {
      context.push('/vod/detail', extra: match);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Non disponible dans le catalogue')),
    );
  }

  static String _formatBirthDate(String date) {
    final parts = date.split('-');
    if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    return date;
  }
}

class _FilmographyCard extends StatelessWidget {
  const _FilmographyCard({required this.credit, required this.onTap});

  final MovieCredit credit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
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
