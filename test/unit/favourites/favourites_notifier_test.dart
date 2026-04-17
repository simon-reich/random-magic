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
    test('initial state is empty when box is empty (FAV-05)', () {
      final cards = container.read(favouritesProvider);
      expect(cards, isEmpty);
    });

    test('add() stores card and isFavourite() returns true (FAV-01)', () {
      final card = fakeFavouriteCard(id: 'card-1');
      final notifier = container.read(favouritesProvider.notifier);

      notifier.add(card);

      expect(notifier.isFavourite('card-1'), isTrue);
      expect(container.read(favouritesProvider), contains(card));
    });

    test('remove() deletes card and isFavourite() returns false (FAV-04)',
        () {
      final card = fakeFavouriteCard(id: 'card-2');
      final notifier = container.read(favouritesProvider.notifier);

      notifier.add(card);
      expect(notifier.isFavourite('card-2'), isTrue);

      notifier.remove('card-2');

      expect(notifier.isFavourite('card-2'), isFalse);
      expect(container.read(favouritesProvider), isNot(contains(card)));
    });

    test('state is sorted newest-savedAt first', () {
      final older = fakeFavouriteCard(
        id: 'old',
        name: 'Older Card',
        savedAt: DateTime(2024, 1, 1),
      );
      final newer = fakeFavouriteCard(
        id: 'new',
        name: 'Newer Card',
        savedAt: DateTime(2024, 6, 1),
      );
      final notifier = container.read(favouritesProvider.notifier);

      // Add older first, then newer — sort must override insertion order.
      notifier.add(older);
      notifier.add(newer);

      final state = container.read(favouritesProvider);
      expect(state.length, equals(2));
      // Newest savedAt (June) must come first.
      expect(state.first.id, equals('new'));
      expect(state.last.id, equals('old'));
    });

    test('add() is idempotent for same card.id (FAV-05)', () {
      final card = fakeFavouriteCard(id: 'dup');
      final notifier = container.read(favouritesProvider.notifier);

      notifier.add(card);
      notifier.add(card); // second add with same id

      final state = container.read(favouritesProvider);
      // Box uses id as key — put() overwrites; list must have exactly one entry.
      expect(state.length, equals(1));
    });

    test('Hive box persists after close and reopen (FAV-05)', () async {
      final card = fakeFavouriteCard(id: 'persist-1', name: 'Persist Me');
      container.read(favouritesProvider.notifier).add(card);

      // Dispose container before closing Hive to avoid dangling box reference.
      container.dispose();
      await Hive.close();

      // Reopen box directly — no ProviderContainer needed for this persistence check.
      Hive.init(Directory.systemTemp.path);
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(FavouriteCardAdapter());
      }
      final reopened = await Hive.openBox<FavouriteCard>('favourites');

      expect(reopened.containsKey('persist-1'), isTrue);
      expect(reopened.get('persist-1')!.name, equals('Persist Me'));

      // Re-create a container so tearDown can dispose it without error.
      container = ProviderContainer();
    });
  });
}
