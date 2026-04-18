import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_magic/features/card_discovery/presentation/providers.dart';
import 'package:random_magic/shared/failures.dart';
import 'package:random_magic/shared/models/magic_card.dart';
import 'package:random_magic/shared/result.dart';

import '../../fixtures/fake_card_repository.dart';
import '../../fixtures/fake_magic_card.dart';

/// Unit tests for [RandomCardNotifier].
///
/// Tests cover success, CardNotFoundFailure, NetworkFailure, and refresh
/// transitions. Injects fakes via [cardRepositoryProvider.overrideWithValue]
/// so no real HTTP calls or Hive initialisation are needed.
void main() {
  /// Creates a [ProviderContainer] with [cardRepositoryProvider] overridden
  /// to return the given [result], and registers [addTearDown] for disposal.
  ProviderContainer makeContainer({required Result<MagicCard> result}) {
    final container = ProviderContainer(
      overrides: [
        cardRepositoryProvider.overrideWithValue(
          FakeCardRepository(result: result),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Waits until [randomCardProvider] has settled into a data or error state.
  ///
  /// In Riverpod 3.x keepAlive AsyncNotifiers, a thrown error produces a state
  /// where both [AsyncValue.isLoading] and [AsyncValue.hasError] are true
  /// simultaneously. Checking [hasValue] or [hasError] is therefore the reliable
  /// settled signal — not [!isLoading].
  Future<AsyncValue<MagicCard>> awaitSettled(
    ProviderContainer container,
  ) async {
    // Trigger the keepAlive provider's build without subscribing permanently.
    container.read(randomCardProvider);

    // Poll with microtask yields so the async build can complete.
    // Fast fakes resolve in <1ms; 100 iterations is a safe upper bound.
    for (var i = 0; i < 100; i++) {
      await Future<void>.delayed(Duration.zero);
      final s = container.read(randomCardProvider);
      if (s.hasValue || s.hasError) return s;
    }

    // Return current state; test expectation will fail with a useful message.
    return container.read(randomCardProvider);
  }

  group('RandomCardNotifier — build()', () {
    test('resolves to AsyncData when repository returns Success', () async {
      final container = makeContainer(result: Success(fakeMagicCard()));

      final card = await container.read(randomCardProvider.future);

      expect(container.read(randomCardProvider).hasValue, isTrue);
      expect(card.name, 'Lightning Bolt');
    });

    test(
        'resolves to AsyncError with CardNotFoundFailure '
        'when repository returns Failure(CardNotFoundFailure)', () async {
      final container = makeContainer(
        result: const Failure(CardNotFoundFailure()),
      );

      final state = await awaitSettled(container);

      expect(state.hasError, isTrue);
      expect(state.error, isA<CardNotFoundFailure>());
    });

    test(
        'resolves to AsyncError with NetworkFailure '
        'when repository returns Failure(NetworkFailure)', () async {
      final container = makeContainer(
        result: const Failure(NetworkFailure()),
      );

      final state = await awaitSettled(container);

      expect(state.hasError, isTrue);
      expect(state.error, isA<NetworkFailure>());
    });
  });

  group('RandomCardNotifier — refresh()', () {
    test('refresh() resolves to AsyncData after Success', () async {
      final container = makeContainer(result: Success(fakeMagicCard()));

      // Wait for initial build to complete.
      await container.read(randomCardProvider.future);

      await container.read(randomCardProvider.notifier).refresh();

      final state = container.read(randomCardProvider);
      expect(state.hasValue, isTrue);
      expect(state.value!.name, 'Lightning Bolt');
    });

    test('refresh() resolves to AsyncError after Failure', () async {
      final container = makeContainer(
        result: const Failure(CardNotFoundFailure()),
      );

      // Wait for initial error state.
      await awaitSettled(container);

      // refresh() calls AsyncValue.guard internally — the method itself
      // completes even when the underlying fetch throws. Error is in state.
      await container.read(randomCardProvider.notifier).refresh();

      final state = container.read(randomCardProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<CardNotFoundFailure>());
    });
  });
}
