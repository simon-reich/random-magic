import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_magic/features/card_discovery/presentation/card_swipe_screen.dart';
import 'package:random_magic/features/card_discovery/presentation/providers.dart';
import 'package:random_magic/features/favourites/domain/favourite_card.dart';
import 'package:random_magic/features/favourites/presentation/providers.dart';
import 'package:random_magic/features/filters/domain/filter_preset.dart';
import 'package:random_magic/features/filters/domain/filter_settings.dart';
import 'package:random_magic/features/filters/presentation/providers.dart';
import 'package:random_magic/shared/models/mtg_color.dart';
import 'package:random_magic/shared/result.dart';

import '../../fixtures/fake_card_repository.dart';
import '../../fixtures/fake_magic_card.dart';

class _StubFavouritesNotifier extends FavouritesNotifier {
  @override
  List<FavouriteCard> build() => const [];

  @override
  bool isFavourite(String id) => false;
}

class _StubPresetsNotifier extends FilterPresetsNotifier {
  @override
  List<FilterPreset> build() => const [];
}

/// Notifier that returns an empty [FilterSettings] (no active filters).
class _EmptyFilterNotifier extends FilterSettingsNotifier {
  @override
  FilterSettings build() => const FilterSettings();
}

/// Notifier that returns [FilterSettings] with Red color active.
class _RedFilterNotifier extends FilterSettingsNotifier {
  @override
  FilterSettings build() => const FilterSettings(colors: {MtgColor.red});
}

Future<void> pumpScreenWithFilter(
  WidgetTester tester, {
  required FilterSettingsNotifier Function() filterNotifier,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cardRepositoryProvider.overrideWithValue(
          FakeCardRepository(result: Success(fakeMagicCard())),
        ),
        favouritesProvider.overrideWith(_StubFavouritesNotifier.new),
        filterPresetsProvider.overrideWith(_StubPresetsNotifier.new),
        filterSettingsProvider.overrideWith(filterNotifier),
      ],
      child: const MaterialApp(home: CardSwipeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ActiveFilterBar — hidden when no filters (DISC-10)', () {
    testWidgets('no FilterChip visible when filter state is empty', (tester) async {
      await pumpScreenWithFilter(tester, filterNotifier: _EmptyFilterNotifier.new);
      expect(find.byType(FilterChip), findsNothing);
    });
  });

  group('ActiveFilterBar — shows chips when filters active (DISC-10)', () {
    testWidgets('FilterChip with label "Red" visible when red color is active', (tester) async {
      await pumpScreenWithFilter(tester, filterNotifier: _RedFilterNotifier.new);
      expect(find.text('Red'), findsOneWidget);
      expect(find.byType(FilterChip), findsWidgets);
    });
  });

  group('ActiveFilterBar — chip tap removes filter (DISC-10)', () {
    testWidgets('tapping chip delete icon removes the Red color chip', (tester) async {
      await pumpScreenWithFilter(tester, filterNotifier: _RedFilterNotifier.new);

      expect(find.text('Red'), findsOneWidget);

      // Tap the delete icon on the FilterChip for 'Red'
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      expect(find.text('Red'), findsNothing);
      expect(find.byType(FilterChip), findsNothing);
    });
  });
}
