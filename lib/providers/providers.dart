export 'package:orbit_3d_flutter/services/epg_data_cache.dart';
export 'package:orbit_3d_flutter/services/replay_cache.dart';
export 'metadata_providers.dart';
export 'subtitle_providers.dart';
export 'epg_fallback_budget_provider.dart';
export 'refresh_state_providers.dart';
export 'search_providers.dart';
export 'replay_providers.dart';
export 'download_providers.dart';
export 'enrichment_providers.dart';
export 'catchup_providers.dart';
export 'epg_providers.dart';
export 'catalog_providers.dart';
export 'core_providers.dart';
export 'profile_type_provider.dart';
export 'content_filter_provider.dart';
export 'subscription_provider.dart';

class StreamAiException implements Exception {
  const StreamAiException(this.message);

  final String message;

  @override
  String toString() => message;
}
