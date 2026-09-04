import 'package:flutter/material.dart';
import 'channel.dart';

/// Catégorie d'abonnement (pour orbite par genre/thème)
class SubscriptionCategory {
  final String id;
  final String name;
  final Color orbitColor;

  const SubscriptionCategory({
    required this.id,
    required this.name,
    this.orbitColor = Colors.purpleAccent,
  });
}

/// Chaîne en tant que planète orbitale (modèle 3D)
class OrbitChannelPlanet {
  final String id;
  final String name;
  final String categoryId;
  final String logoUrl;
  final double userPreferenceScore; // 0.0 à 1.0
  final String currentProgramTitle;
  final double currentProgramProgress; // 0.0 à 1.0

  OrbitChannelPlanet({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.logoUrl,
    this.userPreferenceScore = 0.5,
    required this.currentProgramTitle,
    required this.currentProgramProgress,
  });

  double getOrbitRadius(double baseRadius) {
    return baseRadius + ((1.0 - userPreferenceScore) * 180.0);
  }

  factory OrbitChannelPlanet.fromChannel(Channel channel, {
    double preference = 0.5,
    String currentProgram = '',
    double progress = 0.0,
  }) {
    return OrbitChannelPlanet(
      id: channel.id,
      name: channel.name,
      categoryId: channel.categoryId ?? '',
      logoUrl: channel.logoUrl ?? '',
      userPreferenceScore: preference,
      currentProgramTitle: currentProgram,
      currentProgramProgress: progress,
    );
  }
}

/// Favoris pour le système solaire (Soleil + planètes)
class FavoriteChannelNode {
  final String id;
  final String name;
  final String logoUrl;
  final String currentProgramTitle;
  final double currentProgramProgress;
  final bool isTopFavorite;

  FavoriteChannelNode({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.currentProgramTitle,
    required this.currentProgramProgress,
    this.isTopFavorite = false,
  });
}

/// Résultat de recherche nébuleuse
class NebulaSearchResult {
  final String title;
  final String type; // 'Live', 'VOD', 'Series', 'Channel'
  final double relevanceScore;

  NebulaSearchResult({
    required this.title,
    required this.type,
    required this.relevanceScore,
  });
}

/// Layout pour le dual screen
enum DualScreenLayout { splitEqual, mainWithPip }