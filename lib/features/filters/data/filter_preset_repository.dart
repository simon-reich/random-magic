import 'package:hive_ce/hive.dart';
import 'package:random_magic/features/filters/domain/filter_preset.dart';
import 'package:random_magic/shared/failures.dart';
import 'package:random_magic/shared/result.dart';

/// Provides CRUD access to named [FilterPreset] objects stored in Hive CE.
///
/// The `filter_presets` box must already be open before constructing this
/// repository — [main.dart] opens it before [runApp].
///
/// All operations are synchronous because Hive CE's in-memory box is always
/// available after the box is opened.
class FilterPresetRepository {
  /// Accesses the open `filter_presets` Hive box.
  Box<FilterPreset> get _box => Hive.box<FilterPreset>('filter_presets');

  /// Returns all saved presets in insertion order.
  List<FilterPreset> getAll() => _box.values.toList();

  /// Saves [preset] to the box using its [FilterPreset.name] as the key.
  ///
  /// If [upsert] is `false` (default) and a preset with the same name already
  /// exists, returns a [Failure] wrapping [DuplicatePresetNameFailure] without
  /// modifying the box (FILT-09).
  ///
  /// If [upsert] is `true`, an existing preset with the same name is replaced
  /// (D-08).
  ///
  /// Returns [Success] with a `null` value on success.
  Result<void> save(FilterPreset preset, {bool upsert = false}) {
    if (!upsert && _box.containsKey(preset.name)) {
      return const Failure(DuplicatePresetNameFailure());
    }
    _box.put(preset.name, preset);
    return const Success(null);
  }

  /// Deletes the preset with the given [name]. No-op if not found (FILT-08).
  void delete(String name) => _box.delete(name);
}
