import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

/// Catalogue des avatars proposés pour Orbit 3D.
///
/// 72 avatars issus de la maquette de profils, embarqués localement dans
/// `assets/images/avatars/` (aucun accès réseau) et répartis en 4 catégories :
/// personnages, super-héros, animaux et fleurs.
///
/// La valeur stockée dans `UserProfile.avatarUrl` est `asset:<chemin>` ;
/// `ProfileAvatar` sait l'afficher. Les anciennes valeurs (URL DiceBear, icônes
/// `icone:<id>`) restent affichées telles quelles.
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

  bool get isLocalAsset => imageUrl.startsWith(avatarAssetPrefix);
}

/// Préfixe des avatars embarqués dans `UserProfile.avatarUrl`.
const String avatarAssetPrefix = 'asset:';

const String _avatarDir = 'assets/images/avatars';

/// Identifiants de catégories, dans l'ordre d'affichage. `all` est la
/// pseudo-catégorie « tout afficher ».
const List<String> avatarCategoryIds = [
  'all',
  'characters',
  'superheroes',
  'animals',
  'flowers',
];

/// Libellé localisé d'une catégorie d'avatars.
String avatarCategoryLabel(AppLocalizations l, String id) {
  switch (id) {
    case 'all':
      return l.avatarCategoryAll;
    case 'characters':
      return l.avatarCategoryCharacters;
    case 'superheroes':
      return l.avatarCategorySuperheroes;
    case 'animals':
      return l.avatarCategoryAnimals;
    case 'flowers':
      return l.avatarCategoryFlowers;
    default:
      return id;
  }
}

const List<AvatarItem> orbit3DAvatars = [
  // --- characters (12) ---
  AvatarItem(
    id: 'ch01',
    name: 'Astronaute',
    category: 'characters',
    imageUrl: '$avatarAssetPrefix$_avatarDir/ch01.png',
  ),
  AvatarItem(
    id: 'ch02',
    name: 'Réalité virtuelle',
    category: 'characters',
    imageUrl: '$avatarAssetPrefix$_avatarDir/ch02.png',
  ),
  AvatarItem(
    id: 'ch03',
    name: 'DJ',
    category: 'characters',
    imageUrl: '$avatarAssetPrefix$_avatarDir/ch03.png',
  ),
  AvatarItem(
    id: 'ch04',
    name: 'Lunettes',
    category: 'characters',
    imageUrl: '$avatarAssetPrefix$_avatarDir/ch04.png',
  ),
  AvatarItem(
    id: 'ch05',
    name: 'Rousse',
    category: 'characters',
    imageUrl: '$avatarAssetPrefix$_avatarDir/ch05.png',
  ),
  AvatarItem(
    id: 'ch06',
    name: 'Barbu',
    category: 'characters',
    imageUrl: '$avatarAssetPrefix$_avatarDir/ch06.png',
  ),
  AvatarItem(
    id: 'ch07',
    name: 'Look moderne',
    category: 'characters',
    imageUrl: '$avatarAssetPrefix$_avatarDir/ch07.png',
  ),
  AvatarItem(
    id: 'ch08',
    name: 'Cheveux colorés',
    category: 'characters',
    imageUrl: '$avatarAssetPrefix$_avatarDir/ch08.png',
  ),
  AvatarItem(
    id: 'ch09',
    name: 'Chef',
    category: 'characters',
    imageUrl: '$avatarAssetPrefix$_avatarDir/ch09.png',
  ),
  AvatarItem(
    id: 'ch10',
    name: 'Serveuse',
    category: 'characters',
    imageUrl: '$avatarAssetPrefix$_avatarDir/ch10.png',
  ),
  AvatarItem(
    id: 'ch11',
    name: 'Costume',
    category: 'characters',
    imageUrl: '$avatarAssetPrefix$_avatarDir/ch11.png',
  ),
  AvatarItem(
    id: 'ch12',
    name: 'Business',
    category: 'characters',
    imageUrl: '$avatarAssetPrefix$_avatarDir/ch12.png',
  ),
  // --- superheroes (12) ---
  AvatarItem(
    id: 'sh01',
    name: 'Néon',
    category: 'superheroes',
    imageUrl: '$avatarAssetPrefix$_avatarDir/sh01.png',
  ),
  AvatarItem(
    id: 'sh02',
    name: 'Spartiate',
    category: 'superheroes',
    imageUrl: '$avatarAssetPrefix$_avatarDir/sh02.png',
  ),
  AvatarItem(
    id: 'sh03',
    name: 'Énergie',
    category: 'superheroes',
    imageUrl: '$avatarAssetPrefix$_avatarDir/sh03.png',
  ),
  AvatarItem(
    id: 'sh04',
    name: 'Armure dorée',
    category: 'superheroes',
    imageUrl: '$avatarAssetPrefix$_avatarDir/sh04.png',
  ),
  AvatarItem(
    id: 'sh05',
    name: 'Sentinelle',
    category: 'superheroes',
    imageUrl: '$avatarAssetPrefix$_avatarDir/sh05.png',
  ),
  AvatarItem(
    id: 'sh06',
    name: 'Masque tech',
    category: 'superheroes',
    imageUrl: '$avatarAssetPrefix$_avatarDir/sh06.png',
  ),
  AvatarItem(
    id: 'sh07',
    name: 'Cosmique',
    category: 'superheroes',
    imageUrl: '$avatarAssetPrefix$_avatarDir/sh07.png',
  ),
  AvatarItem(
    id: 'sh08',
    name: 'Cyborg',
    category: 'superheroes',
    imageUrl: '$avatarAssetPrefix$_avatarDir/sh08.png',
  ),
  AvatarItem(
    id: 'sh09',
    name: 'Robot',
    category: 'superheroes',
    imageUrl: '$avatarAssetPrefix$_avatarDir/sh09.png',
  ),
  AvatarItem(
    id: 'sh10',
    name: 'Ombre',
    category: 'superheroes',
    imageUrl: '$avatarAssetPrefix$_avatarDir/sh10.png',
  ),
  AvatarItem(
    id: 'sh11',
    name: 'Cyan',
    category: 'superheroes',
    imageUrl: '$avatarAssetPrefix$_avatarDir/sh11.png',
  ),
  AvatarItem(
    id: 'sh12',
    name: 'Violet',
    category: 'superheroes',
    imageUrl: '$avatarAssetPrefix$_avatarDir/sh12.png',
  ),
  // --- animals (24) ---
  AvatarItem(
    id: 'an01',
    name: 'Chien',
    category: 'animals',
    imageUrl: '$avatarAssetPrefix$_avatarDir/an01.png',
  ),
  AvatarItem(
    id: 'an02',
    name: 'Lionceau',
    category: 'animals',
    imageUrl: '$avatarAssetPrefix$_avatarDir/an02.png',
  ),
  AvatarItem(
    id: 'an03',
    name: 'Panda',
    category: 'animals',
    imageUrl: '$avatarAssetPrefix$_avatarDir/an03.png',
  ),
  AvatarItem(
    id: 'an04',
    name: 'Renard',
    category: 'animals',
    imageUrl: '$avatarAssetPrefix$_avatarDir/an04.png',
  ),
  AvatarItem(
    id: 'an05',
    name: 'Hibou',
    category: 'animals',
    imageUrl: '$avatarAssetPrefix$_avatarDir/an05.png',
  ),
  AvatarItem(
    id: 'an06',
    name: 'Dauphin',
    category: 'animals',
    imageUrl: '$avatarAssetPrefix$_avatarDir/an06.png',
  ),
  AvatarItem(
    id: 'an07',
    name: 'Caméléon',
    category: 'animals',
    imageUrl: '$avatarAssetPrefix$_avatarDir/an07.png',
  ),
  AvatarItem(
    id: 'an08',
    name: 'Panda roux',
    category: 'animals',
    imageUrl: '$avatarAssetPrefix$_avatarDir/an08.png',
  ),
  AvatarItem(
    id: 'an09',
    name: 'Panda roux 2',
    category: 'animals',
    imageUrl: '$avatarAssetPrefix$_avatarDir/an09.png',
  ),
  AvatarItem(
    id: 'an10',
    name: 'Koala',
    category: 'animals',
    imageUrl: '$avatarAssetPrefix$_avatarDir/an10.png',
  ),
  AvatarItem(
    id: 'an11',
    name: 'Tigre',
    category: 'animals',
    imageUrl: '$avatarAssetPrefix$_avatarDir/an11.png',
  ),
  AvatarItem(
    id: 'an12',
    name: 'Tigre 2',
    category: 'animals',
    imageUrl: '$avatarAssetPrefix$_avatarDir/an12.png',
  ),
  AvatarItem(
    id: 'an13',
    name: 'Pingouin',
    category: 'animals',
    imageUrl: '$avatarAssetPrefix$_avatarDir/an13.png',
  ),
  AvatarItem(
    id: 'an14',
    name: 'Raton laveur',
    category: 'animals',
    imageUrl: '$avatarAssetPrefix$_avatarDir/an14.png',
  ),
  AvatarItem(
    id: 'an15',
    name: 'Raton laveur 2',
    category: 'animals',
    imageUrl: '$avatarAssetPrefix$_avatarDir/an15.png',
  ),
  AvatarItem(
    id: 'an16',
    name: 'Grenouille',
    category: 'animals',
    imageUrl: '$avatarAssetPrefix$_avatarDir/an16.png',
  ),
  AvatarItem(
    id: 'an17',
    name: 'Grenouille 2',
    category: 'animals',
    imageUrl: '$avatarAssetPrefix$_avatarDir/an17.png',
  ),
  AvatarItem(
    id: 'an18',
    name: 'Husky',
    category: 'animals',
    imageUrl: '$avatarAssetPrefix$_avatarDir/an18.png',
  ),
  AvatarItem(
    id: 'an19',
    name: 'Colibri',
    category: 'animals',
    imageUrl: '$avatarAssetPrefix$_avatarDir/an19.png',
  ),
  AvatarItem(
    id: 'an20',
    name: 'Colibri 2',
    category: 'animals',
    imageUrl: '$avatarAssetPrefix$_avatarDir/an20.png',
  ),
  AvatarItem(
    id: 'an21',
    name: 'Tortue',
    category: 'animals',
    imageUrl: '$avatarAssetPrefix$_avatarDir/an21.png',
  ),
  AvatarItem(
    id: 'an22',
    name: 'Ours',
    category: 'animals',
    imageUrl: '$avatarAssetPrefix$_avatarDir/an22.png',
  ),
  AvatarItem(
    id: 'an23',
    name: 'Perroquet',
    category: 'animals',
    imageUrl: '$avatarAssetPrefix$_avatarDir/an23.png',
  ),
  AvatarItem(
    id: 'an24',
    name: 'Lapin',
    category: 'animals',
    imageUrl: '$avatarAssetPrefix$_avatarDir/an24.png',
  ),
  // --- flowers (24) ---
  AvatarItem(
    id: 'fl01',
    name: 'Rose',
    category: 'flowers',
    imageUrl: '$avatarAssetPrefix$_avatarDir/fl01.png',
  ),
  AvatarItem(
    id: 'fl02',
    name: 'Tournesol',
    category: 'flowers',
    imageUrl: '$avatarAssetPrefix$_avatarDir/fl02.png',
  ),
  AvatarItem(
    id: 'fl03',
    name: 'Tulipe',
    category: 'flowers',
    imageUrl: '$avatarAssetPrefix$_avatarDir/fl03.png',
  ),
  AvatarItem(
    id: 'fl04',
    name: 'Orchidée',
    category: 'flowers',
    imageUrl: '$avatarAssetPrefix$_avatarDir/fl04.png',
  ),
  AvatarItem(
    id: 'fl05',
    name: 'Lotus',
    category: 'flowers',
    imageUrl: '$avatarAssetPrefix$_avatarDir/fl05.png',
  ),
  AvatarItem(
    id: 'fl06',
    name: 'Cerisier',
    category: 'flowers',
    imageUrl: '$avatarAssetPrefix$_avatarDir/fl06.png',
  ),
  AvatarItem(
    id: 'fl07',
    name: 'Lavande',
    category: 'flowers',
    imageUrl: '$avatarAssetPrefix$_avatarDir/fl07.png',
  ),
  AvatarItem(
    id: 'fl08',
    name: 'Marguerite',
    category: 'flowers',
    imageUrl: '$avatarAssetPrefix$_avatarDir/fl08.png',
  ),
  AvatarItem(
    id: 'fl09',
    name: 'Dahlia rose',
    category: 'flowers',
    imageUrl: '$avatarAssetPrefix$_avatarDir/fl09.png',
  ),
  AvatarItem(
    id: 'fl10',
    name: 'Dahlia',
    category: 'flowers',
    imageUrl: '$avatarAssetPrefix$_avatarDir/fl10.png',
  ),
  AvatarItem(
    id: 'fl11',
    name: 'Hibiscus',
    category: 'flowers',
    imageUrl: '$avatarAssetPrefix$_avatarDir/fl11.png',
  ),
  AvatarItem(
    id: 'fl12',
    name: 'Lys',
    category: 'flowers',
    imageUrl: '$avatarAssetPrefix$_avatarDir/fl12.png',
  ),
  AvatarItem(
    id: 'fl13',
    name: 'Pivoine',
    category: 'flowers',
    imageUrl: '$avatarAssetPrefix$_avatarDir/fl13.png',
  ),
  AvatarItem(
    id: 'fl14',
    name: 'Lys rose',
    category: 'flowers',
    imageUrl: '$avatarAssetPrefix$_avatarDir/fl14.png',
  ),
  AvatarItem(
    id: 'fl15',
    name: 'Pivoine rose',
    category: 'flowers',
    imageUrl: '$avatarAssetPrefix$_avatarDir/fl15.png',
  ),
  AvatarItem(
    id: 'fl16',
    name: 'Jonquille',
    category: 'flowers',
    imageUrl: '$avatarAssetPrefix$_avatarDir/fl16.png',
  ),
  AvatarItem(
    id: 'fl17',
    name: 'Violette',
    category: 'flowers',
    imageUrl: '$avatarAssetPrefix$_avatarDir/fl17.png',
  ),
  AvatarItem(
    id: 'fl18',
    name: 'Iris',
    category: 'flowers',
    imageUrl: '$avatarAssetPrefix$_avatarDir/fl18.png',
  ),
  AvatarItem(
    id: 'fl19',
    name: 'Hortensia',
    category: 'flowers',
    imageUrl: '$avatarAssetPrefix$_avatarDir/fl19.png',
  ),
  AvatarItem(
    id: 'fl20',
    name: 'Œillet',
    category: 'flowers',
    imageUrl: '$avatarAssetPrefix$_avatarDir/fl20.png',
  ),
  AvatarItem(
    id: 'fl21',
    name: 'Œillet rouge',
    category: 'flowers',
    imageUrl: '$avatarAssetPrefix$_avatarDir/fl21.png',
  ),
  AvatarItem(
    id: 'fl22',
    name: 'Digitale',
    category: 'flowers',
    imageUrl: '$avatarAssetPrefix$_avatarDir/fl22.png',
  ),
  AvatarItem(
    id: 'fl23',
    name: 'Souci',
    category: 'flowers',
    imageUrl: '$avatarAssetPrefix$_avatarDir/fl23.png',
  ),
  AvatarItem(
    id: 'fl24',
    name: 'Coquelicot',
    category: 'flowers',
    imageUrl: '$avatarAssetPrefix$_avatarDir/fl24.png',
  ),
];
