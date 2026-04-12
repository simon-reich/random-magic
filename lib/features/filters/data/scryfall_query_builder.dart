import 'package:random_magic/features/filters/domain/filter_settings.dart';
import 'package:random_magic/shared/models/mtg_color.dart';

/// Converts a [FilterSettings] snapshot into a Scryfall query string.
///
/// All methods are pure static — this class has no state and is never
/// instantiated. The only public entry point is [fromSettings].
///
/// Scryfall query syntax reference: https://scryfall.com/docs/syntax
abstract final class ScryfallQueryBuilder {
  /// Builds a Scryfall `q` parameter value from [settings].
  ///
  /// Returns `null` when [settings.isEmpty] is true, which tells callers
  /// to omit the `q` parameter entirely (FILT-10 — unrestricted random card).
  ///
  /// **Colour filter semantics:**
  /// - Non-multicolor colours only → `color<={codes}` (Scryfall "subset" operator).
  ///   This means the card's colour set must be a subset of the selected colours,
  ///   so multicolor cards containing other colours are excluded.
  ///   E.g. Green only → `color<=G` returns mono-green cards, not G/R or G/U.
  /// - [MtgColor.multicolor] only → `color:m` (any multicolor card).
  /// - Specific colours + multicolor → `(color<={codes} OR color:m)`.
  ///   E.g. Green + Multicolor → `(color<=G OR color:m)`.
  ///
  /// Other filter groups (type, rarity) are ORed within their group and
  /// joined with a single space between groups.
  ///
  /// Examples:
  /// - `fromSettings(FilterSettings(colors: {MtgColor.red}))` → `'color<=R'`
  /// - `fromSettings(FilterSettings(types: {'Creature', 'Instant'}))` → `'(type:Creature OR type:Instant)'`
  /// - `fromSettings(FilterSettings(releasedAfter: DateTime(2020,1,1)))` → `'date>=2020-01-01'`
  static String? fromSettings(FilterSettings settings) {
    if (settings.isEmpty) return null;

    final parts = <String>[];

    // Colour filter — split multicolor (M) from specific mono colours.
    //
    // `color=X` in Scryfall means "exactly this colour" — mono-X only.
    // This excludes colorless cards, multicolor cards, and any card that
    // contains additional colours beyond X.
    //
    // Multiple mono selections are OR-joined so the user gets cards of ANY
    // of the chosen colours, each as a pure mono card:
    //   White + Blue → (color=W OR color=U)  — mono-white OR mono-blue only
    //
    // Multicolor (M) is appended as `color:m` when selected, so:
    //   Green + Multicolor → (color=G OR color:m)
    if (settings.colors.isNotEmpty) {
      final hasMulticolor = settings.colors.contains(MtgColor.multicolor);
      final monoColors = settings.colors
          .where((c) => c != MtgColor.multicolor)
          .toList();

      // Build one clause per mono colour (color=X) plus color:m if needed.
      final clauses = <String>[
        ...monoColors.map((c) => 'color=${c.code}'),
        if (hasMulticolor) 'color:m',
      ];

      // Single clause needs no parens; multiple clauses need OR grouping.
      parts.add(clauses.length == 1 ? clauses.first : '(${clauses.join(' OR ')})');
    }

    // Type filter: each value maps to `type:{name}`.
    if (settings.types.isNotEmpty) {
      final clauses = settings.types.map((t) => 'type:$t').toList();
      parts.add('(${clauses.join(' OR ')})');
    }

    // Rarity filter: each value maps to `rarity:{code}`.
    if (settings.rarities.isNotEmpty) {
      final clauses = settings.rarities.map((r) => 'rarity:$r').toList();
      parts.add('(${clauses.join(' OR ')})');
    }

    // Date bounds — not grouped in parens, just bare date expressions.
    if (settings.releasedAfter != null) {
      parts.add('date>=${_formatDate(settings.releasedAfter!)}');
    }
    if (settings.releasedBefore != null) {
      parts.add('date<=${_formatDate(settings.releasedBefore!)}');
    }

    return parts.isEmpty ? null : parts.join(' ');
  }

  /// Formats a [DateTime] as `YYYY-MM-DD` for Scryfall date queries.
  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
