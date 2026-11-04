import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
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
        'Configuration incomplète',
        'Les paramètres de cet abonnement sont manquants ou invalides.',
        [
          'Vérifiez l’URL du serveur ou de la playlist.',
          if (type == SubscriptionType.xtream)
            'Vérifiez également l’identifiant et le mot de passe.',
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
        expired ? 'Certificat SSL expiré' : 'Erreur SSL/TLS',
        expired
            ? 'Le certificat de sécurité du serveur a expiré.'
            : 'La connexion sécurisée au serveur n’a pas pu être établie.',
        [
          'Vérifiez la date et l’heure de votre appareil.',
          'Contactez votre fournisseur si le problème persiste.',
        ],
        rawError,
      );
    }

    if (_containsAny(error, [
      'socketexception',
      'failed host lookup',
      'name resolution failed',
      'dns resolution failed',
      'no address associated with hostname',
      'connection refused',
      'connection reset',
      'network unreachable',
      'no route to host',
    ])) {
      return _info(
        ConnectionErrorCategory.network,
        'Serveur inaccessible',
        'Impossible de joindre le serveur. Vérifiez l’adresse et votre connexion Internet.',
        [
          'Vérifiez l’orthographe de l’URL.',
          'Essayez depuis un autre réseau.',
          'Contactez votre fournisseur si le serveur reste inaccessible.',
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
        'Délai de réponse dépassé',
        'Le serveur n’a pas répondu à temps. Il peut être lent ou momentanément surchargé.',
        [
          'Réessayez dans quelques minutes.',
          'Vérifiez votre connexion Internet.',
        ],
        rawError,
      );
    }

    if (statusCode == 401 ||
        _containsAny(error, ['unauthorized', 'invalid credentials'])) {
      final xtream = type == SubscriptionType.xtream;
      return _info(
        ConnectionErrorCategory.invalidCredentials,
        xtream ? 'Identifiants invalides' : 'Accès refusé',
        xtream
            ? 'L’identifiant ou le mot de passe Xtream est refusé par le serveur.'
            : 'La playlist M3U nécessite une autorisation ou une URL valide.',
        [
          'Vérifiez l’identifiant et le mot de passe, en respectant les majuscules.',
          'Demandez à votre fournisseur de confirmer les informations de connexion.',
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
        'Abonnement ou compte indisponible',
        'Le compte peut être expiré, désactivé ou avoir atteint sa limite de connexions.',
        [
          'Vérifiez l’état de l’abonnement auprès de votre fournisseur.',
          'Fermez les autres appareils connectés puis réessayez.',
        ],
        rawError,
      );
    }

    if (statusCode == 403 ||
        _containsAny(error, ['forbidden', 'access denied', 'ip blocked'])) {
      return _info(
        ConnectionErrorCategory.account,
        'Accès interdit',
        'Le serveur refuse la connexion. Le compte ou l’adresse IP peut être bloqué.',
        [
          'Vérifiez que l’abonnement est toujours actif.',
          'Contactez votre fournisseur pour vérifier l’accès.',
        ],
        rawError,
      );
    }

    if (statusCode == 400 ||
        statusCode == 404 ||
        _containsAny(error, ['bad request', 'not found'])) {
      return _info(
        ConnectionErrorCategory.invalidConfiguration,
        statusCode == 404 ? 'Adresse introuvable (404)' : 'Requête invalide',
        'L’adresse du serveur ou le point d’accès ne semble pas correct.',
        [
          'Vérifiez l’URL de base du serveur ou l’URL M3U.',
          if (type == SubscriptionType.xtream)
            'Utilisez l’adresse du panel Xtream, sans ajouter player_api.php.',
        ],
        rawError,
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return _info(
        ConnectionErrorCategory.server,
        'Serveur temporairement indisponible ($statusCode)',
        'Le serveur du fournisseur rencontre un problème.',
        [
          'Réessayez dans quelques minutes.',
          'Contactez votre fournisseur si l’erreur persiste.',
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
        'Playlist M3U invalide ou vide',
        'La playlist ne contient pas de données lisibles au format attendu.',
        [
          'Vérifiez que l’URL pointe vers une playlist M3U à jour.',
          'Demandez une nouvelle URL à votre fournisseur.',
        ],
        rawError,
      );
    }

    return _info(
      ConnectionErrorCategory.unknown,
      'Échec du test de connexion',
      'Une erreur inattendue a empêché la connexion à cet abonnement.',
      [
        'Vérifiez les informations de l’abonnement et votre connexion Internet.',
        'Réessayez ou contactez votre fournisseur si le problème persiste.',
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
      r'([?&](?:username|user|password|pass|token|api_key)=)[^&\s]+',
      caseSensitive: false,
    ),
    (match) => '${match.group(1)}[masqué]',
  );
  return queryRedacted.replaceAllMapped(
    RegExp(r'(://)[^/@\s:]+:[^/@\s]+@'),
    (match) => '${match.group(1)}[masqué]@',
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
              'À vérifier',
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
              title: const Text('Détails techniques'),
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
        TextButton(
          autofocus: onRetry == null,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
        if (onRetry case final retry?)
          TvFocus(
            autofocus: true,
            onActivate: () {
              Navigator.of(context).pop();
              retry();
            },
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                retry();
              },
              child: const Text('Réessayer'),
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
      errorInfo: ConnectionErrorAnalyzer.analyze(rawError, type: type),
      onRetry: onRetry,
    ),
  );
}
