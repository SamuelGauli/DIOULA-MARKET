// Smoke test : l'app se construit et affiche l'accueil.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dioula_market/app.dart';
import 'package:dioula_market/core/theme/theme_provider.dart';

void main() {
  testWidgets('L\'accueil affiche le nom de l\'app', (tester) async {
    // SharedPreferences simulé pour le provider de thème.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const DioulaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dioula Market'), findsWidgets);
  });
}
