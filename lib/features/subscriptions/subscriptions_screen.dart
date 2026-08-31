import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';
import '../../models/subscription.dart';
import '../../providers/providers.dart';
import '../../providers/subscription_provider.dart';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  @override
  Widget build(BuildContext context) {
    final subs = ref.watch(subscriptionsProvider);
    final activeId = ref.watch(activeSubscriptionProvider).valueOrNull?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Abonnements'),
        actions: [
          IconButton(
            tooltip: 'Ajouter un abonnement',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddSubscriptionDialog(context, ref),
          ),
        ],
      ),
      body: subs.isEmpty
          ? _EmptyState(
              onAdd: () => _showAddSubscriptionDialog(context, ref),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: subs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final sub = subs[index];
                final isActive = sub.id == activeId;
                return _SubscriptionCard(
                  subscription: sub,
                  isActive: isActive,
                  onTap: () {
                    if (!isActive) {
                      ref.read(subscriptionsProvider.notifier).setActive(sub.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Basculé vers "${sub.name}"')),
                      );
                      ref.invalidate(liveChannelsProvider);
                      ref.invalidate(moviesProvider);
                      ref.invalidate(seriesProvider);
                      ref.invalidate(radioChannelsProvider);
                      ref.invalidate(replaysProvider);
                    }
                  },
                  onTest: () => ref.read(subscriptionsProvider.notifier).testConnection(sub),
                  onEdit: () => _showEditSubscriptionDialog(context, ref, sub),
                  onDelete: () => _confirmDelete(context, ref, sub),
                );
              },
            ),
    );
  }

  void _showAddSubscriptionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _SubscriptionFormDialog(onSaved: () => ref.invalidate(subscriptionsProvider)),
    );
  }

  void _showEditSubscriptionDialog(BuildContext context, WidgetRef ref, Subscription sub) {
    showDialog(
      context: context,
      builder: (_) => _SubscriptionFormDialog(
        subscription: sub,
        onSaved: () => ref.invalidate(subscriptionsProvider),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Subscription sub) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'abonnement ?'),
        content: Text('Voulez-vous supprimer "${sub.name}" ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () {
              ref.read(subscriptionsProvider.notifier).deleteSubscription(sub.id);
              Navigator.pop(ctx);
            },
            child: const Text('Supprimer'),
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
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primaryContainer.withOpacity(0.5),
              ),
              child: Icon(Icons.subscriptions_outlined, size: 48, color: scheme.primary),
            ),
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
            FilledButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter un abonnement'),
              onPressed: onAdd,
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
  final VoidCallback onTest;
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
    final isTesting = _isTesting(ref, subscription.id);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      color: isActive ? scheme.primaryContainer.withOpacity(0.3) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TypeBadge(type: subscription.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subscription.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                            ),
                            child: Text(
                              'ACTIF',
                              style: TextStyle(
                                color: scheme.onPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
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
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Modifier'))),
                  const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete), title: Text('Supprimer'))),
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
    return false;
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
        color: type == SubscriptionType.xtream ? scheme.secondaryContainer : scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
      ),
      child: Text(
        type == SubscriptionType.xtream ? 'XTREAM' : 'M3U',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: type == SubscriptionType.xtream ? scheme.onSecondaryContainer : scheme.onTertiaryContainer,
        ),
      ),
    );
  }
}

class _TestResultRow extends ConsumerWidget {
  final Subscription subscription;
  final bool isTesting;
  final VoidCallback onTest;

  const _TestResultRow({
    required this.subscription,
    required this.isTesting,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    if (subscription.lastTestResult == TestResultStatus.untested) {
      return _TestButton(onTest: onTest, isTesting: isTesting);
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
                status == TestResultStatus.success ? Icons.check_circle : Icons.error,
                size: 18,
                color: status == TestResultStatus.success ? Colors.green : scheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status == TestResultStatus.success
                      ? 'Test OK · ${latency != null ? '$latency ms' : '—'}'
                      : 'Échec : ${error ?? 'Erreur inconnue'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: status == TestResultStatus.success ? Colors.green : scheme.error,
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
        _TestButton(onTest: onTest, isTesting: isTesting),
      ],
    );
  }
}

class _TestButton extends StatelessWidget {
  final VoidCallback onTest;
  final bool isTesting;

  const _TestButton({required this.onTest, required this.isTesting});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: isTesting
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
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
  ConsumerState<_SubscriptionFormDialog> createState() => _SubscriptionFormDialogState();
}

class _SubscriptionFormDialogState extends ConsumerState<_SubscriptionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _m3uUrlController = TextEditingController();
  SubscriptionType _type = SubscriptionType.xtream;

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _m3uUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.subscription != null;
    return AlertDialog(
      title: Text(isEditing ? 'Modifier l\'abonnement' : 'Nouvel abonnement'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nom de l\'abonnement'),
                  validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                ),
                const SizedBox(height: 16),
                SegmentedButton<SubscriptionType>(
                  segments: const [
                    ButtonSegment(value: SubscriptionType.xtream, label: Text('Xtream Codes')),
                    ButtonSegment(value: SubscriptionType.m3u, label: Text('M3U Playlist')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (Set<SubscriptionType> newSelection) {
                    setState(() => _type = newSelection.first);
                  },
                ),
                const SizedBox(height: 16),
                if (_type == SubscriptionType.xtream) ...[
                  TextFormField(
                    controller: _baseUrlController,
                    decoration: const InputDecoration(labelText: 'URL du serveur (ex: https://provider.com)'),
                    validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                  ),
                ] else ...[
                  TextFormField(
                    controller: _m3uUrlController,
                    decoration: const InputDecoration(labelText: 'URL de la playlist M3U'),
                    validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          onPressed: _save,
          child: Text(isEditing ? 'Enregistrer' : 'Ajouter'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.subscription?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final sub = widget.subscription?.copyWith(
          id: id,
          name: _nameController.text.trim(),
          type: _type,
          baseUrl: _type == SubscriptionType.xtream ? _baseUrlController.text.trim() : null,
          username: _type == SubscriptionType.xtream ? _usernameController.text.trim() : null,
          password: _type == SubscriptionType.xtream ? _passwordController.text.trim() : null,
          m3uUrl: _type == SubscriptionType.m3u ? _m3uUrlController.text.trim() : null,
        ) ??
        Subscription(
          id: id,
          name: _nameController.text.trim(),
          type: _type,
          baseUrl: _type == SubscriptionType.xtream ? _baseUrlController.text.trim() : null,
          username: _type == SubscriptionType.xtream ? _usernameController.text.trim() : null,
          password: _type == SubscriptionType.xtream ? _passwordController.text.trim() : null,
          m3uUrl: _type == SubscriptionType.m3u ? _m3uUrlController.text.trim() : null,
          isActive: widget.subscription?.isActive ?? false,
          createdAt: widget.subscription?.createdAt ?? DateTime.now(),
        );

    if (widget.subscription != null) {
      await ref.read(subscriptionsProvider.notifier).updateSubscription(sub);
    } else {
      await ref.read(subscriptionsProvider.notifier).addSubscription(sub);
    }
    widget.onSaved();
    if (context.mounted) Navigator.pop(context);
  }
}