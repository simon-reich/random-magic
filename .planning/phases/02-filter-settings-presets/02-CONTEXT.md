# Phase 2: Filter Settings & Presets - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement the `FilterSettingsScreen` with colour/type/rarity/date filter UI, wire it to `RandomCardNotifier` via `ActiveFilterQuery`, and persist named filter presets in Hive CE. Covers FILT-01 through FILT-10 and DISC-10. Replaces the stub `activeFilterQuery` provider (currently returns `null`) with real filter state.

The filter tab already exists in GoRouter (`AppRoutes.filters`) and the `_ShellScaffold` bottom nav — no routing changes needed.

</domain>

<decisions>
## Implementation Decisions

### Colour Toggle Style
- **D-01:** Colour toggles use real MTG mana symbol icons, not coloured circles or text chips.
- **D-02:** Icons sourced from the Scryfall SVG API at runtime (`https://api.scryfall.com/symbology`). No icon assets bundled in the app.
- **D-03:** `flutter_svg` package added to render the SVG responses. Use cached/in-memory approach (similar to `CachedNetworkImage`) so symbols are not re-fetched on every build.
- **D-04:** Colours supported: W (White), U (Blue), B (Black), R (Red), G (Green), C (Colorless), M (Multicolor). Multi-select toggle row.

### Filter Screen Navigation
- **D-05:** Filter screen is the existing third tab in `_ShellScaffold` — no modal, no push. Already wired in `app_router.dart` as `AppRoutes.filters`. No routing changes needed.

### Preset Selection UX
- **D-06:** Saved presets displayed as a horizontal scrolling chip row at the top of `FilterSettingsScreen`, above the filter controls.
- **D-07:** Tapping a preset chip loads its values into all filter fields immediately AND navigates to the Discover tab (`context.go(AppRoutes.discovery)`). The filters take effect immediately via `activeFilterQueryProvider` → `RandomCardNotifier`.
- **D-08:** Preset save: a text field + "Save" button. Duplicate name is blocked with inline validation error (FILT-09). If user edits an existing preset name, it upserts (replaces) the existing one.
- **D-09:** Preset delete: each preset chip has a trailing X / delete action. Confirmation not required.

### Active Filter Bar (DISC-10)
- **D-10:** Active filter bar lives directly above the card on `CardSwipeScreen` — between the `SafeArea` top and the `AspectRatio` card widget. Conditionally visible: shown only when at least one filter is active, hidden otherwise.
- **D-11:** Each active filter value is shown as a dismissible chip (e.g., "Red", "Creature", "Rare").
- **D-12:** When a chip is removed while a preset is active, the preset name is marked as "modified" with a `*` suffix (e.g., "Budget Aggro*"). The modified state is transient — it does not auto-save. The user can re-open the filter tab to save the modified state as a new preset or overwrite the existing one.

### Filter Application
- **D-13:** Filters apply immediately as the user changes them — no explicit "Apply" button. `activeFilterQueryProvider` is watched by `RandomCardNotifier.build()`, so changing the filter state triggers a new card fetch automatically.
- **D-14:** Empty filter (all fields cleared) → `activeFilterQuery` returns `null` → unrestricted random card query (no `q` param). Satisfies FILT-10.

### Hive CE Initialization
- **D-15:** Hive CE boxes are opened in `main()` before `runApp()`. Phase 2 is the first phase that needs Hive — `main.dart` must be updated to call `Hive.initFlutter()` and open the `'filter_presets'` box (typeId: 0). Phase 3 (Favourites) will add the `'favourites'` box.

### Claude's Discretion
- Date picker widget choice (e.g., `showDatePicker` vs a custom input field)
- Exact chip / toggle sizing and padding (within AppSpacing constants)
- Whether type/rarity chips wrap or scroll horizontally
- Error handling for failed SVG symbol fetches (e.g., fallback to a text label)
- Whether `ScryfallQueryBuilder` uses a static class or a standalone function

</decisions>

<specifics>
## Specific Ideas

- User wants the preset selection to be fast: tap chip → filters load → auto-navigate to Discover. Minimal taps.
- Filter bar on the swipe screen should feel lightweight — it should not dominate the card artwork.
- Preset dirty-state indicator (`*` suffix) is a visual hint, not a blocking UI element.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` §Filters — FILT-01 through FILT-10 (complete filter feature requirements)
- `.planning/REQUIREMENTS.md` §Discovery — DISC-10 (active filter chip bar on swipe screen)

### Existing code to read before modifying
- `lib/features/filters/presentation/providers.dart` — stub `activeFilterQuery` provider to replace
- `lib/features/card_discovery/presentation/providers.dart` — `RandomCardNotifier.build()` watches `activeFilterQueryProvider`; must not break
- `lib/core/router/app_router.dart` — `AppRoutes.filters` and `_ShellScaffold` tab setup; already wired
- `lib/main.dart` — Hive CE initialization goes here before `runApp()`
- `lib/features/card_discovery/presentation/card_swipe_screen.dart` — where DISC-10 filter bar is added
- `lib/core/theme/app_theme.dart` — `AppColors` constants available for chip styling
- `lib/core/constants/spacing.dart` — `AppSpacing` constants for all layout spacing

### Scryfall API
- `https://scryfall.com/docs/syntax` — Scryfall query syntax for colour/type/rarity/date filter params
- `https://scryfall.com/docs/api/card-symbols` — Scryfall symbology endpoint for mana SVG icons

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AppColors.surface`, `AppColors.surfaceContainer`, `AppColors.primary`, `AppColors.onSurfaceMuted` — use for chip selected/unselected states, no new colours needed
- `AppSpacing.*` constants — all padding/margins; no magic numbers
- `CachedNetworkImage` pattern in `card_swipe_screen.dart` — similar caching approach for mana SVG icons
- `GoRouter` + `context.go(AppRoutes.discovery)` — preset selection navigates back to Discover tab

### Established Patterns
- Riverpod 3.x `@riverpod` code-gen: all new providers use `@riverpod` / `@Riverpod(keepAlive: true)` annotations; run `build_runner` after adding providers
- `Result<T>` / `AppFailure` sealed class: repository methods return `Result<T>`, never throw across layer boundaries
- `ConsumerWidget` / `ConsumerStatefulWidget`: no `setState`, no direct `StatefulWidget` for Riverpod-connected screens
- `/// doc comments` on every public class, method, and provider — required by CLAUDE.md

### Integration Points
- `activeFilterQueryProvider` in `lib/features/filters/presentation/providers.dart`: replace stub `String? activeFilterQuery(Ref ref) => null` with a real notifier that holds `FilterSettings` and computes the query string via `ScryfallQueryBuilder`
- `RandomCardNotifier.build()` already calls `ref.watch(activeFilterQueryProvider)` — changing the provider output automatically triggers a new card fetch
- `main.dart`: add `Hive.initFlutter()` + `await Hive.openBox<FilterPreset>('filter_presets')` before `runApp()`

</code_context>

<deferred>
## Deferred Ideas

- **Price filter (e.g., cards worth > $5 USD):** Scryfall's `/cards/random` endpoint does not support price-based `q` parameters — price data is returned in the card response but cannot be used as a pre-filter. This would require client-side filtering after fetch, which changes the UX significantly. Defer to post-Phase 4 discussion when card detail (including prices) is implemented.

</deferred>

---

*Phase: 02-filter-settings-presets*
*Context gathered: 2026-04-12*
