import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/widgets/error_action_focus.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';

enum ConnectionErrorCategory {
  invalidConfiguration,
  invalidCredentials,
  network,
  timeout,
  server,
  account,
  playlist,
  security,
  unknown,
}

class ConnectionErrorInfo {
  const ConnectionErrorInfo({
    required this.category,
    required this.title,
    required this.message,
    required this.suggestions,
    required this.technicalDetails,
  });

  final ConnectionErrorCategory category;
  final String title;
  final String message;
  final List<String> suggestions;
  final String technicalDetails;
}

class ConnectionErrorAnalyzer {
  const ConnectionErrorAnalyzer._();

  static ConnectionErrorInfo analyze(
    String rawError, {
    required SubscriptionType type,
    required AppLocalizations l,
  }) {
    final error = rawError.toLowerCase();
    final statusCode = _httpStatusCode(error);

    if (_containsAny(error, [
      'configuration xtream incomplète',
      'configuration incomplete',
      'url m3u manquante',
      'url m3u invalide',
      'missing credentials',
      'invalid config',
    ])) {
      return _info(
        ConnectionErrorCategory.invalidConfiguration,
        l.subscriptionIncomplete,
        l.connectionInvalidConfiguration,
        [
          l.connectionCheckServerOrPlaylist,
          if (type == SubscriptionType.xtream) l.connectionCheckCredentials,
        ],
        rawError,
      );
    }

    if (_containsAny(error, [
      'ssl',
      'tls',
      'certificate',
      'certificat',
      'handshake',
    ])) {
      final expired = _containsAny(error, ['expired', 'expiré']);
      return _info(
        ConnectionErrorCategory.security,
        expired ? l.connectionCertificateExpired : l.connectionSslError,
        expired ? l.connectionCertificateExpiredHelp : l.connectionSslHelp,
        [
          l.connectionCheckDateTime,
          l.connectionContactProvider,
        ],
        rawError,
      );
    }

    if (_containsAny(error, [
      'failed host lookup',
      'name resolution failed',
      'dns resolution failed',
      'temporary failure in name resolution',
      'no address associated with hostname',
    ])) {
      return _info(
        ConnectionErrorCategory.network,
        l.connectionDnsFailure,
        l.connectionDnsFailureHelp,
        [
          l.connectionCheckUrl,
          l.connectionCheckInternet,
          l.connectionTryAnotherNetwork,
        ],
        rawError,
      );
    }

    if (_containsAny(error, [
      'network unreachable',
      'network is unreachable',
      'no route to host',
      'enetunreach',
    ])) {
      return _info(
        ConnectionErrorCategory.network,
        l.connectionNetworkUnavailable,
        l.connectionNetworkUnavailableHelp,
        [
          l.connectionCheckInternet,
          l.connectionTryAnotherNetwork,
        ],
        rawError,
      );
    }

    if (_containsAny(error, [
      'connection refused',
      'connection reset',
      'connection aborted',
      'ecnconnrefused',
      'ecnconnreset',
      'econnrefused',
      'econnreset',
    ])) {
      return _info(
        ConnectionErrorCategory.network,
        l.connectionServerUnreachable,
        l.connectionServerUnreachableHelp,
        [
          l.connectionCheckUrl,
          l.connectionTryAnotherNetwork,
          l.connectionContactUnreachableProvider,
        ],
        rawError,
      );
    }

    if (_containsAny(error, [
      'timeout',
      'timed out',
      'délai d’attente',
    ])) {
      return _info(
        ConnectionErrorCategory.timeout,
        l.connectionTimeout,
        l.connectionTimeoutHelp,
        [
          l.connectionTryLater,
          l.connectionCheckInternet,
        ],
        rawError,
      );
    }

    if (error.contains('socketexception')) {
      return _info(
        ConnectionErrorCategory.network,
        l.connectionServerUnreachable,
        l.connectionServerUnreachableHelp,
        [
          l.connectionCheckUrl,
          l.connectionTryAnotherNetwork,
          l.connectionContactUnreachableProvider,
        ],
        rawError,
      );
    }

    if (statusCode == 401 ||
        _containsAny(error, ['unauthorized', 'invalid credentials'])) {
      final xtream = type == SubscriptionType.xtream;
      return _info(
        ConnectionErrorCategory.invalidCredentials,
        xtream ? l.connectionInvalidCredentials : l.connectionAccessDenied,
        xtream ? l.connectionXtreamRejected : l.connectionM3uAuthorization,
        [
          l.connectionCheckCredentialsCase,
          l.connectionConfirmCredentials,
        ],
        rawError,
      );
    }

    if (_containsAny(error, [
      'expired',
      'expiré',
      'account disabled',
      'disabled',
      'désactivé',
      'too many connections',
      'max connections',
      'concurrent connections',
    ])) {
      return _info(
        ConnectionErrorCategory.account,
        l.connectionAccountUnavailable,
        l.connectionAccountUnavailableHelp,
        [
          l.connectionCheckSubscription,
          l.connectionCloseOtherDevices,
        ],
        rawError,
      );
    }

    if (statusCode == 403 ||
        _containsAny(error, ['forbidden', 'access denied', 'ip blocked'])) {
      return _info(
        ConnectionErrorCategory.account,
        l.connectionForbidden,
        l.connectionForbiddenHelp,
        [
          l.connectionCheckActiveSubscription,
          l.connectionCheckProviderAccess,
        ],
        rawError,
      );
    }

    if (statusCode == 400 ||
        statusCode == 404 ||
        _containsAny(error, ['bad request', 'not found'])) {
      return _info(
        ConnectionErrorCategory.invalidConfiguration,
        statusCode == 404 ? l.connectionNotFound : l.connectionInvalidRequest,
        l.connectionInvalidAddress,
        [
          l.connectionCheckBaseUrl,
          if (type == SubscriptionType.xtream) l.connectionUseXtreamPanel,
        ],
        rawError,
      );
    }

    if ((statusCode != null && statusCode >= 500) ||
        _containsAny(error, [
          'maintenance',
          'service unavailable',
          'bad gateway',
          'internal server error',
        ])) {
      return _info(
        ConnectionErrorCategory.server,
        statusCode == null
            ? l.connectionServerError
            : l.connectionServerUnavailable(statusCode),
        l.connectionServerProblem,
        [
          l.connectionTryLater,
          l.connectionContactProvider,
        ],
        rawError,
      );
    }

    if (type == SubscriptionType.m3u &&
        _containsAny(error, [
          'empty',
          'vide',
          'no streams',
          'invalid m3u',
          'invalid format',
          'parse error',
        ])) {
      return _info(
        ConnectionErrorCategory.playlist,
        l.connectionInvalidPlaylist,
        l.connectionInvalidPlaylistHelp,
        [
          l.connectionCheckPlaylistUrl,
          l.connectionRequestNewUrl,
        ],
        rawError,
      );
    }

    return _info(
      ConnectionErrorCategory.unknown,
      l.connectionTestFailed,
      l.connectionUnexpectedError,
      [
        l.connectionCheckSubscriptionAndInternet,
        l.connectionRetryOrContact,
      ],
      rawError,
    );
  }

  static ConnectionErrorInfo _info(
    ConnectionErrorCategory category,
    String title,
    String message,
    List<String> suggestions,
    String rawError,
  ) {
    return ConnectionErrorInfo(
      category: category,
      title: title,
      message: message,
      suggestions: suggestions,
      technicalDetails: redactConnectionError(rawError),
    );
  }

  static bool _containsAny(String text, List<String> needles) =>
      needles.any(text.contains);

  static int? _httpStatusCode(String error) {
    final match = RegExp(
      r'(?:status(?:\s+code)?|http(?:\s+error)?)[\s:=]*(4\d\d|5\d\d)',
    ).firstMatch(error);
    return match == null ? null : int.tryParse(match.group(1)!);
  }
}

String redactConnectionError(String error) {
  final queryRedacted = error.replaceAllMapped(
    RegExp(
      r'([?&](?:username|user|login|password|pass|token|api_key)=)[^&\s]+',
      caseSensitive: false,
    ),
    (match) => '${match.group(1)}[masqué]',
  );
  final authorityRedacted = queryRedacted.replaceAllMapped(
    RegExp(r'(://)[^/@\s:]+:[^/@\s]+@'),
    (match) => '${match.group(1)}[masqué]@',
  );
  return authorityRedacted.replaceAllMapped(
    RegExp(r'(/(?:live|movie|series)/)[^/\s?#]+/[^/\s?#]+/', caseSensitive: false),
    (match) => '${match.group(1)}[masqué]/[masqué]/',
  );
}

class ConnectionErrorDialog extends StatelessWidget {
  const ConnectionErrorDialog({
    super.key,
    required this.errorInfo,
    this.onRetry,
  });

  final ConnectionErrorInfo errorInfo;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final icon = switch (errorInfo.category) {
      ConnectionErrorCategory.invalidConfiguration => Icons.settings_outlined,
      ConnectionErrorCategory.invalidCredentials ||
      ConnectionErrorCategory.account =>
        Icons.lock_outline,
      ConnectionErrorCategory.network => Icons.wifi_off_outlined,
      ConnectionErrorCategory.timeout => Icons.timer_outlined,
      ConnectionErrorCategory.server => Icons.cloud_off_outlined,
      ConnectionErrorCategory.playlist => Icons.playlist_remove_outlined,
      ConnectionErrorCategory.security => Icons.security_outlined,
      ConnectionErrorCategory.unknown => Icons.error_outline,
    };

    return AlertDialog(
      backgroundColor: scheme.surfaceContainerHigh,
      title: Row(
        children: [
          Icon(icon, color: scheme.error, size: 26),
          const SizedBox(width: 12),
          Expanded(child: Text(errorInfo.title)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(errorInfo.message),
            const SizedBox(height: 16),
            Text(
              l.connectionThingsToCheck,
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (final suggestion in errorInfo.suggestions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_forward, size: 16, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(suggestion)),
                  ],
                ),
              ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              leading: const Icon(Icons.bug_report_outlined),
              title: Text(l.connectionTechnicalDetails),
              children: [
                SelectableText(
                  errorInfo.technicalDetails,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        ErrorActionFocus(
          autofocus: onRetry == null,
          builder: (context, focusNode) => TextButton(
            focusNode: focusNode,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.close),
          ),
        ),
        if (onRetry case final retry?)
          ErrorActionFocus(
            autofocus: true,
            builder: (context, focusNode) => FilledButton(
              focusNode: focusNode,
              onPressed: () {
                Navigator.of(context).pop();
                retry();
              },
              child: Text(l.retry),
            ),
          ),
      ],
    );
  }
}

Future<void> showConnectionErrorDialog(
  BuildContext context,
  String rawError, {
  required SubscriptionType type,
  VoidCallback? onRetry,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => ConnectionErrorDialog(
      errorInfo: ConnectionErrorAnalyzer.analyze(
        rawError,
        type: type,
        l: AppLocalizations.of(context),
      ),
      onRetry: onRetry,
    ),
  );
}
