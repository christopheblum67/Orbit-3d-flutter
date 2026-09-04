import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/settings/advanced_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('affiche les 5 onglets de la config avancée', (tester) async {
    SharedPreferences.setMockInitialValues({
      'tls_impersonation': true,
      'custom_dns': true,
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: AdvancedSettingsScreen()),
      ),
    );
    await tester.pump();

    // TabBar présent avec les 5 libellés.
    expect(find.text('Réseau'), findsOneWidget);
    expect(find.text('Lecteur'), findsOneWidget);
    expect(find.text('Sécurité'), findsOneWidget);
    expect(find.text('Ergonomie'), findsOneWidget);
    expect(find.text('IA'), findsOneWidget);
  });

  testWidgets('bascule et rend une option de l\'onglet initial', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: AdvancedSettingsScreen()),
      ),
    );
    await tester.pump();

    // Onglet Réseau (défaut) : le titre de section est visible.
    expect(
      find.text("PROTECTION CONTRE LE BRIDAGE FAI"),
      findsWidgets,
    );
  });
}
