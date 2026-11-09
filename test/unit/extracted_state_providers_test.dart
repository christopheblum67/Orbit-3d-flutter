import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/providers/epg_fallback_budget_provider.dart'
    as epg;
import 'package:orbit_3d_flutter/providers/providers.dart' as public;
import 'package:orbit_3d_flutter/providers/refresh_state_providers.dart'
    as refresh;
import 'package:orbit_3d_flutter/providers/subtitle_providers.dart'
    as subtitles;

void main() {
  test('public exports retain the same subtitle providers and context', () {
    expect(
      public.subtitleControllerProvider,
      same(subtitles.subtitleControllerProvider),
    );
    expect(
      public.activeSubtitleContextProvider,
      same(subtitles.activeSubtitleContextProvider),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(public.activeSubtitleContextProvider), isNull);
    const context = public.SubtitleContext(
      contentId: 'series',
      isSeries: true,
      streamId: 'episode',
      season: 2,
      episode: 3,
    );
    container.read(public.activeSubtitleContextProvider.notifier).set(context);
    expect(
      container.read(subtitles.activeSubtitleContextProvider),
      same(context),
    );
    container.read(public.activeSubtitleContextProvider.notifier).set(null);
    expect(container.read(public.activeSubtitleContextProvider), isNull);
  });

  test('EPG budget is shared and persists after listeners are removed',
      () async {
    expect(
      public.epgFallbackBudgetProvider,
      same(epg.epgFallbackBudgetProvider),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final listener =
        container.listen(public.epgFallbackBudgetProvider, (_, __) {});
    final budget = listener.read();
    expect(budget.tryConsume(), isTrue);
    listener.close();
    await container.pump();
    expect(container.read(public.epgFallbackBudgetProvider), same(budget));
    expect(budget.remaining, public.EpgFallbackBudget.maxRequests - 1);
  });

  test('refresh state is shared through both imports and survives unlistening',
      () async {
    expect(
      public.lastRefreshTimestampProvider,
      same(refresh.lastRefreshTimestampProvider),
    );
    expect(
      public.startupRefreshAttemptProvider,
      same(refresh.startupRefreshAttemptProvider),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final timestampListener =
        container.listen(public.lastRefreshTimestampProvider, (_, __) {});
    final attemptListener =
        container.listen(public.startupRefreshAttemptProvider, (_, __) {});
    final timestamp = DateTime(2026, 11, 9);
    container
        .read(refresh.lastRefreshTimestampProvider.notifier)
        .restoreTimestamp(timestamp);
    container
        .read(refresh.startupRefreshAttemptProvider.notifier)
        .markCompleted();
    timestampListener.close();
    attemptListener.close();
    await container.pump();
    expect(container.read(public.lastRefreshTimestampProvider), timestamp);
    expect(
      container.read(public.startupRefreshAttemptProvider.notifier).consume(),
      isTrue,
    );
    expect(container.read(refresh.startupRefreshAttemptProvider), isFalse);
  });
}
