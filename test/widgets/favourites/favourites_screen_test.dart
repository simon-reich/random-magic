import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_magic/features/favourites/presentation/favourites_screen.dart';
import 'package:random_magic/features/favourites/presentation/providers.dart';

import '../../fixtures/fake_favourite_card.dart';

void main() {
  group('FavouritesScreen (FAV-02, FAV-03, FAV-06)', () {
    test(
      'renders empty state widget when no favourites (FAV-06)',
      () async {
        // TODO(wave-2): pump FavouritesScreen with empty provider, find empty state
        expect(true, true);
      },
      skip: 'Wave 0 stub — implementation pending',
    );

    test(
      'renders 3-column grid when favourites exist (FAV-02)',
      () async {
        // TODO(wave-2): pump FavouritesScreen with 3 fakeFavouriteCard(), find GridView
        expect(true, true);
      },
      skip: 'Wave 0 stub — implementation pending',
    );

    test(
      'tapping grid cell navigates to /favourites/:id (FAV-03)',
      () async {
        // TODO(wave-2): tap grid cell, verify route push with card id param
        expect(true, true);
      },
      skip: 'Wave 0 stub — implementation pending',
    );

    test(
      'long-press enters multi-select mode (D-06)',
      () async {
        // TODO(wave-2): long-press cell, verify selection checkmark and count bar appear
        expect(true, true);
      },
      skip: 'Wave 0 stub — implementation pending',
    );

    test(
      'filter bottom sheet opens on filter icon tap (FAV-07)',
      () async {
        // TODO(wave-3): tap filter icon, verify bottom sheet with chip filters visible
        expect(true, true);
      },
      skip: 'Wave 0 stub — implementation pending',
    );
  });
}
