import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:orbit_3d_flutter/services/hls_manifest_rewriter.dart';
import 'package:orbit_3d_flutter/services/http_byte_range.dart';
import 'package:orbit_3d_flutter/services/video_disk_cache.dart';

/// Relais HTTP local à durée de vie explicite. Les URL distantes et les
/// identifiants restent dans le registre en mémoire, jamais dans l'URL locale.
class LocalVideoProxy {
  LocalVideoProxy({this.onError, this.cache});

  final void Function()? onError;
  final VideoDiskCache? cache;
  final _client = HttpClient()..autoUncompress = false;
  final _random = Random.secure();
  final _resources = <String, _ProxyResource>{};
  HttpServer? _server;
  bool _closed = false;
  bool _capturing = false;
  final _pendingStores = <Future<void>>{};
  final _pendingCleanup = <Future<void>>{};
  Future<void>? _closing;

  Future<void> start() async {
    if (_closed) throw StateError('Proxy arrêté');
    if (_server != null) return;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    if (_closed || _server != null) {
      await server.close(force: true);
      return;
    }
    _server = server;
    server.listen(_handle, onError: (Object _) => onError?.call());
  }

  /// La session doit être libérée dès que le lecteur ne l'utilise plus.
  LocalVideoProxySession openSession(Uri uri,
      {Map<String, String> headers = const {}}) {
    if (_server == null || _closed) throw StateError('Proxy non démarré');
    _validateTarget(uri);
    final session =
        LocalVideoProxySession._(this, uri, Map.unmodifiable(headers));
    session.url = _register(session, uri);
    return session;
  }

  Uri _register(LocalVideoProxySession session, Uri target) {
    _validateTarget(target);
    if (session._closed) throw StateError('Session proxy fermée');
    // Réutiliser les identifiants limite la croissance lors des rechargements HLS.
    final existing = session._tokens[target];
    if (existing != null) return _localUri(existing, target);
    if (session._tokens.length >= 8192) {
      throw StateError('Limite de ressources HLS atteinte');
    }
    final token = base64Url
        .encode(List<int>.generate(24, (_) => _random.nextInt(256)))
        .replaceAll('=', '');
    _resources[token] = _ProxyResource(session, target);
    session._tokens[target] = token;
    return _localUri(token, target);
  }

  Uri _localUri(String token, Uri target) {
    // Media3 peut déduire le type de média de l'extension.
    final suffix = target.path.toLowerCase().endsWith('.m3u8') ? '.m3u8' : '';
    return Uri(
        scheme: 'http',
        host: '127.0.0.1',
        port: _server!.port,
        path: '/$token$suffix');
  }

  void _validateTarget(Uri uri) {
    final host = uri.host.toLowerCase();
    final address = InternetAddress.tryParse(host);
    final isLoopback = host == 'localhost' ||
        host.endsWith('.localhost') ||
        (address?.isLoopback ?? false);
    if ((uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        (isLoopback && uri.port == _server?.port)) {
      throw ArgumentError('URL de flux non prise en charge');
    }
  }

  Future<void> _handle(HttpRequest request) async {
    var started = false;
    HttpClientResponse? upstream;
    try {
      if (request.method != 'GET' && request.method != 'HEAD') {
        request.response.statusCode = HttpStatus.methodNotAllowed;
        await request.response.close();
        return;
      }
      final path = request.uri.path;
      final token = path.startsWith('/')
          ? path.substring(1).replaceFirst(RegExp(r'\.m3u8$'), '')
          : '';
      final resource = _resources[token];
      if (resource == null ||
          resource.session._closed ||
          request.uri.hasQuery) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      final cacheKey = '$token\n${request.headers.value('accept') ?? ''}';
      if (await _serveCached(request, resource, cacheKey)) return;
      if (resource.session._closed || _closed) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      var target = resource.target;
      for (var redirects = 0;; redirects++) {
        _validateTarget(target);
        final outgoing = await _client.openUrl(request.method, target);
        outgoing.followRedirects = false;
        outgoing.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
        final sameOrigin = _sameOrigin(resource.session.origin, target);
        for (final entry in resource.session.headers.entries) {
          final name = entry.key.toLowerCase();
          if (_forbiddenRequestHeaders.contains(name) ||
              (!sameOrigin && _sensitiveHeaders.contains(name))) {
            continue;
          }
          outgoing.headers.set(name, entry.value);
        }
        for (final name in _forwardRequestHeaders) {
          final values = request.headers[name];
          if (values != null) outgoing.headers.set(name, values);
        }
        upstream = await outgoing.close();
        final location = upstream.headers.value(HttpHeaders.locationHeader);
        if (_redirectStatuses.contains(upstream.statusCode) &&
            location != null) {
          if (redirects >= 5) throw const HttpException('Trop de redirections');
          await upstream.drain<void>();
          final next = target.resolve(location);
          if (target.scheme == 'https' && next.scheme != 'https') {
            throw const HttpException('Redirection HTTPS non sécurisée');
          }
          target = next;
          continue;
        }
        break;
      }

      final response = request.response;
      final contentType = upstream.headers.contentType?.mimeType.toLowerCase();
      if (contentType == 'application/dash+xml' ||
          target.path.toLowerCase().endsWith('.mpd')) {
        await upstream.drain<void>();
        throw const FormatException('Manifeste DASH non pris en charge');
      }
      final isManifest = target.path.toLowerCase().endsWith('.m3u8') ||
          contentType == 'application/vnd.apple.mpegurl' ||
          contentType == 'application/x-mpegurl' ||
          contentType == 'audio/mpegurl' ||
          contentType == 'audio/x-mpegurl';
      if (isManifest &&
          request.method == 'GET' &&
          upstream.statusCode == HttpStatus.partialContent) {
        throw const FormatException('Manifeste HLS partiel');
      }
      if (isManifest &&
          request.method == 'GET' &&
          upstream.statusCode == HttpStatus.ok) {
        if (upstream.headers.value(HttpHeaders.contentEncodingHeader) != null &&
            upstream.headers.value(HttpHeaders.contentEncodingHeader) !=
                'identity') {
          throw const FormatException(
              'Manifeste HLS compressé non pris en charge');
        }
        final bytes = <int>[];
        await for (final chunk in upstream) {
          if (bytes.length + chunk.length > 4 * 1024 * 1024) {
            throw const FormatException('Manifeste HLS trop volumineux');
          }
          bytes.addAll(chunk);
        }
        final manifest = utf8.decode(bytes);
        final rewritten = rewriteHlsManifest(
          manifest,
          target,
          (uri) => _register(resource.session, uri),
        );
        final result = utf8.encode(rewritten);
        response.statusCode = HttpStatus.ok;
        response.headers.contentType =
            ContentType('application', 'vnd.apple.mpegurl');
        response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
        response.contentLength = result.length;
        started = true;
        response.add(result);
        await response.close();
        return;
      }
      response.statusCode = upstream.statusCode;
      final connectionHeaders = (upstream.headers.value('connection') ?? '')
          .split(',')
          .map((value) => value.trim().toLowerCase())
          .toSet();
      upstream.headers.forEach((name, values) {
        if (!_hopByHopHeaders.contains(name.toLowerCase()) &&
            !connectionHeaders.contains(name.toLowerCase())) {
          for (final value in values) {
            response.headers.add(name, value);
          }
        }
      });
      started = true;
      if (request.method == 'HEAD') {
        await upstream.drain<void>();
        await response.close();
      } else {
        final lifetime = _cacheLifetime(request, resource, target, upstream);
        if (cache != null && lifetime != null && !_capturing) {
          _capturing = true;
          final cacheGeneration = cache!.generation;
          final resourceVersion = resource.session._versions[cacheKey] ?? 0;
          final bytes = BytesBuilder(copy: false);
          var storing = false;
          try {
            final body = upstream.map((chunk) {
              if (bytes.length + chunk.length <= upstream!.contentLength) {
                bytes.add(chunk);
              } else {
                throw const FormatException('Réponse plus longue que prévu');
              }
              return chunk;
            });
            await body.pipe(response);
            if (bytes.length == upstream.contentLength &&
                !resource.session._closed &&
                !_closed) {
              final data = bytes.takeBytes();
              final store = _store(
                  cacheKey,
                  data,
                  lifetime,
                  upstream.headers.value('content-type'),
                  resource,
                  cacheGeneration,
                  resourceVersion);
              _pendingStores.add(store);
              storing = true;
              unawaited(store.whenComplete(() {
                _pendingStores.remove(store);
                _capturing = false;
              }));
            }
          } finally {
            if (!storing) _capturing = false;
          }
        } else {
          await upstream.pipe(response);
        }
      }
    } catch (_) {
      // Ne pas journaliser l'exception : elle peut contenir l'URL et ses secrets.
      onError?.call();
      try {
        if (!started) request.response.statusCode = HttpStatus.badGateway;
        await request.response.close();
      } catch (_) {
        onError?.call();
      }
    }
  }

  Future<void> _store(
      String key,
      Uint8List data,
      DateTime expires,
      String? contentType,
      _ProxyResource resource,
      int generation,
      int resourceVersion) async {
    try {
      resource.session._storedKeys.add(key);
      final stored = await cache!.store(key, Stream.value(data),
          contentLength: data.length, expectedGeneration: generation);
      if (stored &&
          !resource.session._closed &&
          !_closed &&
          (resource.session._versions[key] ?? 0) == resourceVersion) {
        resource.session._cached[key] =
            _CachedResponse(expires, contentType, generation);
      }
    } catch (_) {
      onError?.call();
    }
  }

  Future<bool> _serveCached(
      HttpRequest request, _ProxyResource resource, String key) async {
    final metadata = resource.session._cached[key];
    if (request.headers.value('cache-control') != null ||
        request.headers.value('pragma') != null ||
        request.headers.value('if-range') != null ||
        request.headers.value('if-none-match') != null ||
        request.headers.value('if-modified-since') != null ||
        request.headers.value('if-match') != null ||
        request.headers.value('if-unmodified-since') != null) {
      resource.session._cached.remove(key);
      resource.session._versions[key] =
          (resource.session._versions[key] ?? 0) + 1;
      return false;
    }
    if (cache == null ||
        metadata == null ||
        metadata.generation != cache!.generation ||
        !DateTime.now().toUtc().isBefore(metadata.expires)) {
      return false;
    }
    final range = request.headers.value('range');
    final version = resource.session._versions[key] ?? 0;
    final generation = cache!.generation;
    var responseStarted = false;
    try {
      final served = await cache!.withEntry<bool>(key, (file) async {
        if (resource.session._closed ||
            _closed ||
            cache!.generation != generation ||
            (resource.session._versions[key] ?? 0) != version ||
            resource.session._cached[key] != metadata ||
            !DateTime.now().toUtc().isBefore(metadata.expires)) {
          return false;
        }
        final size = await file.length();
        if (resource.session._closed ||
            _closed ||
            cache!.generation != generation ||
            (resource.session._versions[key] ?? 0) != version ||
            resource.session._cached[key] != metadata ||
            !DateTime.now().toUtc().isBefore(metadata.expires)) {
          return false;
        }
        final parsed = range == null ? null : parseHttpByteRange(range, size);
        if (parsed is UnsupportedByteRange) return false;
        final response = request.response;
        responseStarted = true;
        response.headers.set('accept-ranges', 'bytes');
        if (metadata.contentType != null) {
          response.headers.set('content-type', metadata.contentType!);
        }
        response.headers.set('cache-control', 'no-store');
        if (parsed is UnsatisfiableByteRange) {
          response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
          response.headers.set('content-range', 'bytes */$size');
          await response.close();
          return true;
        }
        if (parsed is HttpByteRange) {
          response.statusCode = HttpStatus.partialContent;
          response.headers.set(
              'content-range', 'bytes ${parsed.start}-${parsed.end}/$size');
          response.contentLength = parsed.length;
          if (request.method == 'GET') {
            await response
                .addStream(file.openRead(parsed.start, parsed.end + 1));
          }
        } else {
          response.contentLength = size;
          if (request.method == 'GET') {
            await response.addStream(file.openRead());
          }
        }
        await response.close();
        return true;
      });
      return served ?? false;
    } catch (_) {
      onError?.call();
      if (!responseStarted) return false;
      try {
        await request.response.close();
      } catch (_) {
        onError?.call();
      }
      return true;
    }
  }

  DateTime? _cacheLifetime(HttpRequest request, _ProxyResource resource,
      Uri target, HttpClientResponse response) {
    if (request.method != 'GET' ||
        request.headers.value('range') != null ||
        request.headers.value('cache-control') != null ||
        request.headers.value('pragma') != null ||
        request.headers.value('if-none-match') != null ||
        request.headers.value('if-modified-since') != null ||
        request.headers.value('if-range') != null ||
        request.headers.value('if-match') != null ||
        request.headers.value('if-unmodified-since') != null ||
        response.statusCode != HttpStatus.ok ||
        response.contentLength <= 0 ||
        response.contentLength > 1024 * 1024 ||
        response.headers.value('vary') != null ||
        response.headers.value('set-cookie') != null ||
        response.headers.value('content-encoding') != null ||
        response.headers.value('content-range') != null ||
        resource.session.headers.keys.any((name) =>
            _sensitiveHeaders.contains(name.toLowerCase()) ||
            name.toLowerCase() == 'cache-control') ||
        !RegExp(r'\.(ts|m4s|mp4|mkv|aac|mp3|vtt)$', caseSensitive: false)
            .hasMatch(target.path)) return null;
    final directives = (response.headers.value('cache-control') ?? '')
        .toLowerCase()
        .split(',')
        .map((part) => part.trim())
        .toList();
    if (!directives.contains('public')) return null;
    int? maxAge;
    for (final directive in directives) {
      if (directive == 'public' || directive == 'immutable') continue;
      final match = RegExp(r'^max-age=(\d+)$').firstMatch(directive);
      if (match == null || maxAge != null) return null;
      maxAge = int.tryParse(match[1]!);
    }
    if (maxAge == null || maxAge <= 0) return null;
    final date = response.headers.date;
    if (date == null) return null;
    final ageValue = response.headers.value('age');
    final age = ageValue == null ? 0 : int.tryParse(ageValue);
    if (age == null || age < 0) return null;
    final now = DateTime.now().toUtc();
    final apparentAge = now.difference(date.toUtc()).inSeconds;
    final currentAge = max(age, max(0, apparentAge));
    if (currentAge >= maxAge) return null;
    return now.add(Duration(seconds: min(maxAge - currentAge, 86400)));
  }

  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    _closed = true;
    for (final session in _resources.values.map((r) => r.session).toSet()) {
      session.close();
    }
    await _server?.close(force: true);
    _server = null;
    _client.close(force: true);
    await Future.wait(_pendingStores.toList());
    await Future.wait(_pendingCleanup.toList());
  }

  void _cleanupSession(Set<String> keys) {
    if (cache == null || keys.isEmpty) return;
    final future = cache!.removeEntries(keys).catchError((Object _) {
      onError?.call();
    });
    _pendingCleanup.add(future);
    unawaited(future.whenComplete(() => _pendingCleanup.remove(future)));
  }
}

class LocalVideoProxySession {
  LocalVideoProxySession._(this._proxy, this.origin, this.headers);

  final LocalVideoProxy _proxy;
  final Uri origin;
  final Map<String, String> headers;
  final _tokens = <Uri, String>{};
  final _cached = <String, _CachedResponse>{};
  final _versions = <String, int>{};
  final _storedKeys = <String>{};
  late final Uri url;
  bool _closed = false;

  void close() {
    if (_closed) return;
    _closed = true;
    for (final token in _tokens.values) {
      _proxy._resources.remove(token);
    }
    _tokens.clear();
    _cached.clear();
    _versions.clear();
    _proxy._cleanupSession(_storedKeys);
    _storedKeys.clear();
  }
}

class _CachedResponse {
  const _CachedResponse(this.expires, this.contentType, this.generation);
  final DateTime expires;
  final String? contentType;
  final int generation;
}

class _ProxyResource {
  const _ProxyResource(this.session, this.target);
  final LocalVideoProxySession session;
  final Uri target;
}

bool _sameOrigin(Uri a, Uri b) =>
    a.scheme == b.scheme && a.host == b.host && a.port == b.port;

const _redirectStatuses = {301, 302, 303, 307, 308};
const _sensitiveHeaders = {'authorization', 'cookie', 'proxy-authorization'};
const _hopByHopHeaders = {
  'connection',
  'keep-alive',
  'proxy-authenticate',
  'proxy-authorization',
  'te',
  'trailer',
  'transfer-encoding',
  'upgrade',
};
const _forbiddenRequestHeaders = {
  ..._hopByHopHeaders,
  'host',
  'content-length',
  'accept-encoding',
};
const _forwardRequestHeaders = {
  'range',
  'if-range',
  'if-none-match',
  'if-modified-since',
  'if-match',
  'if-unmodified-since',
  'cache-control',
  'pragma',
  'accept',
};
