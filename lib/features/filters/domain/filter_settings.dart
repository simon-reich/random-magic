import 'package:random_magic/shared/models/mtg_color.dart';

/// Immutable snapshot of all active filter criteria.
///
/// An instance with all fields empty/null represents "no filter" — used to
/// produce an unrestricted random card query (FILT-10).
///
/// Never persisted directly. Only [FilterPreset] (which wraps [FilterSettings])
/// is stored in Hive CE.
class FilterSettings {
  /// Creates a [FilterSettings] instance.
  ///
  /// All fields default to empty/null, representing no active filters.
  const FilterSettings({
    this.colors = const {},
    this.types = const {},
    this.rarities = const {},
    this.releasedAfter,
    this.releasedBefore,
  });

  /// Active colour filters. Matches `color:W`, `color:U`, etc. in Scryfall.
  final Set<MtgColor> colors;

  /// Active card type filters. Values are Scryfall type names:
  /// 'Creature', 'Instant', 'Sorcery', 'Enchantment', 'Artifact',
  /// 'Land', 'Planeswalker', 'Battle'.
  final Set<String> types;

  /// Active rarity filters. Values are Scryfall rarity codes:
  /// 'common', 'uncommon', 'rare', 'mythic'.
  final Set<String> rarities;

  /// Lower bound on card release date (Scryfall: `date>=YYYY-MM-DD`).
  final DateTime? releasedAfter;

  /// Upper bound on card release date (Scryfall: `date<=YYYY-MM-DD`).
  final DateTime? releasedBefore;

  /// Returns true when all filter fields are empty / null.
  ///
  /// Used by [ScryfallQueryBuilder.fromSettings] to return null (no `q` param)
  /// and by [CardSwipeScreen] to hide the active filter bar.
  bool get isEmpty =>
      colors.isEmpty &&
      types.isEmpty &&
      rarities.isEmpty &&
      releasedAfter == null &&
      releasedBefore == null;

  /// Returns a copy of this [FilterSettings] with the specified fields replaced.
  ///
  /// Use [clearReleasedAfter] or [clearReleasedBefore] to explicitly set a
  /// date field to null — passing null for those params keeps the existing value.
  FilterSettings copyWith({
    Set<MtgColor>? colors,
    Set<String>? types,
    Set<String>? rarities,
    DateTime? releasedAfter,
    DateTime? releasedBefore,
    bool clearReleasedAfter = false,
    bool clearReleasedBefore = false,
  }) {
    return FilterSettings(
      colors: colors ?? this.colors,
      types: types ?? this.types,
      rarities: rarities ?? this.rarities,
      releasedAfter: clearReleasedAfter ? null : (releasedAfter ?? this.releasedAfter),
      releasedBefore: clearReleasedBefore ? null : (releasedBefore ?? this.releasedBefore),
    );
  }
}
