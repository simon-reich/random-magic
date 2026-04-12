# Phase 2: Filter Settings & Presets — Research

**Researched:** 2026-04-12
**Domain:** Flutter filter UI, Hive CE persistence, Riverpod 3.x state, Scryfall query building, flutter_svg mana icons
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Colour toggles use real MTG mana symbol icons, not coloured circles or text chips.
- **D-02:** Icons sourced from the Scryfall SVG API at runtime (`https://api.scryfall.com/symbology`). No icon assets bundled in the app.
- **D-03:** `flutter_svg` package added to render the SVG responses. Use cached/in-memory approach (similar to `CachedNetworkImage`) so symbols are not re-fetched on every build.
- **D-04:** Colours supported: W (White), U (Blue), B (Black), R (Red), G (Green), C (Colorless), M (Multicolor). Multi-select toggle row.
- **D-05:** Filter screen is the existing third tab in `_ShellScaffold` — no modal, no push. Already wired in `app_router.dart` as `AppRoutes.filters`. No routing changes needed.
- **D-06:** Saved presets displayed as a horizontal scrolling chip row at the top of `FilterSettingsScreen`, above the filter controls.
- **D-07:** Tapping a preset chip loads its values into all filter fields immediately AND navigates to the Discover tab (`context.go(AppRoutes.discovery)`). The filters take effect immediately via `activeFilterQueryProvider` → `RandomCardNotifier`.
- **D-08:** Preset save: a text field + "Save" button. Duplicate name is blocked with inline validation error (FILT-09). If user edits an existing preset name, it upserts (replaces) the existing one.
- **D-09:** Preset delete: each preset chip has a trailing X / delete action. Confirmation not required.
- **D-10:** Active filter bar lives directly above the card on `CardSwipeScreen` — between the `SafeArea` top and the `AspectRatio` card widget. Conditionally visible: shown only when at least one filter is active, hidden otherwise.
- **D-11:** Each active filter value is shown as a dismissible chip (e.g., "Red", "Creature", "Rare").
- **D-12:** When a chip is removed while a preset is active, the preset name is marked as "modified" with a `*` suffix (e.g., "Budget Aggro*"). The modified state is transient — it does not auto-save.
- **D-13:** Filters apply immediately as the user changes them — no explicit "Apply" button. `activeFilterQueryProvider` is watched by `RandomCardNotifier.build()`, so changing the filter state triggers a new card fetch automatically.
- **D-14:** Empty filter (all fields cleared) → `activeFilterQuery` returns `null` → unrestricted random card query (no `q` param). Satisfies FILT-10.
- **D-15:** Hive CE boxes are opened in `main()` before `runApp()`. Phase 2 is the first phase that needs Hive — `main.dart` must be updated to call `Hive.initFlutter()` and open the `'filter_presets'` box (typeId: 0). Phase 3 (Favourites) will add the `'favourites'` box.

### Claude's Discretion

- Date picker widget choice (e.g., `showDatePicker` vs a custom input field)
- Exact chip / toggle sizing and padding (within AppSpacing constants)
- Whether type/rarity chips wrap or scroll horizontally
- Error handling for failed SVG symbol fetches (e.g., fallback to a text label)
- Whether `ScryfallQueryBuilder` uses a static class or a standalone function

### Deferred Ideas (OUT OF SCOPE)

- **Price filter (e.g., cards worth > $5 USD):** Scryfall's `/cards/random` endpoint does not support price-based `q` parameters. Defer to post-Phase 4.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FILT-01 | User can configure a filter by card colour (W/U/B/R/G/C/M), multi-select | Scryfall `color:W`, `color:m` query syntax verified; mana SVG URLs confirmed from API |
| FILT-02 | User can configure a filter by card type (Creature, Instant, Sorcery, Enchantment, Artifact, Land, Planeswalker, Battle), multi-select | Scryfall `type:Creature` syntax; Material 3 FilterChip in Wrap layout |
| FILT-03 | User can configure a filter by rarity (Common, Uncommon, Rare, Mythic), multi-select | Scryfall `rarity:common` syntax; same chip pattern as FILT-02 |
| FILT-04 | User can configure "Released After" / "Released Before" date | Scryfall `date>=YYYY-MM-DD` syntax; Flutter `showDatePicker` available |
| FILT-05 | Applying filters immediately changes what random cards are returned | `RandomCardNotifier.build()` already watches `activeFilterQueryProvider`; changing notifier state auto-triggers new fetch |
| FILT-06 | User can save the current filter settings as a named preset | `FilterPresetsNotifier` writes to Hive CE box `'filter_presets'`; key = preset name |
| FILT-07 | User can select and apply a previously saved preset | Tap chip → load `FilterPreset` → set `FilterSettingsNotifier` state → navigate to Discover |
| FILT-08 | User can delete a saved preset | `FilterPresetsNotifier.delete(name)` → `box.delete(name)` |
| FILT-09 | Saving a preset with an existing name is blocked with inline validation | `box.containsKey(name)` guard; show inline error text below the save field |
| FILT-10 | Empty filter produces unrestricted query | `ScryfallQueryBuilder` returns `null` when `FilterSettings` is fully empty |
| DISC-10 | Active filter summary bar above card on `CardSwipeScreen`; tapping a chip removes that filter | Row of `FilterChip`s reading from `activeFilterQueryProvider`; remove calls `FilterSettingsNotifier` |
</phase_requirements>

---

## Summary

Phase 2 introduces the full filter feature: a `FilterSettingsScreen` with colour, type, rarity, and date range controls; a `FilterPresetsNotifier` backed by Hive CE; and a `FilterSettingsNotifier` that holds the live filter state and exposes a computed Scryfall query string through `activeFilterQueryProvider`. The stub provider created in Phase 1 is replaced entirely.

The key architectural bridge is that `RandomCardNotifier.build()` already watches `activeFilterQueryProvider` — so any state change in `FilterSettingsNotifier` automatically invalidates the card notifier and fetches a new card with the updated query. No manual invalidation is needed. Filters apply immediately (D-13).

Mana symbol icons come from the Scryfall SVG API (`https://api.scryfall.com/symbology`). SVG URLs for W/U/B/R/G/C are stable and predictable (`https://svgs.scryfall.io/card-symbols/{X}.svg`). Since Scryfall has no `{M}` symbol, the Multicolor toggle requires a custom widget (gradient or composite icon). The `flutter_svg` package (v2.2.4) is not yet in pubspec — it must be added. SVG picture caching is handled in-memory by `flutter_svg`'s picture cache; no persistent disk cache is needed for the small set of 6–7 mana icons.

Hive CE manual `TypeAdapter` (hand-written, no code-gen) is straightforward: extend `TypeAdapter<T>`, override `typeId`, `read(BinaryReader)`, and `write(BinaryWriter, T)`. Register before `openBox`. The adapter must be registered before `runApp()`.

**Primary recommendation:** Replace `activeFilterQuery` stub with a `@Riverpod(keepAlive: true)` `FilterSettingsNotifier` that holds `FilterSettings` immutable value and delegates query building to a pure `ScryfallQueryBuilder` class.

---

## Project Constraints (from CLAUDE.md)

| Directive | Enforcement |
|-----------|-------------|
| No hardcoded colours — use `AppColors` / `Theme.of(context)` | All chip selected/unselected states must reference `AppColors.*` |
| No hardcoded spacing — use `AppSpacing.*` | All padding, gap, and size values from `AppSpacing` constants |
| `flutter analyze --fatal-infos` must be clean | Run after every provider change + `build_runner` step |
| `@riverpod` code-gen for all providers; run `build_runner` after changes | `dart run build_runner build --delete-conflicting-outputs` |
| No cross-feature `data/` or `presentation/` imports | `activeFilterQueryProvider` lives in `features/filters/presentation/` and is imported by `card_discovery` at the provider level only (already established in Phase 1) |
| All public classes, methods, and providers require `///` doc comments | Every new class: `FilterSettings`, `FilterPreset`, `FilterSettingsNotifier`, `FilterPresetsNotifier`, `ScryfallQueryBuilder` |
| Repository methods return `Result<T>` — never throw across layer boundaries | `FilterPresetRepository` methods return `Result<void>` / `Result<List<FilterPreset>>` |
| `ConsumerWidget` / `ConsumerStatefulWidget` — no `setState` | `FilterSettingsScreen` must be `ConsumerStatefulWidget` (has text field for preset name) or `ConsumerWidget` with a separate controller |
| Hive CE box/adapter changes must be documented | Note typeId: 0 assignment for `FilterPreset`; Phase 3 will use typeId: 1 |
| New providers must be `keepAlive: true` for state that must survive tab navigation | `FilterSettingsNotifier` and `FilterPresetsNotifier` both need `keepAlive: true` |

---

## Standard Stack

### Core (already in pubspec)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_riverpod | 3.3.1 | State management | Already in project; `@Riverpod` code-gen with `build_runner` |
| riverpod_annotation | 4.0.2 | Code-gen annotations | Required companion to `riverpod_generator` |
| hive_ce | 2.19.3 | Local persistence for presets | Project-chosen over Isar (ADR-006); pure Dart |
| hive_ce_flutter | 2.3.4 | `Hive.initFlutter()` + Flutter path resolution | Required companion to `hive_ce` |
| dio | 5.9.2 | HTTP — symbology endpoint fetch | Already wired via `dioProvider` |

[VERIFIED: flutter pub deps output, 2026-04-12]

### New Dependency Required

| Library | Version | Purpose | Why |
|---------|---------|---------|-----|
| flutter_svg | ^2.2.4 | Render Scryfall SVG mana symbols | Locked by D-03; only Flutter-native SVG renderer |

[VERIFIED: `flutter pub add flutter_svg --dry-run` → resolves 2.2.4, 2026-04-12]

**Installation:**
```bash
flutter pub add flutter_svg
```

### Dev dependencies (already present)

| Library | Version | Purpose |
|---------|---------|---------|
| riverpod_generator | 4.0.3 | Generates `.g.dart` from `@riverpod` annotations |
| build_runner | 2.4.13 | Runs code generation |
| mockito | 5.4.4 | Mocking in unit tests |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual `TypeAdapter` | `@GenerateAdapters` (hive_ce code-gen) | Code-gen adds `source_gen` dependency — project avoided this for Isar reasons (ADR-006). Manual adapter is 20–30 lines, fully sufficient for `FilterPreset`. |
| `flutter_svg` | `cached_network_svg_image` | Extra dependency not needed — the 6 mana icons are tiny; `flutter_svg`'s in-memory picture cache is sufficient. |
| `showDatePicker` | Custom text input with `DateTime.parse` | `showDatePicker` is Flutter's built-in date picker — zero extra dependency, respects theme. Custom input adds parse/validation complexity. |

---

## Architecture Patterns

### New Files to Create

```
lib/
├── features/
│   └── filters/
│       ├── data/
│       │   ├── filter_preset_repository.dart   # Hive CE CRUD for FilterPreset
│       │   └── scryfall_query_builder.dart      # Pure static class: FilterSettings → String?
│       ├── domain/
│       │   ├── filter_preset.dart               # FilterPreset model + Hive TypeAdapter
│       │   └── filter_settings.dart             # FilterSettings immutable value class
│       └── presentation/
│           ├── filter_settings_screen.dart      # Replace placeholder
│           └── providers.dart                   # Replace stub; add FilterSettingsNotifier, FilterPresetsNotifier
├── features/
│   └── card_discovery/
│       └── presentation/
│           └── card_swipe_screen.dart           # Add DISC-10 active filter bar (modify existing)
└── main.dart                                    # Add Hive.initFlutter() + openBox (modify existing)
```

### Pattern 1: `FilterSettings` — Immutable Value Class

**What:** A plain immutable Dart class holding the current filter state. No Hive adapter needed (it is never persisted directly — only `FilterPreset` is persisted).

**When to use:** Passed between notifiers; used as input to `ScryfallQueryBuilder`.

```dart
// Source: project conventions (immutable value + copyWith)
/// Immutable snapshot of all active filter criteria.
///
/// An instance with all fields empty/null represents "no filter" (FILT-10).
class FilterSettings {
  const FilterSettings({
    this.colors = const {},
    this.types = const {},
    this.rarities = const {},
    this.releasedAfter,
    this.releasedBefore,
  });

  final Set<MtgColor> colors;
  final Set<String> types;      // e.g. {'Creature', 'Instant'}
  final Set<String> rarities;   // e.g. {'common', 'rare'}
  final DateTime? releasedAfter;
  final DateTime? releasedBefore;

  bool get isEmpty =>
      colors.isEmpty &&
      types.isEmpty &&
      rarities.isEmpty &&
      releasedAfter == null &&
      releasedBefore == null;

  FilterSettings copyWith({...}) { ... }
}
```

[ASSUMED] — copyWith pattern is conventional Dart; immutable class structure matches project patterns.

### Pattern 2: `FilterPreset` — Hive CE Manual TypeAdapter

**What:** The persisted model. Stored in Hive box `'filter_presets'` with the preset name as the box key. The TypeAdapter is written by hand (no code-gen).

**When to use:** Whenever saving or loading presets.

```dart
// Source: hive_ce TypeAdapter pattern [CITED: dev.to/dinko7/beyond-code-generation-crafting-custom-hive-adapters-1p33]
/// A named collection of filter settings persisted in Hive CE.
class FilterPreset {
  const FilterPreset({required this.name, required this.settings});
  final String name;
  final FilterSettings settings;
}

/// Hand-written Hive CE type adapter for [FilterPreset].
///
/// typeId: 0 — assigned to this type for the filter_presets box.
/// Phase 3 Favourites will use typeId: 1.
class FilterPresetAdapter extends TypeAdapter<FilterPreset> {
  @override
  final int typeId = 0;

  @override
  FilterPreset read(BinaryReader reader) {
    final name = reader.read() as String;
    final colors = (reader.read() as List).cast<String>().toSet();
    final types = (reader.read() as List).cast<String>().toSet();
    final rarities = (reader.read() as List).cast<String>().toSet();
    final releasedAfter = reader.read() as String?;
    final releasedBefore = reader.read() as String?;
    return FilterPreset(
      name: name,
      settings: FilterSettings(
        colors: colors.map(MtgColor.fromCode).toSet(),
        types: types,
        rarities: rarities,
        releasedAfter: releasedAfter != null ? DateTime.parse(releasedAfter) : null,
        releasedBefore: releasedBefore != null ? DateTime.parse(releasedBefore) : null,
      ),
    );
  }

  @override
  void write(BinaryWriter writer, FilterPreset obj) {
    writer.write(obj.name);
    writer.write(obj.settings.colors.map((c) => c.code).toList());
    writer.write(obj.settings.types.toList());
    writer.write(obj.settings.rarities.toList());
    writer.write(obj.settings.releasedAfter?.toIso8601String().split('T').first);
    writer.write(obj.settings.releasedBefore?.toIso8601String().split('T').first);
  }
}
```

[CITED: dev.to/dinko7/beyond-code-generation-crafting-custom-hive-adapters-1p33]
[VERIFIED: hive_ce pub.dev page confirms TypeAdapter<T>, BinaryReader/BinaryWriter API is identical to original hive]

### Pattern 3: `ScryfallQueryBuilder` — Pure Static Class

**What:** Takes a `FilterSettings` and returns a Scryfall `q` parameter string, or `null` for empty settings.

**When to use:** Called by `FilterSettingsNotifier` to compute the output of `activeFilterQueryProvider`.

```dart
// Source: Scryfall query syntax [CITED: scryfall.com/docs/syntax]
// Verified: color:m works (curl confirmed), date>=YYYY-MM-DD works, type:Creature works
abstract final class ScryfallQueryBuilder {
  /// Builds a Scryfall query string from [settings].
  ///
  /// Returns null when [settings] is empty — results in an unrestricted
  /// random card query with no `q` parameter (FILT-10).
  static String? fromSettings(FilterSettings settings) {
    if (settings.isEmpty) return null;

    final parts = <String>[];

    // Color: Scryfall treats multiple color: terms as OR by default.
    // 'M' is not a Scryfall symbol — use color:m for multicolor.
    if (settings.colors.isNotEmpty) {
      final colorParts = settings.colors
          .map((c) => c == MtgColor.multicolor ? 'color:m' : 'color:${c.code}')
          .join(' OR ');
      parts.add('($colorParts)');
    }

    // Type: multiple type: terms joined with OR.
    if (settings.types.isNotEmpty) {
      final typeParts = settings.types.map((t) => 'type:$t').join(' OR ');
      parts.add('($typeParts)');
    }

    // Rarity: multiple rarity: terms joined with OR.
    if (settings.rarities.isNotEmpty) {
      final rarityParts = settings.rarities.map((r) => 'rarity:$r').join(' OR ');
      parts.add('($rarityParts)');
    }

    // Date range: Scryfall uses date>=YYYY-MM-DD and date<=YYYY-MM-DD.
    if (settings.releasedAfter != null) {
      parts.add('date>=${_formatDate(settings.releasedAfter!)}');
    }
    if (settings.releasedBefore != null) {
      parts.add('date<=${_formatDate(settings.releasedBefore!)}');
    }

    return parts.join(' ');
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
```

[VERIFIED: `curl https://api.scryfall.com/cards/random?q=color:m` returns multicolor card — query is valid]
[CITED: scryfall.com/docs/syntax — color:W/U/B/R/G/C/m, type:, rarity:, date>=]

### Pattern 4: `FilterSettingsNotifier` — Replaces the stub `activeFilterQuery`

**What:** A `keepAlive: true` `Notifier<FilterSettings>` that exposes the current `FilterSettings` and a computed `String?` query. The existing stub provider in `providers.dart` is replaced with two providers: the notifier itself and a computed query provider that reads it.

**Critical constraint:** `RandomCardNotifier.build()` already calls `ref.watch(activeFilterQueryProvider)`. The generated provider name must remain `activeFilterQueryProvider`. This means the new provider function must also be named `activeFilterQuery`.

```dart
// Source: Riverpod 3.x code-gen patterns [ASSUMED: consistent with existing codebase patterns]

@Riverpod(keepAlive: true)
class FilterSettingsNotifier extends _$FilterSettingsNotifier {
  @override
  FilterSettings build() => const FilterSettings();

  void setColors(Set<MtgColor> colors) =>
      state = state.copyWith(colors: colors);
  void setTypes(Set<String> types) =>
      state = state.copyWith(types: types);
  void setRarities(Set<String> rarities) =>
      state = state.copyWith(rarities: rarities);
  void setReleasedAfter(DateTime? date) =>
      state = state.copyWith(releasedAfter: date);
  void setReleasedBefore(DateTime? date) =>
      state = state.copyWith(releasedBefore: date);
  void loadPreset(FilterSettings settings) => state = settings;
  void reset() => state = const FilterSettings();
}

/// Provides the active Scryfall query string.
///
/// Replaces the Phase 1 stub. Returns null when no filters are active (FILT-10).
@Riverpod(keepAlive: true)
String? activeFilterQuery(Ref ref) {
  final settings = ref.watch(filterSettingsNotifierProvider);
  return ScryfallQueryBuilder.fromSettings(settings);
}
```

[VERIFIED: existing `RandomCardNotifier.build()` calls `ref.watch(activeFilterQueryProvider)` — name must be preserved]
[ASSUMED: `Notifier<FilterSettings>` pattern is consistent with `AsyncNotifier<MagicCard>` already in project]

### Pattern 5: `FilterPresetsNotifier` — Hive CE CRUD

**What:** A `keepAlive: true` `Notifier<List<FilterPreset>>` backed by the Hive box. Initial state loads all presets from the box. Save/delete mutate the box and refresh state.

```dart
// Source: project patterns [ASSUMED: consistent with existing notifier patterns]
@Riverpod(keepAlive: true)
class FilterPresetsNotifier extends _$FilterPresetsNotifier {
  Box<FilterPreset> get _box => Hive.box<FilterPreset>('filter_presets');

  @override
  List<FilterPreset> build() => _box.values.toList();

  /// Saves preset. Blocks duplicate names unless upsert=true.
  ///
  /// Returns true on success, false if [name] already exists and upsert=false.
  bool save(FilterPreset preset, {bool upsert = false}) {
    if (!upsert && _box.containsKey(preset.name)) return false;
    _box.put(preset.name, preset);
    state = _box.values.toList();
    return true;
  }

  void delete(String name) {
    _box.delete(name);
    state = _box.values.toList();
  }
}
```

[ASSUMED: write-through notifier pattern is idiomatic for Hive CE + Riverpod; mirrors planned Favourites approach]

### Pattern 6: Mana Symbol Rendering

**What:** Each colour toggle button renders an `SvgPicture.network` from the Scryfall SVG CDN. For the Multicolor "M" option there is no Scryfall SVG — use a custom `Stack` with overlapping coloured circles or a gradient "M" text badge.

**SVG URL pattern (VERIFIED by curl against live API):**
```
https://svgs.scryfall.io/card-symbols/W.svg
https://svgs.scryfall.io/card-symbols/U.svg
https://svgs.scryfall.io/card-symbols/B.svg
https://svgs.scryfall.io/card-symbols/R.svg
https://svgs.scryfall.io/card-symbols/G.svg
https://svgs.scryfall.io/card-symbols/C.svg
```

**Caching:** `flutter_svg` 2.x caches the parsed `ui.Picture` in-memory. For 6 small icons loaded once, in-memory caching is sufficient. The picture cache avoids re-parsing SVG XML on rebuild. No persistent disk cache needed.

**Fallback (Claude's discretion — error handling for failed SVG fetch):** If `SvgPicture.network` fails, fall back to a text badge (e.g., `Text('W')` in a `CircleAvatar`) using the `placeholderBuilder` callback. This prevents a broken icon from blocking the UI.

```dart
// Source: flutter_svg 2.2.4 API [CITED: pub.dev/packages/flutter_svg]
SvgPicture.network(
  'https://svgs.scryfall.io/card-symbols/W.svg',
  width: 32,
  height: 32,
  placeholderBuilder: (_) => const _ManaSymbolFallback(label: 'W'),
)
```

### Pattern 7: Hive CE Initialization in `main.dart`

**What:** `Hive.initFlutter()` + `Hive.registerAdapter(FilterPresetAdapter())` + `Hive.openBox<FilterPreset>('filter_presets')` before `runApp()`. Phase 3 will add the `'favourites'` box.

```dart
// Source: hive_ce_flutter [CITED: pub.dev/packages/hive_ce]
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(FilterPresetAdapter());
  await Hive.openBox<FilterPreset>('filter_presets');
  runApp(const ProviderScope(child: RandomMagicApp()));
}
```

[CITED: pub.dev/packages/hive_ce — initFlutter before openBox; register adapters before openBox]

### Pattern 8: Active Filter Bar on `CardSwipeScreen` (DISC-10)

**What:** A conditional `Wrap` / `SingleChildScrollView` row of `FilterChip`s placed between `SafeArea` and the `AspectRatio` card widget. Only rendered when `filterSettings.isEmpty == false`.

**Integration:** Reads `filterSettingsNotifierProvider`; removing a chip calls the appropriate setter on `FilterSettingsNotifier`. This triggers `activeFilterQueryProvider` → `RandomCardNotifier` to re-fetch.

```dart
// D-10: conditionally shown above the card slot
if (!filterSettings.isEmpty)
  SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    child: Row(children: [
      for (final color in filterSettings.colors)
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xs),
          child: FilterChip(
            label: Text(color.displayName),
            selected: true,
            onSelected: (_) => ref
                .read(filterSettingsNotifierProvider.notifier)
                .setColors(filterSettings.colors.difference({color})),
          ),
        ),
      // ... similar for types, rarities, dates
    ]),
  ),
```

[ASSUMED: widget composition pattern consistent with existing codebase style]

### Preset Dirty-State (D-12)

**What:** A `String? activePresetName` field on `FilterSettingsNotifier` (or a separate `String?` in the provider state). When the user loads a preset, the name is stored. When any filter field changes after a preset is loaded, append `*` to the displayed name. No additional persistence needed.

Simplest approach: extend `FilterSettings` to carry `String? activePresetName` and `bool isPresetDirty`.

### Anti-Patterns to Avoid

- **Persisting `FilterSettings` directly in Hive** — only `FilterPreset` is persisted. `FilterSettings` is transient in the notifier's in-memory state.
- **Calling `box.openBox()` inside a provider** — open all boxes in `main()` before `runApp()` (D-15). Providers call `Hive.box<T>(name)` (synchronous, throws if not open).
- **Using typeId: 0 for both `FilterPreset` and `FavouriteCard`** — Phase 3 must use typeId: 1. typeId must be unique across the app. Document explicitly.
- **Duplicate `activeFilterQueryProvider` registration** — the stub in `providers.g.dart` is code-generated. Replacing the source function and re-running `build_runner` is the only safe path. Do not delete the `.g.dart` file manually.
- **`ref.watch` inside `Notifier.build()` on a non-keepAlive provider** — the rule `only_use_keep_alive_inside_keep_alive` from Riverpod 3.x means that `activeFilterQuery` (which watches `filterSettingsNotifierProvider`) must also be `keepAlive: true`. Both are already planned as `keepAlive`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SVG rendering | Custom SVG parser | `flutter_svg` | SVG is complex; `flutter_svg` handles gradients, paths, masks correctly |
| Date picker UI | Custom text field + manual parse | Flutter's `showDatePicker` | Built-in, themed, accessible, locale-aware |
| Hive CE binary serialisation format | Custom byte writer | `TypeAdapter` + `BinaryWriter`/`BinaryReader` | Hive's internal format handles type tags and field offsets correctly |
| Query string URL encoding | Manual string escaping | Pass raw query to Dio — Dio handles URL encoding | Scryfall accepts spaces in `q`; Dio encodes them correctly |
| Riverpod state change propagation | Manual `ref.invalidate()` | `ref.watch()` in `RandomCardNotifier.build()` | Already established in Phase 1; watch auto-propagates |

**Key insight:** The query building and the state propagation chain are both already designed correctly from Phase 1. Phase 2 only needs to populate the state — the propagation is free.

---

## Common Pitfalls

### Pitfall 1: `Hive.box<T>()` throws if box not opened

**What goes wrong:** Provider calls `Hive.box<FilterPreset>('filter_presets')` but box was not opened before `runApp()`. App crashes with `HiveError: Box not found`.
**Why it happens:** `openBox` is async; if not awaited in `main()`, the box may not be ready when the first provider reads it.
**How to avoid:** `await Hive.openBox<FilterPreset>('filter_presets')` in `main()` before `runApp()`.
**Warning signs:** `HiveError: Box not found` at startup.

### Pitfall 2: typeId collision across adapters

**What goes wrong:** `FilterPresetAdapter` and Phase 3's `FavouriteCardAdapter` both use typeId: 0. Hive silently overwrites one registration.
**Why it happens:** typeId is global across the entire Hive instance, not per-box.
**How to avoid:** `FilterPreset` uses typeId: 0. `FavouriteCard` uses typeId: 1. Document this in the adapter files.
**Warning signs:** Wrong type deserialized from box; `HiveError: Cannot read, unknown typeId`.

### Pitfall 3: `activeFilterQueryProvider` name clash after replacing stub

**What goes wrong:** The stub is a function provider. The replacement uses a `Notifier` class. If the generated provider name changes, `RandomCardNotifier` breaks at compile time.
**Why it happens:** Riverpod code-gen derives the provider name from the function/class name. `activeFilterQuery` (function) → `activeFilterQueryProvider`. This must remain identical.
**How to avoid:** Keep the provider function named `activeFilterQuery`. The notifier class is named `FilterSettingsNotifier` (separate name → `filterSettingsNotifierProvider`). `activeFilterQuery` becomes a computed provider that reads `filterSettingsNotifierProvider`.
**Warning signs:** Compile error in `card_discovery/presentation/providers.dart` after running `build_runner`.

### Pitfall 4: `color:m` in Scryfall combines with other color filters unexpectedly

**What goes wrong:** User selects "Red" AND "Multicolor". Query becomes `(color:R OR color:m)`. Scryfall interprets `color:m` as "contains 2+ colors" and `color:R` as "contains red". Their OR union is broader than intended.
**Why it happens:** Scryfall color operators are set operations, not exclusive tags.
**How to avoid:** The current implementation (OR-join of selected colors) is correct. The behavior is expected and not a bug — it matches any card that is either red or multicolored. Document this in comments.
**Warning signs:** N/A — this is correct behavior, not an error.

### Pitfall 5: `SvgPicture.network` does not cache between widget rebuilds persistently

**What goes wrong:** Every app restart re-downloads the mana SVGs from Scryfall.
**Why it happens:** `flutter_svg` 2.x caches the parsed picture in-memory only (RAM); cache is lost on app restart.
**How to avoid:** For 6 small icons, a network re-fetch on cold start is acceptable and unnoticeable. If disk caching becomes a requirement, add `cached_network_svg_image`. For Phase 2, in-memory is sufficient.
**Warning signs:** Visible flicker on mana icons after app restart on slow connections.

### Pitfall 6: `FilterSettings` with `Set` fields is not `const`-constructable if populated

**What goes wrong:** Using `Set<MtgColor>` in `FilterSettings` prevents `const` constructor when fields are non-empty. Tests calling `const FilterSettings(colors: {MtgColor.red})` fail.
**Why it happens:** `{}` Set literals are not compile-time constants in Dart unless empty.
**How to avoid:** Use `const FilterSettings()` only for the empty default. Non-empty instances use normal `FilterSettings(colors: {MtgColor.red})`. The `const FilterSettings()` default in `Notifier.build()` is fine.
**Warning signs:** Dart compile error: "Arguments of a constant creation must be constant expressions".

### Pitfall 7: `Riverpod 3.x` rule — keepAlive providers can only watch keepAlive providers

**What goes wrong:** `activeFilterQuery` is `keepAlive: true` and watches `filterSettingsNotifierProvider`. If `filterSettingsNotifierProvider` were auto-dispose, Riverpod 3.x throws a lint warning (and potentially a runtime error in strict mode).
**Why it happens:** Auto-dispose providers can be destroyed while keepAlive providers are watching them.
**How to avoid:** Both `FilterSettingsNotifier` and `activeFilterQuery` must be annotated `@Riverpod(keepAlive: true)`.
**Warning signs:** `only_use_keep_alive_inside_keep_alive` lint warning after `flutter analyze`.

---

## Code Examples

### Scryfall Symbology — Live API Response (VERIFIED 2026-04-12)

```json
// GET https://api.scryfall.com/symbology
// Symbol objects for W, U, B, R, G, C:
{
  "symbol": "{W}",
  "svg_uri": "https://svgs.scryfall.io/card-symbols/W.svg",
  "colors": ["W"],
  "appears_in_mana_costs": true
}
// {M} does NOT exist in the symbology endpoint.
// Multicolor is a search concept: color:m in Scryfall query syntax.
```

[VERIFIED: curl https://api.scryfall.com/symbology, 2026-04-12]

### Scryfall Query Syntax (VERIFIED via live API)

```
# Single color
color:W         → white cards only
color:m         → multicolor cards (2+ colors)
color:C         → colorless cards

# Multiple colors (OR — matches any of the selected colors)
(color:R OR color:G)

# Type (OR)
(type:Creature OR type:Instant)

# Rarity (OR)
(rarity:common OR rarity:rare)

# Date range
date>=2020-01-01
date<=2023-12-31

# Combined (space-separated terms are implicitly AND)
(color:R OR color:G) (type:Creature) rarity:rare date>=2020-01-01
```

[VERIFIED: `curl https://api.scryfall.com/cards/random?q=color:m` → multicolor card returned successfully]
[CITED: scryfall.com/docs/syntax]

### Hive CE `main.dart` Initialization

```dart
// Source: hive_ce_flutter documentation pattern
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(FilterPresetAdapter()); // typeId: 0
  await Hive.openBox<FilterPreset>('filter_presets');
  // Phase 3 will add: Hive.registerAdapter(FavouriteCardAdapter()); // typeId: 1
  // Phase 3 will add: await Hive.openBox<FavouriteCard>('favourites');
  runApp(const ProviderScope(child: RandomMagicApp()));
}
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Riverpod 2.x AutoDispose/Family variants | Riverpod 3.x unified `Notifier` / `AsyncNotifier` (autoDispose by default; `keepAlive: true` to disable) | No `AutoDisposeNotifier` — just `Notifier` with `@Riverpod(keepAlive: true)` |
| Isar (code-gen, AGP issues) | Hive CE (pure Dart, manual adapters) | No `build_runner` needed for storage; `build_runner` only for Riverpod |
| Original `hive` package | `hive_ce` (community edition, actively maintained) | API identical; `hive_ce` has additional `registerAdapters()` extension, not needed here |

**Deprecated/outdated:**
- `AutoDisposeNotifier`, `FamilyAsyncNotifier`: Removed in Riverpod 3.x — use `Notifier` / `AsyncNotifier` directly.
- `precachePicture` from `flutter_svg`: Removed in 2.0 — no replacement needed for network SVGs.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Notifier<FilterSettings>` with `copyWith` pattern is idiomatic for sync state in Riverpod 3.x | Pattern 4 | Low — pattern is established Riverpod practice; existing `AsyncNotifier` in project confirms the approach |
| A2 | `FilterSettingsNotifier` holding `activePresetName` / `isPresetDirty` as part of state is the right approach for D-12 | Pattern 4 / D-12 | Low — alternative is a separate provider; either works, recommendation is simpler |
| A3 | Write-through notifier (mutate box + update state) is sufficient for `FilterPresetsNotifier` — no stream listener needed | Pattern 5 | Low — confirmed by Phase 3 roadmap design note; Hive streams are optional |
| A4 | `SvgPicture.network` in-memory picture cache is sufficient for 6–7 mana icons without persistent disk caching | Standard Stack | Low — icons are tiny; re-fetch on cold start is imperceptible on any connection |
| A5 | `color:m` in Scryfall correctly returns multicolor cards when combined with specific color filters via OR | ScryfallQueryBuilder Pattern 3 | Low — verified `color:m` returns multicolor card; OR combination is documented Scryfall behavior |

---

## Open Questions

1. **`MtgColor` enum location**
   - What we know: CLAUDE.md lists `MtgColor` as existing in `shared/models/` with enums for color. The directory has a `.gitkeep` but no `mtg_color.dart` file yet.
   - What's unclear: Does `MtgColor` already exist in the codebase, or must Phase 2 create it?
   - Recommendation: Phase 2 Plan 1 creates `shared/models/mtg_color.dart` with W/U/B/R/G/C/M enum values and a `.code` getter.

2. **`FilterSettings` dirty-state carrier**
   - What we know: D-12 requires showing `*` suffix when user modifies a loaded preset.
   - What's unclear: Should `FilterSettings` carry `activePresetName` / `isDirty` fields, or should `FilterSettingsNotifier` have separate fields beyond its `state`?
   - Recommendation: Add `activePresetName` and `isPresetDirty` as fields on `FilterSettings` itself (or as separate fields on the notifier). The notifier approach is cleaner — `FilterSettings` stays a pure filter value; dirty state is notifier metadata.

3. **Scryfall query: AND vs. OR for multi-color selection**
   - What we know: If user selects Red AND Green, should results match cards that are BOTH red AND green (AND), or cards that are EITHER red OR green (OR)?
   - What's unclear: The context says "multi-select" but doesn't specify AND/OR semantics.
   - Recommendation: Default to OR (broader, more likely to return results). The implementation in Pattern 3 uses OR. If AND is desired, `ScryfallQueryBuilder` can use `color>=RG` syntax (Scryfall supports this). Planner should flag for user confirmation or use OR with a comment.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Build | ✓ | 3.41.6 (stable) | — |
| Dart SDK | Build | ✓ | 3.11.4 | — |
| flutter_svg | Mana icons (D-03) | ✗ (not in pubspec) | — | `flutter pub add flutter_svg` → resolves 2.2.4 |
| Scryfall SVG CDN | Mana icons (D-02) | ✓ | live | Text fallback badges |
| Scryfall `/symbology` API | Optional: dynamic URL discovery | ✓ | live | Hardcode known CDN URLs (no need to call `/symbology` since URLs are predictable) |
| Hive CE box | Filter preset persistence | ✗ (box not opened yet) | hive_ce 2.19.3 installed | Add init to `main.dart` |

**Missing dependencies with no fallback:**
- `flutter_svg` must be added to `pubspec.yaml` — `flutter pub add flutter_svg`

**Missing dependencies with fallback:**
- Scryfall SVG CDN: if unreachable, text fallback badges are shown (Claude's discretion — D-03)

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (built-in) |
| Config file | analysis_options.yaml (no separate test config) |
| Quick run command | `flutter test test/unit/filters/` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FILT-01 | `ScryfallQueryBuilder.fromSettings` produces `color:W` for W-only selection | unit | `flutter test test/unit/filters/scryfall_query_builder_test.dart` | ❌ Wave 0 |
| FILT-02 | `ScryfallQueryBuilder.fromSettings` produces `(type:Creature OR type:Instant)` | unit | `flutter test test/unit/filters/scryfall_query_builder_test.dart` | ❌ Wave 0 |
| FILT-03 | `ScryfallQueryBuilder.fromSettings` produces `(rarity:common OR rarity:rare)` | unit | `flutter test test/unit/filters/scryfall_query_builder_test.dart` | ❌ Wave 0 |
| FILT-04 | `ScryfallQueryBuilder.fromSettings` produces `date>=2020-01-01` | unit | `flutter test test/unit/filters/scryfall_query_builder_test.dart` | ❌ Wave 0 |
| FILT-05 | Changing notifier state causes `RandomCardNotifier` to rebuild | unit | `flutter test test/unit/filters/filter_settings_notifier_test.dart` | ❌ Wave 0 |
| FILT-06 | `FilterPresetsNotifier.save()` persists to Hive box and updates state | unit | `flutter test test/unit/filters/filter_presets_notifier_test.dart` | ❌ Wave 0 |
| FILT-07 | `FilterPresetsNotifier` loads preset into `FilterSettingsNotifier` | unit | `flutter test test/unit/filters/filter_presets_notifier_test.dart` | ❌ Wave 0 |
| FILT-08 | `FilterPresetsNotifier.delete()` removes from box and updates state | unit | `flutter test test/unit/filters/filter_presets_notifier_test.dart` | ❌ Wave 0 |
| FILT-09 | `save()` returns false and does not upsert when name already exists | unit | `flutter test test/unit/filters/filter_presets_notifier_test.dart` | ❌ Wave 0 |
| FILT-10 | `ScryfallQueryBuilder.fromSettings(const FilterSettings())` returns null | unit | `flutter test test/unit/filters/scryfall_query_builder_test.dart` | ❌ Wave 0 |
| DISC-10 | Active filter bar visible when filters set; hidden when empty | widget | `flutter test test/widgets/card_discovery/card_swipe_screen_test.dart` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `flutter test test/unit/filters/` (unit tests only, < 5 seconds)
- **Per wave merge:** `flutter test && flutter analyze --fatal-infos`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/unit/filters/scryfall_query_builder_test.dart` — covers FILT-01 through FILT-04, FILT-10
- [ ] `test/unit/filters/filter_settings_notifier_test.dart` — covers FILT-05
- [ ] `test/unit/filters/filter_presets_notifier_test.dart` — covers FILT-06, FILT-07, FILT-08, FILT-09; requires `Hive.init(tempDir.path)` not `Hive.initFlutter()`
- [ ] `test/widgets/card_discovery/card_swipe_screen_test.dart` — covers DISC-10 (add to existing placeholder)
- [ ] `test/fixtures/fake_preset.dart` — `FilterPreset` factory for tests

**Hive CE in tests:** Use `Hive.init(Directory.systemTemp.path)` (not `Hive.initFlutter()`). Register adapter in `setUp`. Call `Hive.close()` in `tearDown`. [ASSUMED: consistent with Phase 5 roadmap note]

---

## Security Domain

Phase 2 has no authentication, no user-generated network requests beyond existing Scryfall calls, and no sensitive data. ASVS categories do not apply to local filter state persistence.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | N/A |
| V3 Session Management | No | N/A |
| V4 Access Control | No | N/A |
| V5 Input Validation | Partial | Preset name: max length + non-empty guard before `box.put()`; Scryfall query: only trusted enum values and ISO dates used — no user-typed query injection |
| V6 Cryptography | No | N/A |

**Note on V5:** `ScryfallQueryBuilder` only interpolates enum `.code` values and `DateTime`-formatted strings — no free-text user input reaches the query. Preset names are stored as Hive keys and displayed in UI only; they do not reach the Scryfall API.

---

## Sources

### Primary (HIGH confidence)

- [VERIFIED: curl to Scryfall live API] — symbology endpoint response shape, color:m query verified working
- [VERIFIED: flutter pub deps output] — all installed package versions confirmed
- [VERIFIED: flutter pub add flutter_svg --dry-run] — flutter_svg 2.2.4 available and compatible
- Existing codebase files read directly — `providers.dart`, `card_swipe_screen.dart`, `app_router.dart`, `main.dart`, `app_theme.dart`, `spacing.dart`, `magic_card.dart`, `failures.dart`, `result.dart`

### Secondary (MEDIUM confidence)

- [CITED: pub.dev/packages/flutter_svg] — SvgPicture.network API, version 2.2.4 confirmed
- [CITED: pub.dev/packages/hive_ce] — TypeAdapter API, initFlutter pattern
- [CITED: dev.to/dinko7/beyond-code-generation-crafting-custom-hive-adapters-1p33] — Manual TypeAdapter BinaryReader/BinaryWriter pattern
- [CITED: scryfall.com/docs/syntax] — color:, type:, rarity:, date>= query syntax

### Tertiary (LOW confidence)

- None — all critical claims are verified or cited.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all versions verified via `flutter pub deps` and `--dry-run`
- Architecture: HIGH — existing codebase patterns read directly; Riverpod 3.x keepAlive constraints verified
- Scryfall query syntax: HIGH — verified via live API curl calls
- Hive CE TypeAdapter: MEDIUM — API is identical to original `hive`; `hive_ce` confirms compatibility
- Pitfalls: HIGH — derived from existing code analysis (provider naming, typeId, keepAlive lint)

**Research date:** 2026-04-12
**Valid until:** 2026-05-12 (stable stack; Scryfall API has no versioning)
