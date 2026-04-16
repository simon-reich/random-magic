import 'package:hive_ce/hive.dart';
import 'package:random_magic/features/favourites/domain/favourite_card.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// Immutable filter state for the Favourites grid.
///
/// All fields are empty sets by default — an empty filter means "show all cards"
/// (FAV-07, D-10). Filter state is in-memory only; resets when the Favourites tab
/// is left because [FavouritesFilterNotifier] uses the default autoDispose lifecycle.
class FavouritesFilter {
  /// Creates an immutable filter snapshot.
  const FavouritesFilter({
    this.colors = const {},
    this.types = const {},
    this.rarities = const {},
  });

  /// Selected colour identities (e.g. {'R', 'G'}). Empty = no colour filter.
  final Set<String> colors;

  /// Selected type strings (e.g. {'Creature', 'Instant'}). Matched via [String.contains]
  /// against [FavouriteCard.typeLine]. Empty = no type filter.
  final Set<String> types;

  /// Selected rarity strings (e.g. {'common', 'rare'}). Exact match against
  /// [FavouriteCard.rarity]. Empty = no rarity filter.
  final Set<String> rarities;

  /// Returns a copy of this filter with the specified fields replaced.
  FavouritesFilter copyWith({
    Set<String>? colors,
    Set<String>? types,
    Set<String>? rarities,
  }) =>
      FavouritesFilter(
        colors: colors ?? this.colors,
        types: types ?? this.types,
        rarities: rarities ?? this.rarities,
      );

  /// Returns true if no filter criteria are set (equivalent to "show all").
  bool get isEmpty => colors.isEmpty && types.isEmpty && rarities.isEmpty;
}

/// Manages the user's saved favourites collection persisted in Hive CE.
///
/// State is kept alive across tab navigation ([keepAlive: true]) so that the
/// Favourites grid is never re-read from disk on each tab switch (FAV-05).
///
/// Mirrors the [FilterPresetsNotifier] write-through pattern established in Phase 2.
/// Reads are synchronous (Hive CE box is in-memory after [Hive.openBox]).
@Riverpod(keepAlive: true)
class FavouritesNotifier extends _$FavouritesNotifier {
  // Direct box access — faster than going through FavouritesRepository for
  // the isFavourite() hot path (called per rendered card in CardSwipeScreen).
  Box<FavouriteCard> get _box => Hive.box<FavouriteCard>('favourites');

  @override
  List<FavouriteCard> build() => _sorted();

  /// Saves [card] to the Hive box using [FavouriteCard.id] as the key (FAV-01, FAV-05).
  ///
  /// Idempotent — calling [add] with the same [card.id] overwrites the earlier entry.
  /// Updates [state] immediately so the grid rebuilds without a box re-read.
  void add(FavouriteCard card) {
    _box.put(card.id, card);
    state = _sorted();
  }

  /// Removes the card with [id] from the Hive box (FAV-04).
  ///
  /// No-op if [id] is not in the box.
  void remove(String id) {
    _box.delete(id);
    state = _sorted();
  }

  /// Returns true if a card with [id] is currently saved (FAV-01).
  ///
  /// Synchronous O(1) lookup on the in-memory Hive box — safe to call in
  /// [CardSwipeScreen.build()] without async overhead.
  bool isFavourite(String id) => _box.containsKey(id);

  /// Returns all favourites sorted newest [FavouriteCard.savedAt] first.
  List<FavouriteCard> _sorted() =>
      _box.values.toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt));
}

/// Manages the in-memory filter applied to the Favourites grid (FAV-07, D-10).
///
/// autoDispose (default in Riverpod 3.x — no keepAlive annotation) so filter state
/// resets automatically when the Favourites tab is left and the screen is disposed.
@riverpod
class FavouritesFilterNotifier extends _$FavouritesFilterNotifier {
  @override
  FavouritesFilter build() => const FavouritesFilter();

  /// Replaces the active colour selection.
  void setColors(Set<String> colors) => state = state.copyWith(colors: colors);

  /// Replaces the active card type selection.
  void setTypes(Set<String> types) => state = state.copyWith(types: types);

  /// Replaces the active rarity selection.
  void setRarities(Set<String> rarities) =>
      state = state.copyWith(rarities: rarities);

  /// Clears all filter criteria, returning to the "show all" state.
  void reset() => state = const FavouritesFilter();
}

/// Derives the filtered list of favourites for the grid (FAV-07, D-11).
///
/// Watches both [favouritesProvider] (source of truth) and
/// [favouritesFilterNotifierProvider] (in-memory filter state) and recomputes
/// the filtered list whenever either changes. Filter is applied client-side —
/// no Hive re-read on filter change.
///
/// Returns ALL cards when the filter is empty.
@riverpod
List<FavouriteCard> filteredFavourites(Ref ref) {
  final all = ref.watch(favouritesProvider);
  // favouritesFilterProvider is the Riverpod 3.x generated name for FavouritesFilterNotifier
  // (code-gen strips "Notifier" suffix from the provider identifier).
  final filter = ref.watch(favouritesFilterProvider);

  if (filter.isEmpty) return all;

  return all.where((card) {
    // Colour: card must share at least one colour with the filter (OR logic per colour).
    final colorMatch = filter.colors.isEmpty ||
        card.colors.any((c) => filter.colors.contains(c));
    // Type: card's typeLine must contain at least one selected type string (e.g. 'Creature').
    final typeMatch = filter.types.isEmpty ||
        filter.types.any((t) => card.typeLine.contains(t));
    // Rarity: exact string match (Scryfall values: 'common', 'uncommon', 'rare', 'mythic').
    final rarityMatch =
        filter.rarities.isEmpty || filter.rarities.contains(card.rarity);
    // All three conditions must be satisfied simultaneously (AND across categories).
    return colorMatch && typeMatch && rarityMatch;
  }).toList();
}
