import 'package:flutter_test/flutter_test.dart';
import 'package:random_magic/features/favourites/domain/favourite_card.dart';
import 'package:random_magic/features/favourites/presentation/providers.dart';

import '../../fixtures/fake_favourite_card.dart';

/// Applies the same filter logic as [filteredFavouritesProvider], extracted
/// here as a pure function so tests run without a ProviderContainer or Hive.
List<FavouriteCard> applyFilter(
  List<FavouriteCard> cards,
  FavouritesFilter filter,
) {
  if (filter.isEmpty) return cards;
  return cards.where((card) {
    final colorMatch = filter.colors.isEmpty ||
        card.colors.any((c) => filter.colors.contains(c));
    final typeMatch = filter.types.isEmpty ||
        filter.types.any((t) => card.typeLine.contains(t));
    final rarityMatch =
        filter.rarities.isEmpty || filter.rarities.contains(card.rarity);
    return colorMatch && typeMatch && rarityMatch;
  }).toList();
}

void main() {
  group('FavouritesFilter client-side filtering (FAV-07)', () {
    // Three test cards with distinct properties for filter coverage.
    final redInstantCommon = fakeFavouriteCard(
      id: 'red-instant-common',
      typeLine: 'Instant',
      rarity: 'common',
      colors: ['R'],
    );
    final greenCreatureRare = fakeFavouriteCard(
      id: 'green-creature-rare',
      typeLine: 'Creature — Elf',
      rarity: 'rare',
      colors: ['G'],
    );
    final blueEnchantmentUncommon = fakeFavouriteCard(
      id: 'blue-enchantment-uncommon',
      typeLine: 'Enchantment',
      rarity: 'uncommon',
      colors: ['U'],
    );

    final allCards = [
      redInstantCommon,
      greenCreatureRare,
      blueEnchantmentUncommon,
    ];

    test('empty filter returns all cards', () {
      final result = applyFilter(allCards, const FavouritesFilter());
      expect(result, hasLength(3));
    });

    test('color filter matches cards containing any selected color', () {
      final filter = const FavouritesFilter(colors: {'R'});
      final result = applyFilter(allCards, filter);
      expect(result, hasLength(1));
      expect(result.first.id, equals('red-instant-common'));
    });

    test(
      'type filter matches cards whose typeLine contains any selected type',
      () {
        final filter = const FavouritesFilter(types: {'Instant'});
        final result = applyFilter(allCards, filter);
        expect(result, hasLength(1));
        expect(result.first.id, equals('red-instant-common'));
      },
    );

    test('rarity filter matches exact rarity string', () {
      final filter = const FavouritesFilter(rarities: {'common'});
      final result = applyFilter(allCards, filter);
      expect(result, hasLength(1));
      expect(result.first.id, equals('red-instant-common'));
    });

    test(
      'combined color+type+rarity filter applies all conditions (AND logic)',
      () {
        // Only redInstantCommon matches all three: color R, type Instant, rarity common.
        final filter = const FavouritesFilter(
          colors: {'R'},
          types: {'Instant'},
          rarities: {'common'},
        );
        final result = applyFilter(allCards, filter);
        expect(result, hasLength(1));
        expect(result.first.id, equals('red-instant-common'));
      },
    );

    test('filter with no matching cards returns empty list', () {
      // No card has both color B and type Instant simultaneously.
      final filter = const FavouritesFilter(
        colors: {'B'},
        types: {'Sorcery'},
      );
      final result = applyFilter(allCards, filter);
      expect(result, isEmpty);
    });
  });
}
