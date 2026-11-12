import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/providers/category_change_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('tracks increases by subscription and catalog until next refresh',
      () async {
    final tracker = CategoryCountTracker();
    const movies = (subscriptionId: 'one', catalog: CategoryCatalog.movies);
    const series = (subscriptionId: 'one', catalog: CategoryCatalog.series);
    const other = (subscriptionId: 'two', catalog: CategoryCatalog.movies);

    await tracker.record(movies, ['new', 'new', 'old'], refresh: false);
    expect(await tracker.increases(movies), isEmpty);
    await tracker.record(movies, ['new', 'new', 'new', 'old'], refresh: true);
    expect(await tracker.increases(movies), {'new': 3});
    expect(await tracker.increases(series), isEmpty);
    expect(await tracker.increases(other), isEmpty);

    await tracker.record(movies, ['new', 'new', 'new', 'old'], refresh: false);
    expect(await CategoryCountTracker().increases(movies), {'new': 3});
    await tracker.record(movies, ['new', 'new', 'new', 'old'], refresh: true);
    expect(await tracker.increases(movies), isEmpty);
  });

  test('ignores empty results and does not mark decreases as increases',
      () async {
    final tracker = CategoryCountTracker();
    const key = (subscriptionId: 'one', catalog: CategoryCatalog.series);
    await tracker.record(key, ['a', 'a', 'b'], refresh: false);
    await tracker.record(key, [], refresh: true);
    await tracker.record(key, ['a', 'b', 'b'], refresh: true);
    expect(await tracker.increases(key), {'b': 2});
  });
}
