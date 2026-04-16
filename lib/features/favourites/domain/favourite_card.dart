import 'package:hive_ce/hive.dart';

/// A saved card projection stored in the local Hive CE favourites box.
///
/// Contains only the fields needed for display and client-side filtering —
/// NOT the full [MagicCard]. Avoids persisting oracle text, legalities,
/// and price data that are not needed for the Favourites feature (D-12).
///
/// Persisted in Hive CE box `'favourites'` with [id] as the box key.
/// Serialised by [FavouriteCardAdapter].
class FavouriteCard {
  /// Creates a [FavouriteCard] projection from the provided display/filter fields.
  const FavouriteCard({
    required this.id,
    required this.name,
    required this.typeLine,
    required this.rarity,
    required this.setCode,
    required this.savedAt,
    required this.colors,
    this.artCropUrl,
    this.normalImageUrl,
    this.manaCost,
  });

  /// Scryfall card UUID. Used as the Hive box key — guarantees uniqueness (D-12, D-13).
  final String id;

  /// Card name (e.g. 'Lightning Bolt').
  final String name;

  /// Full type line (e.g. 'Instant'). Used for client-side type filtering (D-12).
  final String typeLine;

  /// Rarity string as returned by Scryfall (e.g. 'common', 'rare'). Used for client-side
  /// rarity filtering (D-12). Lowercase — matches Scryfall API values.
  final String rarity;

  /// Scryfall set code (e.g. 'lea'). Displayed in swipe view subtitle.
  final String setCode;

  /// Art-crop image URL (~626×457 px, square-ish). Used as grid thumbnail (D-05).
  /// Null for tokens or emblems with no art crop — grid cell shows [AppColors.surfaceContainer]
  /// fallback (Pitfall 6 in RESEARCH.md).
  final String? artCropUrl;

  /// Normal-format image URL (~488×680 px). Used in [FavouriteSwipeScreen] (D-12).
  /// Null for some promo cards — swipe view must guard.
  final String? normalImageUrl;

  /// Formatted mana cost (e.g. '{2}{R}{R}'). Displayed in swipe view. Null for lands.
  final String? manaCost;

  /// Timestamp when the card was added to Favourites. Used for sort order (newest first).
  final DateTime savedAt;

  /// Scryfall color identity strings (e.g. ['R', 'G'] for Gruul).
  /// Used for client-side colour filtering (D-12).
  /// Empty list for colourless cards.
  final List<String> colors;
}

/// Hand-written Hive CE type adapter for [FavouriteCard].
///
/// typeId: 1 — reserved for FavouriteCard.
/// typeId: 0 is taken by FilterPresetAdapter — collision would corrupt the Hive registry
/// and cause 'type FilterPreset is not a subtype of FavouriteCard' errors at runtime.
///
/// Serialisation field order (MUST NOT change after first release without a migration
/// strategy — reordering fields would corrupt existing saved favourites):
///   0: id           (String)
///   1: name         (String)
///   2: typeLine     (String)
///   3: rarity       (String)
///   4: setCode      (String)
///   5: artCropUrl   (String?)
///   6: normalImageUrl (String?)
///   7: manaCost     (String?)
///   8: savedAt      (String, ISO-8601 — DateTime stored as string to avoid timezone issues)
///   9: colors       (List of String)
class FavouriteCardAdapter extends TypeAdapter<FavouriteCard> {
  @override
  final int typeId = 1;

  @override
  FavouriteCard read(BinaryReader reader) {
    final id = reader.read() as String;
    final name = reader.read() as String;
    final typeLine = reader.read() as String;
    final rarity = reader.read() as String;
    final setCode = reader.read() as String;
    final artCropUrl = reader.read() as String?;
    final normalImageUrl = reader.read() as String?;
    final manaCost = reader.read() as String?;
    // savedAt stored as ISO-8601 string — consistent with FilterPresetAdapter date pattern.
    final savedAtStr = reader.read() as String;
    final colors = (reader.read() as List).cast<String>();
    return FavouriteCard(
      id: id,
      name: name,
      typeLine: typeLine,
      rarity: rarity,
      setCode: setCode,
      artCropUrl: artCropUrl,
      normalImageUrl: normalImageUrl,
      manaCost: manaCost,
      savedAt: DateTime.parse(savedAtStr),
      colors: colors,
    );
  }

  @override
  void write(BinaryWriter writer, FavouriteCard obj) {
    writer.write(obj.id);
    writer.write(obj.name);
    writer.write(obj.typeLine);
    writer.write(obj.rarity);
    writer.write(obj.setCode);
    writer.write(obj.artCropUrl);
    writer.write(obj.normalImageUrl);
    writer.write(obj.manaCost);
    // Store as ISO-8601 string to avoid timezone serialisation issues.
    writer.write(obj.savedAt.toIso8601String());
    writer.write(obj.colors);
  }
}
