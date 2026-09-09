import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

const Color _favoriteActive = Color(0xFFFF5252);

/// Cœur favori permanent et réactif (à la concurrence).
///
/// Lecture : [favoritesProvider] (état réactif partagé). Écriture :
/// toggle via le notifier (Hive + état synchronisés).
class FavoriteToggle extends ConsumerWidget {
  const FavoriteToggle({
    super.key,
    required this.entry,
    this.showMessage = true,
    this.overlay = false,
  });

  /// [overlay] = variante en fondu sur un poster (cartes MediaCard) :
  /// rond translucide lisible sur n'importe quelle image.
  /// Sinon : IconButton classique (trailing de ligne / liste).
  const FavoriteToggle.overlay({super.key, required this.entry})
      : showMessage = true,
        overlay = true;

  final FavoriteEntry entry;
  final bool showMessage;
  final bool overlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final profile = ref.watch(currentProfileProvider);
    final isFavorite =
        favorites.containsKey(_canonicalKey(entry, profile?.id));

    Future<void> onToggle() async {
      final wasFavorite = isFavorite;
      await ref.read(favoritesProvider.notifier).toggle(entry);
      if (!showMessage || !context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              wasFavorite
                  ? '« ${entry.title} » retiré des favoris'
                  : '« ${entry.title} » ajouté aux favoris',
            ),
            duration: const Duration(milliseconds: 1200),
          ),
        );
    }

    if (overlay) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          tooltip: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            size: 22,
            color: isFavorite ? _favoriteActive : Colors.white,
          ),
          onPressed: onToggle,
        ),
      );
    }

    return IconButton(
      tooltip: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? _favoriteActive : null,
      ),
      onPressed: onToggle,
    );
  }

  /// Clé canonique alignée sur [FavoritesNotifier] : les entrées construites à
  /// la volée (écrans détail/cartes) n'ont pas de `profileId` ; on résout le
  /// profil courant pour retrouver la clé persistée `"<profileId>:<type>:<id>"`.
  String _canonicalKey(FavoriteEntry favorite, String? profileId) {
    if (profileId == null || profileId.isEmpty) return favorite.key;
    return '$profileId:${favorite.type.name}:${favorite.id}';
  }
}
