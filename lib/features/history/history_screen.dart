import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide AsyncResult;
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  // TODO: brancher — historyService.addEntry est désormais appelé depuis
  // player_screen.  Vérifier que getHistory renvoie bien les entrées
  // une fois qu'une vidéo a été lue.

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  AsyncResult<List<String>>? _historyResult;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _historyResult = null);
    final result = await safeAsync<List<String>>(
      () async {
        final service = ref.read(historyServiceProvider);
        return service.getHistory();
      },
      context: 'HistoryScreen.loadHistory',
    );
    if (!mounted) return;
    setState(() => _historyResult = result);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final result = _historyResult;
    final Widget body;
    if (result == null) {
      body = const LoadingState(message: 'Chargement de l’historique…');
    } else {
      body = result.when(
        data: (hist) {
          if (hist.isEmpty) {
            return EmptyState(
              icon: Icons.history,
              title: l.noHistory,
              message: 'Tes lectures récentes apparaîtront ici.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: hist.length,
            itemBuilder: (context, index) {
              final parts = hist[index].split('|');
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primaryContainer,
                              Theme.of(context).colorScheme.tertiaryContainer,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(
                          Icons.history,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              parts[0],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (parts.length > 1 && parts[1].isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                parts[1],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        error: (error) => ErrorState(
          icon: Icons.history,
          title: l.historyUnavailable,
          message: userFriendlyError(error.originalError ?? error),
          onRetry: _loadHistory,
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Retour',
                onPressed: () => context.pop(),
              )
            : null,
        title: const Text('Historique'),
      ),
      body: body,
    );
  }
}
