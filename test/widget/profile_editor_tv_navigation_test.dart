import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/widgets/avatar_catalog.dart';
import 'package:orbit_3d_flutter/core/widgets/avatar_picker_grid.dart';
import 'package:orbit_3d_flutter/features/profile/profile_edit_screen.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';

Widget _localizedApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('D-pad selects an avatar from the grid', (tester) async {
    String? selectedUrl;
    await tester.pumpWidget(
      _localizedApp(
        Scaffold(
          body: SingleChildScrollView(
            child: AvatarPickerGrid(
              categoryId: 'characters',
              selectedImageUrl: '',
              onAvatarSelected: (url) => selectedUrl = url,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    FocusScope.of(tester.element(find.byType(AvatarPickerGrid))).nextFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();

    expect(selectedUrl, orbit3DAvatars[1].imageUrl);
  });

  testWidgets('D-pad moves from profile name to next and into settings',
      (tester) async {
    await tester.pumpWidget(
      _localizedApp(const ProfileEditScreen()),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.drag(
      find.byType(ListView).first,
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Camille');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'profile.next');

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'profile.firstAge');
  });
}
