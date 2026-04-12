import 'package:random_magic/features/filters/domain/filter_settings.dart';

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
  /// Each non-empty filter group is enclosed in parentheses and joined with a
  /// single space. Multiple values within a group are joined with ` OR `.
  ///
  /// Examples:
  /// - `fromSettings(FilterSettings(colors: {MtgColor.red}))` → `'(color:R)'`
  /// - `fromSettings(FilterSettings(types: {'Creature', 'Instant'}))` → `'(type:Creature OR type:Instant)'`
  /// - `fromSettings(FilterSettings(releasedAfter: DateTime(2020,1,1)))` → `'date>=2020-01-01'`
  static String? fromSettings(FilterSettings settings) {
    if (settings.isEmpty) return null;

    final parts = <String>[];

    // Color filter: each MtgColor maps to `color:{code}`.
    // multicolor.code is already 'm', so no special case needed.
    if (settings.colors.isNotEmpty) {
      final clauses = settings.colors.map((c) => 'color:${c.code}').toList();
      parts.add('(${clauses.join(' OR ')})');
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
