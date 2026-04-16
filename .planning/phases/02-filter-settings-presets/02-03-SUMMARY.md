---
plan: "02-03"
phase: "02-filter-settings-presets"
status: completed
wave: 3
completed_at: "2026-04-12"
---

# Plan 02-03 Summary — FilterSettingsScreen UI

## What Was Built

Full `FilterSettingsScreen` implementation replacing the Phase 1 placeholder. All filter controls, preset management, and dirty-state tracking are wired to Riverpod providers.

## Key Files

### Modified
- `lib/features/filters/presentation/filter_settings_screen.dart` — Complete replacement: mana symbol toggles (W/U/B/R/G/C/M with SVG via `SvgPicture.network`, fallback `CircleAvatar`, custom `_MulticolorSymbol` gradient), type chips (`Wrap` layout, 8 types), rarity chips (4 rarities), Released After/Before date pickers with inline clear buttons, preset chip row (`Wrap` layout, tap-to-load with D-12 `*` suffix, X-to-delete), preset save field with duplicate name inline error (FILT-09), Reset All Filters button.

## Post-Checkpoint Fixes

Five issues identified during human verification were resolved:

1. **Filter applies only once (D-13):** `RandomCardNotifier.refresh()` was calling `_fetch()` without a query. Fixed to `ref.read(activeFilterQueryProvider)` at call time.
2. **Same preset not triggering new card fetch:** Added `FilterRefreshSignal` counter provider; preset chip tap calls `ref.read(filterRefreshSignalProvider.notifier).trigger()` before navigating; `RandomCardNotifier.build()` watches it.
3. **Preset chips overflow on narrow screens:** Changed from `SingleChildScrollView(horizontal) Row` to `Wrap(spacing, runSpacing)` — chips flow to multiple lines.
4. **D-12 `*` suffix not rebuilding on tab return:** `activePresetName` was a plain Dart field on `FilterSettingsNotifier`. Promoted to dedicated `ActivePresetName` Riverpod provider; screen uses `ref.watch(activePresetNameProvider)` for guaranteed rebuilds.
5. **Checkmark causes chip size jump:** Added `showCheckmark: false` to all `FilterChip`s (type + rarity rows).

## Color Filter Fix (post-checkpoint)

User clarified that `color<=WU` includes colorless and W/U bicolor cards. Changed Scryfall operator from `color<=X` (subset) to `color=X` (exact) in `ScryfallQueryBuilder`. Each mono color generates its own `color=X` clause, OR-joined: White+Blue → `(color=W OR color=U)` → mono-white OR mono-blue only.

## Commits
- Initial FilterSettingsScreen implementation (part of wave 3 execution)
- `dbc41b9` fix(02): implement D-12 dirty-state tracking across plans 00, 02, 03
- `6101c9e` fix(02): use color=X exact operator for mono-only color filtering

## Self-Check

### must_haves verification
- [x] Mana colour toggles visible (SVG for W/U/B/R/G/C, gradient wheel for M)
- [x] Type chips (Creature/Instant/Sorcery/Enchantment/Artifact/Land/Planeswalker/Battle) in Wrap layout
- [x] Rarity chips (Common/Uncommon/Rare/Mythic) in Wrap layout
- [x] Date pickers open from Released After / Released Before rows; inline clear button
- [x] Preset chip row at top when presets exist (Wrap layout)
- [x] Preset chip tap loads preset, fires refresh signal, navigates to Discover (D-07)
- [x] Active preset chip shows `*` suffix (activePresetNameProvider, Riverpod-watched, D-12)
- [x] Save preset: text field + Save button; duplicate name shows inline error (FILT-06, FILT-09)
- [x] Preset chip trailing X deletes preset (FILT-08)
- [x] No hardcoded colours; no hardcoded spacing
- [x] `flutter analyze --fatal-infos` clean
- [x] Human verify checkpoint: approved

### Self-Check: PASSED
