import 'package:flutter_test/flutter_test.dart';
import 'package:random_magic/features/filters/data/scryfall_query_builder.dart';
import 'package:random_magic/features/filters/domain/filter_settings.dart';
import 'package:random_magic/shared/models/mtg_color.dart';

void main() {
  group('color filter', () {
    test('single color returns correct query string (FILT-01)', () {
      final result = ScryfallQueryBuilder.fromSettings(
        const FilterSettings(colors: {MtgColor.red}),
      );
      expect(result, contains('color:R'));
    });

    test('multiple colors joined with OR (FILT-01)', () {
      final result = ScryfallQueryBuilder.fromSettings(
        const FilterSettings(colors: {MtgColor.white, MtgColor.blue}),
      );
      expect(result, contains('color:W'));
      expect(result, contains('color:U'));
      expect(result, contains(' OR '));
    });

    test('multicolor (M) uses correct Scryfall syntax (FILT-01)', () {
      final result = ScryfallQueryBuilder.fromSettings(
        const FilterSettings(colors: {MtgColor.multicolor}),
      );
      expect(result, contains('color:m'));
    });

    test('no colors selected produces no color clause (FILT-01)', () {
      final result = ScryfallQueryBuilder.fromSettings(
        const FilterSettings(types: {'Creature'}),
      );
      expect(result, isNotNull);
      expect(result, isNot(contains('color:')));
    });
  });

  group('type filter', () {
    test('single type returns correct query string (FILT-02)', () {
      final result = ScryfallQueryBuilder.fromSettings(
        const FilterSettings(types: {'Creature'}),
      );
      expect(result, contains('type:Creature'));
    });

    test('multiple types joined with OR (FILT-02)', () {
      final result = ScryfallQueryBuilder.fromSettings(
        const FilterSettings(types: {'Creature', 'Instant'}),
      );
      expect(result, contains('type:Creature'));
      expect(result, contains('type:Instant'));
      expect(result, contains(' OR '));
    });
  });

  group('rarity filter', () {
    test('single rarity returns correct query string (FILT-03)', () {
      final result = ScryfallQueryBuilder.fromSettings(
        const FilterSettings(rarities: {'common'}),
      );
      expect(result, contains('rarity:common'));
    });

    test('multiple rarities joined with OR (FILT-03)', () {
      final result = ScryfallQueryBuilder.fromSettings(
        const FilterSettings(rarities: {'common', 'rare'}),
      );
      expect(result, contains('rarity:common'));
      expect(result, contains('rarity:rare'));
      expect(result, contains(' OR '));
    });
  });

  group('date filter', () {
    test('releasedAfter produces date>= clause (FILT-04)', () {
      final result = ScryfallQueryBuilder.fromSettings(
        FilterSettings(releasedAfter: DateTime(2020, 1, 1)),
      );
      expect(result, contains('date>=2020-01-01'));
    });

    test('releasedBefore produces date<= clause (FILT-04)', () {
      final result = ScryfallQueryBuilder.fromSettings(
        FilterSettings(releasedBefore: DateTime(2023, 12, 31)),
      );
      expect(result, contains('date<=2023-12-31'));
    });

    test('date range combines both clauses (FILT-04)', () {
      final result = ScryfallQueryBuilder.fromSettings(
        FilterSettings(
          releasedAfter: DateTime(2020, 1, 1),
          releasedBefore: DateTime(2023, 12, 31),
        ),
      );
      expect(result, contains('date>=2020-01-01'));
      expect(result, contains('date<=2023-12-31'));
    });
  });

  group('empty filter', () {
    test('empty FilterSettings returns null query (FILT-10)', () {
      final result = ScryfallQueryBuilder.fromSettings(const FilterSettings());
      expect(result, isNull);
    });
  });
}
