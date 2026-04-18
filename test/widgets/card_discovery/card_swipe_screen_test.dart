import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_magic/features/card_discovery/presentation/card_swipe_screen.dart';
import 'package:random_magic/features/card_discovery/domain/card_repository.dart';
import 'package:random_magic/features/card_discovery/presentation/providers.dart';
import 'package:random_magic/features/favourites/domain/favourite_card.dart';
import 'package:random_magic/features/filters/domain/filter_preset.dart';
import 'package:random_magic/features/filters/presentation/providers.dart';
import 'package:random_magic/shared/failures.dart';
import 'package:random_magic/shared/providers/favourites_provider.dart';
import 'package:random_magic/shared/result.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../fixtures/fake_card_repository.dart';
import '../../fixtures/fake_magic_card.dart';

/// Stub for [FavouritesNotifier] — avoids requiring Hive.box('favourites').
///
/// Overrides both [build] and [isFavourite] so that the widget under test
/// never reaches [Hive.box('favourites')] — not even via the hot-path lookup
/// in [_CardSwipeScreenState.build].
class _StubFavouritesNotifier extends FavouritesNotifier {
  @override
  List<FavouriteCard> build() => const [];

  @override
  bool isFavourite(String id) => false;
}

/// Stub for [FilterPresetsNotifier] — avoids requiring Hive.box('filter_presets').
class _StubPresetsNotifier extends FilterPresetsNotifier {
  @override
  List<FilterPreset> build() => const [];
}

/// Pumps [CardSwipeScreen] with all Hive-dependent providers stubbed out.
///
/// [repository] controls what [randomCardProvider] resolves to.
Future<void> pumpSwipeScreen(
  WidgetTester tester, {
  required CardRepository repository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cardRepositoryProvider.overrideWithValue(repository),
        favouritesProvider.overrideWith(_StubFavouritesNotifier.new),
        filterPresetsProvider.overrideWith(_StubPresetsNotifier.new),
      ],
      child: const MaterialApp(home: CardSwipeScreen()),
    ),
  );
}

void main() {
  group('CardSwipeScreen — loading state (TEST-03)', () {
    testWidgets('shows Skeletonizer shimmer while card is loading', (tester) async {
      // StallingFakeRepository never resolves → AsyncLoading perpetually.
      await pumpSwipeScreen(tester, repository: StallingFakeRepository());
      // pump(Duration.zero) lets microtasks run so RandomCardNotifier enters AsyncLoading
      // without settling (pumpAndSettle would wait forever for the stalling future).
      await tester.pump(Duration.zero);

      // Skeletonizer is abstract; the concrete type is private _Skeletonizer.
      // Use byWidgetPredicate so the `is` check matches the subtype at runtime.
      expect(
        find.byWidgetPredicate((w) => w is Skeletonizer),
        findsWidgets,
      );
      // Fake card name must NOT appear — skeleton placeholder has empty strings.
      expect(find.text('Lightning Bolt'), findsNothing);
    });
  });

  group('CardSwipeScreen — success state (TEST-03, QA-02)', () {
    testWidgets('shows bookmark button when card is loaded', (tester) async {
      await pumpSwipeScreen(
        tester,
        repository: FakeCardRepository(result: Success(fakeMagicCard())),
      );
      await tester.pumpAndSettle();

      // Skeletonizer is gone on success — enabled Skeletonizer should not exist.
      expect(
        find.byWidgetPredicate(
          (w) => w is Skeletonizer && w.enabled,
        ),
        findsNothing,
      );
      // Bookmark IconButton always rendered in success state.
      expect(find.byTooltip('Save to Favourites'), findsOneWidget);
    });
  });

  group('CardSwipeScreen — error states (TEST-03, QA-02)', () {
    testWidgets('CardNotFoundFailure shows "No cards found" and "Adjust Filters" button',
        (tester) async {
      await pumpSwipeScreen(
        tester,
        repository: FailingFakeRepository(const CardNotFoundFailure()),
      );
      await tester.pumpAndSettle();

      expect(find.text('No cards found'), findsOneWidget);
      expect(find.text('Adjust Filters'), findsOneWidget);
    });

    testWidgets('InvalidQueryFailure shows "Invalid filter settings" and "Fix Filters" button',
        (tester) async {
      await pumpSwipeScreen(
        tester,
        repository: FailingFakeRepository(const InvalidQueryFailure()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Invalid filter settings'), findsOneWidget);
      expect(find.text('Fix Filters'), findsOneWidget);
    });

    testWidgets('NetworkFailure shows "Could not reach Scryfall" and "Retry" button',
        (tester) async {
      await pumpSwipeScreen(
        tester,
        repository: FailingFakeRepository(const NetworkFailure()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Could not reach Scryfall'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('RateLimitedFailure shows "Too Many Requests" and "Retry" button',
        (tester) async {
      await pumpSwipeScreen(
        tester,
        repository: FailingFakeRepository(const RateLimitedFailure()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Too Many Requests'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
