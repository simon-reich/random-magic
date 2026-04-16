---
phase: "03"
plan: "04"
subsystem: favourites
tags: [flutter, riverpod, ui, grid, multi-select, filter]
dependency_graph:
  requires:
    - 03-02  # FavouritesNotifier, FavouritesFilterNotifier, filteredFavouritesProvider
    - 03-03  # favourites_provider.dart re-export (shared/providers)
  provides:
    - FavouritesScreen full implementation (grid + multi-select + filter sheet)
  affects:
    - lib/features/favourites/presentation/favourites_screen.dart
    - test/widgets/favourites/favourites_screen_test.dart
tech_stack:
  added: []
  patterns:
    - ConsumerStatefulWidget for local UI state + Riverpod provider access
    - SliverGrid.count in CustomScrollView (SliverAppBar + SliverGrid)
    - PopScope for intercepting back navigation during multi-select
    - showModalBottomSheet with ConsumerWidget sheet body
    - CachedNetworkImage with ColoredBox placeholder/error fallback
key_files:
  created: []
  modified:
    - lib/features/favourites/presentation/favourites_screen.dart
    - test/widgets/favourites/favourites_screen_test.dart
decisions:
  - "Used favouritesFilterProvider (generated name) not favouritesFilterNotifierProvider — plan interface section had wrong name; .g.dart is the source of truth"
  - "Made _selectedIds final — all mutations are in-place (.add/.remove/.clear); no reassignment"
  - "Record destructuring ((code, label)) in lambda is rejected by Dart analyzer; used entry.$1/entry.$2 pattern instead"
  - "_FavouritesFilterSheet receives WidgetRef from parent as widgetRef field; ConsumerWidget build() receives its own ref — both refs are used correctly (parent ref for notifier calls deferred to ConsumerWidget ref)"
metrics:
  duration_minutes: 25
  completed_date: "2026-04-16"
  tasks_completed: 1
  tasks_total: 1
  files_changed: 2
---

# Phase 3 Plan 04: FavouritesScreen Full Implementation Summary

**One-liner:** Full FavouritesScreen with 3-column art-crop SliverGrid, long-press multi-select, batch-delete Undo Snackbar, and Colour/Type/Rarity filter bottom sheet.

## What Was Built

Replaced the `FavouritesScreen` placeholder (`StatelessWidget` returning `Text('Favourites')`) with a complete `ConsumerStatefulWidget` implementation delivering FAV-02, FAV-03, FAV-06, and FAV-07.

### Screen Structure

- `PopScope(canPop: !_isSelecting)` wraps the `Scaffold` — back button exits multi-select instead of navigating away (D-07)
- `CustomScrollView` with two slivers: `SliverAppBar` (floating) + body sliver

### Interaction States

| State | Condition | UI |
|-------|-----------|-----|
| True empty | `allFavourites.isEmpty` | `_EmptyStateWidget`: icon + "No Favourites Yet" + body |
| Filtered empty | `allFavourites` non-empty, `filtered.isEmpty` | "No cards match your filters." + Clear Filters TextButton |
| Success | `filtered` non-empty | `SliverGrid.count(crossAxisCount: 3)` of `_FavouriteGridCell` |

### Multi-Select (D-06, D-07)

- Long-press any cell → enters select mode, selects pressed card
- Second long-press → exits select mode
- Back button during select → exits select mode (via `PopScope`)
- App bar adapts: default shows "Favourites" + filter icon; selecting shows "{N} selected" + delete icon (AppColors.error)

### Batch Delete + Undo (D-09)

- Tapping delete captures selected `FavouriteCard` objects before removal
- Calls `FavouritesNotifier.remove()` for each selected card
- Shows 3-second `SnackBar` with "Undo" action
- Undo calls `FavouritesNotifier.add()` for each captured card (idempotent — T-03-04-01 mitigation)

### Filter Bottom Sheet (D-10, D-11, FAV-07)

- `_FavouritesFilterSheet` is a `ConsumerWidget` opened via `showModalBottomSheet`
- Sections: Colour (W/U/B/R/G/C), Type (8 types), Rarity (common/uncommon/rare/mythic)
- `FilterChip` style matches Phase 2 filter screen: `showCheckmark: false`, `selectedColor: AppColors.primary.withValues(alpha: 0.2)`
- Clear Filters button: `AppColors.error` foreground

### Grid Cell (`_FavouriteGridCell`)

- `CachedNetworkImage` for `artCropUrl`; `ColoredBox(AppColors.surfaceContainer)` on null/error
- Selection overlay: `AppColors.primary.withValues(alpha: 0.3)` + `Icons.check_circle`
- `Semantics` label switches between `card.name` and `"${card.name}, selected"`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Dart record destructuring in lambda parameter is invalid**
- **Found during:** Task 1, first analyze run
- **Issue:** Plan used `((code, label)) => FilterChip(...)` syntax in `.map()` — Dart does not support record pattern destructuring in lambda parameter lists; analyzer reported `missing_identifier` and `undefined_identifier`
- **Fix:** Changed to `(entry) { final code = entry.$1; final label = entry.$2; return FilterChip(...); }` pattern
- **Files modified:** `lib/features/favourites/presentation/favourites_screen.dart`
- **Commit:** ef1772b

**2. [Rule 2 - Missing critical fix] `_selectedIds` must be `final`**
- **Found during:** Task 1, first analyze run (`prefer_final_fields` info)
- **Issue:** Field was declared `Set<String> _selectedIds = {}` but all mutations are in-place (`.add`, `.remove`, `.clear`) — no reassignment occurs
- **Fix:** Declared as `final Set<String> _selectedIds = {}`
- **Files modified:** `lib/features/favourites/presentation/favourites_screen.dart`
- **Commit:** ef1772b

**3. [Rule 1 - Bug] Provider name mismatch: plan used wrong generated name**
- **Found during:** Task 1, reviewing providers.g.dart before writing
- **Issue:** Plan interfaces section referenced `favouritesFilterNotifierProvider` but the Riverpod 3.x code generator produces `favouritesFilterProvider` for `FavouritesFilterNotifier` (strips "Notifier" suffix)
- **Fix:** Used `favouritesFilterProvider` throughout implementation
- **Files modified:** `lib/features/favourites/presentation/favourites_screen.dart`
- **Commit:** ef1772b

### Out-of-Scope Pre-existing Warnings

Four `unused_import` warnings exist in `test/unit/favourites/favourites_filter_test.dart` and `test/unit/favourites/favourites_notifier_test.dart` — these are Wave 0 stubs that predate this plan. Not modified, not fixed, logged here for tracking.

## Known Stubs

None — all grid cells render real `FavouriteCard` data from `filteredFavouritesProvider`.

## Threat Flags

None — no new network endpoints, auth paths, or trust boundary changes introduced. All data flows through existing `favouritesProvider` (Hive CE local storage) with no new surface.

## Self-Check

### Files exist
- `lib/features/favourites/presentation/favourites_screen.dart` — FOUND
- `test/widgets/favourites/favourites_screen_test.dart` — FOUND

### Commits exist
- `ef1772b` — FOUND (`feat(03-04): implement FavouritesScreen grid, multi-select, and filter sheet`)

### Tests
- 5/5 widget tests pass
- `flutter analyze lib/features/favourites/presentation/favourites_screen.dart` — No issues found

## Self-Check: PASSED
