import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/core/theme/app_theme.dart';
import 'package:orbit_3d_flutter/features/settings/widgets/settings_tab_bar.dart';

void main() {
  const labels = ['Compte', 'Réseau', 'Lecteur', 'Sécurité', 'Audio', 'Avancé'];

  for (final dark in [false, true]) {
    testWidgets(
        'settings icons remain visible in ${dark ? "dark" : "light"} theme',
        (tester) async {
      final theme = dark ? AppTheme.darkTheme() : AppTheme.lightTheme();
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: DefaultTabController(
            length: labels.length,
            child: Builder(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  bottom: SettingsTabBar(
                    controller: DefaultTabController.of(context),
                    labels: labels,
                  ),
                ),
                body: const TabBarView(
                  children: [
                    Text('Page compte'),
                    Text('Page réseau'),
                    Text('Page lecteur'),
                    Text('Page sécurité'),
                    Text('Page audio'),
                    Text('Page avancé'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final colors = <Color>{};
      for (final iconData in SettingsTabBar.icons) {
        final icon = tester.widget<Icon>(find.byIcon(iconData));
        expect(icon.size, 24);
        final color = icon.color!;
        colors.add(color);
        final foreground = color.computeLuminance();
        final background = theme.scaffoldBackgroundColor.computeLuminance();
        final contrast = foreground > background
            ? (foreground + 0.05) / (background + 0.05)
            : (background + 0.05) / (foreground + 0.05);
        expect(contrast, greaterThanOrEqualTo(3));
      }
      expect(colors, hasLength(6));
      final focused = find.byIcon(SettingsTabBar.icons[2]);
      Focus.of(tester.element(focused)).requestFocus();
      await tester.pumpAndSettle();
      expect(tester.widget<Icon>(focused).size, 34);
      expect(
          tester.widget<Icon>(find.byIcon(SettingsTabBar.icons[0])).size, 24);
      Focus.of(tester.element(find.byIcon(SettingsTabBar.icons[3])))
          .requestFocus();
      await tester.pumpAndSettle();
      expect(tester.widget<Icon>(focused).size, 24);
      expect(
          tester.widget<Icon>(find.byIcon(SettingsTabBar.icons[3])).size, 34);
      await tester.tap(find.text('Lecteur'));
      await tester.pumpAndSettle();
      expect(find.text('Page lecteur'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
