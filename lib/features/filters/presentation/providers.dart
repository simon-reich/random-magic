import 'package:hive_ce/hive.dart';
import 'package:random_magic/features/filters/data/scryfall_query_builder.dart';
import 'package:random_magic/features/filters/domain/filter_preset.dart';
import 'package:random_magic/features/filters/domain/filter_settings.dart';
import 'package:random_magic/shared/models/mtg_color.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// Tracks the name of the last-loaded preset for dirty-state display (D-12).
///
/// A separate provider so that [FilterSettingsScreen] can [ref.watch] it and
/// rebuild the chip label immediately when a preset is loaded — even if the
/// filter state itself hasn't changed (e.g. same preset re-selected).
/// Cleared by any mutation method on [FilterSettingsNotifier].
@Riverpod(keepAlive: true)
class ActivePresetName extends _$ActivePresetName {
  @override
  String? build() => null;

  /// Sets the active preset name. Called by [FilterSettingsNotifier.loadPreset].
  void setName(String? name) => state = name;
}

/// Incremented whenever a preset is applied, so [RandomCardNotifier] re-fetches
/// even when the filter query string hasn't changed (e.g. same preset tapped twice).
@Riverpod(keepAlive: true)
class FilterRefreshSignal extends _$FilterRefreshSignal {
  @override
  int build() => 0;

  /// Increments the signal, triggering a rebuild of any provider that watches it.
  void trigger() => state++;
}

/// Manages the live filter state for the current session.
///
/// State is kept alive across tab navigation ([keepAlive: true]).
/// Changing any field automatically propagates to [activeFilterQueryProvider],
/// which [RandomCardNotifier] watches — triggering a new card fetch (D-13, FILT-05).
@Riverpod(keepAlive: true)
class FilterSettingsNotifier extends _$FilterSettingsNotifier {
  /// The name of the last-loaded preset, or null if filters have been modified
  /// since loading (D-12). Backed by [activePresetNameProvider] so the screen
  /// always rebuilds immediately when this changes.
  String? get activePresetName => ref.read(activePresetNameProvider);

  @override
  FilterSettings build() => const FilterSettings();

  /// Replaces the active colour selection. Clears [activePresetName] (D-12).
  void setColors(Set<MtgColor> colors) {
    ref.read(activePresetNameProvider.notifier).setName(null);
    state = state.copyWith(colors: colors);
  }

  /// Replaces the active card type selection. Clears [activePresetName] (D-12).
  void setTypes(Set<String> types) {
    ref.read(activePresetNameProvider.notifier).setName(null);
    state = state.copyWith(types: types);
  }

  /// Replaces the active rarity selection. Clears [activePresetName] (D-12).
  void setRarities(Set<String> rarities) {
    ref.read(activePresetNameProvider.notifier).setName(null);
    state = state.copyWith(rarities: rarities);
  }

  /// Sets or clears the Released After date bound. Clears [activePresetName] (D-12).
  void setReleasedAfter(DateTime? date) {
    ref.read(activePresetNameProvider.notifier).setName(null);
    state = date == null
        ? state.copyWith(clearReleasedAfter: true)
        : state.copyWith(releasedAfter: date);
  }

  /// Sets or clears the Released Before date bound. Clears [activePresetName] (D-12).
  void setReleasedBefore(DateTime? date) {
    ref.read(activePresetNameProvider.notifier).setName(null);
    state = date == null
        ? state.copyWith(clearReleasedBefore: true)
        : state.copyWith(releasedBefore: date);
  }

  /// Loads all filter values from [settings], replacing current state entirely.
  ///
  /// Sets [activePresetName] to [presetName] so the UI can show the dirty-state
  /// `*` suffix when the user later modifies a filter (D-07, D-12).
  void loadPreset(FilterSettings settings, {String? presetName}) {
    ref.read(activePresetNameProvider.notifier).setName(presetName);
    state = settings;
  }

  /// Clears all filters, returning to the unrestricted query state (FILT-10).
  /// Also clears [activePresetName].
  void reset() {
    ref.read(activePresetNameProvider.notifier).setName(null);
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
