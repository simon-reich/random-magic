import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:random_magic/features/card_detail/presentation/card_detail_screen.dart';
import 'package:random_magic/shared/models/magic_card.dart';

import '../../fixtures/fake_magic_card.dart';

// Minimal test router for null-card error state test.
GoRouter _testRouter(MagicCard? card) => GoRouter(
      initialLocation: '/card/test',
      routes: [
        GoRoute(
          path: '/card/:id',
          builder: (context, state) => CardDetailScreen(card: card),
        ),
      ],
    );

/// Pumps [CardDetailScreen] for a given card in isolation (no GoRouter needed).
///
/// Uses a tall viewport so all content is rendered in one frame.
Future<void> pumpDetail(WidgetTester tester, MagicCard card) async {
  // Use a taller test surface so the SliverList content below the 440px
  // artwork area is also laid out and findable without scrolling.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: CardDetailScreen(card: card),
      ),
    ),
  );
  await tester.pump(); // initial frame
}

void main() {
  group('CardDetailScreen', () {
    testWidgets('CARD-02: shows card name in AppBar title', (tester) async {
      await pumpDetail(tester, fakeMagicCard());
      // Name appears in FlexibleSpaceBar title (may appear multiple times)
      expect(find.text('Lightning Bolt'), findsWidgets);
    });

    testWidgets('CARD-02: shows oracle text', (tester) async {
      await pumpDetail(tester, fakeMagicCard());
      expect(
        find.text('Lightning Bolt deals 3 damage to any target.'),
        findsOneWidget,
      );
    });

    testWidgets('CARD-02: shows set name and collector number', (tester) async {
      await pumpDetail(tester, fakeMagicCard());
      expect(find.text('Limited Edition Alpha'), findsOneWidget);
      expect(find.text('161'), findsOneWidget);
    });

    testWidgets('CARD-02: flavour text shown when present', (tester) async {
      await pumpDetail(
        tester,
        fakeMagicCard(flavorText: "The sky's disapproval is rarely subtle."),
      );
      expect(
        find.text("The sky's disapproval is rarely subtle."),
        findsOneWidget,
      );
    });

    testWidgets('CARD-02: flavour text section absent when null', (tester) async {
      await pumpDetail(tester, fakeMagicCard(flavorText: null));
      // No flavor text should appear — section is hidden entirely (not blank)
      expect(
        find.text("The sky's disapproval is rarely subtle."),
        findsNothing,
      );
    });

    testWidgets('CARD-03: shows USD, USD Foil, EUR prices', (tester) async {
      await pumpDetail(tester, fakeMagicCard());
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('0.50'), findsOneWidget);
      expect(find.text('USD Foil'), findsOneWidget);
      expect(find.text('1.25'), findsOneWidget);
      expect(find.text('EUR'), findsOneWidget);
      expect(find.text('0.45'), findsOneWidget);
    });

    testWidgets('CARD-03: shows N/A for all prices when prices is null',
        (tester) async {
      await pumpDetail(tester, fakeMagicCard(prices: null));
      // All three price rows show N/A
      expect(find.text('N/A'), findsNWidgets(3));
    });

    testWidgets('CARD-04: shows Standard, Modern, Legacy, Commander rows',
        (tester) async {
      await pumpDetail(tester, fakeMagicCard());
      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('Modern'), findsOneWidget);
      expect(find.text('Legacy'), findsOneWidget);
      expect(find.text('Commander'), findsOneWidget);
    });

    testWidgets('CARD-04: Legal badge shown for modern:legal', (tester) async {
      await pumpDetail(tester, fakeMagicCard());
      // fakeMagicCard has modern: 'legal' — at least one Legal badge appears
      expect(find.text('Legal'), findsWidgets);
    });

    testWidgets('CARD-04: Not Legal badge shown for standard:not_legal',
        (tester) async {
      await pumpDetail(tester, fakeMagicCard());
      // fakeMagicCard has standard: 'not_legal'
      expect(find.text('Not Legal'), findsWidgets);
    });

    testWidgets('CARD-05: flip FAB hidden for single-faced card', (tester) async {
      await pumpDetail(tester, fakeMagicCard(cardFaces: null));
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('CARD-05: flip FAB visible for double-faced card', (tester) async {
      await pumpDetail(tester, fakeDfcMagicCard());
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('CARD-05: tapping flip FAB shows back face name', (tester) async {
      await pumpDetail(tester, fakeDfcMagicCard());
      // Front face name is visible
      expect(find.text('Delver of Secrets'), findsWidgets);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // Back face name should now appear
      expect(find.text('Insectile Aberration'), findsWidgets);
    });

    testWidgets('CARD-05: tapping flip FAB again returns to front face',
        (tester) async {
      await pumpDetail(tester, fakeDfcMagicCard());
      // Tap once to go to back face
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(find.text('Insectile Aberration'), findsWidgets);

      // Tap again to return to front face
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(find.text('Delver of Secrets'), findsWidgets);
    });

    testWidgets('shows error widget when card is null', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: _testRouter(null)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Card not available. Go back and try again.'),
        findsOneWidget,
      );
      expect(find.text('Back'), findsOneWidget);
    });
  });
}
