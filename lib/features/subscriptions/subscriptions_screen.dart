import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/core/constants/app_constants.dart';
import 'package:orbit_3d_flutter/core/widgets/app_card.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/subscription.dart';
import 'package:orbit_3d_flutter/providers/subscription_provider.dart';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() =>
      _SubscriptionsScreenState();
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
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Retour',
                onPressed: () => context.pop(),
              )
            : null,
        title: const Text('Abonnements'),
        actions: [
          IconButton(
            tooltip: l.addSubscription,
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddSubscriptionDialog(context, ref),
          ),
        ],
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Subscription sub) async {
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
          'Voulez-vous supprimer "${sub.name}" ? Cette action est irr�versible.',
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
          TextButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Activer'),
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
              label: Text(l.addSubscription),
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius:
                                  BorderRadius.circular(AppConstants.radiusSm),
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
                        if (!isActive)
                          IconButton(
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
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Modifier'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete),
                      title: Text('Supprimer'),
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
      return sub.baseUrl ?? 'Configuration incompl�te';
    }
    return sub.m3uUrl ?? 'Configuration incompl�te';
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
                      ? 'Test OK � ${latency != null ? '$latency ms' : '�'}'
                      : '�chec : ${error ?? 'Erreur inconnue'}',
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
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.wifi_find, size: 18),
      label: Text(isTesting ? 'Test�' : 'Tester'),
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
  final _nameFocus = FocusNode();
  final _baseUrlFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _m3uFocus = FocusNode();
  final _cancelFocus = FocusNode();
  final _saveFocus = FocusNode();
  final _segmentedButtonFocus = FocusNode();
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
    _segmentedButtonFocus.dispose();
    _cancelFocus.dispose();
    _saveFocus.dispose();
    super.dispose();
  }

  void _requestFocus(FocusNode focus) {
    if (mounted) {
      FocusScope.of(context).requestFocus(focus);
    }
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
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          _requestFocus(nextFocusNode);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: labelText,
          suffixIcon: suffixIcon,
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        inputFormatters: inputFormatters,
        textInputAction: TextInputAction.next,
        onEditingComplete: () => _requestFocus(nextFocusNode),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isEditing = widget.subscription != null;

    final nextAfterName = _type == SubscriptionType.xtream ? _baseUrlFocus : _m3uFocus;

    return AlertDialog(
      title: Text(isEditing ? 'Modifier l\'abonnement' : 'Nouvel abonnement'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: FocusTraversalGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTvTextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    nextFocusNode: nextAfterName,
                    labelText: 'Nom de l\'abonnement',
                    validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<SubscriptionType>(
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
                    const SizedBox(height: 16),
                  if (_type == SubscriptionType.xtream) ...[
                    _buildTvTextField(
                      controller: _baseUrlController,
                      focusNode: _baseUrlFocus,
                      nextFocusNode: _usernameFocus,
                      labelText: l.serverUrlPlaceholder,
                      validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTvTextField(
                      controller: _usernameController,
                      focusNode: _usernameFocus,
                      nextFocusNode: _passwordFocus,
                      labelText: 'Username',
                      validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTvTextField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      nextFocusNode: _saveFocus,
                      labelText: 'Password',
                      obscureText: _obscurePassword,
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
                      validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                    ),
                  ] else ...[
                    _buildTvTextField(
                      controller: _m3uUrlController,
                      focusNode: _m3uFocus,
                      nextFocusNode: _saveFocus,
                      labelText: l.m3uPlaylistUrl,
                      validator: (v) => v!.isEmpty ? 'Obligatoire' : null,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        Focus(
          focusNode: _cancelFocus,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.select ||
                    event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
              Navigator.pop(context);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ),
        Focus(
          focusNode: _saveFocus,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.select ||
                    event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
              _save();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: FilledButton(
            onPressed: _save,
            child: Text(isEditing ? 'Enregistrer' : 'Ajouter'),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

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

    if (widget.subscription != null) {
      await ref.read(subscriptionsProvider.notifier).updateSubscription(sub);
    } else {
      await ref.read(subscriptionsProvider.notifier).addSubscription(sub);
    }
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }
}
