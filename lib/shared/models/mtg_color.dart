/// The seven MTG mana colours supported by the filter UI.
///
/// [code] is the Scryfall query value used in `color:X` expressions.
/// [displayName] is the human-readable label shown in chips and filter bars.
/// [svgUrl] is the Scryfall CDN URL for the mana symbol SVG, or null for
/// [MtgColor.multicolor] which has no official Scryfall symbol.
enum MtgColor {
  /// White mana ({W})
  white(code: 'W', displayName: 'White', svgUrl: 'https://svgs.scryfall.io/card-symbols/W.svg'),

  /// Blue mana ({U})
  blue(code: 'U', displayName: 'Blue', svgUrl: 'https://svgs.scryfall.io/card-symbols/U.svg'),

  /// Black mana ({B})
  black(code: 'B', displayName: 'Black', svgUrl: 'https://svgs.scryfall.io/card-symbols/B.svg'),

  /// Red mana ({R})
  red(code: 'R', displayName: 'Red', svgUrl: 'https://svgs.scryfall.io/card-symbols/R.svg'),

  /// Green mana ({G})
  green(code: 'G', displayName: 'Green', svgUrl: 'https://svgs.scryfall.io/card-symbols/G.svg'),

  /// Colorless mana ({C})
  colorless(code: 'C', displayName: 'Colorless', svgUrl: 'https://svgs.scryfall.io/card-symbols/C.svg'),

  /// Multicolor — Scryfall query uses `color:m`; no SVG symbol exists.
  multicolor(code: 'm', displayName: 'Multicolor', svgUrl: null);

  const MtgColor({required this.code, required this.displayName, this.svgUrl});

  /// Scryfall query code: 'W', 'U', 'B', 'R', 'G', 'C', or 'm' for multicolor.
  final String code;

  /// Human-readable name for display in chips and filter bars.
  final String displayName;

  /// Scryfall CDN URL for the mana symbol SVG, or null for multicolor.
  final String? svgUrl;

  /// Returns the [MtgColor] for a given [code], case-insensitive.
  ///
  /// Throws [ArgumentError] if [code] does not match any known colour.
  static MtgColor fromCode(String code) {
    return MtgColor.values.firstWhere(
      (c) => c.code.toLowerCase() == code.toLowerCase(),
      orElse: () => throw ArgumentError('Unknown MtgColor code: $code'),
    );
  }
}
