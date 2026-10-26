import 'package:orbit_3d_flutter/models/channel.dart';

/// Catégories standardisées pour l'auto-classification M3U
enum AutoCategory {
  films('Films'),
  series('Séries'),
  sport('Sport'),
  enfants('Enfants'),
  news('Actualités'),
  documentaires('Documentaires'),
  musique('Musique'),
  divertissement('Divertissement'),
  science('Sciences'),
  technologie('Technologie'),
  nature('Nature'),
  histoire('Histoire'),
  culture('Culture'),
  art('Art'),
  autre('Autre');

  const AutoCategory(this.label);
  final String label;

  static AutoCategory fromString(String value) {
    return AutoCategory.values.firstWhere(
      (c) => c.name == value,
      orElse: () => AutoCategory.autre,
    );
  }
}

/// Mots-clés pour la détection automatique de catégorie
/// Basé sur le nom de la chaîne et son groupe (group-title)
class AutoCategoryDetector {
  AutoCategoryDetector._();

  // Mots-clés FR + EN pour chaque catégorie
  static const Map<AutoCategory, List<String>> _keywords = {
    AutoCategory.films: [
      // FR
      'cinema', 'cinéma', 'film', 'films', 'movie', 'movies', 'premiere', 'première',
      'blockbuster', 'classique', 'classic', 'action', 'thriller', 'horreur', 'horror',
      'comédie', 'comedy', 'drame', 'drama', 'romance', 'romantic', 'sci-fi', 'science-fiction',
      'fantastique', 'fantasy', 'aventure', 'adventure', 'animation', 'anime', 'manga',
      'west', 'western', 'polar', 'noir', 'guerre', 'war', 'historique', 'historical',
      'biopic', 'documentaire', 'documentary', 'reportage', 'magazine', 'ciné', 'cine',
      'bollywood', 'hollywood', 'indie', 'independant', 'art et essai', 'art house',
      // Mots composés fréquents
      'ciné+', 'cine+', 'cine plus', 'oc', 'orange cinema', 'canal+', 'canal plus',
    ],
    AutoCategory.series: [
      // FR
      'serie', 'série', 'series', 'show', 'shows', 'episode', 'épisode', 'episodes',
      'saison', 'season', 'netflix', 'amazon', 'disney+', 'disney plus', 'apple tv',
      'hbo', 'oc', 'canal+', 'canal plus', 'serie+', 'series+', 'tvshow', 'tv show',
      'sitcom', 'soap', 'telenovela', 'drama', 'kdrama', 'anime', 'manga',
      'replay', 'catch up', 'catchup', 'rattrapage', 'integrale', 'intégrale',
      'complete', 'complet', 'best of', 'bestof', 'marathon', 'binge',
    ],
    AutoCategory.sport: [
      // FR
      'sport', 'sports', 'foot', 'football', 'soccer', 'rugby', 'tennis', 'basket',
      'basketball', 'hand', 'handball', 'volley', 'volleyball', 'natation', 'swimming',
      'cyclisme', 'cycling', 'formule 1', 'f1', 'moto', 'motogp', 'f2', 'f3',
      'golf', 'ski', 'snowboard', 'athletisme', 'athletics', 'jo', 'jeux olympiques',
      'olympics', 'champions league', 'ligue 1', 'ligue 2', 'premier league',
      'liga', 'bundesliga', 'serie a', 'europa league', 'conference league',
      'coupe du monde', 'world cup', 'euro', 'roland garros', 'wimbledon',
      'tour de france', 'dakar', 'marathon', 'triathlon', 'ironman',
      'boxe', 'mma', 'ufc', 'wrestling', 'catch', 'esport', 'e-sport',
      // Chaînes connues
      'bein', 'beinsport', 'bein sports', 'rmc sport', 'rmcsport', 'eurosport',
      'canal+ sport', 'canalsport', 'infosport', 'l\'equipe', 'lequipe',
    ],
    AutoCategory.enfants: [
      // FR
      'enfant', 'enfants', 'kids', 'kid', 'junior', 'baby', 'bebe', 'bébé',
      'maternelle', 'primaire', 'collège', 'lycée', 'ado', 'adolescent',
      'cartoon', 'cartoon network', 'boomerang', 'boing', 'gulli', 'canal j',
      'tiJi', 'disney', 'disney channel', 'disney junior', 'disney xd',
      'nickelodeon', 'nick jr', 'nicktoons', 'mtv', 'mtv hits',
      'pokemon', 'yugioh', 'digimon', 'naruto', 'one piece', 'dragon ball',
      'miraculous', 'ladybug', 'pat patrouille', 'paw patrol', 'peppa pig',
      'sam le pompier', 'tchoupi', 'tchoupi et doudou', 'trotro', 'petit ours brun',
      'kazoos', 'ouat', 'odeon', 'm6 kid', 'w9 kid', 'tfou', 'tf1 junior',
      'piwi', 'piwi+', 'canal+ kids', 'canal+ family', 'oc kids',
    ],
    AutoCategory.news: [
      // FR
      'news', 'actualité', 'actualités', 'info', 'infos', 'journal', 'journaux',
      'bfm', 'bfmtv', 'bfm tv', 'lci', 'france info', 'franceinfo', 'cnews',
      'c news', 'europe 1', 'rtl', 'rcf', 'rfi', 'monte carlo', 'sud radio',
      'africa', 'afrique', 'tv5', 'tv5monde', 'france 24', 'france24',
      'euronews', 'dwt', 'al jazeera', 'aljazeera', 'rt', 'rt news',
      'bloomberg', 'cnbc', 'reuters', 'ap', 'associated press', 'afp',
      'meteo', 'météo', 'weather', 'journal', 'édition', 'edition', 'soir',
      'matin', 'matinale', 'weekend', 'débat', 'debate', 'editorial', 'éditorial',
      'politique', 'politics', 'économie', 'economie', 'finance', 'bourse',
    ],
    AutoCategory.documentaires: [
      // FR
      'documentaire', 'documentaires', 'documentary', 'documentaries',
      'reportage', 'reportages', 'enquête', 'enquete', 'investigation',
      'decouverte', 'découverte', 'discovery', 'national geographic', 'nat geo',
      'geo', 'arte', 'arte tv', 'planete', 'planète', 'planete+', 'planète+',
      'science', 'sciences', 'nature', 'animaux', 'animals', 'wildlife',
      'environnement', 'environment', 'ecologie', 'écologie', 'climat',
      'espace', 'space', 'astronomie', 'astronomy', 'univers', 'universe',
      'histoire', 'history', 'civilisation', 'civilization', 'archeologie',
      'archéologie', 'patrimoine', 'heritage', 'monument', 'museum', 'musée',
    ],
    AutoCategory.musique: [
      // FR
      'musique', 'music', 'musical', 'concert', 'concerts', 'live', 'festival',
      'festival', 'opera', 'opéra', 'classique', 'classical', 'jazz', 'blues',
      'rock', 'pop', 'rap', 'hip hop', 'hip-hop', 'r&b', 'rnb', 'soul', 'funk',
      'electro', 'electronic', 'edm', 'house', 'techno', 'trance', 'dubstep',
      'reggae', 'reggaeton', 'latino', 'salsa', 'bachata', 'kizomba', 'zouk',
      'world', 'monde', 'afro', 'african', 'rai', 'chaabi', 'oriental',
      'mtv', 'mtv hits', 'mtv base', 'mtv rocks', 'mtv dance', 'mtv live',
      'vh1', 'cstar', 'nrj', 'nrj hits', 'nrj 12', 'rfm', 'rfm music',
      'chérie', 'cherie fm', 'nostalgie', 'rtl2', 'ouï fm', 'oui fm',
    ],
    AutoCategory.divertissement: [
      // FR
      'divertissement', 'entertainment', 'variété', 'varietes', 'variété',
      'jeu', 'jeux', 'game', 'games', 'quiz', 'quiz', 'loterie', 'loto',
      'telerealite', 'télérealité', 'reality', 'reality tv', 'secret story',
      'koh lanta', 'koh-lanta', 'the voice', 'danse avec les stars', 'dal',
      'top chef', 'masterchef', 'meilleur patissier', 'patissier', 'pâtissier',
      'incroyable talent', 'france a un incroyable talent', 'agg', 'agv',
      'tpmp', 'touche pas a mon poste', 'cyril hanouna', 'quelli', 'quelli',
      'c à vous', 'c a vous', 'c dans l\'air', 'c dans lair', 'c dans l\'air',
      'quelli', 'qdb', 'questions pour un champion', 'des chiffres et des lettres',
      'motus', 'slam', 'tout le monde veut prendre sa place', 'n\'oubliez pas les paroles',
      'noubliezpaslesparoles', 'n\'oubliez pas les paroles',
    ],
    AutoCategory.science: [
      // FR
      'science', 'sciences', 'scientifique', 'scientific', 'recherche', 'research',
      'innovation', 'innovation', 'technologie', 'technology', 'tech', 'future',
      'futur', 'avenir', 'decouverte', 'découverte', 'discovery', 'invention',
      'invention', 'labo', 'laboratoire', 'laboratory', 'experience', 'expérience',
      'experiment', 'physique', 'physics', 'chimie', 'chemistry', 'biologie',
      'biology', 'medecine', 'médecine', 'medical', 'health', 'sante', 'santé',
    ],
    AutoCategory.technologie: [
      // FR
      'tech', 'technology', 'technologie', 'informatique', 'computer', 'digital',
      'numerique', 'numérique', 'web', 'internet', 'reseau', 'réseau', 'wifi',
      '5g', '4g', 'fibre', 'fiber', 'cloud', 'ia', 'ai', 'intelligence artificielle',
      'artificial intelligence', 'machine learning', 'ml', 'deep learning', 'dl',
      'robot', 'robotique', 'robotics', 'drone', 'vr', 'ar', 'realite virtuelle',
      'réalité virtuelle', 'realite augmentee', 'réalité augmentée', 'metaverse',
      'metavers', 'crypto', 'bitcoin', 'blockchain', 'nft', 'startup', 'start-up',
      'innovation', 'innovation', 'future tech', 'gadget', 'smartphone', 'mobile',
      'app', 'application', 'logiciel', 'software', 'code', 'coding', 'dev', 'devops',
    ],
    AutoCategory.nature: [
      // FR
      'nature', 'environnement', 'environment', 'ecologie', 'écologie', 'green',
      'vert', 'durable', 'sustainable', 'bio', 'organic', 'agriculture', 'ferme',
      'farm', 'jardin', 'garden', 'foret', 'forêt', 'forest', 'ocean', 'océan',
      'mer', 'sea', 'riviere', 'rivière', 'river', 'lac', 'lake', 'montagne',
      'mountain', 'alpes', 'alps', 'pyrenees', 'pyrénées', 'volcan', 'volcano',
      'ile', 'île', 'island', 'plage', 'beach', 'cote', 'côte', 'coast', 'recif',
      'récif', 'corail', 'coral', 'plankton', 'plancton', 'biodiversite',
      'biodiversité', 'biodiversity', 'espece', 'espèce', 'species', 'faune',
      'flore', 'flora', 'animal', 'animaux', 'animals', 'oiseau', 'oiseaux',
      'mammifere', 'mammifère', 'mammal', 'reptile', 'poisson', 'insecte',
    ],
    AutoCategory.histoire: [
      // FR
      'histoire', 'history', 'historique', 'historical', 'civilisation', 'civilization',
      'archeologie', 'archéologie', 'archaeology', 'patrimoine', 'heritage',
      'monument', 'museum', 'musée', 'chateau', 'château', 'castle', 'palais',
      'palace', 'eglise', 'église', 'church', 'cathedrale', 'cathédrale', 'cathedral',
      'abbaye', 'abbey', 'cloitre', 'cloître', 'cloister', 'ruine', 'ruins',
      'antiquite', 'antiquité', 'antiquity', 'rome', 'rome antique', 'grece',
      'grèce', 'greece', 'egypte', 'égyptienne', 'egypt', 'pharaon', 'pharaoh',
      'moyen age', 'moyen-âge', 'middle ages', 'renaissance', 'revolution',
      'révolution', 'guerre', 'war', 'paix', 'peace', 'traite', 'traité', 'treaty',
    ],
    AutoCategory.culture: [
      // FR
      'culture', 'cultural', 'art', 'arts', 'litterature', 'littérature', 'literature',
      'livre', 'book', 'lecture', 'reading', 'ecrivain', 'écrivain', 'writer',
      'auteur', 'author', 'poesie', 'poésie', 'poetry', 'poeme', 'poème', 'poem',
      'theatre', 'théâtre', 'theater', 'piece', 'pièce', 'play', 'danse', 'dance',
      'ballet', 'opera', 'opéra', 'philosophie', 'philosophy', 'pensee', 'pensée',
      'idee', 'idée', 'idea', 'savoir', 'knowledge', 'education', 'education',
      'ecole', 'école', 'school', 'universite', 'université', 'university',
      'fac', 'campus', 'etudiant', 'étudiant', 'student', 'prof', 'professeur',
      'professor', 'enseignant', 'teacher', 'apprentissage', 'learning', 'mooc',
    ],
    AutoCategory.art: [
      // FR
      'art', 'arts', 'peinture', 'painting', 'dessin', 'drawing', 'sculpture',
      'sculpture', 'photo', 'photography', 'photographie', 'exposition', 'exhibition',
      'galerie', 'gallery', 'musee', 'musée', 'museum', 'vernissage', 'opening',
      'artiste', 'artist', 'peintre', 'painter', 'sculpteur', 'sculptor',
      'graffiti', 'street art', 'streetart', 'contemporain', 'contemporary',
      'moderne', 'modern', 'classique', 'classic', 'impressionnisme', 'impressionism',
      'cubisme', 'cubism', 'surrealisme', 'surréalisme', 'surrealism', 'abstrait',
      'abstract', 'pop art', 'popart', 'minimalisme', 'minimalism', 'conceptuel',
      'conceptual', 'performance', 'installation', 'video art', 'videoart',
      'new media', 'digital art', 'digitalart', 'net art', 'netart',
    ],
  };

  /// Détecte la catégorie à partir du nom de la chaîne et de son groupe
  static AutoCategory detect(String channelName, String group) {
    final text = '${channelName} ${group}';
    
    // 1. Détection par regex (priorité haute : patterns spécifiques séries/films)
    final regexCategory = _detectByRegex(text);
    if (regexCategory != null) return regexCategory;

    // 2. Détection par mots-clés (fallback)
    return _detectByKeywords(channelName, group);
  }

  /// Détection par regex pour patterns spécifiques séries/films
  /// Patterns: S01E01, 1080p, 720p, WEB-DL, BLURAY, etc.
  static AutoCategory? _detectByRegex(String text) {
    final lower = text.toLowerCase();

    // Patterns séries (très forts)
    final seriesPatterns = [
      RegExp(r's\d{1,2}e\d{1,2}'),           // S01E01, S1E1
      RegExp(r'saison\s*\d+'),               // Saison 1, Saison 01
      RegExp(r'season\s*\d+'),               // Season 1
      RegExp(r'épisode\s*\d+'),              // Épisode 1
      RegExp(r'episode\s*\d+'),              // Episode 1
      RegExp(r'ep\s*\d+'),                   // Ep 1
      RegExp(r'\d+x\d{2}'),                  // 1x01, 2x10
      RegExp(r'complete\s*series?'),         // Complete series
      RegExp(r'intégrale'),                 // Intégrale
      RegExp(r'int[eé]grale'),               // Integrale (sans accent)
      RegExp(r'box\s*set'),                  // Box set
      RegExp(r'collection'),                 // Collection
    ];

    for (final pattern in seriesPatterns) {
      if (pattern.hasMatch(lower)) return AutoCategory.series;
    }

    // Patterns films (qualité vidéo = indicateur film/VOD)
    final moviePatterns = [
      RegExp(r'\b(1080p|720p|480p|2160p|4k)\b'),  // Résolutions
      RegExp(r'\b(web[-\s]?dl|webrip|web\s*dl)\b'),  // WEB-DL, WebRip
      RegExp(r'\b(bluray|blu[-\s]?ray|bdrip|brrip)\b'), // BluRay
      RegExp(r'\b(hdtv|hdtvrip)\b'),              // HDTV
      RegExp(r'\b(dvdrip|dvd\s*rip)\b'),          // DVDRip
      RegExp(r'\b(xvid|x264|x265|h264|h265|hevc)\b'), // Codecs
      RegExp(r'\b(remux|repack|proper|real|internal)\b'), // Tags release
      RegExp(r'\b\d{4}\b'),                       // Année (ex: 2023)
    ];

    for (final pattern in moviePatterns) {
      if (pattern.hasMatch(lower)) return AutoCategory.films;
    }

    return null;
  }

  /// Détection par mots-clés (méthode originale)
  static AutoCategory _detectByKeywords(String channelName, String group) {
    final text = '${channelName} ${group}'.toLowerCase();
    final words = text.split(RegExp(r'[^\p{L}\p{N}]+'));

    // Score par catégorie
    final scores = <AutoCategory, int>{};

    for (final entry in _keywords.entries) {
      final category = entry.key;
      final kws = entry.value;
      int score = 0;

      for (final kw in kws) {
        final kwLower = kw.toLowerCase();
        if (text.contains(kwLower)) {
          // Score plus élevé si le mot-clé est un mot complet
          if (words.contains(kwLower)) {
            score += 3;
          } else {
            score += 1;
          }
        }
      }

      if (score > 0) {
        scores[category] = score;
      }
    }

    if (scores.isEmpty) return AutoCategory.autre;

    // Retourne la catégorie avec le score max
    return scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// Applique la détection à une liste de chaînes
  static List<Channel> categorizeAll(List<Channel> channels) {
    return channels.map((c) {
      final category = detect(c.name, c.group);
      // On pourrait stocker la catégorie dans un champ dédié si le modèle le permet
      // Pour l'instant, on peut utiliser le champ `group` ou `categoryId`
      return c;
    }).toList();
  }

  /// Retourne le libellé localisé d'une catégorie
  static String label(AutoCategory category, {String locale = 'fr'}) {
    switch (category) {
      case AutoCategory.films:
        return locale == 'fr' ? 'Films' : 'Movies';
      case AutoCategory.series:
        return locale == 'fr' ? 'Séries' : 'Series';
      case AutoCategory.sport:
        return locale == 'fr' ? 'Sport' : 'Sports';
      case AutoCategory.enfants:
        return locale == 'fr' ? 'Enfants' : 'Kids';
      case AutoCategory.news:
        return locale == 'fr' ? 'Actualités' : 'News';
      case AutoCategory.documentaires:
        return locale == 'fr' ? 'Documentaires' : 'Documentaries';
      case AutoCategory.musique:
        return locale == 'fr' ? 'Musique' : 'Music';
      case AutoCategory.divertissement:
        return locale == 'fr' ? 'Divertissement' : 'Entertainment';
      case AutoCategory.science:
        return locale == 'fr' ? 'Sciences' : 'Science';
      case AutoCategory.technologie:
        return locale == 'fr' ? 'Technologie' : 'Technology';
      case AutoCategory.nature:
        return locale == 'fr' ? 'Nature' : 'Nature';
      case AutoCategory.histoire:
        return locale == 'fr' ? 'Histoire' : 'History';
      case AutoCategory.culture:
        return locale == 'fr' ? 'Culture' : 'Culture';
      case AutoCategory.art:
        return locale == 'fr' ? 'Art' : 'Art';
      case AutoCategory.autre:
        return locale == 'fr' ? 'Autre' : 'Other';
    }
  }
}