import 'package:cyberpath_ci/app.dart';
import 'package:cyberpath_ci/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpApp(WidgetTester tester, Map<String, Object> prefs) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final instance = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(instance)],
      child: const CyberPathApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("l'onboarding mène au parcours", (tester) async {
    await pumpApp(tester, {});
    expect(find.text('Où en es-tu dans tes études ?'), findsOneWidget);

    await tester.tap(find.text('BTS 2e année'));
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Je ne sais pas encore'));
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    expect(find.text('Commencer'), findsOneWidget);
    await tester.tap(find.textContaining("Je m'engage"));
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    expect(find.text('Ton parcours'), findsOneWidget);
    expect(find.text('Ton labo virtuel'), findsOneWidget);
  });

  testWidgets('valider une étape affiche le succès puis permet d\'annuler', (tester) async {
    await pumpApp(tester, {
      'profile.onboarded': true,
      'profile.ethicsAccepted': true,
      'profile.level': 'BTS1',
    });
    expect(find.text('2 étapes sur 9 acquises'), findsNothing);
    expect(find.text('0 étapes sur 9 acquises'), findsOneWidget);

    await tester.tap(find.text("Continuer l'étape"));
    await tester.pumpAndSettle();
    expect(find.text('Bases des réseaux'), findsOneWidget);

    await tester.tap(find.text('Marquer comme validée'));
    await tester.pumpAndSettle();
    expect(find.text('Étape validée'), findsOneWidget);
    expect(find.text('Linux en ligne de commande'), findsOneWidget);

    await tester.tap(find.text('Annuler la validation'));
    await tester.pumpAndSettle();
    expect(find.text('Marquer comme validée'), findsOneWidget);
  });

  testWidgets('les quatre onglets sont accessibles', (tester) async {
    await pumpApp(tester, {
      'profile.onboarded': true,
      'profile.ethicsAccepted': true,
      'profile.level': 'L3',
      'profile.goal': 'defensive',
    });
    await tester.tap(find.text('Métiers').last);
    await tester.pumpAndSettle();
    expect(find.text('Ton objectif'), findsOneWidget);

    await tester.tap(find.text('Certifs').last);
    await tester.pumpAndSettle();
    expect(find.text('TA PROCHAINE CIBLE'), findsOneWidget);

    await tester.tap(find.text('Plus').last);
    await tester.pumpAndSettle();
    expect(find.text('Réduire les effets'), findsOneWidget);
  });
}
