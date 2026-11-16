import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/providers/catalog_db_provider.dart';

void main() {
  test('les signatures distinguent les ensembles de même taille', () {
    expect(catalogSetSignature({'b', 'a'}), catalogSetSignature({'a', 'b'}));
    expect(catalogSetSignature({'a', 'b'}),
        isNot(catalogSetSignature({'a', 'c'})));
    expect(catalogSetSignature(null), isNot(catalogSetSignature({})));
    expect(
        catalogSetSignature({'a,b'}), isNot(catalogSetSignature({'a', 'b'})));
  });

  test('les pages sont chargées une fois à la demande', () async {
    final requests = <(int, int)>[];
    var changes = 0;
    final pager = CatalogPager<int>(
      pageSize: 2,
      fetch: (limit, offset) async {
        requests.add((limit, offset));
        return [0, 1, 2].skip(offset).take(limit).toList();
      },
      onChange: () => changes++,
    );
    await pager.reset();
    expect(pager.items, [0, 1]);
    expect(requests, [(2, 0)]);
    await pager.loadMore();
    await pager.loadMore();
    expect(pager.items, [0, 1, 2]);
    expect(requests, [(2, 0), (2, 2)]);
    expect(pager.done, isTrue);
    expect(changes, 2);
  });

  test('une page issue d’un ancien filtre ne modifie pas le nouveau', () async {
    final old = Completer<List<int>>();
    var calls = 0;
    final pager = CatalogPager<int>(
      fetch: (_, __) => ++calls == 1 ? old.future : Future.value([2]),
      onChange: () {},
    );
    final first = pager.reset();
    await pager.reset();
    old.complete([1]);
    await first;
    expect(pager.items, [2]);
    expect(pager.loaded, isTrue);
    expect(pager.loading, isFalse);
  });

  test('la page suivante utilise la dernière entrée comme curseur', () async {
    final cursors = <int?>[];
    final pager = CatalogPager<int>(
      pageSize: 2,
      fetch: (_, __) => throw StateError('OFFSET ne doit pas être utilisé'),
      fetchAfter: (limit, after) async {
        cursors.add(after);
        return [1, 2, 3]
            .where((value) => after == null || value > after)
            .take(limit)
            .toList();
      },
      onChange: () {},
    );
    await pager.reset();
    await pager.loadMore();
    expect(pager.items, [1, 2, 3]);
    expect(cursors, [null, 2]);
    expect(pager.done, isTrue);
  });
}
