import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';

/// Calcule le fingerprint SHA-256 d'un certificat X.509 (hex uppercase).
String _certificateSha256(X509Certificate cert) {
  final bytes = cert.der;
  final digest = sha256.convert(bytes);
  return digest.toString().toUpperCase();
}

/// Intercepteur Dio pour le certificate pinning (SHA-256).
class CertificatePinningInterceptor extends Interceptor {
  CertificatePinningInterceptor({
    required this.allowedSha256Fingerprints,
    this.logger,
  });

  final Set<String> allowedSha256Fingerprints;
  final LoggerService? logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.badCertificate) {
      logger?.error('Certificate pinning failed: ${err.message}');
      throw DioException(
        requestOptions: err.requestOptions,
        error: 'Certificate pinning validation failed: certificate not trusted',
        type: DioExceptionType.badCertificate,
      );
    }
    handler.next(err);
  }
}

/// Crée un HttpClientAdapter avec certificate pinning pour Dio.
HttpClientAdapter createPinningHttpClientAdapter({
  required Set<String> allowedFingerprints,
  LoggerService? logger,
}) {
  return _PinningHttpClientAdapter(
    allowedFingerprints: allowedFingerprints,
    logger: logger,
  );
}

/// Adapter HttpClient personnalisé avec certificate pinning.
class _PinningHttpClientAdapter implements HttpClientAdapter {
  _PinningHttpClientAdapter({
    required this.allowedFingerprints,
    this.logger,
  });

  final Set<String> allowedFingerprints;
  final LoggerService? logger;

  late final HttpClient _httpClient = HttpClient()
    ..badCertificateCallback = (X509Certificate cert, String host, int port) {
      final sha256 = _certificateSha256(cert);
      final isAllowed = allowedFingerprints.contains(sha256);
      if (!isAllowed) {
        logger?.warning(
            'Certificate pinning failed for $host:$port. '
            'Expected one of: $allowedFingerprints, got: $sha256');
        return false;
      }
      logger?.debug('Certificate pinning OK for $host: $sha256');
      return true;
    };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<dynamic>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final uri = options.uri;
    final method = options.method;
    final request = await _httpClient.openUrl(method, uri);

    // Headers
    options.headers.forEach((key, value) {
      request.headers.add(key, value.toString());
    });

    // Body
    if (options.data != null) {
      final data = options.data;
      if (data is Map) {
        request.write(jsonEncode(data));
      } else if (data is List<int>) {
        request.add(data);
      } else if (data is String) {
        request.write(data);
      }
    }

    // Stream body
    if (requestStream != null) {
      await requestStream.pipe(request);
    }

    final response = await request.close();

    // Response body
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
    }
    final headersMap = <String, List<String>>{};
    response.headers.forEach((k, v) {
      headersMap[k] = v.toList();
    });
    final headers = Headers.fromMap(headersMap);

    return ResponseBody.fromBytes(bytes, response.statusCode);
  }

  @override
  void close({bool force = false}) {
    _httpClient.close(force: force);
  }
}