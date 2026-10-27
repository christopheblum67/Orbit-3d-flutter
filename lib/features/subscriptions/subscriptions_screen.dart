import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/utils/logger_service.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
import 'package:orbit_3d_flutter/core/widgets/orbit_logo_icon.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_dropdown.dart';
import 'package:orbit_3d_flutter/core/widgets/tv_focus.dart';
import 'package:orbit_3d_flutter/features/subscriptions/widgets/connection_error_dialog.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/subscription_provider.dart';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() =>
      _SubscriptionsScreenState();
}

/// Message d'information : réglages de filtres disponibles dans paramètres > abonnement.
class _FilterInfoBanner extends StatelessWidget {
  const _FilterInfoBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Réglages de filtres disponibles dans Paramètres > Abonnement.',
              style: TextStyle(color: Colors.amber.shade700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final subs = ref.watch(subscriptionsProvider);
    final activeId = ref.watch(activeSubscriptionProvider)?.id;

    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Retour',
                    onPressed: () => context.pop(),
                  ),
                  TvFocus(
                    onActivate: () => _showAddSubscriptionDialog(context, ref),
                    child: IconButton(
                      tooltip: l.addSubscription,
                      icon: const Icon(Icons.add_rounded),
                      onPressed: () => _showAddSubscriptionDialog(context, ref),
                    ),
                  ),
                ],
              )
            : TvFocus(
                onActivate: () => _showAddSubscriptionDialog(context, ref),
                child: IconButton(
                  tooltip: l.addSubscription,
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => _showAddSubscriptionDialog(context, ref),
                ),
              ),
        title: const Text('Abonnements'),
        actions: [],
      ),
      body: subs.isEmpty
          ? _EmptyState(
              onAdd: () => _showAddSubscriptionDialog(context, ref),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (activeId == null)
                  _NoActiveBanner(
                    onAdd: () => _showAddSubscriptionDialog(context, ref),
                  ),
                ..._buildSubCards(context, ref, subs, activeId),
              ],
            ),
    );
  }

  List<Widget> _buildSubCards(
    BuildContext context,
    WidgetRef ref,
    List<Subscription> subs,
    String? activeId,
  ) {
    return [
      for (var index = 0; index < subs.length; index++) ...[
        if (index > 0) const SizedBox(height: 12),
        Builder(
          builder: (_) {
            final sub = subs[index];
            final isActive = sub.id == activeId;
            return _SubscriptionCard(
              subscription: sub,
              isActive: isActive,
              onTap: () async {
                if (!isActive) {
                  await ref
                      .read(subscriptionsProvider.notifier)
                      .setActive(sub.id);
                  if (!context.mounted) return;
                  // Régénère complètement les flux (catalogue, EPG, replays)
                  // via l'écran de démarrage, comme au lancement de l'app :
                  // après la bascule on arrive sur l'accueil avec les données
                  // du nouvel abonnement.
                  context.go('/startup');
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

  void _showAddSubscriptionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _SubscriptionFormDialog(
        onSaved: () => ref.invalidate(subscriptionsProvider),
      ),
    );
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
        onSaved: () => ref.invalidate(subscriptionsProvider),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Subscription sub,) async {
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
        title: const Text('Supprimer l\'abonnement ?'),
        content: Text(
          'Voulez-vous supprimer "${sub.name}" ? Cette action est irréversible.',
        ),
        actions: [
          Focus(
            focusNode: cancelFocus,
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
              child: const Text('Annuler'),
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
              child: const Text('Supprimer'),
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
              'Aucun abonnement actif. Sélectionnez-en un ou ajoutez-en un nouveau.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          TvFocus(
            onActivate: onAdd,
            child: TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Activer'),
              onPressed: onAdd,
            ),
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OrbitLogoIcon(size: 100),
            const SizedBox(height: 20),
            Text(
              'Aucun abonnement',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez votre premier abonnement Xtream Codes ou M3U pour commencer.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            TvFocus(
              onActivate: onAdd,
              child: FilledButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Ajouter'),
                onPressed: onAdd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionCard extends ConsumerWidget {
  final Subscription subscription;
  final bool isActive;
  final VoidCallback onTap;
  final Future<void> Function() onTest;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubscriptionCard({
    required this.subscription,
    required this.isActive,
    required this.onTap,
    required this.onTest,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final isTesting = _isTesting(ref, subscription.id);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      color: isActive ? scheme.primaryContainer.withValues(alpha: 0.3) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type badge + ACTIF badge stacked vertically
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TypeBadge(type: subscription.type),
                  if (isActive) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                      ),
                      child: Text(
                        'ACTIF',
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(subscription),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    !isActive
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: TvFocus(
                              onActivate: onTap,
                              child: IconButton(
                                tooltip: l.setAsDefaultServer,
                                icon: const Icon(Icons.star_outline, size: 20),
                                color: scheme.onSurfaceVariant,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                onPressed: onTap,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TvFocus(
                    onActivate: onEdit,
                    child: IconButton(
                      tooltip: 'Modifier',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: onEdit,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TvFocus(
                    onActivate: onDelete,
                    child: IconButton(
                      tooltip: 'Supprimer',
                      icon: const Icon(Icons.delete_outlined),
                      color: Theme.of(context).colorScheme.error,
                      onPressed: onDelete,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TestResultRow(
            subscription: subscription,
            isTesting: isTesting,
            onTest: onTest,
          ),
        ],
      ),
    );
  }

  bool _isTesting(WidgetRef ref, String id) {
    return ref.watch(subscriptionsTestingProvider).contains(id);
  }

  String _subtitle(Subscription sub) {
    if (sub.type == SubscriptionType.xtream) {
      return sub.baseUrl ?? 'Configuration incomplète';
    }
    return sub.m3uUrl ?? 'Configuration incomplète';
  }
}

class _TypeBadge extends StatelessWidget {
  final SubscriptionType type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: type == SubscriptionType.xtream
            ? scheme.secondaryContainer
            : scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
      ),
      child: Text(
        type == SubscriptionType.xtream ? 'XTREAM' : 'M3U',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: type == SubscriptionType.xtream
              ? scheme.onSecondaryContainer
              : scheme.onTertiaryContainer,
        ),
      ),
    );
  }
}

class _TestResultRow extends ConsumerWidget {
  final Subscription subscription;
  final bool isTesting;
  final Future<void> Function() onTest;

  const _TestResultRow({
    required this.subscription,
    required this.isTesting,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    if (subscription.lastTestResult == TestResultStatus.untested) {
      return _TestButton(
        onTest: () => _handleTestWithErrorDialog(context, ref, subscription, onTest),
        isTesting: isTesting,
      );
    }

    final status = subscription.lastTestResult;
    final latency = subscription.lastTestLatencyMs;
    final error = subscription.lastTestError;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(
                status == TestResultStatus.success
                    ? Icons.check_circle
                    : Icons.error,
                size: 18,
                color: status == TestResultStatus.success
                    ? Colors.green
                    : scheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status == TestResultStatus.success
                      ? 'Test OK — ${latency != null ? '$latency ms' : '—'}'
                      : 'Échec : ${error ?? 'Erreur inconnue'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: status == TestResultStatus.success
                            ? Colors.green
                            : scheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TvFocus(
          onActivate: isTesting
              ? null
              : () => _handleTestWithErrorDialog(context, ref, subscription, onTest),
          child: _TestButton(
            onTest: () => _handleTestWithErrorDialog(context, ref, subscription, onTest),
            isTesting: isTesting,
          ),
        ),
      ],
    );
  }

  Future<void> _handleTestWithErrorDialog(
    BuildContext context,
    WidgetRef ref,
    Subscription subscription,
    Future<void> Function() onTest,
  ) async {
    // Lance le test
    await onTest();

    // Attends un peu pour que le résultat soit mis à jour
    await Future.delayed(const Duration(milliseconds: 300));

    if (!context.mounted) return;

    // Si le test a échoué, affiche le dialog d'erreur
    final updatedSub = ref.read(subscriptionsProvider).firstWhere(
      (s) => s.id == subscription.id,
      orElse: () => subscription,
    );

    if (updatedSub.lastTestResult == TestResultStatus.error &&
        updatedSub.lastTestError != null &&
        updatedSub.lastTestError!.isNotEmpty) {
      await showConnectionErrorDialog(
        context,
        updatedSub.lastTestError!,
        type: subscription.type,
        onRetry: () => _handleTestWithErrorDialog(context, ref, subscription, onTest),
      );
    }
  }
}

class _TestButton extends StatelessWidget {
  final Future<void> Function() onTest;
  final bool isTesting;

  const _TestButton({required this.onTest, required this.isTesting});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: isTesting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.wifi_find, size: 18),
      label: Text(isTesting ? 'Test…' : 'Tester'),
      onPressed: isTesting ? null : onTest,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _SubscriptionFormDialog extends ConsumerStatefulWidget {
  final Subscription? subscription;
  final VoidCallback onSaved;

  const _SubscriptionFormDialog({this.subscription, required this.onSaved});

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
  
  // FocusNodes pour le clavier virtuel (TextFormField)
  final _nameFocus = FocusNode();
  final _baseUrlFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _m3uFocus = FocusNode();
  final _submitFocus = FocusNode();
  final _typeFocus = FocusNode();
  
  // FocusNodes DÉDIÉS pour la navigation TV (TvFocus) — séparés du clavier
  final _nameTvFocus = FocusNode();
  final _baseUrlTvFocus = FocusNode();
  final _usernameTvFocus = FocusNode();
  final _passwordTvFocus = FocusNode();
  final _m3uTvFocus = FocusNode();
  final _typeTvFocus = FocusNode();
  final _submitTvFocus = FocusNode();

  SubscriptionType _type = SubscriptionType.xtream;
  bool _obscurePassword = true;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
      _nameTvFocus.requestFocus();
    });
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
    _typeFocus.dispose();
    _nameTvFocus.dispose();
    _baseUrlTvFocus.dispose();
    _usernameTvFocus.dispose();
    _passwordTvFocus.dispose();
    _m3uTvFocus.dispose();
    _submitTvFocus.dispose();
    super.dispose();
  }

  void _requestFocus(FocusNode focus) {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) FocusScope.of(context).requestFocus(focus);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isEditing = widget.subscription != null;

    // Focus traversal order: Name -> Type (Xtream/M3U) -> Fields -> Submit
    return AlertDialog(
      title: Text(isEditing ? 'Modifier l\'abonnement' : 'Nouvel abonnement'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. NOM
                  TvFocus(
                    focusNode: _nameTvFocus,
                    onFocusChange: (hasFocus) {},
                    child: TextFormField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      decoration: const InputDecoration(
                        labelText: 'Nom de l\'abonnement',
                        prefixIcon: Icon(Icons.edit_outlined),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () => _requestFocus(_typeFocus),
                      validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. TYPE XTREAM / M3U (EN HAUT - toggle TV-friendly)
                  TvFocus(
                    focusNode: _typeTvFocus,
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
                            event.logicalKey == LogicalKeyboardKey.enter ||
                            event.logicalKey == LogicalKeyboardKey.select ||
                            event.logicalKey == LogicalKeyboardKey.gameButtonA) {
                          final nextFocus = _type == SubscriptionType.xtream
                              ? _baseUrlFocus
                              : _m3uFocus;
                          _requestFocus(nextFocus);
                          return KeyEventResult.handled;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                          _requestFocus(_nameFocus);
                          return KeyEventResult.handled;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                          if (_type != SubscriptionType.xtream) {
                            setState(() => _type = SubscriptionType.xtream);
                          }
                          return KeyEventResult.handled;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                          if (_type != SubscriptionType.m3u) {
                            setState(() => _type = SubscriptionType.m3u);
                          }
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Type de source',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FocusTraversalGroup(
                          policy: OrderedTraversalPolicy(),
                          child: Row(
                            children: [
                              Expanded(
                                child: _TypeToggleButton(
                                  value: SubscriptionType.xtream,
                                  groupValue: _type,
                                  label: l.xtreamCodes,
                                  icon: Icons.tv_outlined,
                                  onChanged: (v) => setState(() => _type = v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _TypeToggleButton(
                                  value: SubscriptionType.m3u,
                                  groupValue: _type,
                                  label: l.m3uPlaylist,
                                  icon: Icons.playlist_play_outlined,
                                  onChanged: (v) => setState(() => _type = v),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. CHAMPS SELON TYPE
                  if (_type == SubscriptionType.xtream) ...[
                    TvFocus(
                      focusNode: _baseUrlTvFocus,
                      child: TextFormField(
                        controller: _baseUrlController,
                        focusNode: _baseUrlFocus,
                        decoration: InputDecoration(
                          labelText: l.serverUrlPlaceholder,
                          prefixIcon: const Icon(Icons.link_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                        onEditingComplete: () => _requestFocus(_usernameFocus),
                        validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TvFocus(
                      focusNode: _usernameTvFocus,
                      child: TextFormField(
                        controller: _usernameController,
                        focusNode: _usernameFocus,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person_outlined),
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                        onEditingComplete: () => _requestFocus(_passwordFocus),
                        validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TvFocus(
                      focusNode: _passwordTvFocus,
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.enter ||
                              event.logicalKey == LogicalKeyboardKey.select ||
                              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
                            // Toggle password visibility on OK/Enter
                            setState(() => _obscurePassword = !_obscurePassword);
                            return KeyEventResult.handled;
                          }
                          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                            _requestFocus(_submitFocus);
                            return KeyEventResult.handled;
                          }
                        }
                        return KeyEventResult.ignored;
                      },
                      child: TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Afficher le mot de passe'
                                : 'Masquer le mot de passe',
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                      ),
                    ),
                  ] else ...[
                    TvFocus(
                      focusNode: _m3uTvFocus,
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.enter ||
                              event.logicalKey == LogicalKeyboardKey.select ||
                              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
                            _requestFocus(_submitFocus);
                            return KeyEventResult.handled;
                          }
                          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                            _requestFocus(_typeFocus);
                            return KeyEventResult.handled;
                          }
                        }
                        return KeyEventResult.ignored;
                      },
                      child: TextFormField(
                        controller: _m3uUrlController,
                        focusNode: _m3uFocus,
                        decoration: InputDecoration(
                          labelText: l.m3uPlaylistUrl,
                          prefixIcon: const Icon(Icons.playlist_play_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.done,
                        validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TvFocus(
          focusNode: _submitTvFocus,
          autofocus: false,
          onActivate: _save,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.select ||
                    event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
              _save();
              return KeyEventResult.handled;
            }
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.escape ||
                    event.logicalKey == LogicalKeyboardKey.gameButtonB)) {
              Navigator.pop(context);
              return KeyEventResult.handled;
            }
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.arrowUp)) {
              final prevFocus = _type == SubscriptionType.xtream
                  ? _passwordTvFocus
                  : _m3uTvFocus;
              _requestFocus(prevFocus);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _save,
                child: Text(isEditing ? 'Enregistrer' : 'Ajouter'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

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
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e, st) {
      LoggerService.instance
          .error('_SubscriptionFormDialog._save failed', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde : $e')),
        );
      }
    }
  }
}

/// Bouton toggle TV-friendly pour choisir Xtream/M3U (remplace SegmentedButton)
class _TypeToggleButton extends StatelessWidget {
  const _TypeToggleButton({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  final SubscriptionType value;
  final SubscriptionType groupValue;
  final String label;
  final IconData icon;
  final ValueChanged<SubscriptionType> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = groupValue == value;

    return Expanded(
      child: TvFocus(
        onActivate: () => onChanged(value),
        child: Focus(
          onFocusChange: (hasFocus) {},
          child: InkWell(
            onTap: () => onChanged(value),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [scheme.primary, scheme.primary.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.04),
                      ],
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? scheme.primary
                    : scheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? scheme.onPrimary : scheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  icon,
                  size: 18,
                  color: Colors.transparent,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}
