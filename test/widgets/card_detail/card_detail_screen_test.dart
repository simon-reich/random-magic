import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:random_magic/features/card_detail/presentation/card_detail_screen.dart';
import 'package:random_magic/shared/models/magic_card.dart';

import '../../fixtures/fake_magic_card.dart';

// Minimal test router that pushes CardDetailScreen with a card via extra.
GoRouter _testRouter(MagicCard? card) => GoRouter(
      initialLocation: '/card/test',
      routes: [
        GoRoute(
          path: '/card/:id',
          builder: (context, state) => CardDetailScreen(card: card),
        ),
      ],
    );

void main() {
  group('CardDetailScreen', () {
    testWidgets('CARD-02: shows card name, type line, oracle text, set info',
        (tester) async {
      // TODO(phase4): implement after plan 04-02 delivers full screen
      // Expected: name, typeLine, oracleText, setName, collectorNumber, releasedAt visible
    }, skip: true);

    testWidgets('CARD-02: flavour text hidden when null', (tester) async {
      // TODO(phase4): verify no empty gap when flavorText is null
    }, skip: true);

    testWidgets('CARD-03: shows USD, USD Foil, EUR prices', (tester) async {
      // TODO(phase4): verify _PriceRow renders '0.50', '1.25', '0.45'
    }, skip: true);

    testWidgets('CARD-03: shows N/A for null prices', (tester) async {
      // TODO(phase4): fakeMagicCard(prices: null) — all three rows show 'N/A'
    }, skip: true);

    testWidgets('CARD-04: shows Standard, Modern, Legacy, Commander legality rows',
        (tester) async {
      // TODO(phase4): verify four _LegalityRow widgets present
    }, skip: true);

    testWidgets('CARD-05: flip button hidden for single-faced card', (tester) async {
      // TODO(phase4): fakeMagicCard(cardFaces: null) — no FAB visible
    }, skip: true);

    testWidgets('CARD-05: flip button visible for DFC', (tester) async {
      // TODO(phase4): fakeDfcMagicCard() — FAB with Icons.flip visible
    }, skip: true);

    testWidgets('CARD-05: tapping flip FAB swaps image and text to back face',
        (tester) async {
      // TODO(phase4): tap FAB, verify back face name appears
    }, skip: true);

    testWidgets('shows error widget when card is null', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: _testRouter(null)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Card not available. Go back and try again.'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
    });
  });
}
