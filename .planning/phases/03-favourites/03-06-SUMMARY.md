---
plan: "03-06"
phase: "03-favourites"
status: completed
gap_closure: true
completed_at: 2026-04-17
---

## What Was Built

Filled the 12 skipped unit tests across two test files, closing the gaps identified in 03-VERIFICATION.md.

**Task 1 — FavouritesNotifier tests** (`test/unit/favourites/favourites_notifier_test.dart`):
- 6 real tests replacing stub bodies and removing all `skip:` markers
- Covers: initial empty state, add+isFavourite, remove+isFavourite, newest-first sort order, add idempotency, Hive persistence across close/reopen
- Uses `ProviderContainer` with real Hive CE box in `Directory.systemTemp`

**Task 2 — FavouritesFilter tests** (`test/unit/favourites/favourites_filter_test.dart`):
- Standalone `applyFilter()` helper replicating the `filteredFavourites` where-block from `providers.dart` — no Riverpod container needed
- 6 real tests covering: empty filter (returns all), color filter (OR per colour), type filter (typeLine.contains), rarity filter (exact match), combined AND logic, no-match returns empty
- Import limited to `show FavouritesFilter` — no provider symbols imported

## Verification Evidence

```
flutter test test/unit/favourites/ --no-pub
+21: All tests passed!
```

```
flutter test test/unit/favourites/favourites_filter_test.dart --no-pub
+6: All tests passed!
```

- Zero `skip:` markers in either file
- Zero `expect(true, true)` bodies in either file
- `container.read(favouritesProvider)` used in 4 places in notifier test
- `applyFilter(` called 6 times in filter test

## Deviations

None. Files written exactly as specified in the plan.

## Self-Check: PASSED

- [x] All 6 FavouritesNotifier tests pass with real assertions — no skip markers
- [x] All 6 filter tests pass with real assertions — no skip markers
- [x] `flutter test test/unit/favourites/` exits 0 with 12+ tests passing
- [x] `applyFilter()` helper replicates the production `filteredFavourites` where-block

## key-files

### created
- test/unit/favourites/favourites_notifier_test.dart (overwritten with real assertions)
- test/unit/favourites/favourites_filter_test.dart (overwritten with real assertions + applyFilter helper)
