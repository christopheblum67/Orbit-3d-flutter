import 'dart:convert';

import 'package:orbit_3d_flutter/services/stream_helpers.dart';

/// Adresses du proxy Rust local. Alignées sur le défaut du proxy côté Rust :
/// `config.rs` → `listen_addr = "127.0.0.1:8787"`.
const String kRustProxyHost = '127.0.0.1';
const int kRustProxyPort = 8787;
const String kRustProxyBase = 'http://127.0.0.1:8787';
const String kRustProxyStatusPath = '/api/proxy-status';

/// Seul le flux du serveur « draap.online » est relayé par le proxy local
/// (le CDN signé derrière est protégé par Cloudflare). Extensible par
/// suffixe : `live.draap.online`, `stream.draap.online`, … sont aussi
/// concernés.
const String kRelayHost = 'draap.online';

/// `true` si [url] doit être relayée par le proxy local quand il est prêt.
bool isRelayCandidate(String url) {
  if (!isLikelyStreamUrl(url)) return false;
  final host = Uri.tryParse(url)?.host;
  if (host == null || host.isEmpty) return false;
  return host == kRelayHost || host.endsWith('.$kRelayHost');
}

/// Hash déterministe (16 hex) utilisé dans les URLs réécrites
/// `/hls/<hash>/<fichier>`. La forme miroir `build_proxy_url` côté Rust
/// (hls.rs → `UrlRegistry::hash_url`). L'autorité d'une URL reste le
/// registre du serveur (renseigné à la réécriture des manifests) : ce hash
/// côté client sert de clé stable et documentaire, pas de résolution.
String proxyHashFor(String url) {
  const fnvPrime = 1099511628211; // FNV-1a 64-bit prime.
  const fnvOffsetBasis = -3750763034362895579; // 0xcbf29ce484222325 (signé).
  var hash = fnvOffsetBasis;
  for (final byte in utf8.encode(url)) {
    hash ^= byte;
    hash *= fnvPrime; // Débordement 64 bits volontaire (wrap VM).
  }
  return BigInt.from(hash).toUnsigned(64).toRadixString(16).padLeft(16, '0');
}

/// Dernier segment du chemin (nom de fichier) d'une URL, comme côté Rust
/// (`UrlRegistry::filename`). Retourne `'segment'` si indéterminable.
String proxyFilename(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return 'segment';
  final trimmed = uri.path.replaceAll(RegExp(r'/+$'), '');
  final segments = trimmed.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return 'segment';
  return segments.last;
}

/// Construit l'URL réécrite par le proxy : `{proxyBase}/hls/<hash>/<fichier>`.
/// Miroir exact de `hls::build_proxy_url` côté Rust. Utilisée par le serveur
/// quand il réécrit un manifest ; côté client elle documente la forme des
/// liens que le player suivra ensuite.
String buildProxyUrl(String originalUrl, {String proxyBase = kRustProxyBase}) {
  final hash = proxyHashFor(originalUrl);
  final filename = proxyFilename(originalUrl);
  return '${proxyBase.replaceAll(RegExp(r'/$'), '')}/hls/$hash/$filename';
}

/// URL « d'entrée » du proxy pour une URL originale donnée.
///
/// Le proxy ne connaît une URL qu'UNE FOIS qu'elle est enregistrée dans son
/// `UrlRegistry` (cela arrive lors de la réécriture d'un manifest). La
/// première requête depuis l'app ne peut donc PAS être `/hls/<hash>/…` (elle
/// répondrait 404) : elle passe par un endpoint d'entrée qui enregistre
/// ensuite tous les enfants réécrits :
///   - manifest HLS/DASH (`*.m3u8`, `*.mpd`) → `/proxy/hls?url=…` (réécrit) ;
///   - segment (`*.ts`, `*.m4s`, audio, subs) → `/proxy/segment?url=…`
///     (cache LRU + Range requests) ;
///   - média générique (`*.mp4`, `*.mkv`, …) → `/proxy/stream?url=…`
///     (passthrough streamé).
String relayUrlFor(String originalUrl, {String proxyBase = kRustProxyBase}) {
  final uri = Uri.tryParse(originalUrl);
  final path = (uri?.path ?? originalUrl).toLowerCase();
  final String endpoint;
  if (path.endsWith('.m3u8') ||
      path.endsWith('.m3u') ||
      path.endsWith('.mpd') ||
      path.endsWith('.xml')) {
    endpoint = '/proxy/hls';
  } else if (path.endsWith('.ts') ||
      path.endsWith('.m4s') ||
      path.endsWith('.mp4') ||
      path.endsWith('.aac') ||
      path.endsWith('.mp3') ||
      path.endsWith('.vtt')) {
    endpoint = '/proxy/segment';
  } else {
    endpoint = '/proxy/stream';
  }
  final base = Uri.parse(proxyBase);
  return base.replace(
    path: endpoint,
    queryParameters: <String, String>{'url': originalUrl},
  ).toString();
}

/// Rebâse [originalUrl] via le proxy local si (et seulement si) :
///   - le proxy est prêt ([proxyReady]),
///   - l'URL est un flux valide (`isLikelyStreamUrl`),
///   - son hôte matche [relayHost] (défaut `draap.online`).
///
/// Renvoie TOUJOURS une URL utilisable (l'originale dans tous les cas où on
/// ne relaye pas) : jamais de `null`, jamais de double-relais (une URL déjà
/// sur 127.0.0.1 n'est pas un candidat).
String maybeRebaseThroughProxy(
  String originalUrl, {
  required bool proxyReady,
  String proxyBase = kRustProxyBase,
  String relayHost = kRelayHost,
}) {
  if (!proxyReady) return originalUrl;
  if (!isLikelyStreamUrl(originalUrl)) return originalUrl;
  final host = Uri.tryParse(originalUrl)?.host;
  if (host == null || host.isEmpty) return originalUrl;
  if (host != relayHost && !host.endsWith('.$relayHost')) {
    return originalUrl;
  }
  return relayUrlFor(originalUrl, proxyBase: proxyBase);
}
