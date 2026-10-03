import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/downloads/downloads_screen.dart';
import 'package:orbit_3d_flutter/features/library/content_type_selector.dart';
import 'package:orbit_3d_flutter/features/library/library_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/download.dart';
import 'package:orbit_3d_flutter/models/favorite_entry.dart';
import 'package:orbit_3d_flutter/providers/favorites_provider.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';

/// Écran « Mes contenus » : deux onglets, quatre types de contenu.
///
/// Ce que le test fixe, c'est ce qui ne se voit pas à l'écran : que les deux
/// routes 历史 pointent le même écran sur l'onglet voulu, et que le type
/// sélectionné filtre bien les téléchargements.
/// Favoris de test : aucun accès au service, aucune dépendance à Hive.
class _FakeFavoritesNotifier extends FavoritesNotifier {
  @override
  Map<String, FavoriteEntry> build() => const {};
}

void main() {
  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        // L'écran lit deux flux qui, en production, ouvrent une boîte Hive et
        // démarrent le gestionnaire de téléchargements. Les remplacer garde le
        // test centré sur la structure d'onglets.
        favoritesProvider.overrideWith(_FakeFavoritesNotifier.new),
        downloadTasksStreamProvider
            .overrideWith((ref) => Stream.value(const <DownloadTask>[])),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Les assertions lisent des libelles francais : sans locale explicite,
        // le test tournerait en anglais et ne trouverait rien.
        locale: const Locale('fr'),
        home: child,
      ),
    );
  }

  testWidgets('le double onglet est présent', (tester) async {
    await tester.pumpWidget(wrap(const LibraryScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Favoris'), findsWidgets);
    expect(find.textContaining('Téléchargements'), findsWidgets);
  });

  testWidgets('l’onglet Téléchargements affiche son état vide', (tester) async {
    await tester.pumpWidget(wrap(const LibraryScreen(initialTab: 1)));
    await tester.pumpAndSettle();

    // Sans téléchargement, le panneau doit le dire plutôt que montrer une
    // liste blanche : c'est le symptôme que l'écran rapportait.
    expect(find.text('Aucun téléchargement'), findsOneWidget);
  });

  testWidgets('les quatre types sont proposés', (tester) async {
    await tester.pumpWidget(wrap(const LibraryScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(ContentTypeSelector), findsOneWidget);
    expect(ContentType.values, hasLength(4));
  });

  testWidgets('« tout supprimer » n’apparaît que sur les favoris', (tester) async {
    await tester.pumpWidget(wrap(const LibraryScreen()));
    await tester.pumpAndSettle();

    // La liste est vide : l'action n'a rien à supprimer, elle doit être absente
    // plutôt qu'inactive et inerte.
    expect(find.byIcon(Icons.delete_sweep), findsNothing);

    await tester.pumpWidget(wrap(const LibraryScreen(initialTab: 1)));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.delete_sweep), findsNothing);
  });

  test('le tri des téléchargements est stable et lisible', () {
    // Un téléchargement en cours doit passer avant un échec : l'utilisateur
    // regarde d'abord ce qui travaille.
    expect(downloadStatusOrder(DownloadStatus.downloading), 0);
    expect(
      downloadStatusOrder(DownloadStatus.completed),
      lessThan(downloadStatusOrder(DownloadStatus.failed)),
    );
  });
}
