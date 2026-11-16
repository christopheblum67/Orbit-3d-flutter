import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class UpdateException implements Exception {
  const UpdateException(this.code);
  final String code;
}

class UpdateRelease {
  const UpdateRelease({
    required this.version,
    required this.notes,
    required this.url,
    required this.sha256,
    required this.size,
  });

  final String version;
  final String notes;
  final Uri url;
  final String sha256;
  final int size;
}

class GithubUpdateService {
  GithubUpdateService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.connectTimeout ??= const Duration(seconds: 15);
  }

  static const channel = MethodChannel('orbit/update');
  static const assetName = 'orbit-3d-universal.apk';
  static const maxBytes = 1024 * 1024 * 1024;
  static final _releaseUri = Uri.https(
    'api.github.com',
    '/repos/christopheblum67/Orbit-3d-flutter/releases/latest',
  );
  static const _downloadHosts = {
    'github.com',
    'release-assets.githubusercontent.com',
    'objects.githubusercontent.com',
    'github-releases.githubusercontent.com',
  };
  final Dio _dio;

  Future<UpdateRelease?> check() async {
    final info = await channel.invokeMapMethod<String, dynamic>('version');
    final version = info?['versionName'];
    final build = info?['versionCode'];
    if (version is! String || build is! int) {
      throw const UpdateException('installed_version');
    }
    final response = await _dio.getUri<dynamic>(
      _releaseUri,
      options: Options(
        headers: {'Accept': 'application/vnd.github+json'},
        validateStatus: (_) => true,
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
    if (response.statusCode == 404) {
      throw const UpdateException('no_release');
    }
    if (response.statusCode != 200) throw const UpdateException('network');
    return parseRelease(response.data, version, build);
  }

  static UpdateRelease? parseRelease(
    dynamic data,
    String currentVersion,
    int currentBuild,
  ) {
    if (data is! Map || data['tag_name'] is! String) {
      throw const UpdateException('invalid_release');
    }
    final tag = data['tag_name'] as String;
    final current = _Version.parse(currentVersion);
    final latest = _Version.parse(tag);
    if (current == null || latest == null) {
      throw const UpdateException('invalid_version');
    }
    final comparison = latest.compareTo(current);
    if (comparison < 0 ||
        (comparison == 0 &&
            (latest.build == null || latest.build! <= currentBuild))) {
      return null;
    }
    final assets = data['assets'];
    if (assets is! List) throw const UpdateException('missing_asset');
    final matches = assets.where((a) => a is Map && a['name'] == assetName);
    if (matches.length != 1) throw const UpdateException('missing_asset');
    final asset = matches.single as Map;
    final rawUrl = asset['browser_download_url'];
    final digest = asset['digest'];
    final size = asset['size'];
    if (rawUrl is! String ||
        digest is! String ||
        !RegExp(r'^sha256:[0-9a-fA-F]{64}$').hasMatch(digest) ||
        size is! int ||
        size <= 0 ||
        size > maxBytes) {
      throw const UpdateException('invalid_asset');
    }
    final uri = Uri.tryParse(rawUrl);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'github.com' ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        !uri.path.startsWith(
          '/christopheblum67/Orbit-3d-flutter/releases/download/',
        )) {
      throw const UpdateException('invalid_asset');
    }
    return UpdateRelease(
      version: tag,
      notes: data['body'] is String ? data['body'] as String : '',
      url: uri,
      sha256: digest.substring(7).toLowerCase(),
      size: size,
    );
  }

  Future<void> download(
      UpdateRelease release, void Function(double) progress) async {
    final directory =
        Directory(path.join((await getTemporaryDirectory()).path, 'updates'));
    await directory.create(recursive: true);
    final file = File(path.join(directory.path, 'update.apk'));
    final partial = File('${file.path}.part');
    try {
      var uri = release.url;
      Response<ResponseBody>? response;
      for (var redirects = 0; redirects <= 5; redirects++) {
        if (uri.scheme != 'https' ||
            !_downloadHosts.contains(uri.host) ||
            uri.userInfo.isNotEmpty ||
            uri.hasPort) {
          throw const UpdateException('invalid_asset');
        }
        response = await _dio.getUri<ResponseBody>(
          uri,
          options: Options(
            responseType: ResponseType.stream,
            followRedirects: false,
            validateStatus: (_) => true,
            receiveTimeout: const Duration(seconds: 30),
          ),
        );
        if (response.statusCode == 200) break;
        final body = response.data;
        if (body != null) await body.stream.listen((_) {}).cancel();
        if (response.statusCode != 301 &&
            response.statusCode != 302 &&
            response.statusCode != 303 &&
            response.statusCode != 307 &&
            response.statusCode != 308) {
          throw const UpdateException('download');
        }
        final location = response.headers.value('location');
        if (location == null) throw const UpdateException('download');
        uri = uri.resolve(location);
        response = null;
      }
      if (response?.statusCode != 200 || response?.data == null) {
        throw const UpdateException('download');
      }
      final sink = partial.openWrite();
      var received = 0;
      try {
        await for (final chunk in response!.data!.stream) {
          received += chunk.length;
          if (received > release.size || received > maxBytes) {
            throw const UpdateException('download');
          }
          sink.add(chunk);
          progress(received / release.size);
        }
      } finally {
        await sink.close();
      }
      if (received != release.size ||
          (await sha256.bind(partial.openRead()).first).toString() !=
              release.sha256) {
        throw const UpdateException('integrity');
      }
      if (await file.exists()) await file.delete();
      await partial.rename(file.path);
    } finally {
      if (await partial.exists()) await partial.delete();
    }
  }

  Future<bool> install(UpdateRelease release) async {
    final result = await channel
        .invokeMethod<bool>('install', {'version': release.version});
    if (result == null) throw const UpdateException('installer_unavailable');
    return result;
  }
}

class _Version {
  const _Version(this.parts, this.build);
  final List<int> parts;
  final int? build;

  static _Version? parse(String value) {
    final match =
        RegExp(r'^v?(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?$').firstMatch(value.trim());
    if (match == null) return null;
    final parts = [for (var i = 1; i <= 3; i++) int.tryParse(match[i]!)];
    if (parts.any((part) => part == null)) return null;
    final build = match[4] == null ? null : int.tryParse(match[4]!);
    if (match[4] != null && build == null) return null;
    return _Version(parts.cast<int>(), build);
  }

  int compareTo(_Version other) {
    for (var i = 0; i < 3; i++) {
      final comparison = parts[i].compareTo(other.parts[i]);
      if (comparison != 0) return comparison;
    }
    return 0;
  }
}
