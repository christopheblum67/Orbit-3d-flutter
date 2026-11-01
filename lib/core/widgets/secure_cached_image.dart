import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_3d_flutter/core/widgets/orbit_cached_image.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// Image réseau sécurisée : injecte automatiquement les en-têtes Cloudflare
/// (cf_clearance, User-Agent, etc.) dans la requête, pour contourner les 403
/// sur les posters/bannières hébergés sur le panel IPTV protégé.
///
/// À utiliser à la place de [OrbitCachedImage] / [CachedImage] pour toutes
/// les images provenant du panel IPTV.
class SecureCachedImage extends ConsumerWidget {
  const SecureCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, Object)? errorWidget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Map<String, String>? headers;
    try {
      headers = ref.read(cloudflareSessionProvider).videoHeaders;
    } catch (_) {
      headers = null;
    }
    return OrbitCachedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      httpHeaders: headers,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}
