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
  'Fantasy',
  'Sci-Fi',
  'Nature',
  'Rétro',
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

  // --- Catégorie 4 : Fantasy & Magique (10) ---
  AvatarItem(
    id: 'f1',
    name: 'Mage Arcanique',
    category: 'Fantasy',
    imageUrl: 'https://api.dicebear.com/7.x/lorelei/png?seed=ArcaneMage',
  ),
  AvatarItem(
    id: 'f2',
    name: 'Guerrière Elfique',
    category: 'Fantasy',
    imageUrl: 'https://api.dicebear.com/7.x/lorelei/png?seed=ElfWarrior',
  ),
  AvatarItem(
    id: 'f3',
    name: 'Dragon Ancien',
    category: 'Fantasy',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=AncientDragon',
  ),
  AvatarItem(
    id: 'f4',
    name: 'Druide Sylvestre',
    category: 'Fantasy',
    imageUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=Druid',
  ),
  AvatarItem(
    id: 'f5',
    name: 'Paladin Lumière',
    category: 'Fantasy',
    imageUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=Paladin',
  ),
  AvatarItem(
    id: 'f6',
    name: 'Voleur Ombre',
    category: 'Fantasy',
    imageUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=ShadowThief',
  ),
  AvatarItem(
    id: 'f7',
    name: 'Nécromancien',
    category: 'Fantasy',
    imageUrl: 'https://api.dicebear.com/7.x/lorelei/png?seed=Necromancer',
  ),
  AvatarItem(
    id: 'f8',
    name: 'Barbare Glacé',
    category: 'Fantasy',
    imageUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=IceBarbarian',
  ),
  AvatarItem(
    id: 'f9',
    name: 'Sorcière Lune',
    category: 'Fantasy',
    imageUrl: 'https://api.dicebear.com/7.x/lorelei/png?seed=MoonWitch',
  ),
  AvatarItem(
    id: 'f10',
    name: 'Chevalier Dragon',
    category: 'Fantasy',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=DragonKnight',
  ),

  // --- Catégorie 5 : Sci-Fi & Cyberpunk (10) ---
  AvatarItem(
    id: 'c1',
    name: 'Cyber Samouraï',
    category: 'Sci-Fi',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=CyberSamurai',
  ),
  AvatarItem(
    id: 'c2',
    name: 'Pilote Mécha',
    category: 'Sci-Fi',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=MechaPilot',
  ),
  AvatarItem(
    id: 'c3',
    name: 'Agent Synthétique',
    category: 'Sci-Fi',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=SynthAgent',
  ),
  AvatarItem(
    id: 'c4',
    name: 'Hacker Neon',
    category: 'Sci-Fi',
    imageUrl: 'https://api.dicebear.com/7.x/fun-emoji/png?seed=NeonHacker',
  ),
  AvatarItem(
    id: 'c5',
    name: 'Explorateur Spatial',
    category: 'Sci-Fi',
    imageUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=SpaceExplorer',
  ),
  AvatarItem(
    id: 'c6',
    name: 'IA Consciente',
    category: 'Sci-Fi',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=SentientAI',
  ),
  AvatarItem(
    id: 'c7',
    name: 'Mineur Astéroïde',
    category: 'Sci-Fi',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=AsteroidMiner',
  ),
  AvatarItem(
    id: 'c8',
    name: 'Commandant Flotte',
    category: 'Sci-Fi',
    imageUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=FleetCommander',
  ),
  AvatarItem(
    id: 'c9',
    name: 'Ingénieur Orbital',
    category: 'Sci-Fi',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=OrbitalEngineer',
  ),
  AvatarItem(
    id: 'c10',
    name: 'Voyageur Temporel',
    category: 'Sci-Fi',
    imageUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=TimeTraveler',
  ),

  // --- Catégorie 6 : Nature & Élémentaire (10) ---
  AvatarItem(
    id: 'n1',
    name: 'Esprit Forêt',
    category: 'Nature',
    imageUrl: 'https://api.dicebear.com/7.x/lorelei/png?seed=ForestSpirit',
  ),
  AvatarItem(
    id: 'n2',
    name: 'Gardien Océan',
    category: 'Nature',
    imageUrl: 'https://api.dicebear.com/7.x/lorelei/png?seed=OceanGuardian',
  ),
  AvatarItem(
    id: 'n3',
    name: 'Faucon Montagne',
    category: 'Nature',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=MountainHawk',
  ),
  AvatarItem(
    id: 'n4',
    name: 'Esprit Flamme',
    category: 'Nature',
    imageUrl: 'https://api.dicebear.com/7.x/fun-emoji/png?seed=FireSpirit',
  ),
  AvatarItem(
    id: 'n5',
    name: 'Gardienne Rivière',
    category: 'Nature',
    imageUrl: 'https://api.dicebear.com/7.x/lorelei/png?seed=RiverGuardian',
  ),
  AvatarItem(
    id: 'n6',
    name: 'Tempête Sable',
    category: 'Nature',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=Sandstorm',
  ),
  AvatarItem(
    id: 'n7',
    name: 'Aurore Boréale',
    category: 'Nature',
    imageUrl: 'https://api.dicebear.com/7.x/fun-emoji/png?seed=Aurora',
  ),
  AvatarItem(
    id: 'n8',
    name: 'Vent Glacial',
    category: 'Nature',
    imageUrl: 'https://api.dicebear.com/7.x/fun-emoji/png?seed=IceWind',
  ),
  AvatarItem(
    id: 'n9',
    name: 'Cœur Volcan',
    category: 'Nature',
    imageUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=VolcanoHeart',
  ),
  AvatarItem(
    id: 'n10',
    name: 'Feuille Dansante',
    category: 'Nature',
    imageUrl: 'https://api.dicebear.com/7.x/lorelei/png?seed=DancingLeaf',
  ),

  // --- Catégorie 7 : Rétro & Pixel Art (10) ---
  AvatarItem(
    id: 'r1',
    name: 'Héros 8-bit',
    category: 'Rétro',
    imageUrl: 'https://api.dicebear.com/7.x/pixel-art/png?seed=8bitHero',
  ),
  AvatarItem(
    id: 'r2',
    name: 'Princesse Pixel',
    category: 'Rétro',
    imageUrl: 'https://api.dicebear.com/7.x/pixel-art/png?seed=PixelPrincess',
  ),
  AvatarItem(
    id: 'r3',
    name: 'Guerrier 16-bit',
    category: 'Rétro',
    imageUrl: 'https://api.dicebear.com/7.x/pixel-art/png?seed=16bitWarrior',
  ),
  AvatarItem(
    id: 'r4',
    name: 'Mage Rétro',
    category: 'Rétro',
    imageUrl: 'https://api.dicebear.com/7.x/pixel-art/png?seed=RetroMage',
  ),
  AvatarItem(
    id: 'r5',
    name: 'Robot Arcade',
    category: 'Rétro',
    imageUrl: 'https://api.dicebear.com/7.x/pixel-art/png?seed=ArcadeBot',
  ),
  AvatarItem(
    id: 'r6',
    name: 'Pilote Course',
    category: 'Rétro',
    imageUrl: 'https://api.dicebear.com/7.x/pixel-art/png?seed=RacingPilot',
  ),
  AvatarItem(
    id: 'r7',
    name: 'Ninja Pixel',
    category: 'Rétro',
    imageUrl: 'https://api.dicebear.com/7.x/pixel-art/png?seed=PixelNinja',
  ),
  AvatarItem(
    id: 'r8',
    name: 'Chevalier Old-School',
    category: 'Rétro',
    imageUrl: 'https://api.dicebear.com/7.x/pixel-art/png?seed=OldSchoolKnight',
  ),
  AvatarItem(
    id: 'r9',
    name: 'Explorateur Dungeon',
    category: 'Rétro',
    imageUrl: 'https://api.dicebear.com/7.x/pixel-art/png?seed=DungeonExplorer',
  ),
  AvatarItem(
    id: 'r10',
    name: 'Boss Final',
    category: 'Rétro',
    imageUrl: 'https://api.dicebear.com/7.x/pixel-art/png?seed=FinalBoss',
  ),
];
