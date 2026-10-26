import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';

/// Catégories d'erreurs de connexion pour diagnostic utilisateur
enum ConnectionErrorCategory {
  // Erreurs de configuration
  invalidConfig,
  missingCredentials,
  invalidUrl,

  // Erreurs réseau
  dnsResolutionFailed,
  connectionTimeout,
  connectionRefused,
  networkUnreachable,

  // Erreurs HTTP
  http400BadRequest,
  http401Unauthorized,
  http403Forbidden,
  http404NotFound,
  http500ServerError,
  http502BadGateway,
  http503ServiceUnavailable,
  http504GatewayTimeout,

  // Erreurs Xtream Codes spécifiques
  xtreamInvalidCredentials,
  xtreamExpiredSubscription,
  xtreamAccountDisabled,
  xtreamIpBlocked,
  xtreamTooManyConnections,
  xtreamServerMaintenance,

  // Erreurs M3U
  m3uEmpty,
  m3uInvalidFormat,
  m3uAccessDenied,

  // Erreurs SSL/TLS
  sslHandshakeFailed,
  sslCertificateExpired,
  sslCertificateInvalid,

  // Erreurs génériques
  unknown,
  cancelled,
}

/// Résultat de l'analyse d'erreur
class ConnectionErrorInfo {
  const ConnectionErrorInfo({
    required this.category,
    required this.title,
    required this.message,
    required this.suggestions,
    this.technicalDetails,
  });

  final ConnectionErrorCategory category;
  final String title;
  final String message;
  final List<String> suggestions;
  final String? technicalDetails;
}

/// Analyseur d'erreurs de connexion pour affichage utilisateur
class ConnectionErrorAnalyzer {
  static ConnectionErrorInfo analyze(String rawError, {required SubscriptionType type}) {
    final error = rawError.toLowerCase();

    // 1. Erreurs de configuration
    if (_matchesAny(error, [
      'configuration xtream incomplète',
      'configuration incomplète',
      'url m3u manquante',
      'url m3u invalide',
      'missing credentials',
      'invalid config',
    ])) {
      return ConnectionErrorInfo(
        category: ConnectionErrorCategory.invalidConfig,
        title: 'Configuration incomplète',
        message: 'Les paramètres de l\'abonnement sont manquants ou invalides.',
        suggestions: [
          'Vérifiez l\'URL du serveur (baseUrl pour Xtream, URL M3U pour M3U)',
          'Vérifiez identifiant et mot de passe (Xtream)',
          'Assurez-vous qu\'aucun champ obligatoire n\'est vide',
        ],
        technicalDetails: rawError,
      );
    }

    // 2. Erreurs DNS
    if (_matchesAny(error, [
      'socketexception',
      'dns resolution failed',
      'name resolution failed',
      'temporary failure in name resolution',
      'no address associated with hostname',
      'failed host lookup',
    ])) {
      return ConnectionErrorInfo(
        category: ConnectionErrorCategory.dnsResolutionFailed,
        title: 'Serveur introuvable (DNS)',
        message: 'Impossible de résoudre l\'adresse du serveur. L\'URL semble incorrecte ou le serveur n\'existe pas.',
        suggestions: [
          'Vérifiez l\'orthographe de l\'URL du serveur',
          'Testez l\'URL dans un navigateur web',
          'Vérifiez votre connexion Internet',
          'Essayez avec une autre connexion (4G, WiFi différent)',
        ],
        technicalDetails: rawError,
      );
    }

    // 3. Timeout
    if (_matchesAny(error, [
      'timeout',
      'timed out',
      'connection timed out',
      'receive timeout',
      'send timeout',
    ])) {
      return ConnectionErrorInfo(
        category: ConnectionErrorCategory.connectionTimeout,
        title: 'Délai d\'attente dépassé',
        message: 'Le serveur met trop de temps à répondre. Le réseau est peut-être lent ou le serveur surchargé.',
        suggestions: [
          'Réessayez plus tard (heures creuses)',
          'Vérifiez votre connexion Internet',
          'Essayez depuis un autre réseau',
          'Contactez votre fournisseur IPTV si le problème persiste',
        ],
        technicalDetails: rawError,
      );
    }

    // 4. Connexion refusée
    if (_matchesAny(error, [
      'connection refused',
      'connection reset',
      'connection aborted',
      'ecnconnrefused',
      'ecnconnreset',
    ])) {
      return ConnectionErrorInfo(
        category: ConnectionErrorCategory.connectionRefused,
        title: 'Connexion refusée par le serveur',
        message: 'Le serveur a rejeté la connexion. Il est peut-être hors ligne ou bloque votre IP.',
        suggestions: [
          'Vérifiez que le serveur est en ligne',
          'Essayez avec un VPN (blocage IP possible)',
          'Contactez votre fournisseur IPTV',
        ],
        technicalDetails: rawError,
      );
    }

    // 5. Réseau inaccessible
    if (_matchesAny(error, [
      'network unreachable',
      'network is unreachable',
      'no route to host',
      'enetunreach',
    ])) {
      return ConnectionErrorInfo(
        category: ConnectionErrorCategory.networkUnreachable,
        title: 'Réseau inaccessible',
        message: 'Impossible d\'atteindre le réseau du serveur. Problème de routage ou pare-feu.',
        suggestions: [
          'Vérifiez votre connexion Internet',
          'Désactivez temporairement VPN/Proxy',
          'Vérifiez les règles pare-feu/antivirus',
        ],
        technicalDetails: rawError,
      );
    }

    // 6. Erreurs HTTP spécifiques
    if (_matchesAny(error, [
      '400', 'bad request',
    ])) {
      return ConnectionErrorInfo(
        category: ConnectionErrorCategory.http400BadRequest,
        title: 'Requête invalide (400)',
        message: 'Le serveur ne comprend pas la requête. Paramètres probablement incorrects.',
        suggestions: [
          'Vérifiez l\'URL de base (baseUrl) pour Xtream',
          'Vérifiez que l\'API Xtream est bien activée sur le panel',
        ],
        technicalDetails: rawError,
      );
    }

    if (_matchesAny(error, [
      '401', 'unauthorized', 'invalid credentials', 'wrong password', 'invalid username',
    ])) {
      return ConnectionErrorInfo(
        category: type == SubscriptionType.xtream
            ? ConnectionErrorCategory.xtreamInvalidCredentials
            : ConnectionErrorCategory.http401Unauthorized,
        title: type == SubscriptionType.xtream ? 'Identifiants invalides (401)' : 'Non autorisé (401)',
        message: type == SubscriptionType.xtream
            ? 'Identifiant ou mot de passe incorrect pour ce serveur Xtream.'
            : 'Accès refusé. L\'URL M3U nécessite une authentification.',
        suggestions: [
          'Vérifiez l\'orthographe exacte de l\'identifiant et du mot de passe',
          'Attention aux majuscules/minuscules',
          'Copiez-collez depuis l\'email du fournisseur pour éviter les fautes',
          'Demandez au fournisseur de confirmer les identifiants',
        ],
        technicalDetails: rawError,
      );
    }

    if (_matchesAny(error, [
      '403', 'forbidden', 'access denied', 'ip blocked', 'banned',
    ])) {
      return ConnectionErrorInfo(
        category: ConnectionErrorCategory.http403Forbidden,
        title: 'Accès interdit (403)',
        message: 'Le serveur refuse l\'accès. Votre IP est peut-être bloquée ou le compte suspendu.',
        suggestions: [
          'Essayez avec un VPN (changement d\'IP)',
          'Contactez votre fournisseur pour débloquer votre IP',
          'Vérifiez si votre abonnement est toujours actif',
        ],
        technicalDetails: rawError,
      );
    }

    if (_matchesAny(error, [
      '404', 'not found',
    ])) {
      return ConnectionErrorInfo(
        category: ConnectionErrorCategory.http404NotFound,
        title: 'Ressource introuvable (404)',
        message: 'L\'endpoint API n\'existe pas sur ce serveur. URL de base probablement incorrecte.',
        suggestions: [
          'Vérifiez l\'URL de base (doit pointer vers la racine du panel Xtream)',
          'L\'API Xtream n\'est peut-être pas activée sur ce panel',
        ],
        technicalDetails: rawError,
      );
    }

    if (_matchesAny(error, [
      '500', 'internal server error',
    ])) {
      return ConnectionErrorInfo(
        category: ConnectionErrorCategory.http500ServerError,
        title: 'Erreur serveur (500)',
        message: 'Le serveur Xtream a rencontré une erreur interne. C\'est un problème côté fournisseur.',
        suggestions: [
          'Réessayez dans quelques minutes',
          'Contactez votre fournisseur IPTV',
        ],
        technicalDetails: rawError,
      );
    }

    if (_matchesAny(error, [
      '502', 'bad gateway',
    ])) {
      return ConnectionErrorInfo(
        category: ConnectionErrorCategory.http502BadGateway,
        title: 'Passerelle invalide (502)',
        message: 'Le serveur proxy/passerelle a reçu une réponse invalide du serveur upstream.',
        suggestions: [
          'Réessayez plus tard',
          'Problème côté fournisseur',
        ],
        technicalDetails: rawError,
      );
    }

    if (_matchesAny(error, [
      '503', 'service unavailable', 'maintenance',
    ])) {
      return ConnectionErrorInfo(
        category: ConnectionErrorCategory.http503ServiceUnavailable,
        title: 'Service indisponible (503)',
        message: 'Le serveur est temporairement indisponible (maintenance ou surcharge).',
        suggestions: [
          'Réessayez plus tard (souvent la nuit)',
          'Vérifiez les annonces du fournisseur (Telegram, email)',
        ],
        technicalDetails: rawError,
      );
    }

    if (_matchesAny(error, [
      '504', 'gateway timeout',
    ])) {
      return ConnectionErrorInfo(
        category: ConnectionErrorCategory.http504GatewayTimeout,
        title: 'Délai passerelle (504)',
        message: 'Le serveur n\'a pas répondu à temps. Surcharge ou problème réseau.',
        suggestions: [
          'Réessayez aux heures creuses',
          'Problème côté fournisseur',
        ],
        technicalDetails: rawError,
      );
    }

    // 7. Erreurs Xtream spécifiques (réponses JSON du panel)
    if (type == SubscriptionType.xtream) {
      if (_matchesAny(error, [
        'expired', 'expiré', 'subscription expired', 'account expired',
      ])) {
        return ConnectionErrorInfo(
          category: ConnectionErrorCategory.xtreamExpiredSubscription,
          title: 'Abonnement expiré',
          message: 'Votre abonnement Xtream a expiré. Il faut le renouveler auprès du fournisseur.',
          suggestions: [
            'Contactez votre fournisseur pour renouveler',
            'Vérifiez la date d\'expiration dans les détails de l\'abonnement',
          ],
          technicalDetails: rawError,
        );
      }

      if (_matchesAny(error, [
        'disabled', 'désactivé', 'banned', 'blocked', 'account disabled',
      ])) {
        return ConnectionErrorInfo(
          category: ConnectionErrorCategory.xtreamAccountDisabled,
          title: 'Compte désactivé/bloqué',
          message: 'Votre compte Xtream a été désactivé par le fournisseur.',
          suggestions: [
            'Contactez immédiatement votre fournisseur',
            'Vérifiez vos emails pour une notification',
          ],
          technicalDetails: rawError,
        );
      }

      if (_matchesAny(error, [
        'too many connections', 'max connections', 'concurrent connections', 'limit reached',
      ])) {
        return ConnectionErrorInfo(
          category: ConnectionErrorCategory.xtreamTooManyConnections,
          title: 'Trop de connexions simultanées',
          message: 'La limite de connexions simultanées est atteinte pour ce compte.',
          suggestions: [
            'Fermez l\'application sur les autres appareils',
            'Attendez quelques minutes avant de réessayer',
            'Demandez au fournisseur d\'augmenter la limite',
          ],
          technicalDetails: rawError,
        );
      }
    }

    // 8. Erreurs M3U
    if (type == SubscriptionType.m3u) {
      if (_matchesAny(error, [
        'empty', 'vide', 'no streams', 'aucune chaîne',
      ])) {
        return ConnectionErrorInfo(
          category: ConnectionErrorCategory.m3uEmpty,
          title: 'Playlist M3U vide',
          message: 'La playlist M3U ne contient aucune chaîne valide.',
          suggestions: [
            'Vérifiez que l\'URL M3U est complète et à jour',
            'Demandez une nouvelle URL au fournisseur',
          ],
          technicalDetails: rawError,
        );
      }

      if (_matchesAny(error, [
        'invalid format', 'invalid m3u', 'parse error', 'format invalide',
      ])) {
        return ConnectionErrorInfo(
          category: ConnectionErrorCategory.m3uInvalidFormat,
          title: 'Format M3U invalide',
          message: 'Le fichier M3U ne respecte pas le format standard.',
          suggestions: [
            'Vérifiez que l\'URL pointe bien vers un fichier .m3u ou .m3u8',
            'Testez l\'URL dans VLC pour valider le format',
          ],
          technicalDetails: rawError,
        );
      }
    }

    // 9. Erreurs SSL/TLS
    if (_matchesAny(error, [
      'ssl', 'tls', 'certificate', 'handshake', 'certificat',
    ])) {
      if (_matchesAny(error, [
        'expired', 'expiré',
      ])) {
        return ConnectionErrorInfo(
          category: ConnectionErrorCategory.sslCertificateExpired,
          title: 'Certificat SSL expiré',
          message: 'Le certificat de sécurité du serveur a expiré.',
          suggestions: [
            'Contactez le fournisseur pour qu\'il renouvelle son certificat',
            'En attendant, essayez l\'URL en HTTP (si dispo) — moins sécurisé',
          ],
          technicalDetails: rawError,
        );
      }

      return ConnectionErrorInfo(
        category: ConnectionErrorCategory.sslHandshakeFailed,
        title: 'Erreur SSL/TLS',
        message: 'Impossible d\'établir une connexion sécurisée avec le serveur.',
        suggestions: [
          'Essayez l\'URL en HTTP au lieu de HTTPS (si dispo)',
          'Mettez à jour l\'application / Android WebView',
          'Contactez le fournisseur pour son certificat',
        ],
        technicalDetails: rawError,
      );
    }

    // 10. Annulation utilisateur
    if (_matchesAny(error, [
      'cancelled', 'canceled', 'annulé', 'user cancelled',
    ])) {
      return ConnectionErrorInfo(
        category: ConnectionErrorCategory.cancelled,
        title: 'Test annulé',
        message: 'Le test de connexion a été interrompu.',
        suggestions: ['Réessayez si nécessaire'],
        technicalDetails: rawError,
      );
    }

    // 11. Erreur inconnue
    return ConnectionErrorInfo(
      category: ConnectionErrorCategory.unknown,
      title: 'Erreur de connexion',
      message: 'Une erreur inattendue s\'est produite lors du test de connexion.',
      suggestions: [
        'Réessayez le test',
        'Vérifiez votre connexion Internet',
        'Notez l\'erreur technique et contactez le support',
      ],
      technicalDetails: rawError,
    );
  }

  static bool _matchesAny(String error, List<String> keywords) {
    return keywords.any((k) => error.contains(k.toLowerCase()));
  }
}

/// Dialog d'erreur de connexion TV-friendly
class ConnectionErrorDialog extends ConsumerWidget {
  const ConnectionErrorDialog({
    super.key,
    required this.errorInfo,
    this.onRetry,
    this.onDismiss,
  });

  final ConnectionErrorInfo errorInfo;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: scheme.surfaceContainerHigh,
      title: Row(
        children: [
          Icon(
            _iconForCategory(errorInfo.category),
            color: scheme.error,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorInfo.title,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            errorInfo.message,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          if (errorInfo.suggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Suggestions :',
              style: TextStyle(
                color: scheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...errorInfo.suggestions.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: scheme.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
          if (errorInfo.technicalDetails != null) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              leading: Icon(Icons.bug_report, color: scheme.onSurfaceVariant, size: 20),
              title: Text(
                'Détails techniques',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    errorInfo.technicalDetails!,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Row(
            children: [
              Expanded(
                child: TvFocus(
                  autofocus: true, // "Annuler" par défaut (action sûre)
                  onActivate: onDismiss ?? () => Navigator.of(context).pop(),
                  child: TextButton(
                    onPressed: onDismiss ?? () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (onRetry != null)
                Expanded(
                  child: TvFocus(
                    onActivate: () {
                      Navigator.of(context).pop();
                      onRetry!();
                    },
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onRetry!();
                      },
                      child: const Text('Réessayer'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static IconData _iconForCategory(ConnectionErrorCategory category) {
    switch (category) {
      case ConnectionErrorCategory.invalidConfig:
      case ConnectionErrorCategory.missingCredentials:
      case ConnectionErrorCategory.invalidUrl:
        return Icons.settings_outlined;
      case ConnectionErrorCategory.dnsResolutionFailed:
        return Icons.dns_outlined;
      case ConnectionErrorCategory.connectionTimeout:
      case ConnectionErrorCategory.http504GatewayTimeout:
        return Icons.timer_outlined;
      case ConnectionErrorCategory.connectionRefused:
        return Icons.block_outlined;
      case ConnectionErrorCategory.networkUnreachable:
        return Icons.wifi_off_outlined;
      case ConnectionErrorCategory.http400BadRequest:
      case ConnectionErrorCategory.http404NotFound:
        return Icons.error_outline;
      case ConnectionErrorCategory.http401Unauthorized:
      case ConnectionErrorCategory.xtreamInvalidCredentials:
        return Icons.lock_outline;
      case ConnectionErrorCategory.http403Forbidden:
      case ConnectionErrorCategory.xtreamAccountDisabled:
        return Icons.lock_outline;
      case ConnectionErrorCategory.http500ServerError:
      case ConnectionErrorCategory.http502BadGateway:
      case ConnectionErrorCategory.http503ServiceUnavailable:
      case ConnectionErrorCategory.xtreamServerMaintenance:
        return Icons.cloud_off_outlined;
      case ConnectionErrorCategory.xtreamExpiredSubscription:
        return Icons.event_busy_outlined;
      case ConnectionErrorCategory.xtreamIpBlocked:
        return Icons.block_outlined;
      case ConnectionErrorCategory.xtreamTooManyConnections:
        return Icons.people_outline;
      case ConnectionErrorCategory.m3uEmpty:
      case ConnectionErrorCategory.m3uInvalidFormat:
      case ConnectionErrorCategory.m3uAccessDenied:
        return Icons.playlist_remove_outlined;
      case ConnectionErrorCategory.sslHandshakeFailed:
      case ConnectionErrorCategory.sslCertificateExpired:
      case ConnectionErrorCategory.sslCertificateInvalid:
        return Icons.security_outlined;
      case ConnectionErrorCategory.cancelled:
        return Icons.cancel_outlined;
      default:
        return Icons.error_outline;
    }
  }
}

/// Helper pour afficher le dialog d'erreur après un test échoué
Future<void> showConnectionErrorDialog(
  BuildContext context,
  String rawError, {
  required SubscriptionType type,
  VoidCallback? onRetry,
}) {
  final errorInfo = ConnectionErrorAnalyzer.analyze(rawError, type: type);
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => ConnectionErrorDialog(
      errorInfo: errorInfo,
      onRetry: onRetry,
    ),
  );
}