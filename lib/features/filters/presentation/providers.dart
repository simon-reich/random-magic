import 'package:hive_ce/hive.dart';
import 'package:random_magic/features/filters/data/scryfall_query_builder.dart';
import 'package:random_magic/features/filters/domain/filter_preset.dart';
import 'package:random_magic/features/filters/domain/filter_settings.dart';
import 'package:random_magic/shared/models/mtg_color.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// Manages the live filter state for the current session.
///
/// State is kept alive across tab navigation ([keepAlive: true]).
/// Changing any field automatically propagates to [activeFilterQueryProvider],
/// which [RandomCardNotifier] watches — triggering a new card fetch (D-13, FILT-05).
@Riverpod(keepAlive: true)
class FilterSettingsNotifier extends _$FilterSettingsNotifier {
  /// Tracks the name of the last-loaded preset (D-12).
  ///
  /// Set by [loadPreset] and cleared by any mutation method. Transient — not
  /// persisted. Used by [FilterSettingsScreen] to render the `*` dirty-state
  /// suffix on the active preset chip.
  String? activePresetName;

  @override
  FilterSettings build() => const FilterSettings();

  /// Replaces the active colour selection. Clears [activePresetName] (D-12).
  void setColors(Set<MtgColor> colors) {
    activePresetName = null;
    state = state.copyWith(colors: colors);
  }

  /// Replaces the active card type selection. Clears [activePresetName] (D-12).
  void setTypes(Set<String> types) {
    activePresetName = null;
    state = state.copyWith(types: types);
  }

  /// Replaces the active rarity selection. Clears [activePresetName] (D-12).
  void setRarities(Set<String> rarities) {
    activePresetName = null;
    state = state.copyWith(rarities: rarities);
  }

  /// Sets or clears the Released After date bound. Clears [activePresetName] (D-12).
  void setReleasedAfter(DateTime? date) {
    activePresetName = null;
    state = date == null
        ? state.copyWith(clearReleasedAfter: true)
        : state.copyWith(releasedAfter: date);
  }

  /// Sets or clears the Released Before date bound. Clears [activePresetName] (D-12).
  void setReleasedBefore(DateTime? date) {
    activePresetName = null;
    state = date == null
        ? state.copyWith(clearReleasedBefore: true)
        : state.copyWith(releasedBefore: date);
  }

  /// Loads all filter values from [settings], replacing current state entirely.
  ///
  /// Sets [activePresetName] to [presetName] so the UI can show the dirty-state
  /// `*` suffix when the user later modifies a filter (D-07, D-12).
  void loadPreset(FilterSettings settings, {String? presetName}) {
    activePresetName = presetName;
    state = settings;
  }

  /// Clears all filters, returning to the unrestricted query state (FILT-10).
  /// Also clears [activePresetName].
  void reset() {
    activePresetName = null;
    state = const FilterSettings();
  }
}

/// Provides the active Scryfall query string for card discovery.
///
/// Replaces the Phase 1 stub. Returns null when no filters are active (FILT-10),
/// which causes [RandomCardNotifier] to fetch without a `q` parameter.
///
/// The provider name [activeFilterQueryProvider] is preserved so that
/// [RandomCardNotifier.build()] continues to work without modification.
@Riverpod(keepAlive: true)
String? activeFilterQuery(Ref ref) {
  final settings = ref.watch(filterSettingsProvider);
  return ScryfallQueryBuilder.fromSettings(settings);
}

/// Manages named filter presets persisted in Hive CE.
///
/// State is kept alive across tab navigation ([keepAlive: true]).
/// Initial state loads all presets from the open Hive box.
@Riverpod(keepAlive: true)
class FilterPresetsNotifier extends _$FilterPresetsNotifier {
  Box<FilterPreset> get _box => Hive.box<FilterPreset>('filter_presets');

  @override
  List<FilterPreset> build() => _box.values.toList();

  /// Saves [preset] to the box using its name as the key.
  ///
  /// Returns true on success. Returns false if [preset.name] already exists
  /// and [upsert] is false — caller should display an inline error (FILT-09).
  /// When [upsert] is true, replaces an existing preset with the same name (D-08).
  bool save(FilterPreset preset, {bool upsert = false}) {
    if (!upsert && _box.containsKey(preset.name)) return false;
    _box.put(preset.name, preset);
    state = _box.values.toList();
    return true;
  }

  /// Deletes the preset named [name]. No-op if not found (FILT-08).
  void delete(String name) {
    _box.delete(name);
    state = _box.values.toList();
  }
}
