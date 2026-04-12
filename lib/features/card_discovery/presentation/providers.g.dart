// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a [ScryfallApiClient] backed by the shared [dioProvider].

@ProviderFor(scryfallApiClient)
final scryfallApiClientProvider = ScryfallApiClientProvider._();

/// Provides a [ScryfallApiClient] backed by the shared [dioProvider].

final class ScryfallApiClientProvider
    extends
        $FunctionalProvider<
          ScryfallApiClient,
          ScryfallApiClient,
          ScryfallApiClient
        >
    with $Provider<ScryfallApiClient> {
  /// Provides a [ScryfallApiClient] backed by the shared [dioProvider].
  ScryfallApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scryfallApiClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scryfallApiClientHash();

  @$internal
  @override
  $ProviderElement<ScryfallApiClient> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ScryfallApiClient create(Ref ref) {
    return scryfallApiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScryfallApiClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScryfallApiClient>(value),
    );
  }
}

String _$scryfallApiClientHash() => r'341ef6396c6c8148bffa63a2bc887fb8578d39b9';

/// Provides the [CardRepository] implementation.
///
/// Swap this override in tests to inject a fake repository without touching Dio.

@ProviderFor(cardRepository)
final cardRepositoryProvider = CardRepositoryProvider._();

/// Provides the [CardRepository] implementation.
///
/// Swap this override in tests to inject a fake repository without touching Dio.

final class CardRepositoryProvider
    extends $FunctionalProvider<CardRepository, CardRepository, CardRepository>
    with $Provider<CardRepository> {
  /// Provides the [CardRepository] implementation.
  ///
  /// Swap this override in tests to inject a fake repository without touching Dio.
  CardRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cardRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cardRepositoryHash();

  @$internal
  @override
  $ProviderElement<CardRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CardRepository create(Ref ref) {
    return cardRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CardRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CardRepository>(value),
    );
  }
}

String _$cardRepositoryHash() => r'436e05298717f080ca7cc97dbb996c3197046b00';

/// Manages the state of the currently displayed random card.
///
/// Exposes [AsyncValue<MagicCard>] — consumers use `.when(data:, loading:, error:)`
/// to render the appropriate UI state.
///
/// Call [randomCardNotifier.refresh] to fetch a new random card (e.g. on swipe).

@ProviderFor(RandomCardNotifier)
final randomCardProvider = RandomCardNotifierProvider._();

/// Manages the state of the currently displayed random card.
///
/// Exposes [AsyncValue<MagicCard>] — consumers use `.when(data:, loading:, error:)`
/// to render the appropriate UI state.
///
/// Call [randomCardNotifier.refresh] to fetch a new random card (e.g. on swipe).
final class RandomCardNotifierProvider
    extends $AsyncNotifierProvider<RandomCardNotifier, MagicCard> {
  /// Manages the state of the currently displayed random card.
  ///
  /// Exposes [AsyncValue<MagicCard>] — consumers use `.when(data:, loading:, error:)`
  /// to render the appropriate UI state.
  ///
  /// Call [randomCardNotifier.refresh] to fetch a new random card (e.g. on swipe).
  RandomCardNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'randomCardProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$randomCardNotifierHash();

  @$internal
  @override
  RandomCardNotifier create() => RandomCardNotifier();
}

String _$randomCardNotifierHash() =>
    r'67d7900c032390b97e1de3760f7b600aa9aa48b7';

/// Manages the state of the currently displayed random card.
///
/// Exposes [AsyncValue<MagicCard>] — consumers use `.when(data:, loading:, error:)`
/// to render the appropriate UI state.
///
/// Call [randomCardNotifier.refresh] to fetch a new random card (e.g. on swipe).

abstract class _$RandomCardNotifier extends $AsyncNotifier<MagicCard> {
  FutureOr<MagicCard> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<MagicCard>, MagicCard>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MagicCard>, MagicCard>,
              AsyncValue<MagicCard>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
