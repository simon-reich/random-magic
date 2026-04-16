// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the user's saved favourites collection persisted in Hive CE.
///
/// State is kept alive across tab navigation ([keepAlive: true]) so that the
/// Favourites grid is never re-read from disk on each tab switch (FAV-05).
///
/// Mirrors the [FilterPresetsNotifier] write-through pattern established in Phase 2.
/// Reads are synchronous (Hive CE box is in-memory after [Hive.openBox]).

@ProviderFor(FavouritesNotifier)
final favouritesProvider = FavouritesNotifierProvider._();

/// Manages the user's saved favourites collection persisted in Hive CE.
///
/// State is kept alive across tab navigation ([keepAlive: true]) so that the
/// Favourites grid is never re-read from disk on each tab switch (FAV-05).
///
/// Mirrors the [FilterPresetsNotifier] write-through pattern established in Phase 2.
/// Reads are synchronous (Hive CE box is in-memory after [Hive.openBox]).
final class FavouritesNotifierProvider
    extends $NotifierProvider<FavouritesNotifier, List<FavouriteCard>> {
  /// Manages the user's saved favourites collection persisted in Hive CE.
  ///
  /// State is kept alive across tab navigation ([keepAlive: true]) so that the
  /// Favourites grid is never re-read from disk on each tab switch (FAV-05).
  ///
  /// Mirrors the [FilterPresetsNotifier] write-through pattern established in Phase 2.
  /// Reads are synchronous (Hive CE box is in-memory after [Hive.openBox]).
  FavouritesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favouritesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favouritesNotifierHash();

  @$internal
  @override
  FavouritesNotifier create() => FavouritesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FavouriteCard> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FavouriteCard>>(value),
    );
  }
}

String _$favouritesNotifierHash() =>
    r'42fc32816b0c61a07c3ddb63ac98ce73fdf6c5e3';

/// Manages the user's saved favourites collection persisted in Hive CE.
///
/// State is kept alive across tab navigation ([keepAlive: true]) so that the
/// Favourites grid is never re-read from disk on each tab switch (FAV-05).
///
/// Mirrors the [FilterPresetsNotifier] write-through pattern established in Phase 2.
/// Reads are synchronous (Hive CE box is in-memory after [Hive.openBox]).

abstract class _$FavouritesNotifier extends $Notifier<List<FavouriteCard>> {
  List<FavouriteCard> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<FavouriteCard>, List<FavouriteCard>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<FavouriteCard>, List<FavouriteCard>>,
              List<FavouriteCard>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Manages the in-memory filter applied to the Favourites grid (FAV-07, D-10).
///
/// autoDispose (default in Riverpod 3.x — no keepAlive annotation) so filter state
/// resets automatically when the Favourites tab is left and the screen is disposed.

@ProviderFor(FavouritesFilterNotifier)
final favouritesFilterProvider = FavouritesFilterNotifierProvider._();

/// Manages the in-memory filter applied to the Favourites grid (FAV-07, D-10).
///
/// autoDispose (default in Riverpod 3.x — no keepAlive annotation) so filter state
/// resets automatically when the Favourites tab is left and the screen is disposed.
final class FavouritesFilterNotifierProvider
    extends $NotifierProvider<FavouritesFilterNotifier, FavouritesFilter> {
  /// Manages the in-memory filter applied to the Favourites grid (FAV-07, D-10).
  ///
  /// autoDispose (default in Riverpod 3.x — no keepAlive annotation) so filter state
  /// resets automatically when the Favourites tab is left and the screen is disposed.
  FavouritesFilterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favouritesFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favouritesFilterNotifierHash();

  @$internal
  @override
  FavouritesFilterNotifier create() => FavouritesFilterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FavouritesFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FavouritesFilter>(value),
    );
  }
}

String _$favouritesFilterNotifierHash() =>
    r'ddf48a627fbf013b726d5c2150385fc0b35fbed1';

/// Manages the in-memory filter applied to the Favourites grid (FAV-07, D-10).
///
/// autoDispose (default in Riverpod 3.x — no keepAlive annotation) so filter state
/// resets automatically when the Favourites tab is left and the screen is disposed.

abstract class _$FavouritesFilterNotifier extends $Notifier<FavouritesFilter> {
  FavouritesFilter build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FavouritesFilter, FavouritesFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FavouritesFilter, FavouritesFilter>,
              FavouritesFilter,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Derives the filtered list of favourites for the grid (FAV-07, D-11).
///
/// Watches both [favouritesProvider] (source of truth) and
/// [favouritesFilterNotifierProvider] (in-memory filter state) and recomputes
/// the filtered list whenever either changes. Filter is applied client-side —
/// no Hive re-read on filter change.
///
/// Returns ALL cards when the filter is empty.

@ProviderFor(filteredFavourites)
final filteredFavouritesProvider = FilteredFavouritesProvider._();

/// Derives the filtered list of favourites for the grid (FAV-07, D-11).
///
/// Watches both [favouritesProvider] (source of truth) and
/// [favouritesFilterNotifierProvider] (in-memory filter state) and recomputes
/// the filtered list whenever either changes. Filter is applied client-side —
/// no Hive re-read on filter change.
///
/// Returns ALL cards when the filter is empty.

final class FilteredFavouritesProvider
    extends
        $FunctionalProvider<
          List<FavouriteCard>,
          List<FavouriteCard>,
          List<FavouriteCard>
        >
    with $Provider<List<FavouriteCard>> {
  /// Derives the filtered list of favourites for the grid (FAV-07, D-11).
  ///
  /// Watches both [favouritesProvider] (source of truth) and
  /// [favouritesFilterNotifierProvider] (in-memory filter state) and recomputes
  /// the filtered list whenever either changes. Filter is applied client-side —
  /// no Hive re-read on filter change.
  ///
  /// Returns ALL cards when the filter is empty.
  FilteredFavouritesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredFavouritesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredFavouritesHash();

  @$internal
  @override
  $ProviderElement<List<FavouriteCard>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<FavouriteCard> create(Ref ref) {
    return filteredFavourites(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FavouriteCard> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FavouriteCard>>(value),
    );
  }
}

String _$filteredFavouritesHash() =>
    r'd0729997ee34ecbc4d7c2ca0a62b9df15de5cfb9';
