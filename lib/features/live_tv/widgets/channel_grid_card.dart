import 'package:flutter/material.dart';

import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/features/favorites/widgets/favorite_toggle.dart';

/// Delegate de la grille de chaînes, partagé par tous les écrans qui en
/// affichent une (Live TV, Replay).
///
/// C'est le MÊME objet présenté deux fois, donc la tuile doit être la même.
/// Le Replay avait son propre delegate (260 / 0,42) contre 200 / 0,55 en Live
/// TV : les deux écrans ne se ressemblaient pas, et l'utilisateur ne retrouvait
/// pas ses repères en passant de l'un à l'autre. Un delegate dupliqué avait
/// dérivé ; ici il n'existe qu'en un point.
const channelGridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 200,
  childAspectRatio: 0.55,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
);

/// Marge de grille commune aux écrans de chaînes.
const channelGridPadding = EdgeInsets.all(16);

/// Tuile de chaîne, partagée par le Live TV et le Replay.
///
/// Reprend exactement les réglages du Live TV — logo en `contain` avec marge
/// (un wordmark rogné en `cover` débordait), numéro de chaîne, cœur favori —
/// pour que les deux écrans affichent la même chose. Le Replay n'ajoute qu'une
/// ligne de méta ([meta]) qui porte le nombre de programmes rejouables.
class ChannelGridCard extends StatelessWidget {
  const ChannelGridCard({
    super.key,
    required this.name,
    required this.logoUrl,
    required this.onTap,
    this.onFocus,
    this.meta = '',
    this.badgeNumber = 0,
    this.favoriteEntry,
    this.autofocus = false,
  });

  /// Nom de chaîne, tel que le panel le publie.
  final String name;

  final String logoUrl;

  final VoidCallback onTap;

  /// Appelé quand la tuile reçoit le focus : sert à précharger le flux.
  final VoidCallback? onFocus;

  /// Ligne de méta sous le nom. Vide = pas de ligne, comme en Live TV.
  final String meta;

  /// Numéro de chaîne affiché en pastille. `0` = aucune pastille.
  final int badgeNumber;

  /// Cœur favori. `null` si la chaîne est inconnue du catalogue live, auquel
  /// cas aucun favori ne peut être proposé.
  final FavoriteEntry? favoriteEntry;

  /// Se positionne automatiquement au focus au chargement (première tuile).
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TvFocus(
      autofocus: autofocus,
      onActivate: onTap,
      onFocusChange: (focused) {
        if (focused) onFocus?.call();
      },
      child: MediaCard(
        title: name,
        posterUrl: logoUrl,
        year: 0,
        genre: meta,
        rating: 0,
        ageLabel: null,
        fallbackIcon: Icons.live_tv,
        // Un logo de chaîne est un wordmark large : `contain` + marge évite le
        // zoom/rognage de `cover`, qui le faisait déborder de la tuile.
        posterFit: BoxFit.contain,
        posterPadding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
        onTap: onTap,
        topBadge: badgeNumber > 0
            ? ChannelNumBadge(number: badgeNumber)
            : null,
        favoriteOverlay: favoriteEntry == null
            ? null
            : FavoriteToggle.overlay(entry: favoriteEntry!),
      ),
    );
  }
}

/// Pastille du numéro de chaîne, en haut à gauche de la tuile.
class ChannelNumBadge extends StatelessWidget {
  const ChannelNumBadge({super.key, required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$number',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
