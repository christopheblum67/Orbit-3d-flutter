import 'package:flutter/material.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';

class VideoErrorState extends StatelessWidget {
  const VideoErrorState({
    super.key,
    this.title = 'Flux indisponible',
    this.message = 'Impossible de lancer cette chaîne. '
        'Vérifie ton abonnement ou réessaie.',
    this.onRetry,
    this.onCloudflare,
    this.cloudflareMessage,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  /// Action lancée pour débloquer un flux protégé par un challenge Cloudflare
  /// (cf_clearance) via un WebView.
  final VoidCallback? onCloudflare;
  final String? cloudflareMessage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.tertiaryContainer, scheme.errorContainer],
                  ),
                ),
                child: Icon(
                  Icons.live_tv_rounded,
                  size: 44,
                  color: scheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Réessayer'),
                ),
              ],
              if (onCloudflare != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onCloudflare,
                  icon: const Icon(Icons.security_rounded),
                  label: const Text('Débloquer (Cloudflare)'),
                ),
                if (cloudflareMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    cloudflareMessage!,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
