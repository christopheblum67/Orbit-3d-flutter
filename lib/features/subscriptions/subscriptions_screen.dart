import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/features/startup/refresh_progress_screen.dart';
import 'package:orbit_3d_flutter/features/subscriptions/widgets/connection_error_dialog.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/subscription_provider.dart';
import 'package:orbit_3d_flutter/services/xtream_url_builder.dart';

bool _sameSubscriptionSource(Subscription a, Subscription b) {
  if (a.id == b.id || a.type != b.type) return false;
  final aUrl = a.type == SubscriptionType.xtream
      ? XtreamUrlBuilder.trimBaseUrl(a.baseUrl ?? '')
      : (a.m3uUrl ?? '').trim();
  final bUrl = b.type == SubscriptionType.xtream
      ? XtreamUrlBuilder.trimBaseUrl(b.baseUrl ?? '')
      : (b.m3uUrl ?? '').trim();
  final uri = Uri.tryParse(aUrl);
  if (aUrl != bUrl ||
      uri == null ||
      !['http', 'https'].contains(uri.scheme) ||
      uri.host.isEmpty) {
    return false;
  }
  if (a.type == SubscriptionType.m3u) return true;
  return a.username != null &&
      a.username!.trim().isNotEmpty &&
      a.password != null &&
      a.password!.isNotEmpty &&
      a.username == b.username &&
      a.password == b.password;
}

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() =>
      _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  bool _refreshing = false;

  Future<void> _forceRefresh() async {
    if (_refreshing || ref.read(activeSubscriptionProvider) == null) return;
    setState(() => _refreshing = true);
    try {
      final result = await showRefreshProgress(context);
      if (!mounted || result == null) return;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            result ? l.subscriptionRefreshSuccess : l.subscriptionRefreshFailed,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final subs = ref.watch(subscriptionsProvider);
    final activeId = ref.watch(activeSubscriptionProvider)?.id;
    final duplicateIds = <String>{
      for (final sub in subs)
        if (subs.any((other) => _sameSubscriptionSource(sub, other))) sub.id,
    };
    final connectionError =
        GoRouterState.of(context).uri.queryParameters['connectionError'] == '1';

    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: l.profileBack,
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(l.subscriptionTitle),
        actions: [
          IconButton(
            tooltip: l.addSubscription,
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddSubscriptionDialog(context),
          ),
        ],
      ),
      body: subs.isEmpty
          ? _EmptyState(
              onAdd: () => _showAddSubscriptionDialog(context),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (connectionError) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l.subscriptionConnectionHelp,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const _CategoryFilterInfoBanner(),
                const SizedBox(height: 12),
                if (duplicateIds.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.content_copy_rounded),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(l.subscriptionDuplicateHelp),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Align(
                  alignment: Alignment.center,
                  child: OutlinedButton.icon(
                    onPressed:
                        activeId == null || _refreshing ? null : _forceRefresh,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      l.subscriptionRefreshActive,
                      textAlign: TextAlign.center,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (activeId == null)
                  _NoActiveBanner(
                    onAdd: () => _showAddSubscriptionDialog(context),
                  ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 44,
                  runSpacing: 40,
                  children: _buildSubCards(
                      context, ref, subs, activeId, duplicateIds),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildSubCards(
    BuildContext context,
    WidgetRef ref,
    List<Subscription> subs,
    String? activeId,
    Set<String> duplicateIds,
  ) {
    return [
      for (var index = 0; index < subs.length; index++) ...[
        Builder(
          builder: (_) {
            final sub = subs[index];
            final isActive = sub.id == activeId;
            return _SubscriptionCard(
              subscription: sub,
              isActive: isActive,
              isPossibleDuplicate: duplicateIds.contains(sub.id),
              onTap: () async {
                if (!isActive) {
                  await _activateSubscription(sub);
                }
              },
              onTest: () =>
                  ref.read(subscriptionsProvider.notifier).testConnection(sub),
              onEdit: () => _showEditSubscriptionDialog(context, ref, sub),
              onDelete: () => _confirmDelete(context, ref, sub),
            );
          },
        ),
      ],
    ];
  }

  Future<void> _activateSubscription(Subscription sub) async {
    try {
      await ref.read(subscriptionsProvider.notifier).setActive(sub.id);
      if (mounted) context.go('/startup');
    } catch (e, st) {
      LoggerService.instance.error(
        'SubscriptionsScreen.activateSubscription failed',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context).subscriptionActivationFailed),
          ),
        );
      }
    }
  }

  Future<void> _showAddSubscriptionDialog(BuildContext context) async {
    final added = await showDialog<Subscription>(
      context: context,
      builder: (_) => const _SubscriptionFormDialog(),
    );
    if (!context.mounted || added == null) return;
    final activate = await showDialog<bool>(
      context: context,
      builder: (_) => _AddedSubscriptionDialog(subscription: added),
    );
    if (activate == true && mounted) await _activateSubscription(added);
  }

  void _showEditSubscriptionDialog(
    BuildContext context,
    WidgetRef ref,
    Subscription sub,
  ) {
    showDialog(
      context: context,
      builder: (_) => _SubscriptionFormDialog(
        subscription: sub,
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Subscription sub,
  ) async {
    final cancelFocus = FocusNode();
    final confirmFocus = FocusNode();

    void requestFocus(FocusNode focus) {
      if (mounted) {
        FocusScope.of(context).requestFocus(focus);
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx).subscriptionDeleteTitle),
        content:
            Text(AppLocalizations.of(ctx).subscriptionDeleteHelp(sub.name)),
        actions: [
          Focus(
            focusNode: cancelFocus,
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.select ||
                      event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                Navigator.pop(ctx);
                return KeyEventResult.handled;
              }
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                      event.logicalKey == LogicalKeyboardKey.arrowLeft)) {
                requestFocus(confirmFocus);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(ctx).cancel),
            ),
          ),
          Focus(
            focusNode: confirmFocus,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.select ||
                      event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
                ref
                    .read(subscriptionsProvider.notifier)
                    .deleteSubscription(sub.id);
                Navigator.pop(ctx);
                return KeyEventResult.handled;
              }
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                      event.logicalKey == LogicalKeyboardKey.arrowLeft)) {
                requestFocus(cancelFocus);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              onPressed: () {
                ref
                    .read(subscriptionsProvider.notifier)
                    .deleteSubscription(sub.id);
                Navigator.pop(ctx);
              },
              child: Text(AppLocalizations.of(ctx).profileDelete),
            ),
          ),
        ],
      ),
    );
    cancelFocus.dispose();
    confirmFocus.dispose();
  }
}

class _NoActiveBanner extends StatelessWidget {
  final VoidCallback onAdd;

  const _NoActiveBanner({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.secondary.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: scheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l.subscriptionNoActive,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l.subscriptionActivate),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primaryContainer.withValues(alpha: 0.5),
              ),
              child: Icon(
                Icons.subscriptions_outlined,
                size: 48,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l.subscriptionNone,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l.subscriptionEmptyHelp,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: Text(l.addSubscription),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterInfoBanner extends StatelessWidget {
  const _CategoryFilterInfoBanner();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.secondary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: scheme.secondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l.subscriptionFilterHelp,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends ConsumerWidget {
  final Subscription subscription;
  final bool isActive;
  final bool isPossibleDuplicate;
  final VoidCallback onTap;
  final Future<void> Function() onTest;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubscriptionCard({
    required this.subscription,
    required this.isActive,
    required this.isPossibleDuplicate,
    required this.onTap,
    required this.onTest,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isTesting = ref.watch(subscriptionsTestingProvider).contains(
          subscription.id,
        );
    final isXtream = subscription.type == SubscriptionType.xtream;
    final status = subscription.lastTestResult;
    final ok = status == TestResultStatus.success;
    final resultColor = ok ? Colors.green : scheme.error;
    final latency = subscription.lastTestLatencyMs;
    final resultText = isTesting
        ? l.subscriptionTesting
        : status == TestResultStatus.untested
            ? l.subscriptionUntested
            : ok
                ? (latency == null
                    ? l.subscriptionTestOk
                    : l.subscriptionTestLatency(latency))
                : l.subscriptionTestFailed;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.5),
        border:
            Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TvFocus(
            onActivate: onTap,
            child: GestureDetector(
              onTap: onTap,
              child: Semantics(
                button: true,
                label: '${l.subscriptionSemantic(subscription.name)}'
                    '${isActive ? ', ${l.subscriptionSemanticActive}' : ''}'
                    '${isPossibleDuplicate ? ', ${l.subscriptionSemanticDuplicate}' : ''}',
                child: Container(
                  width: 240,
                  height: 240,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? scheme.primaryContainer.withValues(alpha: 0.35)
                        : scheme.surfaceContainerLow,
                    border: Border.all(
                      color: isActive
                          ? scheme.primary
                          : scheme.outlineVariant.withValues(alpha: 0.6),
                      width: isActive ? 3 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isActive ? scheme.primary : Colors.black)
                            .withValues(alpha: isActive ? 0.4 : 0.25),
                        blurRadius: isActive ? 22 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isXtream ? Icons.dns_rounded : Icons.playlist_play,
                        size: 30,
                        color: scheme.primary,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isXtream ? 'XTREAM' : 'M3U',
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          if (isPossibleDuplicate) ...[
                            const SizedBox(width: 6),
                            Tooltip(
                              message: l.subscriptionPossibleDuplicate,
                              child: const Icon(Icons.content_copy_rounded,
                                  size: 18),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subscription.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _host(l, subscription),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (isActive)
                        const _ActiveBadge()
                      else
                        Text(
                          l.subscriptionInactive,
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isTesting)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if (status != TestResultStatus.untested)
                            Icon(
                              ok ? Icons.check_circle : Icons.error,
                              size: 16,
                              color: resultColor,
                            ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              resultText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: status == TestResultStatus.untested ||
                                        isTesting
                                    ? scheme.onSurfaceVariant
                                    : resultColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: l.subscriptionTestAction,
                icon: const Icon(Icons.wifi_find),
                onPressed:
                    isTesting ? null : () => _testWithErrorDialog(context, ref),
              ),
              IconButton(
                tooltip: l.profileEdit,
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: l.profileDelete,
                icon: const Icon(Icons.delete),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Seul l'hôte est affiché : une URL M3U ou Xtream peut contenir des
  /// identifiants.
  String _host(AppLocalizations l, Subscription sub) {
    final raw = sub.type == SubscriptionType.xtream ? sub.baseUrl : sub.m3uUrl;
    if (raw == null || raw.isEmpty) return l.subscriptionIncomplete;
    final host = Uri.tryParse(raw)?.host ?? '';
    return host.isEmpty ? l.subscriptionIncomplete : host;
  }

  Future<void> _testWithErrorDialog(BuildContext context, WidgetRef ref) async {
    await onTest();
    if (!context.mounted) return;

    final matches = ref
        .read(subscriptionsProvider)
        .where((item) => item.id == subscription.id);
    final updatedSubscription = matches.isEmpty ? null : matches.first;
    final error = updatedSubscription?.lastTestError;
    if (updatedSubscription?.lastTestResult != TestResultStatus.error ||
        error == null ||
        error.isEmpty) {
      return;
    }

    await showConnectionErrorDialog(
      context,
      error,
      type: subscription.type,
      onRetry: () => _testWithErrorDialog(context, ref),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
      ),
      child: Text(
        AppLocalizations.of(context).profileActive.toUpperCase(),
        style: TextStyle(
          color: scheme.onPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _AddedSubscriptionDialog extends ConsumerStatefulWidget {
  const _AddedSubscriptionDialog({required this.subscription});

  final Subscription subscription;

  @override
  ConsumerState<_AddedSubscriptionDialog> createState() =>
      _AddedSubscriptionDialogState();
}

class _AddedSubscriptionDialogState
    extends ConsumerState<_AddedSubscriptionDialog> {
  bool _testing = false;
  String? _result;
  final _testFocus = FocusNode();
  final _activateFocus = FocusNode();
  final _cancelFocus = FocusNode();

  @override
  void dispose() {
    _testFocus.dispose();
    _activateFocus.dispose();
    _cancelFocus.dispose();
    super.dispose();
  }

  KeyEventResult _handleNavigation(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_testFocus.hasFocus) {
        (_testing ? _cancelFocus : _activateFocus).requestFocus();
      } else if (_activateFocus.hasFocus) {
        _cancelFocus.requestFocus();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_cancelFocus.hasFocus) {
        (_testing ? _testFocus : _activateFocus).requestFocus();
      } else if (_activateFocus.hasFocus) {
        _testFocus.requestFocus();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _test() async {
    if (_testing) return;
    setState(() {
      _testing = true;
      _result = null;
    });
    try {
      await ref.read(subscriptionsProvider.notifier).testConnection(
            widget.subscription,
          );
      if (!mounted) return;
      final updated = ref
          .read(subscriptionsProvider)
          .where((sub) => sub.id == widget.subscription.id)
          .firstOrNull;
      final l = AppLocalizations.of(context);
      final message = switch (updated?.lastTestResult) {
        TestResultStatus.success => l.subscriptionTestSuccess,
        TestResultStatus.error => ConnectionErrorAnalyzer.analyze(
            updated?.lastTestError ?? '',
            type: widget.subscription.type,
            l: l,
          ).message,
        _ => l.subscriptionTestUnavailable,
      };
      setState(() => _result = message);
    } catch (e, st) {
      LoggerService.instance.error(
        'AddedSubscriptionDialog.test failed',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        final l = AppLocalizations.of(context);
        setState(() => _result = l.subscriptionTestError);
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.subscriptionAdded),
      content: SingleChildScrollView(
        child: Focus(
          canRequestFocus: false,
          onKeyEvent: _handleNavigation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.subscriptionAddedHelp(widget.subscription.name)),
              if (_testing || _result != null) ...[
                const SizedBox(height: 16),
                Text(_testing ? l.subscriptionTestRunning : _result!),
              ],
              const SizedBox(height: 16),
              TvFocus(
                autofocus: true,
                focusNode: _testFocus,
                onActivate: _testing ? null : _test,
                child: ExcludeFocus(
                  child: OutlinedButton(
                    onPressed: _testing ? null : _test,
                    child: Text(l.subscriptionTestAction),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TvFocus(
                focusNode: _activateFocus,
                onActivate:
                    _testing ? null : () => Navigator.pop(context, true),
                child: ExcludeFocus(
                  child: FilledButton(
                    onPressed:
                        _testing ? null : () => Navigator.pop(context, true),
                    child: Text(l.subscriptionActivate),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TvFocus(
                focusNode: _cancelFocus,
                onActivate: () => Navigator.pop(context, false),
                child: ExcludeFocus(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l.cancel),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionFormDialog extends ConsumerStatefulWidget {
  final Subscription? subscription;

  const _SubscriptionFormDialog({this.subscription});

  @override
  ConsumerState<_SubscriptionFormDialog> createState() =>
      _SubscriptionFormDialogState();
}

class _SubscriptionFormDialogState
    extends ConsumerState<_SubscriptionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _m3uUrlController = TextEditingController();
  final _nameFocus = FocusNode();
  final _baseUrlFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _m3uFocus = FocusNode();
  final _submitFocus = FocusNode();
  final _typeKey = GlobalKey();
  late final Map<FocusNode, GlobalKey> _fieldKeys;
  SubscriptionType _type = SubscriptionType.xtream;
  bool _obscurePassword = false;
  bool _saving = false;
  FocusNode? _editingFocus;
  double _keyboardInset = 0;

  @override
  void initState() {
    super.initState();
    if (widget.subscription != null) {
      final sub = widget.subscription!;
      _nameController.text = sub.name;
      _type = sub.type;
      _baseUrlController.text = sub.baseUrl ?? '';
      _usernameController.text = sub.username ?? '';
      _passwordController.text = sub.password ?? '';
      _m3uUrlController.text = sub.m3uUrl ?? '';
    }
    _fieldKeys = {
      for (final focus in [
        _nameFocus,
        _baseUrlFocus,
        _usernameFocus,
        _passwordFocus,
        _m3uFocus,
      ])
        focus: GlobalKey(),
    };
    for (final focus in _fieldKeys.keys) {
      focus.onKeyEvent = _handleTextFieldKey;
      focus.addListener(() {
        if (!mounted) return;
        if (focus.hasPrimaryFocus) {
          _scheduleEnsureVisible(focus);
        } else if (!focus.hasFocus && _editingFocus == focus) {
          setState(() => _editingFocus = null);
        }
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nameFocus.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    if (inset > _keyboardInset) {
      for (final focus in _fieldKeys.keys) {
        if (focus.hasPrimaryFocus) _scheduleEnsureVisible(focus);
      }
    }
    _keyboardInset = inset;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _m3uUrlController.dispose();
    _nameFocus.dispose();
    _baseUrlFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _m3uFocus.dispose();
    _submitFocus.dispose();
    super.dispose();
  }

  void _requestFocus(FocusNode focus) {
    if (mounted) focus.requestFocus();
  }

  void _ensureVisible(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      alignment: 0.5,
      duration: const Duration(milliseconds: 120),
    );
  }

  void _scheduleEnsureVisible(FocusNode focus) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && focus.hasPrimaryFocus) {
        _ensureVisible(_fieldKeys[focus]!);
      }
    });
  }

  KeyEventResult _handleTextFieldKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final mode = ref.read(tvModeNotifierProvider);
    final key = event.logicalKey;
    if (!mode.enabled) return KeyEventResult.ignored;
    if (_editingFocus == node) {
      if (key == LogicalKeyboardKey.escape ||
          key == LogicalKeyboardKey.goBack ||
          key == LogicalKeyboardKey.gameButtonB) {
        setState(() => _editingFocus = null);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.gameButtonA) {
        SystemChannels.textInput.invokeMethod<void>('TextInput.show');
        return KeyEventResult.handled;
      }
      if (key != LogicalKeyboardKey.arrowUp &&
          key != LogicalKeyboardKey.arrowDown) {
        return KeyEventResult.ignored;
      }
      setState(() => _editingFocus = null);
    }
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      if (key == LogicalKeyboardKey.arrowDown && node == _baseUrlFocus) {
        _requestFocus(_usernameFocus);
      } else if (key == LogicalKeyboardKey.arrowDown &&
          node == _usernameFocus) {
        _requestFocus(_passwordFocus);
      } else if (key == LogicalKeyboardKey.arrowUp && node == _usernameFocus) {
        _requestFocus(_baseUrlFocus);
      } else if (key == LogicalKeyboardKey.arrowUp && node == _passwordFocus) {
        _requestFocus(_usernameFocus);
      } else if (key == LogicalKeyboardKey.arrowDown &&
          (node == _passwordFocus || node == _m3uFocus)) {
        _requestFocus(_submitFocus);
      } else {
        node.focusInDirection(
          switch (key) {
            LogicalKeyboardKey.arrowUp => TraversalDirection.up,
            LogicalKeyboardKey.arrowDown => TraversalDirection.down,
            LogicalKeyboardKey.arrowLeft => TraversalDirection.left,
            _ => TraversalDirection.right,
          },
        );
      }
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent &&
        (key == LogicalKeyboardKey.select ||
            key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.gameButtonA)) {
      setState(() => _editingFocus = node);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildTvTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required FocusNode nextFocusNode,
    required String labelText,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return ListenableBuilder(
      listenable: ref.read(tvModeNotifierProvider),
      builder: (context, _) {
        final tvMode = ref.read(tvModeNotifierProvider).enabled;
        final scheme = Theme.of(context).colorScheme;
        return TextFormField(
          key: _fieldKeys[focusNode],
          controller: controller,
          focusNode: focusNode,
          readOnly: tvMode && _editingFocus != focusNode,
          decoration: InputDecoration(
            labelText: labelText,
            suffixIcon: suffixIcon,
            border: tvMode ? const OutlineInputBorder() : null,
            focusedBorder: tvMode
                ? OutlineInputBorder(
                    borderSide: BorderSide(color: scheme.primary, width: 3),
                  )
                : null,
          ),
          keyboardType: keyboardType,
          obscureText: obscureText,
          inputFormatters: inputFormatters,
          textInputAction: TextInputAction.next,
          onTap: () {
            if (tvMode && _editingFocus != focusNode) {
              setState(() => _editingFocus = focusNode);
            }
          },
          onEditingComplete: () {
            if (_editingFocus == focusNode) {
              setState(() => _editingFocus = null);
            }
            _requestFocus(nextFocusNode);
          },
          validator: validator,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isEditing = widget.subscription != null;

    final nextAfterName =
        _type == SubscriptionType.xtream ? _baseUrlFocus : _m3uFocus;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      insetAnimationDuration: Duration.zero,
      child: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: FocusTraversalGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isEditing
                        ? l.subscriptionEditTitle
                        : l.subscriptionNewTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _buildTvTextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    nextFocusNode: nextAfterName,
                    labelText: l.subscriptionName,
                    validator: (v) => v!.isEmpty ? l.profileRequired : null,
                  ),
                  const SizedBox(height: 16),
                  Focus(
                    canRequestFocus: false,
                    onFocusChange: (focused) {
                      if (focused && ref.read(tvModeNotifierProvider).enabled) {
                        _ensureVisible(_typeKey);
                      }
                    },
                    child: SegmentedButton<SubscriptionType>(
                      key: _typeKey,
                      segments: [
                        ButtonSegment(
                          value: SubscriptionType.xtream,
                          label: Text(l.xtreamCodes),
                        ),
                        ButtonSegment(
                          value: SubscriptionType.m3u,
                          label: Text(l.m3uPlaylist),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (Set<SubscriptionType> newSelection) {
                        setState(() => _type = newSelection.first);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_type == SubscriptionType.xtream) ...[
                    _buildTvTextField(
                      controller: _baseUrlController,
                      focusNode: _baseUrlFocus,
                      nextFocusNode: _usernameFocus,
                      labelText: l.serverUrlPlaceholder,
                      validator: (v) => v!.isEmpty ? l.profileRequired : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTvTextField(
                      controller: _usernameController,
                      focusNode: _usernameFocus,
                      nextFocusNode: _passwordFocus,
                      labelText: l.subscriptionUsername,
                      validator: (v) => v!.isEmpty ? l.profileRequired : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTvTextField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      nextFocusNode: _submitFocus,
                      labelText: l.subscriptionPassword,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? l.subscriptionShowPassword
                            : l.subscriptionHidePassword,
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? l.profileRequired : null,
                    ),
                  ] else ...[
                    _buildTvTextField(
                      controller: _m3uUrlController,
                      focusNode: _m3uFocus,
                      nextFocusNode: _submitFocus,
                      labelText: l.m3uPlaylistUrl,
                      validator: (v) => v!.isEmpty ? l.profileRequired : null,
                    ),
                  ],
                  const SizedBox(height: 16),
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed:
                            _saving ? null : () => Navigator.pop(context),
                        child: Text(l.cancel),
                      ),
                      FilledButton(
                        focusNode: _submitFocus,
                        onPressed: _saving ? null : _save,
                        child: Text(
                          isEditing ? l.profileSaveAction : l.subscriptionAdd,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;
    setState(() => _saving = true);

    final id = widget.subscription?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final sub = widget.subscription?.copyWith(
          id: id,
          name: _nameController.text.trim(),
          type: _type,
          baseUrl: _type == SubscriptionType.xtream
              ? _baseUrlController.text.trim()
              : null,
          username: _type == SubscriptionType.xtream
              ? _usernameController.text.trim()
              : null,
          password: _type == SubscriptionType.xtream
              ? _passwordController.text.trim()
              : null,
          m3uUrl: _type == SubscriptionType.m3u
              ? _m3uUrlController.text.trim()
              : null,
        ) ??
        Subscription(
          id: id,
          name: _nameController.text.trim(),
          type: _type,
          baseUrl: _type == SubscriptionType.xtream
              ? _baseUrlController.text.trim()
              : null,
          username: _type == SubscriptionType.xtream
              ? _usernameController.text.trim()
              : null,
          password: _type == SubscriptionType.xtream
              ? _passwordController.text.trim()
              : null,
          m3uUrl: _type == SubscriptionType.m3u
              ? _m3uUrlController.text.trim()
              : null,
          isActive: widget.subscription?.isActive ?? false,
          createdAt: widget.subscription?.createdAt ?? DateTime.now(),
        );

    try {
      if (widget.subscription != null) {
        await ref.read(subscriptionsProvider.notifier).updateSubscription(sub);
      } else {
        await ref.read(subscriptionsProvider.notifier).addSubscription(sub);
      }
      if (mounted) Navigator.pop(context, sub);
    } catch (e, st) {
      LoggerService.instance.error(
        '_SubscriptionFormDialog._save failed',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.errorSaving}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
