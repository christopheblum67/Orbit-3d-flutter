import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/utils/xtream_taxonomy.dart';

void main() {
  group('countryFromName', () {
    test('reconnaît les préfixes des trois panels', () {
      expect(XtreamTaxonomy.countryFromName('|BE| ANTIPODE'), 'BE');
      expect(XtreamTaxonomy.countryFromName('FR | NRJ France'), 'FR');
      expect(XtreamTaxonomy.countryFromName('[fr] Radio X'), 'FR');
      expect(XtreamTaxonomy.countryFromName('WEB | Hotmix BBQ'), 'WEB');
    });

    test('sans préfixe : null', () {
      expect(XtreamTaxonomy.countryFromName('RADIO QURAN 1'), isNull);
      expect(XtreamTaxonomy.countryFromName('TRACE GUADALUPE'), isNull);
    });
  });

  group('countryFromCategory', () {
    test('lit le nom du pays malgré la décoration', () {
      expect(XtreamTaxonomy.countryFromCategory('ⓉⓋ ║ FRANCE HD'), 'FR');
      expect(XtreamTaxonomy.countryFromCategory('ⓉⓋ ║ BELGIUM | LUX'), 'BE');
      expect(XtreamTaxonomy.countryFromCategory('ⓉⓋ ║ ESPAÑA'), 'ES');
      expect(XtreamTaxonomy.countryFromCategory('FRANCE FHD'), 'FR');
      expect(XtreamTaxonomy.countryFromCategory('SPORT US'), isNull);
    });

    test('préfixe de code reconnu', () {
      expect(XtreamTaxonomy.countryFromCategory('|BE| FILMS'), 'BE');
    });
  });

  group('countryOf', () {
    test('nom d abord, catégorie ensuite, sinon Autres', () {
      expect(XtreamTaxonomy.countryOf('|BE| X', categoryName: 'FRANCE'), 'BE');
      expect(XtreamTaxonomy.countryOf('X', categoryName: 'ITALY'), 'IT');
      expect(XtreamTaxonomy.countryOf('X'), XtreamTaxonomy.others);
    });
  });

  group('cleanCategory / primarySegment', () {
    test('retire seulement la décoration de tête', () {
      expect(XtreamTaxonomy.cleanCategory('ⓉⓋ ║ FRANCE HD'), 'FRANCE HD');
      expect(XtreamTaxonomy.cleanCategory('FRANCE HD | OTT'), 'FRANCE HD | OTT');
      expect(XtreamTaxonomy.cleanCategory('FR | Films'), 'FR | Films');
      expect(XtreamTaxonomy.cleanCategory('Cinéma: Action'), 'Cinéma: Action');
      expect(XtreamTaxonomy.cleanCategory('Tous'), 'Tous');
    });

    test('primarySegment garde le premier segment utile', () {
      expect(XtreamTaxonomy.primarySegment('FRANCE HD | OTT'), 'FRANCE HD');
      expect(XtreamTaxonomy.primarySegment('ⓉⓋ ║ FRANCE HD'), 'FRANCE HD');
      expect(XtreamTaxonomy.primarySegment('A; B'), 'A');
    });
  });

  group('isRadioCategory', () {
    test('détecte le mot radio', () {
      expect(XtreamTaxonomy.isRadioCategory('ⓉⓋ ║ RADIOS'), isTrue);
      expect(XtreamTaxonomy.isRadioCategory('Web Radio'), isTrue);
      expect(XtreamTaxonomy.isRadioCategory('MUSIC'), isFalse);
      expect(XtreamTaxonomy.isRadioCategory('FRANCE HD'), isFalse);
    });
  });

  test('sortCountries met Autres en dernier', () {
    expect(
      XtreamTaxonomy.sortCountries(['FR', 'Autres', 'BE', 'FR']),
      ['BE', 'FR', 'Autres'],
    );
  });
}
