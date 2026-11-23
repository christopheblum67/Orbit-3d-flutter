import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbit_3d_flutter/features/profile/profile_edit_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/user_profile.dart';
import 'package:orbit_3d_flutter/providers/providers.dart';
import 'package:orbit_3d_flutter/services/storage_service.dart';

class _Storage extends StorageService {
  UserProfile? saved;

  @override
  Future<void> saveProfile(UserProfile profile) async => saved = profile;
}

void main() {
  for (final scenario in ['creation', 'editing', 'preserving']) {
    final editing = scenario != 'creation';
    final preserving = scenario == 'preserving';
    testWidgets('profile fields and international names: $scenario',
        (tester) async {
      final storage = _Storage();
      final existing = UserProfile(
        id: 'existing',
        firstName: 'Alex',
        dateOfBirth: DateTime(1990),
        gender: preserving ? 'Non spécifié' : 'Homme',
        profileType: editing ? ProfileType.child : ProfileType.adult,
        favoriteGenres: const [],
        hideAdultContent: true,
      );
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => context.push('/edit'),
                child: const Text('Open'),
              ),
            ),
          ),
          GoRoute(
            path: '/edit',
            builder: (_, __) =>
                ProfileEditScreen(profileId: editing ? existing.id : null),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
            profilesProvider.overrideWith(
              (ref) async => editing ? [existing] : <UserProfile>[],
            ),
            currentProfileProvider.overrideWithBuild(
              (ref, notifier) => editing ? existing : null,
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Âge'), findsNothing);
      expect(find.text('- 12 ans'), findsNothing);
      expect(find.text('Profil'), findsNothing);
      expect(find.text('enfant'), findsNothing);
      expect(find.text('expert'), findsNothing);
      expect(find.text('Continuer'), findsNothing);

      final scrollable = find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first;
      Future<void> tapVisible(Finder finder) async {
        await tester.scrollUntilVisible(finder, 250, scrollable: scrollable);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      await tester.scrollUntilVisible(
        find.byType(TextFormField),
        250,
        scrollable: scrollable,
      );
      await tester.enterText(find.byType(TextFormField), 'Zoë 李 42');
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        'Zoë 李 42',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Aventure'), 250,
          scrollable: scrollable);
      expect(find.text('Homme'), findsNothing);
      expect(find.text('Femme'), findsNothing);
      expect(find.text('Autre'), findsNothing);
      expect(find.text('Aucun'), findsNothing);
      await tapVisible(find.text('Aventure'));
      await tapVisible(find.text(editing ? 'Enregistrer' : 'Créer le profil'));

      final saved = storage.saved;
      expect(saved, isNotNull);
      expect(saved!.firstName, 'Zoë 李 42');
      expect(saved.gender, editing ? existing.gender : 'Non spécifié');
      expect(
        saved.profileType,
        editing ? ProfileType.child : ProfileType.adult,
      );
      if (editing) {
        expect(saved.dateOfBirth, existing.dateOfBirth);
      } else {
        expect(saved.age, 24);
      }
      expect(saved.favoriteGenres, contains('Aventure'));
      if (editing) expect(saved.hideAdultContent, isTrue);
    });
  }
}
