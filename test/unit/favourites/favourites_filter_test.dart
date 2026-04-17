import 'package:flutter_test/flutter_test.dart';
import 'package:random_magic/features/favourites/domain/favourite_card.dart';
import 'package:random_magic/features/favourites/presentation/providers.dart'
    show FavouritesFilter;

import '../../fixtures/fake_favourite_card.dart';

/// Replicates the filter where-block from [filteredFavourites] in providers.dart.
///
/// Keeps these tests independent of Riverpod — no ProviderContainer needed.
/// Logic MUST stay in sync with the production provider (FAV-07).
List<FavouriteCard> applyFilter(
  List<FavouriteCard> all,
  FavouritesFilter filter,
) {
  if (filter.isEmpty) return all;

  return all.where((card) {
    // Colour: card must share at least one colour with the filter (OR per colour).
    final colorMatch = filter.colors.isEmpty ||
        card.colors.any((c) => filter.colors.contains(c));
    // Type: card's typeLine must contain at least one selected type string.
    final typeMatch = filter.types.isEmpty ||
        filter.types.any((t) => card.typeLine.contains(t));
    // Rarity: exact string match (Scryfall lowercase values).
    final rarityMatch =
        filter.rarities.isEmpty || filter.rarities.contains(card.rarity);
    // All three conditions must be satisfied simultaneously (AND across categories).
    return colorMatch && typeMatch && rarityMatch;
  }).toList();
}

void main() {
  group('FavouritesFilter client-side filtering (FAV-07)', () {
    final redInstantCommon = fakeFavouriteCard(
      id: 'r-inst',
      name: 'Lightning Bolt',
      typeLine: 'Instant',
      rarity: 'common',
      colors: ['R'],
    );
    final blueCreatureRare = fakeFavouriteCard(
      id: 'u-crea',
      name: 'Snapcaster Mage',
      typeLine: 'Creature — Human Wizard',
      rarity: 'rare',
      colors: ['U'],
    );
    final greenCreatureCommon = fakeFavouriteCard(
      id: 'g-crea',
      name: 'Llanowar Elves',
      typeLine: 'Creature — Elf Druid',
      rarity: 'common',
      colors: ['G'],
    );

    final allCards = [redInstantCommon, blueCreatureRare, greenCreatureCommon];

    test('empty filter returns all cards', () {
      final result = applyFilter(allCards, const FavouritesFilter());
      expect(result, equals(allCards));
      expect(result.length, equals(3));
    });

    test('color filter matches cards containing any selected color', () {
      final filter = FavouritesFilter(colors: {'R'});
      final result = applyFilter(allCards, filter);

      expect(result.length, equals(1));
      expect(result.first.id, equals('r-inst'));
    });

    test(
        'type filter matches cards whose typeLine contains any selected type',
        () {
      final filter = FavouritesFilter(types: {'Instant'});
      final result = applyFilter(allCards, filter);

      expect(result.length, equals(1));
      expect(result.first.id, equals('r-inst'));
    });

    test('rarity filter matches exact rarity string', () {
      final filter = FavouritesFilter(rarities: {'common'});
      final result = applyFilter(allCards, filter);

      // Lightning Bolt and Llanowar Elves are both common.
      expect(result.length, equals(2));
      expect(result.map((c) => c.id), containsAll(['r-inst', 'g-crea']));
    });

    test(
        'combined color+type+rarity filter applies all conditions (AND logic)',
        () {
      // Only redInstantCommon satisfies all three: R + Instant + common.
      final filter = FavouritesFilter(
        colors: {'R'},
        types: {'Instant'},
        rarities: {'common'},
      );
      final result = applyFilter(allCards, filter);

      expect(result.length, equals(1));
      expect(result.first.id, equals('r-inst'));
    });

    test('filter with no matching cards returns empty list', () {
      // No card in allCards is mythic.
      final filter = FavouritesFilter(rarities: {'mythic'});
      final result = applyFilter(allCards, filter);

      expect(result, isEmpty);
    });
  });
}
