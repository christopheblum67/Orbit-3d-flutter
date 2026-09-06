/// Catalogue des avatars proposés pour Orbit 3D.
///
/// 30 avatars répartis en 3 catégories, servis par DiceBear (API d'avatars
/// gratuite) — aucune binaire embarquée, chargés en cache via
/// `CachedNetworkImage` dans `AvatarPickerGrid`.
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

const List<String> avatarCategories = [
  'Tous',
  'Smileys 3D',
  'Personnages',
  'Mascottes',
];

const List<AvatarItem> orbit3DAvatars = [
  // --- Catégorie 1 : Smileys 3D & Expressions (10) ---
  AvatarItem(
    id: 's1',
    name: 'Cool Glass',
    category: 'Smileys 3D',
    imageUrl: 'https://api.dicebear.com/7.x/fun-emoji/png?seed=CoolGlass',
  ),
  AvatarItem(
    id: 's2',
    name: 'Star Eyes',
    category: 'Smileys 3D',
    imageUrl: 'https://api.dicebear.com/7.x/fun-emoji/png?seed=StarEyes',
  ),
  AvatarItem(
    id: 's3',
    name: 'Cyber Wink',
    category: 'Smileys 3D',
    imageUrl: 'https://api.dicebear.com/7.x/fun-emoji/png?seed=Wink',
  ),
  AvatarItem(
    id: 's4',
    name: 'Fire Smile',
    category: 'Smileys 3D',
    imageUrl: 'https://api.dicebear.com/7.x/fun-emoji/png?seed=Fire',
  ),
  AvatarItem(
    id: 's5',
    name: 'Gamer Mind',
    category: 'Smileys 3D',
    imageUrl: 'https://api.dicebear.com/7.x/fun-emoji/png?seed=Gamer',
  ),
  AvatarItem(
    id: 's6',
    name: 'Neon Laugh',
    category: 'Smileys 3D',
    imageUrl: 'https://api.dicebear.com/7.x/fun-emoji/png?seed=Neon',
  ),
  AvatarItem(
    id: 's7',
    name: 'Shocked 3D',
    category: 'Smileys 3D',
    imageUrl: 'https://api.dicebear.com/7.x/fun-emoji/png?seed=Shocked',
  ),
  AvatarItem(
    id: 's8',
    name: 'Angel Glow',
    category: 'Smileys 3D',
    imageUrl: 'https://api.dicebear.com/7.x/fun-emoji/png?seed=Angel',
  ),
  AvatarItem(
    id: 's9',
    name: 'Devil Chill',
    category: 'Smileys 3D',
    imageUrl: 'https://api.dicebear.com/7.x/fun-emoji/png?seed=Devil',
  ),
  AvatarItem(
    id: 's10',
    name: 'Mind Blown',
    category: 'Smileys 3D',
    imageUrl: 'https://api.dicebear.com/7.x/fun-emoji/png?seed=MindBlown',
  ),

  // --- Catégorie 2 : Personnages & Pop Culture (10) ---
  AvatarItem(
    id: 'p1',
    name: 'Orbit Pilot',
    category: 'Personnages',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=Pilot',
  ),
  AvatarItem(
    id: 'p2',
    name: 'Cyber Hero',
    category: 'Personnages',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=CyberHero',
  ),
  AvatarItem(
    id: 'p3',
    name: 'Astro Girl',
    category: 'Personnages',
    imageUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=AstroGirl',
  ),
  AvatarItem(
    id: 'p4',
    name: 'Cosmo Boy',
    category: 'Personnages',
    imageUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=CosmoBoy',
  ),
  AvatarItem(
    id: 'p5',
    name: 'Cinema Fan',
    category: 'Personnages',
    imageUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=CinemaFan',
  ),
  AvatarItem(
    id: 'p6',
    name: 'Retro Gamer',
    category: 'Personnages',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=RetroGamer',
  ),
  AvatarItem(
    id: 'p7',
    name: 'VR Explorer',
    category: 'Personnages',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=VRExplorer',
  ),
  AvatarItem(
    id: 'p8',
    name: 'Pop Queen',
    category: 'Personnages',
    imageUrl: 'https://api.dicebear.com/7.x/lorelei/png?seed=PopQueen',
  ),
  AvatarItem(
    id: 'p9',
    name: 'SciFi Captain',
    category: 'Personnages',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=SciFiCaptain',
  ),
  AvatarItem(
    id: 'p10',
    name: 'Streamer Pro',
    category: 'Personnages',
    imageUrl: 'https://api.dicebear.com/7.x/lorelei/png?seed=StreamerPro',
  ),

  // --- Catégorie 3 : Mascottes & Animaux 3D (10) ---
  AvatarItem(
    id: 'm1',
    name: 'Cyber Cat',
    category: 'Mascottes',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=CyberCat',
  ),
  AvatarItem(
    id: 'm2',
    name: 'Space Dog',
    category: 'Mascottes',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=SpaceDog',
  ),
  AvatarItem(
    id: 'm3',
    name: 'Neon Panda',
    category: 'Mascottes',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=NeonPanda',
  ),
  AvatarItem(
    id: 'm4',
    name: 'Astro Fox',
    category: 'Mascottes',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=AstroFox',
  ),
  AvatarItem(
    id: 'm5',
    name: 'Galaxy Bear',
    category: 'Mascottes',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=GalaxyBear',
  ),
  AvatarItem(
    id: 'm6',
    name: 'Orbit Bot',
    category: 'Mascottes',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=OrbitBot',
  ),
  AvatarItem(
    id: 'm7',
    name: 'Alien Blue',
    category: 'Mascottes',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=AlienBlue',
  ),
  AvatarItem(
    id: 'm8',
    name: 'Rocket Bunny',
    category: 'Mascottes',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=RocketBunny',
  ),
  AvatarItem(
    id: 'm9',
    name: 'Pixel Dragon',
    category: 'Mascottes',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=PixelDragon',
  ),
  AvatarItem(
    id: 'm10',
    name: 'Cosmic Lion',
    category: 'Mascottes',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=CosmicLion',
  ),
];