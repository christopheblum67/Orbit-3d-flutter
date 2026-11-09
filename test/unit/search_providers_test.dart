import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/search.dart';
import 'package:orbit_3d_flutter/providers/providers.dart' as public;
import 'package:orbit_3d_flutter/providers/search_providers.dart' as search;
import 'package:orbit_3d_flutter/providers/vod_category_filter_provider.dart';
import 'package:orbit_3d_flutter/services/search_service.dart';

class _Filter extends VodCategoryFilterNotifier {
  @override
  VodCategoryFilter build() => const VodCategoryFilter(
        subscriptionId: 'account',
        hiddenVodCategoryIds: {'film-hidden'},
        hiddenSeriesCategoryIds: {'series-hidden'},
      );

  void update(VodCategoryFilter filter) => state = filter;
}

class _Search implements SearchService {
  final calls = <({
    String query,
    SearchType? type,
    String? category,
    List<String>? vod,
    List<String>? series
  })>[];
  final suggestionsQueries = <String>[];

  @override
  Future<UnifiedSearchResult> search(
    String query, {
    int limit = 50,
    SearchType? filterType,
    AppLocalizations? l,
    List<String>? hiddenVodCategoryIds,
    List<String>? hiddenSeriesCategoryIds,
    String? categoryId,
  }) async {
    calls.add(
      (
        query: query,
        type: filterType,
        category: categoryId,
        vod: hiddenVodCategoryIds,
        series: hiddenSeriesCategoryIds,
      ),
    );
    return UnifiedSearchResult.empty();
  }

  @override
  Stream<List<SearchSuggestion>> suggestions(String query) async* {
    suggestionsQueries.add(query);
    yield [SearchSuggestion(text: query)];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('public exports refer to the same search providers', () {
    expect(public.searchServiceProvider, same(search.searchServiceProvider));
    expect(
      public.searchIndexServiceProvider,
      same(search.searchIndexServiceProvider),
    );
    expect(public.searchProvider, same(search.searchProvider));
    expect(public.searchFilteredProvider, same(search.searchFilteredProvider));
    expect(
      public.searchSuggestionsProvider,
      same(search.searchSuggestionsProvider),
    );
    expect(public.searchQueryKey('  MATRix \t Reloaded '), 'matrix reloaded');
  });

  test('search providers pass normalized queries and category filters',
      () async {
    final service = _Search();
    final container = ProviderContainer(
      overrides: [
        public.searchServiceProvider.overrideWithValue(service),
        vodCategoryFilterProvider.overrideWith(_Filter.new),
      ],
    );
    addTearDown(container.dispose);
    final first =
        container.listen(public.searchProvider('  MATRIX  '), (_, __) {});
    final filtered = container.listen(
      public.searchFilteredProvider(
        (
          query: '  My   Show ',
          filterType: SearchType.series,
          categoryId: 'cat',
        ),
      ),
      (_, __) {},
    );
    addTearDown(first.close);
    addTearDown(filtered.close);
    await container.read(public.searchProvider('  MATRIX  ').future);
    await container.read(
      public.searchFilteredProvider(
        (
          query: '  My   Show ',
          filterType: SearchType.series,
          categoryId: 'cat',
        ),
      ).future,
    );
    expect(service.calls[0].query, 'matrix');
    expect(service.calls[0].vod, ['film-hidden']);
    expect(service.calls[0].series, ['series-hidden']);
    expect(service.calls[1].query, 'my show');
    expect(service.calls[1].type, SearchType.series);
    expect(service.calls[1].category, 'cat');
    expect(service.calls[1].vod, ['film-hidden']);
    expect(service.calls[1].series, ['series-hidden']);
    (container.read(vodCategoryFilterProvider.notifier) as _Filter).update(
      const VodCategoryFilter(
        subscriptionId: 'account',
        hiddenVodCategoryIds: {'another'},
      ),
    );
    await container.pump();
    await container.read(public.searchProvider('  MATRIX  ').future);
    expect(
      service.calls.where((call) => call.query == 'matrix').last.vod,
      ['another'],
    );
  });

  test('short queries avoid the service; suggestions preserve the input',
      () async {
    final service = _Search();
    final container = ProviderContainer(
      overrides: [public.searchServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    final result = container.listen(public.searchProvider(' x '), (_, __) {});
    final suggestions = container.listen(
      public.searchSuggestionsProvider(' x '),
      (_, __) {},
    );
    addTearDown(result.close);
    addTearDown(suggestions.close);
    expect(
      (await container.read(public.searchProvider(' x ').future)).items,
      isEmpty,
    );
    expect(
      await container.read(public.searchSuggestionsProvider(' x ').future),
      isEmpty,
    );
    expect(service.calls, isEmpty);
    expect(service.suggestionsQueries, isEmpty);
    final valid = container.listen(
      public.searchSuggestionsProvider('  Ab '),
      (_, __) {},
    );
    addTearDown(valid.close);
    expect(
      (await container.read(public.searchSuggestionsProvider('  Ab ').future))
          .single
          .text,
      '  Ab ',
    );
    expect(service.suggestionsQueries, ['  Ab ']);
  });
}
