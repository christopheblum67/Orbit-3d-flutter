import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_profile.dart';

class AiService {
  final Dio _dio = Dio();

  Future<List<String>> getRecommendations(UserProfile profile) async {
    final apiKey = dotenv.env['IA_API_KEY'];
    final endpoint = dotenv.env['IA_API_ENDPOINT'] ?? 'https://api.openai.com/v1/chat/completions';

    if (apiKey == null || apiKey.isEmpty) {
      return ['Veuillez configurer votre clé API IA dans .env'];
    }

    final prompt = '''
Tu es un assistant de recommandation de films et séries. L'utilisateur s'appelle ${profile.firstName}, a ${DateTime.now().year - profile.dateOfBirth.year} ans, et aime les genres suivants : ${profile.favoriteGenres.join(', ')}.
Propose 5 films ou séries adaptés à ses goûts, avec un titre et une brève explication.
''';

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
          {'role': 'user', 'content': prompt}
        ],
      },
    );

    final content = response.data['choices'][0]['message']['content'] as String;
    return content.split('\n').where((line) => line.trim().isNotEmpty).toList();
  }
}
