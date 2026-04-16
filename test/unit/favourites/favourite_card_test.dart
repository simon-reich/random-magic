import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:random_magic/features/favourites/domain/favourite_card.dart';

/// Unit tests for [FavouriteCard] and [FavouriteCardAdapter].
///
/// Validates the domain model fields and round-trip serialisation via the
/// hand-written Hive CE adapter using a real Hive box opened in a temp directory.
void main() {
  group('FavouriteCard', () {
    test('constructs with all required fields without error', () {
      final card = FavouriteCard(
        id: 'abc',
        name: 'Lightning Bolt',
        typeLine: 'Instant',
        rarity: 'common',
        setCode: 'lea',
        savedAt: DateTime(2024, 1, 15),
        colors: const ['R'],
      );

      expect(card.id, 'abc');
      expect(card.name, 'Lightning Bolt');
      expect(card.typeLine, 'Instant');
      expect(card.rarity, 'common');
      expect(card.setCode, 'lea');
      expect(card.colors, ['R']);
      expect(card.artCropUrl, isNull);
      expect(card.normalImageUrl, isNull);
      expect(card.manaCost, isNull);
    });

    test('constructs with all optional fields', () {
      final card = FavouriteCard(
        id: 'xyz',
        name: 'Tarmogoyf',
        typeLine: 'Creature — Lhurgoyf',
        rarity: 'rare',
        setCode: 'fut',
        savedAt: DateTime(2024, 6, 1),
        colors: const ['G'],
        artCropUrl: 'https://example.com/art.jpg',
        normalImageUrl: 'https://example.com/normal.jpg',
        manaCost: '{1}{G}',
      );

      expect(card.artCropUrl, 'https://example.com/art.jpg');
      expect(card.normalImageUrl, 'https://example.com/normal.jpg');
      expect(card.manaCost, '{1}{G}');
    });

    test('colors list preserves multi-color', () {
      final card = FavouriteCard(
        id: 'multi',
        name: 'Gruul Spellbreaker',
        typeLine: 'Creature — Ogre Warrior',
        rarity: 'rare',
        setCode: 'rna',
        savedAt: DateTime(2024, 1, 1),
        colors: const ['R', 'G'],
      );

      expect(card.colors, ['R', 'G']);
    });

    test('colors list can be empty for colorless cards', () {
      final card = FavouriteCard(
        id: 'colorless',
        name: 'Eldrazi Temple',
        typeLine: 'Land',
        rarity: 'uncommon',
        setCode: 'roe',
        savedAt: DateTime(2024, 1, 1),
        colors: const [],
      );

      expect(card.colors, isEmpty);
    });
  });

  group('FavouriteCardAdapter', () {
    test('typeId is 1', () {
      final adapter = FavouriteCardAdapter();
      expect(adapter.typeId, 1);
    });
  });

  group('FavouriteCard round-trip via Hive box', () {
    late Box<FavouriteCard> box;

    setUp(() async {
      Hive.init(Directory.systemTemp.path);
      // Guard against double-registration across test runs
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(FavouriteCardAdapter());
      }
      box = await Hive.openBox<FavouriteCard>('test_favourites');
      await box.clear();
    });

    tearDown(() async {
      await Hive.close();
    });

    test('round-trips a fully-populated FavouriteCard', () async {
      final original = FavouriteCard(
        id: 'abc123',
        name: 'Lightning Bolt',
        typeLine: 'Instant',
        rarity: 'common',
        setCode: 'lea',
        savedAt: DateTime.utc(2024, 1, 15, 12, 0, 0),
        colors: const ['R'],
        artCropUrl: 'https://example.com/art.jpg',
        normalImageUrl: 'https://example.com/normal.jpg',
        manaCost: '{R}',
      );

      await box.put(original.id, original);
      final restored = box.get(original.id)!;

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.typeLine, original.typeLine);
      expect(restored.rarity, original.rarity);
      expect(restored.setCode, original.setCode);
      expect(restored.artCropUrl, original.artCropUrl);
      expect(restored.normalImageUrl, original.normalImageUrl);
      expect(restored.manaCost, original.manaCost);
      expect(
        restored.savedAt.toIso8601String(),
        original.savedAt.toIso8601String(),
      );
      expect(restored.colors, original.colors);
    });

    test('round-trips with nullable fields as null', () async {
      final original = FavouriteCard(
        id: 'null-test',
        name: 'Plains',
        typeLine: 'Basic Land — Plains',
        rarity: 'common',
        setCode: 'lea',
        savedAt: DateTime.utc(2024, 3, 1),
        colors: const [],
      );

      await box.put(original.id, original);
      final restored = box.get(original.id)!;

      expect(restored.artCropUrl, isNull);
      expect(restored.normalImageUrl, isNull);
      expect(restored.manaCost, isNull);
      expect(restored.colors, isEmpty);
    });

    test('savedAt round-trips preserving the ISO-8601 timestamp', () async {
      final savedAt = DateTime.utc(2024, 12, 25, 8, 30, 0);
      final card = FavouriteCard(
        id: 'date-test',
        name: 'Gift of Fortune',
        typeLine: 'Instant',
        rarity: 'uncommon',
        setCode: 'xmas',
        savedAt: savedAt,
        colors: const [],
      );

      await box.put(card.id, card);
      final restored = box.get(card.id)!;

      expect(restored.savedAt.toIso8601String(), savedAt.toIso8601String());
    });

    test('round-trips multi-color list preserving order', () async {
      final original = FavouriteCard(
        id: 'wubrg',
        name: 'Sliver Hivelord',
        typeLine: 'Legendary Creature — Sliver',
        rarity: 'mythic',
        setCode: 'm15',
        savedAt: DateTime.utc(2024, 1, 1),
        colors: const ['W', 'U', 'B', 'R', 'G'],
      );

      await box.put(original.id, original);
      final restored = box.get(original.id)!;

      expect(restored.colors, ['W', 'U', 'B', 'R', 'G']);
    });
  });
}
