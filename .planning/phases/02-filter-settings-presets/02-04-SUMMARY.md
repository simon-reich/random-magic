---
plan: "02-04"
phase: "02-filter-settings-presets"
status: completed
wave: 4
completed_at: "2026-04-16"
---

# Plan 02-04 Summary — Active Filter Bar on CardSwipeScreen

## What Was Built

`_ActiveFilterBar` widget added to `CardSwipeScreen` (DISC-10). A `Wrap`-based row of
dismissible `FilterChip`s appears between the SafeArea and card slot whenever any filter
is active. Tapping a chip's X removes that filter from `FilterSettingsNotifier`, which
cascades through `activeFilterQueryProvider` → `RandomCardNotifier` to trigger a new
card fetch automatically.

## Key Files

### Modified
- `lib/features/card_discovery/presentation/card_swipe_screen.dart` — `_CardSwipeScreenState.build()` restructured from `Center(Padding(AspectRatio))` to `Column([if (!filterState.isEmpty) _ActiveFilterBar(...), Expanded(Center(...))])`. `_ActiveFilterBar` private `ConsumerWidget` added at end of file. Chip label and delete icon colours overridden to `AppColors.background` (dark navy) for readable contrast against gold selected chip background.

### Fixed (post-checkpoint)
- `test/widgets/card_discovery/card_swipe_screen_filter_bar_test.dart` — Removed 4 unused imports (Wave 0 stubs have no bodies; imports were dead weight flagged by `--fatal-infos`).
- `test/widgets/filters/filter_settings_screen_test.dart` — Removed 3 unused imports for same reason.

## Post-Checkpoint Fixes

Two issues identified during human verification were resolved:

1. **Chips not wrapping:** Original layout used `SizedBox(height) + SingleChildScrollView(Axis.horizontal) + Row` — chips went off-screen when many filters active. Changed to `Padding + Wrap(spacing: xs, runSpacing: xs)` — chips now break into multiple lines automatically.
2. **Chip text unreadable:** `labelSmall` inherits `AppColors.onSurfaceMuted` (grey `#9E9EAE`) — poor contrast on gold selected chip background. Overridden to `AppColors.background` (`#1A1D2E`, dark navy) on both label and delete icon.

## Known Limitation (deferred to backlog)

When many filters are active the `Wrap` rows grow tall and the card shrinks proportionally. A
proper fix (e.g., a summary chip "Red · Creature +3 ▾" that opens a bottom sheet) is deferred
as a backlog item — it requires its own design and is out of scope for DISC-10.

## Commits
- `f02f0fa` feat(02-04): add active filter bar to CardSwipeScreen (DISC-10)
- post-checkpoint: wrap layout + chip contrast fix + unused import cleanup

## Self-Check

### must_haves verification
- [x] Active filter bar hidden when `FilterSettings.isEmpty == true`
- [x] Bar appears between SafeArea and card slot when any filter active
- [x] Each active colour shows chip labelled with `MtgColor.displayName`
- [x] Each active type/rarity/date shows dismissible chip
- [x] Chip X tap removes that filter; new card fetch triggered automatically
- [x] Bar disappears when all chips removed; card expands to full height
- [x] `flutter analyze --fatal-infos` clean (zero warnings)
- [x] Human verify checkpoint: approved

### Self-Check: PASSED
