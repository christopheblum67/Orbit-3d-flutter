import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_profile.dart';
import '../models/movie.dart';
import '../models/ai_recommendation.dart';

/// Message utilisateur compréhensible pour une erreur IA dédiée.
String aiUserFriendlyError(Object error) {
  if (error is AIApiKeyMissingException) {
    return error.message;
  }
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Le service IA met trop de temps à répondre. Vérifie ta connexion et réessaie.';
      case DioExceptionType.connectionError:
        return 'Impossible de contacter le service IA. Vérifie ta connexion internet.';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        if (status == 401 || status == 403) {
          return 'Le service IA a refusé l\'accès (code $status). Vérifie ta clé API dans .env.';
        }
        if (status == 429) {
          return 'Trop de requêtes IA. Réessaie dans quelques instants.';
        }
        return 'Le service IA a renvoyé une erreur (code ${status ?? 'inconnu'}). Réessaie plus tard.';
      default:
        return 'Une erreur réseau est survenue avec le service IA. Réessaie plus tard.';
    }
  }
  return 'Impossible d\'obtenir les recommandations IA. Réessaie plus tard.';
}

/// Levée quand la clé API n'est pas configurée dans .env.
class AIApiKeyMissingException implements Exception {
  const AIApiKeyMissingException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AiService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 40),
  ));

  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(milliseconds: 900);

  Future<List<AIRecommendation>> getRecommendations(
    UserProfile profile, [
    List<Movie> availableMovies = const [],
  ]) async {
    final apiKey = dotenv.env['IA_API_KEY'];
    final endpoint =
        dotenv.env['IA_API_ENDPOINT'] ?? 'https://api.openai.com/v1/chat/completions';

    if (apiKey == null || apiKey.isEmpty) {
      throw const AIApiKeyMissingException(
        'Aucune clé API IA configurée. Ajoute IA_API_KEY dans ton fichier .env.',
      );
    }

    final prompt = _buildPrompt(profile, availableMovies);

    Object? lastError;
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await _dio.post(
          endpoint,
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
          ),
          data: {
            'model': 'gpt-3.5-turbo',
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            if (_supportsResponseFormat(endpoint)) 'response_format': {'type': 'json_object'},
          },
        );
        final content =
            response.data?['choices']?[0]?['message']?['content']?.toString() ?? '';
        return _parseContent(content);
      } catch (error) {
        lastError = error;
        if (!_isRetriable(error) || attempt == _maxRetries - 1) break;
        await Future<void>.delayed(_retryDelay);
      }
    }
    throw lastError ?? StateError('Aucune recommandation obtenue.');
  }

  bool _supportsResponseFormat(String endpoint) =>
      endpoint.toLowerCase().contains('openai');

  bool _isRetriable(Object error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.unknown ||
          error.response?.statusCode == 429;
    }
    return false;
  }

  /// Essaie d'abord le JSON structuré, puis le format texte comme repli.
  List<AIRecommendation> _parseContent(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return const [];

    final jsonList = _extractJsonArray(trimmed);
    if (jsonList != null) {
      return jsonList
          .whereType<Map<String, dynamic>>()
          .map(AIRecommendation.fromJson)
          .toList();
    }

    return _parseFallbackText(trimmed);
  }

  List<Map<String, dynamic>>? _extractJsonArray(String content) {
    final candidates = <String>[
      content,
      // Certaines réponses OpenAI peuvent englober le JSON dans des blocs.
      _stripCodeFences(content),
    ];
    for (final candidate in candidates) {
      final start = candidate.indexOf('[');
      final end = candidate.lastIndexOf(']');
      if (start < 0 || end <= start) continue;
      final jsonStr = candidate.substring(start, end + 1);
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          return decoded
              .where((e) => e is Map)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      } catch (_) {
        // JSON invalide : on continue vers le repli.
      }
    }
    return null;
  }

  String _stripCodeFences(String content) {
    final regex = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final match = regex.firstMatch(content);
    if (match != null) return match.group(1)!.trim();
    return content;
  }

  /// Repli sur le format texte simple (une ligne par titre).
  List<AIRecommendation> _parseFallbackText(String content) {
    return content
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => AIRecommendation(
              title: _cleanTitle(line),
              reason: '',
              category: 'Film / Série',
            ))
        .toList();
  }

  String _cleanTitle(String line) {
    return line
        .replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '')
        .replaceFirst(RegExp(r'^[-*]\s*'), '')
        .replaceAll(RegExp(r'["“”]'), '')
        .trim();
  }

  String _buildPrompt(UserProfile profile, List<Movie> movies) {
    final age = DateTime.now().year - profile.dateOfBirth.year;
    final genres = profile.favoriteGenres.join(', ');

    final librarySection = movies.isEmpty
        ? 'Aucun contenu n\'est disponible dans la bibliothèque de l\'utilisateur.'
        : 'Contenu disponible dans la bibliothèque de l\'utilisateur :\n'
            '${movies.take(10).map((m) => '- ${m.title} (${m.genre})').join('\n')}';

    return '''
Tu es un assistant de recommandation de films et séries pour une application IPTV.
L'utilisateur s'appelle ${profile.firstName}, a $age ans, et aime les genres suivants : $genres.

$librarySection

Propose exactement 5 films ou séries adaptés aux goûts et à l'âge de l'utilisateur.
Si des contenus de sa bibliothèque correspondent à ses goûts, tu peux les recommander,
sinon propose des titres connus et pertinents.

Réponds UNIQUEMENT avec un tableau JSON valide (sans texte autour, sans balises), au format suivant :
[
  {
    "title": "Titre du film ou de la série",
    "reason": "Explication brève en français (1 phrase) adaptée à l'âge et aux goûts",
    "category": "Film" ou "Série",
    "rating": 8.5
  }
]
''';
  }
}
