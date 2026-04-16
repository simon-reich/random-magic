import 'package:hive_ce/hive.dart';
import 'package:random_magic/features/favourites/domain/favourite_card.dart';

/// Local storage repository for the user's saved favourite cards.
///
/// Provides synchronous Hive CE read/write operations against the `'favourites'`
/// box (opened in [main]). All write operations are write-through — Hive flushes
/// to disk automatically after each [put] / [delete].
///
/// Uses [FavouriteCard.id] as the Hive box key, guaranteeing uniqueness and
/// enabling O(1) lookups via [contains] (D-12, D-13).
class FavouritesRepository {
  Box<FavouriteCard> get _box => Hive.box<FavouriteCard>('favourites');

  /// Returns all saved favourites sorted by [FavouriteCard.savedAt] descending
  /// (newest first). Pure in-memory read — O(n log n).
  List<FavouriteCard> getAll() =>
      _box.values.toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt));

  /// Saves [card] using [FavouriteCard.id] as the box key.
  ///
  /// Idempotent — writing the same [id] twice overwrites the earlier entry.
  void save(FavouriteCard card) => _box.put(card.id, card);

  /// Deletes the card with the given [id]. No-op if [id] is not in the box.
  void delete(String id) => _box.delete(id);

  /// Returns true if a card with [id] is in the box. Synchronous O(1) lookup.
  bool contains(String id) => _box.containsKey(id);
}
