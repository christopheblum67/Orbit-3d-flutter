import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide AsyncResult;
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/core/utils/safe_async.dart';
import 'package:orbit_3d_flutter/core/widgets/widgets.dart';
import 'package:orbit_3d_flutter/services/history_service.dart';
import 'package:orbit_3d_flutter/services/user_friendly_error.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  AsyncResult<List<HistoryEntry>>? _historyResult;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _historyResult = null);
    final result = await safeAsync<List<HistoryEntry>>(
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
          return RefreshIndicator(
            onRefresh: _loadHistory,
            child: ListView.builder(
              scrollCacheExtent: const ScrollCacheExtent.pixels(500),
              padding: const EdgeInsets.all(16),
              addAutomaticKeepAlives: false,
              itemCount: hist.length,
              itemBuilder: (context, index) {
                final entry = hist[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    child: ListTile(
                      leading: Container(
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
                      title: Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(entry.type),
                      trailing: entry.streamUrl.isEmpty
                          ? null
                          : const Icon(Icons.play_arrow_rounded),
                      onTap: entry.streamUrl.isEmpty
                          ? null
                          : () => context.go(
                                Uri(
                                  path: '/player',
                                  queryParameters: {
                                    'url': entry.streamUrl,
                                    'title': entry.title,
                                    'type': entry.type,
                                  },
                                ).toString(),
                              ),
                    ),
                  ),
                );
              },
            ),
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
        title: Text(l.history),
        actions: [
          IconButton(
            onPressed: _loadHistory,
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: body,
    );
  }
}
