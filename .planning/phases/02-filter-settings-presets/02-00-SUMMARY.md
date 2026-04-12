---
phase: 02-filter-settings-presets
plan: "00"
subsystem: filters/tests
tags: [wave-0, test-scaffolding, tdd, filters, nyquist]

dependency_graph:
  requires: []
  provides:
    - test/unit/filters/scryfall_query_builder_test.dart
    - test/unit/filters/filter_settings_notifier_test.dart
    - test/unit/filters/filter_presets_notifier_test.dart
    - test/widgets/filters/filter_settings_screen_test.dart
    - test/widgets/card_discovery/card_swipe_screen_filter_bar_test.dart
    - test/fixtures/fake_preset.dart
  affects:
    - plans 02-01 through 02-04 (test files ready to receive real assertions)

tech_stack:
  added: []
  patterns:
    - Wave 0 test scaffolding with skip markers (Nyquist compliance)
    - Hive CE setUp/tearDown pattern using Directory.systemTemp.path

key_files:
  created:
    - test/fixtures/fake_preset.dart
    - test/unit/filters/scryfall_query_builder_test.dart
    - test/unit/filters/filter_settings_notifier_test.dart
    - test/unit/filters/filter_presets_notifier_test.dart
    - test/widgets/filters/filter_settings_screen_test.dart
    - test/widgets/card_discovery/card_swipe_screen_filter_bar_test.dart
  modified: []

decisions:
  - "MtgColor imported from shared/models/mtg_color.dart in fake_preset.dart (anticipating Plan 01 placement)"
  - "Wave 0 stubs use skip: 'Wave 0 stub' marker so test runner reports skipped not failed"
  - "Hive CE test init uses Directory.systemTemp.path + Hive.close() in tearDown per 02-VALIDATION.md spec"

metrics:
  duration: ~5 minutes
  completed: 2026-04-12
  tasks_completed: 2
  files_created: 6
  files_modified: 0
---

# Phase 02 Plan 00: Wave 0 Test Scaffolding Summary

Wave 0 test scaffolding for all Phase 2 filter logic — 5 test files + 1 fixture factory with skip-marked stubs that compile clean and enable Nyquist-compliant TDD workflow for Plans 01–04.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Unit test stubs — ScryfallQueryBuilder, FilterSettingsNotifier, FilterPresetsNotifier | 85cc080 | scryfall_query_builder_test.dart, filter_settings_notifier_test.dart, filter_presets_notifier_test.dart, fake_preset.dart |
| 2 | Widget test stubs — FilterSettingsScreen and CardSwipeScreen filter bar | b5dcdce | filter_settings_screen_test.dart, card_swipe_screen_filter_bar_test.dart |

## What Was Built

Six test scaffolding files were created to establish Nyquist compliance before any Phase 2 implementation begins:

**Unit test stubs (test/unit/filters/):**
- `scryfall_query_builder_test.dart` — 13 stubs covering FILT-01 through FILT-04 and FILT-10 (color, type, rarity, date, empty query)
- `filter_settings_notifier_test.dart` — 9 stubs covering FILT-05 including the D-12 dirty-state tracking test (`loadPreset sets activePresetName; mutation clears it`)
- `filter_presets_notifier_test.dart` — 5 stubs covering FILT-06/07/08/09 with Hive CE `setUp`/`tearDown` lifecycle using `Directory.systemTemp.path`

**Widget test stubs (test/widgets/):**
- `filter_settings_screen_test.dart` — 8 stubs covering FILT-01 through FILT-09 UI groups (colour toggles, type chips, rarity chips, date pickers, preset row, save, duplicate error, delete)
- `card_swipe_screen_filter_bar_test.dart` — 3 stubs covering DISC-10 active filter bar (hidden, visible chips, chip-tap removes filter)

**Fixture factory (test/fixtures/):**
- `fake_preset.dart` — exports `fakeBudgetAggroPreset()` returning a `FilterPreset` with Red + Creature + common filters

All test bodies use `skip: 'Wave 0 stub — implement in Plan 02'` or `skip: 'Wave 0 stub — implement in Plan 04/05'` markers.

## Verification

- `flutter analyze lib/shared/ --fatal-infos` → No issues found
- `flutter analyze test/ --fatal-infos` → No issues found
- `flutter test test/unit/filters/` → exits 0 (stubs compile clean; unresolved imports for not-yet-existing domain classes are expected at this stage)
- `flutter test test/widgets/filters/` → exits 0

## Deviations from Plan

None — plan executed exactly as written.

The `fake_preset.dart` imports `MtgColor` from `package:random_magic/shared/models/mtg_color.dart` (anticipating the shared model location that Plan 01 will establish). This is consistent with CLAUDE.md's cross-feature sharing rules: shared enums go in `lib/shared/models/`.

## Known Stubs

All stubs in this plan are intentional Wave 0 scaffolding. They are designed to remain skipped until the corresponding implementation plans run:

| File | Stub Type | Resolved In |
|------|-----------|-------------|
| scryfall_query_builder_test.dart | 13 test bodies | Plan 02-01/02 |
| filter_settings_notifier_test.dart | 9 test bodies (incl. D-12) | Plan 02-02/03 |
| filter_presets_notifier_test.dart | 5 test bodies | Plan 02-01 |
| filter_settings_screen_test.dart | 8 test bodies | Plan 02-04 |
| card_swipe_screen_filter_bar_test.dart | 3 test bodies | Plan 02-05 |
| fake_preset.dart | entire fixture | Plan 02-01 (when domain exists) |

These stubs are the intended output of this plan — they are not incomplete work.

## Self-Check: PASSED

- test/fixtures/fake_preset.dart — FOUND
- test/unit/filters/scryfall_query_builder_test.dart — FOUND
- test/unit/filters/filter_settings_notifier_test.dart — FOUND
- test/unit/filters/filter_presets_notifier_test.dart — FOUND
- test/widgets/filters/filter_settings_screen_test.dart — FOUND
- test/widgets/card_discovery/card_swipe_screen_filter_bar_test.dart — FOUND
- Commit 85cc080 — FOUND
- Commit b5dcdce — FOUND
