---
phase: 03-favourites
plan: "01"
subsystem: favourites/domain
tags: [hive-ce, domain-model, type-adapter, magic-card, colours]
dependency_graph:
  requires: []
  provides:
    - FavouriteCard domain model with FavouriteCardAdapter (typeId 1)
    - Hive box 'favourites' opened in main.dart
    - MagicCard.colors field parsed from Scryfall JSON
  affects:
    - lib/main.dart
    - lib/shared/models/magic_card.dart
    - lib/features/card_discovery/presentation/card_swipe_screen.dart
tech_stack:
  added: []
  patterns:
    - Hand-written Hive CE TypeAdapter (same pattern as FilterPresetAdapter)
    - ISO-8601 string serialisation for DateTime fields
    - Safe nullable List cast: (json['colors'] as List<dynamic>?)?.cast<String>() ?? const []
key_files:
  created:
    - lib/features/favourites/domain/favourite_card.dart
    - lib/features/favourites/presentation/providers.dart
    - test/unit/favourites/favourite_card_test.dart
    - test/unit/card_discovery/magic_card_colors_test.dart
  modified:
    - lib/main.dart
    - lib/shared/models/magic_card.dart
    - lib/features/card_discovery/presentation/card_swipe_screen.dart
decisions:
  - "FavouriteCardAdapter uses typeId 1 (typeId 0 reserved for FilterPresetAdapter) — collision would corrupt Hive registry"
  - "savedAt stored as ISO-8601 string in adapter — avoids timezone serialisation issues, consistent with FilterPresetAdapter date pattern"
  - "providers.dart stub created so Wave 0 test stubs compile — filled in by Plan 02"
  - "colors: [] added to card_swipe_screen.dart placeholder MagicCard — required by new mandatory field"
metrics:
  duration_minutes: 15
  completed_date: "2026-04-16"
  tasks_completed: 3
  tasks_total: 3
  files_created: 4
  files_modified: 3
---

# Phase 3 Plan 01: FavouriteCard Domain Model and Hive Adapter Summary

**One-liner:** FavouriteCard projection model with hand-written FavouriteCardAdapter (typeId 1), Hive box init in main.dart, and MagicCard.colors parsed from Scryfall JSON for colour filtering.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create FavouriteCard domain model and Hive adapter | 33b4425 | lib/features/favourites/domain/favourite_card.dart, test/unit/favourites/favourite_card_test.dart |
| 2 | Register FavouriteCardAdapter and open favourites box in main.dart | cc1d9b9 | lib/main.dart |
| 3 | Add colors field to MagicCard parsed from Scryfall json['colors'] | a65ed51 | lib/shared/models/magic_card.dart, test/unit/card_discovery/magic_card_colors_test.dart, lib/features/favourites/presentation/providers.dart |

## What Was Built

**FavouriteCard** (`lib/features/favourites/domain/favourite_card.dart`): A typed Dart class representing a card projection stored in the local Hive CE favourites box. Contains exactly the 10 D-12 fields needed for display and client-side filtering — `id`, `name`, `typeLine`, `rarity`, `setCode`, `artCropUrl?`, `normalImageUrl?`, `manaCost?`, `savedAt`, `colors`. Avoids persisting oracle text, legalities, and price data that are not needed.

**FavouriteCardAdapter**: Hand-written Hive CE `TypeAdapter<FavouriteCard>` using `typeId = 1`. Serialises all 10 fields in a fixed order documented in the class comment. `savedAt` is stored as an ISO-8601 string (not raw DateTime) to avoid timezone issues. `colors` round-trips via `.cast<String>()`.

**main.dart**: Extended with `Hive.registerAdapter(FavouriteCardAdapter())` and `await Hive.openBox<FavouriteCard>('favourites')` before `runApp`, immediately after the FilterPreset lines. Doc comment updated to mention both boxes.

**MagicCard.colors**: Added `final List<String> colors` field with `required this.colors` in the constructor. `fromJson` parses `(json['colors'] as List<dynamic>?)?.cast<String>() ?? const []` — colourless cards (absent or null key) produce an empty list, not a crash. This enables `FavouriteCard.colors` to be populated from real Scryfall data for FAV-07 colour filtering.

## Tests

- **9 tests** in `test/unit/favourites/favourite_card_test.dart`: construction, nullable fields, multi-color list, Hive box round-trips (fully populated, null fields, savedAt ISO-8601, WUBRG order), typeId.
- **6 tests** in `test/unit/card_discovery/magic_card_colors_test.dart`: single-color, multi-color, empty list, null colors key, absent colors key.
- **Wave 0 stubs** in `test/unit/favourites/favourites_notifier_test.dart`: all 6 tests skipped (Wave 2 pending) — confirmed compilable.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed missing colors field on placeholder MagicCard in card_swipe_screen.dart**
- **Found during:** Task 3 — `flutter analyze lib/` revealed a compile error
- **Issue:** `card_swipe_screen.dart` line 89 constructs a `const MagicCard(...)` for the shimmer loading skeleton. After adding `required this.colors` to `MagicCard`, this became a compile error.
- **Fix:** Added `colors: []` to the placeholder `const MagicCard` in `_buildLoadingCard()`.
- **Files modified:** `lib/features/card_discovery/presentation/card_swipe_screen.dart`
- **Commit:** a65ed51

**2. [Rule 3 - Blocking] Created stub providers.dart so Wave 0 test stubs compile**
- **Found during:** Task 3 verification — `flutter test test/unit/favourites/favourites_notifier_test.dart` failed to compile because `lib/features/favourites/presentation/providers.dart` did not exist.
- **Issue:** The Wave 0 test stub file (pre-created by Plan 00) imports `providers.dart` which is only implemented in Plan 02. Without the file, the test cannot even load.
- **Fix:** Created a minimal stub `providers.dart` with a `library;` declaration and explanatory doc comment. Plan 02 will replace this with the full implementation.
- **Files modified:** `lib/features/favourites/presentation/providers.dart` (created)
- **Commit:** a65ed51

## Known Stubs

- `lib/features/favourites/presentation/providers.dart`: Empty stub with `library;` declaration. Contains no providers. Plan 03-02 (FavouritesNotifier) will fill this in with `favouritesProvider` and related providers.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced. All changes are local Hive CE storage and JSON parsing (already within the existing Scryfall trust boundary).

## Self-Check: PASSED

All created files confirmed present. All task commits (33b4425, cc1d9b9, a65ed51) verified in git log.
