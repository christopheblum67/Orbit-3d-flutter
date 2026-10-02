import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/services/stall_detector.dart';

/// Overlay non-intrusif affichant l'état du monitoring réseau/stall/cooldown
/// pendant la lecture. Se place au-dessus du player vidéo.
class PlayerMonitoringOverlay extends ConsumerWidget {
  const PlayerMonitoringOverlay({
    super.key,
    this.onRetry,
    this.streamUrl,
  });

  final VoidCallback? onRetry;
  final String? streamUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityMonitorProvider);
    final stallDetector = ref.watch(stallDetectorProvider);
    final circuitBreaker = ref.watch(hostCircuitBreakerProvider);

    final host = streamUrl != null ? Uri.tryParse(streamUrl!)?.host : null;
    final isInCooldown = host != null && circuitBreaker.isInCooldown(host);
    final cooldownMessage =
        host != null ? circuitBreaker.cooldownMessage(host) : null;

    final showOverlay =
        !connectivity.isOnline || stallDetector.isStalling || isInCooldown;

    if (!showOverlay) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        ignoring:
            stallDetector.isStalling && connectivity.isOnline && !isInCooldown,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Container(
            key: ValueKey(
              'overlay_${connectivity.isOnline}_${stallDetector.isStalling}_$isInCooldown',
            ),
            color: Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!connectivity.isOnline)
                      _buildNetworkOfflineCard(context, ref),
                    if (stallDetector.isStalling &&
                        connectivity.isOnline &&
                        !isInCooldown)
                      _buildStallingCard(context, stallDetector.stallKind),
                    if (isInCooldown)
                      _buildCooldownCard(context, cooldownMessage!),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkOfflineCard(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return _MonitorCard(
      icon: Icons.wifi_off_rounded,
      title: l.networkDisconnected,
      message: 'Vérifiez votre connexion Internet.',
      actionLabel: 'Réessayer',
      onAction: onRetry,
      iconColor: scheme.error,
      backgroundColor: scheme.errorContainer.withValues(alpha: 0.9),
    );
  }

  Widget _buildStallingCard(BuildContext context, StallKind kind) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    // Le message nomme la CAUSE mesurée, pas une supposition. Dire
    // « connexion instable » pour un flux dont le tampon est rempli (28 s
    // relevés) alors que la position reste bloquée envoie l'utilisateur
    // debugger sa box alors que le réseau fonctionne : c'est la lecture qui
    // bloque, très souvent sur une piste trop lourde pour l'appareil.
    final (title, message) = switch (kind) {
      StallKind.notStarted => (
          l.unstableConnection,
          'Le flux est bien reçu mais la lecture ne démarre pas. '
              'La piste est peut-être trop lourde pour cet appareil.',
        ),
      StallKind.frozen => (
          l.unstableConnection,
          'Le flux est reçu mais la lecture est figée.',
        ),
      StallKind.buffering => (
          l.unstableConnection,
          'Le flux ne progresse plus. Tentative de récupération…',
        ),
      StallKind.none => (
          l.unstableConnection,
          'Le flux ne progresse plus. Tentative de récupération…',
        ),
    };
    return _MonitorCard(
      icon: Icons.wifi_tethering_rounded,
      title: title,
      message: message,
      showSpinner: true,
      iconColor: scheme.tertiary,
      backgroundColor: scheme.tertiaryContainer.withValues(alpha: 0.9),
    );
  }

  Widget _buildCooldownCard(BuildContext context, String message) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return _MonitorCard(
      icon: Icons.security_rounded,
      title: l.serverProtectedAntiLeech,
      message: message,
      // Sans action, l'utilisateur restait bloqué 90 s(full) sans lever le
      // cooldown : le cooldown est un anti-rebond, pas une sanction.
      actionLabel: l.retry,
      onAction: onRetry,
      iconColor: scheme.error,
      backgroundColor: scheme.errorContainer.withValues(alpha: 0.9),
    );
  }
}

class _MonitorCard extends StatelessWidget {
  const _MonitorCard({
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor,
    this.backgroundColor,
    this.actionLabel,
    this.onAction,
    this.showSpinner = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color? iconColor;
  final Color? backgroundColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bgColor = backgroundColor ??
        scheme.surfaceContainerHighest.withValues(alpha: 0.95);
    final fgColor = iconColor ?? scheme.onSurface;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner)
            CircularProgressIndicator(
              color: fgColor,
              strokeWidth: 3,
            )
          else
            Icon(
              icon,
              size: 48,
              color: fgColor,
            ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: fgColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: fgColor.withValues(alpha: 0.8),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
