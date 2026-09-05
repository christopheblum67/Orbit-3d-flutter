import 'package:flutter/material.dart';

/// Acteur/Casting - style Allociné
class Actor {
  final String id;
  final String name;
  final String character; // Rôle joué
  final String profilePath; // Photo de l'acteur (URL)
  final int order; // Ordre au générique

  Actor({
    required this.id,
    required this.name,
    required this.character,
    required this.profilePath,
    this.order = 0,
  });

  factory Actor.fromMap(Map<String, dynamic> map) {
    return Actor(
      id: map['id']?.toString() ?? map['cast_id']?.toString() ?? '',
      name: map['name'] ?? map['original_name'] ?? '',
      character: map['character'] ?? map['role'] ?? '',
      profilePath: map['profile_path'] ?? map['profile_url'] ?? '',
      order: map['order'] ?? map['cast_id'] ?? 0,
    );
  }

  String get profileUrl {
    if (profilePath.isEmpty) return '';
    if (profilePath.startsWith('http')) return profilePath;
    return 'https://image.tmdb.org/t/p/w185$profilePath'; // TMDB format
  }

  bool get hasProfile => profilePath.isNotEmpty;
}

/// Membre de l'équipe technique (réalisateur, scénariste, producteur, etc.)
class CrewMember {
  final String id;
  final String name;
  final String job; // Réalisateur, Scénariste, Producteur, Musique, etc.
  final String department; // Directing, Writing, Production, Sound, etc.
  final String profilePath; // Photo
  final int order;

  CrewMember({
    required this.id,
    required this.name,
    required this.job,
    required this.department,
    required this.profilePath,
    this.order = 0,
  });

  factory CrewMember.fromMap(Map<String, dynamic> map) {
    return CrewMember(
      id: map['id']?.toString() ?? map['credit_id']?.toString() ?? '',
      name: map['name'] ?? '',
      job: map['job'] ?? '',
      department: map['department'] ?? '',
      profilePath: map['profile_path'] ?? map['profile_url'] ?? '',
      order: map['order'] ?? 0,
    );
  }

  String get profileUrl {
    if (profilePath.isEmpty) return '';
    if (profilePath.startsWith('http')) return profilePath;
    return 'https://image.tmdb.org/t/p/w185$profilePath';
  }

  bool get hasProfile => profilePath.isNotEmpty;

  /// Icône selon le département
  IconData get departmentIcon {
    switch (department.toLowerCase()) {
      case 'directing':
        return Icons.movie_outlined;
      case 'writing':
        return Icons.edit_outlined;
      case 'production':
        return Icons.business_outlined;
      case 'sound':
        return Icons.music_note_outlined;
      case 'camera':
        return Icons.videocam_outlined;
      case 'editing':
        return Icons.content_cut_outlined;
      case 'art':
        return Icons.palette_outlined;
      case 'costume':
        return Icons.checkroom_outlined;
      case 'visual effects':
        return Icons.auto_fix_high_outlined;
      default:
        return Icons.person_outline;
    }
  }

  /// Couleur selon le département
  Color get departmentColor {
    switch (department.toLowerCase()) {
      case 'directing':
        return Colors.redAccent;
      case 'writing':
        return Colors.blueAccent;
      case 'production':
        return Colors.greenAccent;
      case 'sound':
        return Colors.orangeAccent;
      case 'camera':
        return Colors.purpleAccent;
      case 'editing':
        return Colors.tealAccent;
      case 'art':
        return Colors.pinkAccent;
      case 'costume':
        return Colors.amberAccent;
      case 'visual effects':
        return Colors.deepOrangeAccent;
      default:
        return Colors.grey;
    }
  }
}

/// Casting complet d'un film
class MovieCredits {
  final List<Actor> cast;
  final List<CrewMember> crew;

  MovieCredits({required this.cast, required this.crew});

  factory MovieCredits.fromMap(Map<String, dynamic> map) {
    final castList = (map['cast'] as List<dynamic>? ?? [])
        .map((e) => Actor.fromMap(e as Map<String, dynamic>))
        .toList();
    final crewList = (map['crew'] as List<dynamic>? ?? [])
        .map((e) => CrewMember.fromMap(e as Map<String, dynamic>))
        .toList();

    // Trier le cast par ordre (générique)
    castList.sort((a, b) => a.order.compareTo(b.order));
    // Trier l'équipe par département puis ordre
    crewList.sort((a, b) {
      final deptCompare = a.department.compareTo(b.department);
      if (deptCompare != 0) return deptCompare;
      return a.order.compareTo(b.order);
    });

    return MovieCredits(cast: castList, crew: crewList);
  }

  /// Acteurs principaux (premiers 10-15)
  List<Actor> get mainCast => cast.take(15).toList();

  /// Équipe technique groupée par département
  Map<String, List<CrewMember>> get crewByDepartment {
    final map = <String, List<CrewMember>>{};
    for (final member in crew) {
      map.putIfAbsent(member.department, () => []).add(member);
    }
    return map;
  }

  /// Réalisateurs
  List<CrewMember> get directors => crew
      .where((m) => m.department.toLowerCase() == 'directing' && m.job.toLowerCase().contains('director'))
      .toList();

  /// Scénaristes
  List<CrewMember> get writers => crew
      .where((m) => m.department.toLowerCase() == 'writing')
      .toList();

  /// Producteurs
  List<CrewMember> get producers => crew
      .where((m) => m.department.toLowerCase() == 'production')
      .toList();
}