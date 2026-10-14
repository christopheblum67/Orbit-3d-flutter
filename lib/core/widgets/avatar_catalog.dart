import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Catalogue des avatars proposés pour Orbit 3D.
///
/// 72 avatars (9 styles DiceBear × 8 variantes) répartis en 4 catégories,
/// servis par l'API d'avatars gratuite DiceBear (v10) — aucune binaire
/// embarquée, images chargées en cache via `CachedNetworkImage` dans
/// `AvatarPickerGrid`.
///
/// `category` stocke un identifiant stable (`characters`, `smileys`,
/// `blackWhite`, `pixels`) : le libellé affiché est résolu par
/// [avatarCategoryLabel] afin de rester traduisible (6 locales).
///
/// Les styles *-neutral* de la catégorie « Noir & Blanc » dessinent déjà une
/// encre noire (#000000) sur un fond blanc (#FFFFFF) fourni nativement par
/// DiceBear : aucune option `backgroundColor` n'est donc appliquée, ce qui
/// garantit un vrai noir & blanc (et non un gris délavé).
class AvatarItem {
  final String id;
  final String name;
  final String category;
  final String imageUrl;

  const AvatarItem({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
  });
}

/// Base de l'API DiceBear. Les styles `marbles`, `voxel-art` et `voxel-bot`
/// n'existent qu'à partir de la version 10 de l'API.
const String _diceBearBase = 'https://api.dicebear.com/10.x';

/// Identifiants de catégories, dans l'ordre d'affichage. `all` est la
/// pseudo-catégorie « tout afficher ».
const List<String> avatarCategoryIds = [
  'all',
  'characters',
  'smileys',
  'blackWhite',
  'pixels',
];

/// Libellé localisé d'une catégorie d'avatars.
String avatarCategoryLabel(AppLocalizations l, String id) {
  switch (id) {
    case 'all':
      return l.avatarCategoryAll;
    case 'characters':
      return l.avatarCategoryCharacters;
    case 'smileys':
      return l.avatarCategorySmileys;
    case 'blackWhite':
      return l.avatarCategoryBlackWhite;
    case 'pixels':
      return l.avatarCategoryPixels;
    default:
      return id;
  }
}

const List<AvatarItem> orbit3DAvatars = [
  // --- Catégorie 1 : Personnages (3 styles x 8 = 24) ---
  // Avataaars
  AvatarItem(
    id: 'av1',
    name: 'Léa',
    category: 'characters',
    imageUrl: '$_diceBearBase/avataaars/png?seed=Lea',
  ),
  AvatarItem(
    id: 'av2',
    name: 'Noah',
    category: 'characters',
    imageUrl: '$_diceBearBase/avataaars/png?seed=Noah',
  ),
  AvatarItem(
    id: 'av3',
    name: 'Jade',
    category: 'characters',
    imageUrl: '$_diceBearBase/avataaars/png?seed=Jade',
  ),
  AvatarItem(
    id: 'av4',
    name: 'Lucas',
    category: 'characters',
    imageUrl: '$_diceBearBase/avataaars/png?seed=Lucas',
  ),
  AvatarItem(
    id: 'av5',
    name: 'Emma',
    category: 'characters',
    imageUrl: '$_diceBearBase/avataaars/png?seed=Emma',
  ),
  AvatarItem(
    id: 'av6',
    name: 'Hugo',
    category: 'characters',
    imageUrl: '$_diceBearBase/avataaars/png?seed=Hugo',
  ),
  AvatarItem(
    id: 'av7',
    name: 'Mila',
    category: 'characters',
    imageUrl: '$_diceBearBase/avataaars/png?seed=Mila',
  ),
  AvatarItem(
    id: 'av8',
    name: 'Louis',
    category: 'characters',
    imageUrl: '$_diceBearBase/avataaars/png?seed=Louis',
  ),
  // Adventurer
  AvatarItem(
    id: 'ad1',
    name: 'Nova',
    category: 'characters',
    imageUrl: '$_diceBearBase/adventurer/png?seed=Nova',
  ),
  AvatarItem(
    id: 'ad2',
    name: 'Milo',
    category: 'characters',
    imageUrl: '$_diceBearBase/adventurer/png?seed=Milo',
  ),
  AvatarItem(
    id: 'ad3',
    name: 'Zara',
    category: 'characters',
    imageUrl: '$_diceBearBase/adventurer/png?seed=Zara',
  ),
  AvatarItem(
    id: 'ad4',
    name: 'Tom',
    category: 'characters',
    imageUrl: '$_diceBearBase/adventurer/png?seed=Tom',
  ),
  AvatarItem(
    id: 'ad5',
    name: 'Anya',
    category: 'characters',
    imageUrl: '$_diceBearBase/adventurer/png?seed=Anya',
  ),
  AvatarItem(
    id: 'ad6',
    name: 'Kai',
    category: 'characters',
    imageUrl: '$_diceBearBase/adventurer/png?seed=Kai',
  ),
  AvatarItem(
    id: 'ad7',
    name: 'Iris',
    category: 'characters',
    imageUrl: '$_diceBearBase/adventurer/png?seed=Iris',
  ),
  AvatarItem(
    id: 'ad8',
    name: 'Max',
    category: 'characters',
    imageUrl: '$_diceBearBase/adventurer/png?seed=Max',
  ),
  // Micah
  AvatarItem(
    id: 'mi1',
    name: 'Aria',
    category: 'characters',
    imageUrl: '$_diceBearBase/micah/png?seed=Aria',
  ),
  AvatarItem(
    id: 'mi2',
    name: 'Nino',
    category: 'characters',
    imageUrl: '$_diceBearBase/micah/png?seed=Nino',
  ),
  AvatarItem(
    id: 'mi3',
    name: 'Salma',
    category: 'characters',
    imageUrl: '$_diceBearBase/micah/png?seed=Salma',
  ),
  AvatarItem(
    id: 'mi4',
    name: 'Liv',
    category: 'characters',
    imageUrl: '$_diceBearBase/micah/png?seed=Liv',
  ),
  AvatarItem(
    id: 'mi5',
    name: 'Idris',
    category: 'characters',
    imageUrl: '$_diceBearBase/micah/png?seed=Idris',
  ),
  AvatarItem(
    id: 'mi6',
    name: 'Maé',
    category: 'characters',
    imageUrl: '$_diceBearBase/micah/png?seed=Mae',
  ),
  AvatarItem(
    id: 'mi7',
    name: 'Yuna',
    category: 'characters',
    imageUrl: '$_diceBearBase/micah/png?seed=Yuna',
  ),
  AvatarItem(
    id: 'mi8',
    name: 'Enzo',
    category: 'characters',
    imageUrl: '$_diceBearBase/micah/png?seed=Enzo',
  ),

  // --- Catégorie 2 : Smileys (2 styles x 8 = 16) ---
  // Marbles
  AvatarItem(
    id: 'mb1',
    name: 'Bulles',
    category: 'smileys',
    imageUrl: '$_diceBearBase/marbles/png?seed=Bubble',
  ),
  AvatarItem(
    id: 'mb2',
    name: 'Crépuscule',
    category: 'smileys',
    imageUrl: '$_diceBearBase/marbles/png?seed=Dusk',
  ),
  AvatarItem(
    id: 'mb3',
    name: 'Corail',
    category: 'smileys',
    imageUrl: '$_diceBearBase/marbles/png?seed=Coral',
  ),
  AvatarItem(
    id: 'mb4',
    name: 'Menthe',
    category: 'smileys',
    imageUrl: '$_diceBearBase/marbles/png?seed=Mint',
  ),
  AvatarItem(
    id: 'mb5',
    name: 'Orbite',
    category: 'smileys',
    imageUrl: '$_diceBearBase/marbles/png?seed=Orbit',
  ),
  AvatarItem(
    id: 'mb6',
    name: 'Vapeur',
    category: 'smileys',
    imageUrl: '$_diceBearBase/marbles/png?seed=Vapor',
  ),
  AvatarItem(
    id: 'mb7',
    name: 'Couchant',
    category: 'smileys',
    imageUrl: '$_diceBearBase/marbles/png?seed=Sunset',
  ),
  AvatarItem(
    id: 'mb8',
    name: 'Aurore',
    category: 'smileys',
    imageUrl: '$_diceBearBase/marbles/png?seed=Aurora',
  ),
  // Fun Emoji
  AvatarItem(
    id: 'fe1',
    name: 'Joyeux',
    category: 'smileys',
    imageUrl: '$_diceBearBase/fun-emoji/png?seed=Happy',
  ),
  AvatarItem(
    id: 'fe2',
    name: 'Cool',
    category: 'smileys',
    imageUrl: '$_diceBearBase/fun-emoji/png?seed=Cool',
  ),
  AvatarItem(
    id: 'fe3',
    name: 'Clin d\'œil',
    category: 'smileys',
    imageUrl: '$_diceBearBase/fun-emoji/png?seed=Wink',
  ),
  AvatarItem(
    id: 'fe4',
    name: 'Amoureux',
    category: 'smileys',
    imageUrl: '$_diceBearBase/fun-emoji/png?seed=Love',
  ),
  AvatarItem(
    id: 'fe5',
    name: 'Étoilé',
    category: 'smileys',
    imageUrl: '$_diceBearBase/fun-emoji/png?seed=Star',
  ),
  AvatarItem(
    id: 'fe6',
    name: 'Enflammé',
    category: 'smileys',
    imageUrl: '$_diceBearBase/fun-emoji/png?seed=Fire',
  ),
  AvatarItem(
    id: 'fe7',
    name: 'Détendu',
    category: 'smileys',
    imageUrl: '$_diceBearBase/fun-emoji/png?seed=Chill',
  ),
  AvatarItem(
    id: 'fe8',
    name: 'Éclair',
    category: 'smileys',
    imageUrl: '$_diceBearBase/fun-emoji/png?seed=Zap',
  ),

  // --- Catégorie 3 : Noir & Blanc (2 styles x 8 = 16) ---
  // Lorelei (neutral) — encre noire sur blanc natif
  AvatarItem(
    id: 'ln1',
    name: 'Encre',
    category: 'blackWhite',
    imageUrl: '$_diceBearBase/lorelei-neutral/png?seed=Ink',
  ),
  AvatarItem(
    id: 'ln2',
    name: 'Croquis',
    category: 'blackWhite',
    imageUrl: '$_diceBearBase/lorelei-neutral/png?seed=Sketch',
  ),
  AvatarItem(
    id: 'ln3',
    name: 'Monochrome',
    category: 'blackWhite',
    imageUrl: '$_diceBearBase/lorelei-neutral/png?seed=Mono',
  ),
  AvatarItem(
    id: 'ln4',
    name: 'Crayon',
    category: 'blackWhite',
    imageUrl: '$_diceBearBase/lorelei-neutral/png?seed=Pencil',
  ),
  AvatarItem(
    id: 'ln5',
    name: 'Graphite',
    category: 'blackWhite',
    imageUrl: '$_diceBearBase/lorelei-neutral/png?seed=Graphite',
  ),
  AvatarItem(
    id: 'ln6',
    name: 'Fusain',
    category: 'blackWhite',
    imageUrl: '$_diceBearBase/lorelei-neutral/png?seed=Charcoal',
  ),
  AvatarItem(
    id: 'ln7',
    name: 'Ligne',
    category: 'blackWhite',
    imageUrl: '$_diceBearBase/lorelei-neutral/png?seed=Line',
  ),
  AvatarItem(
    id: 'ln8',
    name: 'Plume',
    category: 'blackWhite',
    imageUrl: '$_diceBearBase/lorelei-neutral/png?seed=Quill',
  ),
  // Notionists (neutral) — encre noire sur blanc natif
  AvatarItem(
    id: 'nn1',
    name: 'Nota',
    category: 'blackWhite',
    imageUrl: '$_diceBearBase/notionists-neutral/png?seed=Nota',
  ),
  AvatarItem(
    id: 'nn2',
    name: 'Idée',
    category: 'blackWhite',
    imageUrl: '$_diceBearBase/notionists-neutral/png?seed=Idee',
  ),
  AvatarItem(
    id: 'nn3',
    name: 'Trait',
    category: 'blackWhite',
    imageUrl: '$_diceBearBase/notionists-neutral/png?seed=Trait',
  ),
  AvatarItem(
    id: 'nn4',
    name: 'Note',
    category: 'blackWhite',
    imageUrl: '$_diceBearBase/notionists-neutral/png?seed=Note',
  ),
  AvatarItem(
    id: 'nn5',
    name: 'Schéma',
    category: 'blackWhite',
    imageUrl: '$_diceBearBase/notionists-neutral/png?seed=Schema',
  ),
  AvatarItem(
    id: 'nn6',
    name: 'Plan',
    category: 'blackWhite',
    imageUrl: '$_diceBearBase/notionists-neutral/png?seed=Plan',
  ),
  AvatarItem(
    id: 'nn7',
    name: 'Épure',
    category: 'blackWhite',
    imageUrl: '$_diceBearBase/notionists-neutral/png?seed=Epure',
  ),
  AvatarItem(
    id: 'nn8',
    name: 'Brouillon',
    category: 'blackWhite',
    imageUrl: '$_diceBearBase/notionists-neutral/png?seed=Draft',
  ),

  // --- Catégorie 4 : Pixels (2 styles x 8 = 16) ---
  // Voxel Art
  AvatarItem(
    id: 'va1',
    name: 'Cube',
    category: 'pixels',
    imageUrl: '$_diceBearBase/voxel-art/png?seed=Cube',
  ),
  AvatarItem(
    id: 'va2',
    name: 'Prisme',
    category: 'pixels',
    imageUrl: '$_diceBearBase/voxel-art/png?seed=Prism',
  ),
  AvatarItem(
    id: 'va3',
    name: 'Pixel',
    category: 'pixels',
    imageUrl: '$_diceBearBase/voxel-art/png?seed=Pixel',
  ),
  AvatarItem(
    id: 'va4',
    name: 'Isométrie',
    category: 'pixels',
    imageUrl: '$_diceBearBase/voxel-art/png?seed=Isometric',
  ),
  AvatarItem(
    id: 'va5',
    name: 'Volume',
    category: 'pixels',
    imageUrl: '$_diceBearBase/voxel-art/png?seed=Voxel',
  ),
  AvatarItem(
    id: 'va6',
    name: 'Grille',
    category: 'pixels',
    imageUrl: '$_diceBearBase/voxel-art/png?seed=Grid',
  ),
  AvatarItem(
    id: 'va7',
    name: 'Bloc',
    category: 'pixels',
    imageUrl: '$_diceBearBase/voxel-art/png?seed=Block',
  ),
  AvatarItem(
    id: 'va8',
    name: 'Rendu',
    category: 'pixels',
    imageUrl: '$_diceBearBase/voxel-art/png?seed=Render',
  ),
  // Voxel Bot
  AvatarItem(
    id: 'vb1',
    name: 'Mécano',
    category: 'pixels',
    imageUrl: '$_diceBearBase/voxel-bot/png?seed=Mech',
  ),
  AvatarItem(
    id: 'vb2',
    name: 'Circuit',
    category: 'pixels',
    imageUrl: '$_diceBearBase/voxel-bot/png?seed=Circuit',
  ),
  AvatarItem(
    id: 'vb3',
    name: 'Puce',
    category: 'pixels',
    imageUrl: '$_diceBearBase/voxel-bot/png?seed=Chiptune',
  ),
  AvatarItem(
    id: 'vb4',
    name: 'Rétro',
    category: 'pixels',
    imageUrl: '$_diceBearBase/voxel-bot/png?seed=Retro',
  ),
  AvatarItem(
    id: 'vb5',
    name: 'Bit',
    category: 'pixels',
    imageUrl: '$_diceBearBase/voxel-bot/png?seed=Bit',
  ),
  AvatarItem(
    id: 'vb6',
    name: 'Servo',
    category: 'pixels',
    imageUrl: '$_diceBearBase/voxel-bot/png?seed=Servo',
  ),
  AvatarItem(
    id: 'vb7',
    name: 'Droïde',
    category: 'pixels',
    imageUrl: '$_diceBearBase/voxel-bot/png?seed=Android',
  ),
  AvatarItem(
    id: 'vb8',
    name: 'Néon',
    category: 'pixels',
    imageUrl: '$_diceBearBase/voxel-bot/png?seed=Neon',
  ),
];
