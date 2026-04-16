import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_magic/features/favourites/presentation/favourites_screen.dart';
import 'package:random_magic/features/favourites/presentation/providers.dart';

import '../../fixtures/fake_favourite_card.dart';

/// Pumps [FavouritesScreen] inside a [ProviderScope] that overrides
/// [favouritesProvider] with [cards] and [filteredFavouritesProvider] with
/// [filtered] (defaults to same as [cards]).
Future<void> pumpScreen(
  WidgetTester tester, {
  List<dynamic> cards = const [],
  List<dynamic>? filtered,
}) async {
  final favourites = List<dynamic>.from(cards);
  final filteredList = filtered ?? favourites;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        favouritesProvider.overrideWithValue(List.from(favourites)),
        filteredFavouritesProvider
            .overrideWithValue(List.from(filteredList)),
      ],
      child: const MaterialApp(home: FavouritesScreen()),
    ),
  );
  // Settle animations and async frames.
  await tester.pump();
}

void main() {
  group('FavouritesScreen (FAV-02, FAV-03, FAV-06)', () {
    testWidgets(
      'renders empty state widget when no favourites (FAV-06)',
      (tester) async {
        await pumpScreen(tester, cards: []);

        expect(find.text('No Favourites Yet'), findsOneWidget);
        expect(
          find.text('Swipe up on any card to save it here.'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.favorite_outline), findsOneWidget);
      },
    );

    testWidgets(
      'renders 3-column grid when favourites exist (FAV-02)',
      (tester) async {
        final cards = [
          fakeFavouriteCard(id: '1', name: 'Card 1'),
          fakeFavouriteCard(id: '2', name: 'Card 2'),
          fakeFavouriteCard(id: '3', name: 'Card 3'),
        ];

        await pumpScreen(tester, cards: cards);

        // SliverGrid is present — verify via Semantics labels set on each cell.
        expect(find.bySemanticsLabel('Card 1'), findsOneWidget);
        expect(find.bySemanticsLabel('Card 2'), findsOneWidget);
        expect(find.bySemanticsLabel('Card 3'), findsOneWidget);

        // Empty state must NOT appear.
        expect(find.text('No Favourites Yet'), findsNothing);
      },
    );

    testWidgets(
      'shows filtered-empty state with Clear Filters button when filter matches nothing',
      (tester) async {
        final cards = [fakeFavouriteCard(id: '1')];

        // Provide non-empty allFavourites but empty filtered list to simulate
        // an active filter that matches nothing.
        await pumpScreen(tester, cards: cards, filtered: []);

        expect(find.text('No cards match your filters.'), findsOneWidget);
        expect(find.text('Clear Filters'), findsOneWidget);
      },
    );

    testWidgets(
      'long-press enters multi-select mode (D-06)',
      (tester) async {
        final cards = [
          fakeFavouriteCard(id: 'abc-123', name: 'Lightning Bolt'),
        ];

        await pumpScreen(tester, cards: cards);

        // Long-press the cell to enter multi-select.
        await tester.longPress(find.bySemanticsLabel('Lightning Bolt'));
        await tester.pump();

        // App bar should now show "1 selected".
        expect(find.text('1 selected'), findsOneWidget);

        // Delete icon should appear in the app bar.
        expect(find.byIcon(Icons.delete), findsOneWidget);

        // Cell should now be marked as selected via Semantics.
        expect(
          find.bySemanticsLabel('Lightning Bolt, selected'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'filter bottom sheet opens on filter icon tap (FAV-07)',
      (tester) async {
        final cards = [fakeFavouriteCard(id: '1')];

        await pumpScreen(tester, cards: cards);

        // Tap the filter icon in the app bar.
        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();

        // Bottom sheet should be visible with the title and chip sections.
        expect(find.text('Filter Favourites'), findsOneWidget);
        expect(find.text('Colour'), findsOneWidget);
        expect(find.text('Type'), findsOneWidget);
        expect(find.text('Rarity'), findsOneWidget);
      },
    );
  });
}
