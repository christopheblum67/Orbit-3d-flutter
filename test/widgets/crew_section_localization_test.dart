import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_3d_flutter/features/vod/widgets/crew_section.dart';
import 'package:orbit_3d_flutter/l10n/generated/app_localizations.dart';
import 'package:orbit_3d_flutter/models/cast.dart';

void main() {
  testWidgets('crew departments follow the locale and preserve unknown names',
      (tester) async {
    final crew = [
      CrewMember(
          id: '1',
          name: 'Alex',
          job: 'Director',
          department: 'Directing',
          profilePath: ''),
      CrewMember(
          id: '2',
          name: 'Sam',
          job: 'Other',
          department: 'Special department',
          profilePath: ''),
    ];

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: CrewSection(crew: crew)),
    ));

    expect(find.text('Crew'), findsOneWidget);
    expect(find.text('Directing'), findsOneWidget);
    expect(find.text('Special department'), findsOneWidget);
    expect(find.text('Director'), findsOneWidget);
  });
}
