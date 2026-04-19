// Requires network access — run manually on a device or emulator with internet.
// Do NOT include in the offline unit test suite (flutter test test/).
// Run with: flutter test integration_test/core_flow_test.dart
//
// Flow: app boots → card loads → save to favourites → Favourites tab shows card in grid.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:random_magic/main.dart' as app;
import 'package:skeletonizer/skeletonizer.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'core flow: app boots, card loads, save to favourites, card appears in grid (TEST-06)',
    (tester) async {
      // 1. Boot the full app (real Hive, real Scryfall API).
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 2. Assert a card has loaded — Skeletonizer must be disabled.
      expect(
        find.byWidgetPredicate((w) => w is Skeletonizer && w.enabled),
        findsNothing,
        reason:
            'Expected card to have loaded (Skeletonizer disabled), but shimmer is still showing.',
      );

      // 3. Assert the bookmark button is visible (success state rendered).
      expect(find.byTooltip('Save to Favourites'), findsOneWidget);

      // 4. Tap the bookmark button to save the card to Favourites.
      await tester.tap(find.byTooltip('Save to Favourites'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // SnackBar confirms the save.
      expect(find.text('Saved to Favourites'), findsOneWidget);

      // 5. Navigate to the Favourites tab via the NavigationBar.
      await tester.tap(find.text('Favourites').last);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 6. Assert the Favourites grid shows at least one card.
      expect(
        find.byType(GridView),
        findsOneWidget,
        reason:
            'Expected FavouritesScreen GridView to be visible after saving a card.',
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
