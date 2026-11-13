import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/services/api_service.dart';
import 'package:orbit_3d_flutter/services/stream_helpers.dart';

class _Api extends ApiService {
  _Api(this.response);
  final Future<Response<dynamic>> Function(String) response;

  @override
  Future<Response<dynamic>> get(String url) => response(url);
}

void main() {
  Subscription subscription({String url = 'https://example.test'}) =>
      Subscription(
        id: 'one',
        name: 'Test',
        type: SubscriptionType.xtream,
        baseUrl: url,
        username: 'user',
        password: 'pass',
        createdAt: DateTime(2026),
      );

  test('detects an Xtream authentication rejection', () async {
    final api = _Api((url) async {
      final uri = Uri.parse(url);
      expect(uri.path, '/player_api.php');
      expect(uri.queryParameters['username'], 'user');
      expect(uri.queryParameters['password'], 'pass');
      return Response(
        requestOptions: RequestOptions(path: url),
        data: {
          'user_info': {'auth': 0}
        },
      );
    });
    expect(await api.isXtreamConfigurationInvalid(subscription()), isTrue);
    expect(
      await api.isXtreamConfigurationInvalid(subscription(url: 'not a url')),
      isTrue,
    );
  });

  test('does not mistake successful or ambiguous responses for rejection',
      () async {
    for (final data in [
      {
        'user_info': {'auth': 1}
      },
      {'unexpected': 'response'},
      '<html>security check</html>',
    ]) {
      final api = _Api((url) async => Response(
            requestOptions: RequestOptions(path: url),
            data: data,
          ));
      expect(await api.isXtreamConfigurationInvalid(subscription()), isFalse);
    }
  });

  test('distinguishes connection or configuration failures from server errors',
      () async {
    for (final status in [401, 403, 404, 429, 500]) {
      final api = _Api((url) async {
        final options = RequestOptions(path: url);
        throw StreamNetworkException(
          'error',
          original: DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: options, statusCode: status),
          ),
        );
      });
      expect(await api.isXtreamConfigurationInvalid(subscription()),
          status == 401 || status == 403 || status == 404);
    }
    for (final type in [
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
    ]) {
      final api = _Api((url) async => throw DioException(
            requestOptions: RequestOptions(path: url),
            type: type,
          ));
      expect(await api.isXtreamConfigurationInvalid(subscription()),
          type == DioExceptionType.connectionError);
    }
  });
}
