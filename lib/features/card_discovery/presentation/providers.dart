import 'package:random_magic/core/network/dio_client.dart';
import 'package:random_magic/features/card_discovery/data/card_repository_impl.dart';
import 'package:random_magic/features/card_discovery/data/scryfall_api_client.dart';
import 'package:random_magic/features/card_discovery/domain/card_repository.dart';
import 'package:random_magic/shared/models/magic_card.dart';
import 'package:random_magic/shared/result.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// Provides a [ScryfallApiClient] backed by the shared [dioProvider].
@riverpod
ScryfallApiClient scryfallApiClient(Ref ref) {
  return ScryfallApiClient(ref.watch(dioProvider));
}

/// Provides the [CardRepository] implementation.
///
/// Swap this override in tests to inject a fake repository without touching Dio.
@riverpod
CardRepository cardRepository(Ref ref) {
  return CardRepositoryImpl(ref.watch(scryfallApiClientProvider));
}

/// Manages the state of the currently displayed random card.
///
/// Exposes [AsyncValue<MagicCard>] — consumers use `.when(data:, loading:, error:)`
/// to render the appropriate UI state.
///
/// Call [randomCardNotifier.refresh] to fetch a new random card (e.g. on swipe).
@riverpod
class RandomCardNotifier extends _$RandomCardNotifier {
  @override
  Future<MagicCard> build() => _fetch();

  /// Fetches a fresh random card, replacing the current state.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<MagicCard> _fetch({String? query}) async {
    final result = await ref
        .read(cardRepositoryProvider)
        .getRandomCard(query: query);

    return switch (result) {
      // Unwrap the value — AsyncValue.guard will wrap it in AsyncData.
      Success(:final value) => value,
      // Throw the typed failure — AsyncValue.guard catches it as AsyncError.
      // The UI switches on the error type to show the right error state.
      Failure(:final error) => throw error,
    };
  }
}
