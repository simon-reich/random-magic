import 'package:hive_ce/hive.dart';
import 'package:random_magic/features/filters/domain/filter_settings.dart';
import 'package:random_magic/shared/models/mtg_color.dart';

/// A named collection of filter settings that can be saved and restored.
///
/// Persisted in the Hive CE box `'filter_presets'` using the preset [name]
/// as the box key. Serialised by [FilterPresetAdapter].
class FilterPreset {
  /// Creates a [FilterPreset] with the given [name] and [settings].
  const FilterPreset({required this.name, required this.settings});

  /// The user-assigned preset name. Used as the Hive box key.
  final String name;

  /// The filter criteria stored in this preset.
  final FilterSettings settings;
}

/// Hand-written Hive CE type adapter for [FilterPreset].
///
/// typeId: 0 — reserved for FilterPreset in this app.
/// Phase 3 FavouriteCard MUST use typeId: 1 to avoid collision.
///
/// Serialisation order (must not change without a migration strategy):
///   0: name (String)
///   1: colors (List of MtgColor.code strings)
///   2: types (List of String)
///   3: rarities (List of String)
///   4: releasedAfter (String? ISO-8601 date, or null)
///   5: releasedBefore (String? ISO-8601 date, or null)
class FilterPresetAdapter extends TypeAdapter<FilterPreset> {
  @override
  final int typeId = 0;

  @override
  FilterPreset read(BinaryReader reader) {
    final name = reader.read() as String;
    final colors = (reader.read() as List).cast<String>();
    final types = (reader.read() as List).cast<String>();
    final rarities = (reader.read() as List).cast<String>();
    final releasedAfterStr = reader.read() as String?;
    final releasedBeforeStr = reader.read() as String?;
    return FilterPreset(
      name: name,
      settings: FilterSettings(
        colors: colors.map(MtgColor.fromCode).toSet(),
        types: types.toSet(),
        rarities: rarities.toSet(),
        releasedAfter: releasedAfterStr != null ? DateTime.parse(releasedAfterStr) : null,
        releasedBefore: releasedBeforeStr != null ? DateTime.parse(releasedBeforeStr) : null,
      ),
    );
  }

  @override
  void write(BinaryWriter writer, FilterPreset obj) {
    writer.write(obj.name);
    writer.write(obj.settings.colors.map((c) => c.code).toList());
    writer.write(obj.settings.types.toList());
    writer.write(obj.settings.rarities.toList());
    // Store date as YYYY-MM-DD string to avoid timezone issues.
    writer.write(obj.settings.releasedAfter?.toIso8601String().split('T').first);
    writer.write(obj.settings.releasedBefore?.toIso8601String().split('T').first);
  }
}
