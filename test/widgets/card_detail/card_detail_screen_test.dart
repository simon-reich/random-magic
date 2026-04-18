import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:random_magic/features/card_detail/presentation/card_detail_screen.dart';
import 'package:random_magic/features/favourites/domain/favourite_card.dart';
import 'package:random_magic/features/favourites/presentation/providers.dart'
    show FavouritesNotifier, favouritesProvider;
import 'package:random_magic/shared/models/magic_card.dart';

import '../../fixtures/fake_magic_card.dart';

// Minimal Hive-free stub so widget tests don't require an open Hive box.
class _FakeFavouritesNotifier extends FavouritesNotifier {
  @override
  List<FavouriteCard> build() => const [];
}

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

/// Pumps [CardDetailScreen] for a given card in isolation.
///
/// Uses a tall viewport so all SliverList content is rendered without scrolling.
/// Overrides [favouritesProvider] with an empty stub to avoid requiring Hive.
Future<void> pumpDetail(WidgetTester tester, MagicCard card) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        favouritesProvider.overrideWith(_FakeFavouritesNotifier.new),
      ],
      child: MaterialApp(
        home: CardDetailScreen(card: card),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('CardDetailScreen', () {
    testWidgets('CARD-02: shows card name below artwork', (tester) async {
      await pumpDetail(tester, fakeMagicCard());
      expect(find.text('Lightning Bolt'), findsOneWidget);
    });

    testWidgets('CARD-02: oracle text not displayed (visible on card image)',
        (tester) async {
      await pumpDetail(tester, fakeMagicCard());
      expect(
        find.text('Lightning Bolt deals 3 damage to any target.'),
        findsNothing,
      );
    });

    testWidgets('CARD-02: shows set name and collector number', (tester) async {
      await pumpDetail(tester, fakeMagicCard());
      expect(find.text('Limited Edition Alpha'), findsOneWidget);
      expect(find.text('161'), findsOneWidget);
    });

    testWidgets('CARD-02: release date formatted as Month YYYY', (tester) async {
      await pumpDetail(tester, fakeMagicCard(releasedAt: '1993-08-05'));
      expect(find.text('August 1993'), findsOneWidget);
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
      expect(find.text('Legal'), findsWidgets);
    });

    testWidgets('CARD-04: Not Legal badge shown for standard:not_legal',
        (tester) async {
      await pumpDetail(tester, fakeMagicCard());
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
      expect(find.text('Delver of Secrets'), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(find.text('Insectile Aberration'), findsOneWidget);
    });

    testWidgets('CARD-05: tapping flip FAB again returns to front face',
        (tester) async {
      await pumpDetail(tester, fakeDfcMagicCard());
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(find.text('Insectile Aberration'), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(find.text('Delver of Secrets'), findsOneWidget);
    });

    testWidgets('shows error widget when card is null', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            favouritesProvider.overrideWith(_FakeFavouritesNotifier.new),
          ],
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
