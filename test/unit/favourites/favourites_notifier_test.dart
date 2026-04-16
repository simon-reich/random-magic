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
    test(
      'initial state is empty when box is empty (FAV-05)',
      () async {
        // TODO(wave-1): verify container.read(favouritesProvider) is empty
        expect(true, true);
      },
      skip: 'Wave 0 stub — implementation pending',
    );

    test(
      'add() stores card and isFavourite() returns true (FAV-01)',
      () async {
        // TODO(wave-1): add fakeFavouriteCard(), assert isFavourite(id) == true
        expect(true, true);
      },
      skip: 'Wave 0 stub — implementation pending',
    );

    test(
      'remove() deletes card and isFavourite() returns false (FAV-04)',
      () async {
        // TODO(wave-1): add then remove fakeFavouriteCard(), assert not present
        expect(true, true);
      },
      skip: 'Wave 0 stub — implementation pending',
    );

    test(
      'state is sorted newest-savedAt first',
      () async {
        // TODO(wave-1): add two cards with different savedAt, assert order
        expect(true, true);
      },
      skip: 'Wave 0 stub — implementation pending',
    );

    test(
      'add() is idempotent for same card.id (FAV-05)',
      () async {
        // TODO(wave-1): add same card twice, assert length == 1
        expect(true, true);
      },
      skip: 'Wave 0 stub — implementation pending',
    );

    test(
      'Hive box persists after close and reopen (FAV-05)',
      () async {
        // TODO(wave-1): add card, close Hive, reopen box, assert card present
        expect(true, true);
      },
      skip: 'Wave 0 stub — implementation pending',
    );
  });
}
