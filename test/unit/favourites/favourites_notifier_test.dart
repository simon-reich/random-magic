import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:random_magic/features/favourites/domain/favourite_card.dart';
import 'package:random_magic/features/favourites/presentation/providers.dart';

import '../../fixtures/fake_favourite_card.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    Hive.init(Directory.systemTemp.path);
    // Guard against double-registration across test runs (FAV typeId: 1)
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(FavouriteCardAdapter());
    }
    final box = await Hive.openBox<FavouriteCard>('favourites');
    await box.clear();
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
  });

  group('FavouritesNotifier', () {
    test('initial state is empty when box is empty (FAV-05)', () async {
      expect(container.read(favouritesProvider), isEmpty);
    });

    test('add() stores card and isFavourite() returns true (FAV-01)', () async {
      final card = fakeFavouriteCard();
      container.read(favouritesProvider.notifier).add(card);

      expect(
        container.read(favouritesProvider.notifier).isFavourite('abc-123'),
        isTrue,
      );
      expect(container.read(favouritesProvider), hasLength(1));
    });

    test(
      'remove() deletes card and isFavourite() returns false (FAV-04)',
      () async {
        final card = fakeFavouriteCard();
        container.read(favouritesProvider.notifier).add(card);
        container.read(favouritesProvider.notifier).remove('abc-123');

        expect(
          container.read(favouritesProvider.notifier).isFavourite('abc-123'),
          isFalse,
        );
        expect(container.read(favouritesProvider), isEmpty);
      },
    );

    test('state is sorted newest-savedAt first', () async {
      final older = fakeFavouriteCard(
        id: 'older',
        savedAt: DateTime(2024, 1, 1),
      );
      final newer = fakeFavouriteCard(
        id: 'newer',
        savedAt: DateTime(2024, 6, 1),
      );

      // Add older first, then newer — sorted list should put newer at index 0.
      container.read(favouritesProvider.notifier).add(older);
      container.read(favouritesProvider.notifier).add(newer);

      final state = container.read(favouritesProvider);
      expect(state.first.id, equals('newer'));
      expect(state.last.id, equals('older'));
    });

    test('add() is idempotent for same card.id (FAV-05)', () async {
      final card = fakeFavouriteCard();
      container.read(favouritesProvider.notifier).add(card);
      container.read(favouritesProvider.notifier).add(card);

      expect(container.read(favouritesProvider), hasLength(1));
    });

    test('Hive box persists after close and reopen (FAV-05)', () async {
      final card = fakeFavouriteCard();
      container.read(favouritesProvider.notifier).add(card);
      container.dispose();

      // Close Hive and re-initialise to simulate app restart.
      await Hive.close();
      Hive.init(Directory.systemTemp.path);
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(FavouriteCardAdapter());
      }
      await Hive.openBox<FavouriteCard>('favourites');

      // A fresh ProviderContainer should read the persisted card from the reopened box.
      final fresh = ProviderContainer();
      addTearDown(fresh.dispose);
      expect(fresh.read(favouritesProvider), hasLength(1));
      expect(fresh.read(favouritesProvider).first.id, equals('abc-123'));
    });
  });
}
