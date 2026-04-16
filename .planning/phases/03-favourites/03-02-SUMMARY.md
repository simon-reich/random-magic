---
phase: "03-favourites"
plan: "02"
subsystem: "favourites/data + favourites/presentation"
tags: ["hive-ce", "riverpod", "state-management", "repository", "providers"]
dependency_graph:
  requires:
    - "03-01 — FavouriteCard domain model + Hive adapter + main.dart box init"
  provides:
    - "FavouritesRepository — synchronous Hive write-through (getAll/save/delete/contains)"
    - "favouritesProvider — keepAlive FavouritesNotifier (add/remove/isFavourite/sorted)"
    - "favouritesFilterProvider — autoDispose FavouritesFilterNotifier (setColors/setTypes/setRarities/reset)"
    - "filteredFavouritesProvider — autoDispose derived list with AND colour/type/rarity filter"
  affects:
    - "03-03 — CardSwipeScreen integration (imports favouritesProvider)"
    - "03-04 — FavouritesScreen (imports filteredFavouritesProvider)"
    - "03-05 — FavouriteSwipeScreen (imports favouritesProvider)"
tech_stack:
  added: []
  patterns:
    - "FavouritesRepository: thin Hive write-through (mirrors FilterPresetsNotifier pattern from Phase 2)"
    - "FavouritesNotifier: @Riverpod(keepAlive: true) synchronous Notifier"
    - "FavouritesFilterNotifier: @riverpod autoDispose Notifier (resets on tab leave)"
    - "filteredFavouritesProvider: @riverpod derived provider (client-side AND filter)"
key_files:
  created:
    - "lib/features/favourites/data/favourites_repository.dart"
    - "lib/features/favourites/presentation/providers.dart"
    - "lib/features/favourites/presentation/providers.g.dart"
  modified:
    - "test/unit/favourites/favourites_notifier_test.dart (stubs filled with real assertions)"
    - "test/unit/favourites/favourites_filter_test.dart (stubs filled with real assertions)"
decisions:
  - "favouritesFilterProvider is Riverpod 3.x generated name for FavouritesFilterNotifier — code-gen strips 'Notifier' suffix from class name when generating the provider identifier"
  - "FavouritesRepository not used inside FavouritesNotifier — direct box access faster for isFavourite() hot path; Repository kept for future use by other consumers"
  - "filteredFavouritesProvider uses FavouritesFilter.isEmpty early-exit to skip where() iteration when no filter is active"
metrics:
  duration: "~20 minutes"
  completed: "2026-04-16"
  tasks_completed: 2
  files_changed: 5
---

# Phase 03 Plan 02: FavouritesRepository + Providers Summary

Hive write-through repository and three Riverpod providers that form the state management backbone for all Wave 3 Favourites UI plans.

## What Was Built

**Task 1 — FavouritesRepository** (`lib/features/favourites/data/favourites_repository.dart`)

Thin synchronous Hive CE repository with four methods — `getAll()`, `save()`, `delete()`, `contains()`. All return typed results; write methods are fire-and-forget (Hive flushes to disk automatically). `getAll()` sorts by `savedAt` descending (newest first). Uses `FavouriteCard.id` as the box key for O(1) `containsKey` lookups.

**Task 2 — Providers** (`lib/features/favourites/presentation/providers.dart`)

Three providers plus `FavouritesFilter` value object:

- `FavouritesNotifier` (`@Riverpod(keepAlive: true)`) — `add()`, `remove()`, `isFavourite()`, sorted state. Direct box access (not through Repository) for the `isFavourite()` hot path called per-card in `CardSwipeScreen`.
- `FavouritesFilterNotifier` (`@riverpod` autoDispose) — in-memory filter state, resets on tab leave. Exposes `setColors()`, `setTypes()`, `setRarities()`, `reset()`.
- `filteredFavouritesProvider` (`@riverpod` autoDispose derived) — client-side AND logic: colour OR within filter set, type substring match, rarity exact match. Short-circuits on empty filter.

`build_runner` generated `providers.g.dart` producing `favouritesProvider`, `favouritesFilterProvider`, and `filteredFavouritesProvider`.

Test stubs in `favourites_notifier_test.dart` and `favourites_filter_test.dart` were filled with real assertions — all 12 tests pass green.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Riverpod 3.x generated provider name differs from plan interface**
- **Found during:** Task 2 — first test run
- **Issue:** Plan interface and `providers.dart` referenced `favouritesFilterNotifierProvider`, but Riverpod 3.x code-gen produces `favouritesFilterProvider` (strips "Notifier" suffix from class name — same behaviour seen for `FilterPresetsNotifier` → `filterPresetsProvider` in Phase 2).
- **Fix:** Updated `filteredFavouritesProvider` body to use `favouritesFilterProvider`. Filter test file uses the extracted `applyFilter()` helper so no provider name reference is needed there.
- **Files modified:** `lib/features/favourites/presentation/providers.dart`
- **Commit:** `04d13a0`

**2. Worktree base mismatch**
- **Found during:** Start-up branch check
- **Issue:** Worktree HEAD was `0a1ba84` (Phase 2 tip); plan requires 03-01 outputs (`favourite_card.dart`, `main.dart` box init, test stubs, fixture). Target commit `f30fe025` contained these.
- **Fix:** Used `git checkout f30fe025 -- <files>` to bring the 03-01 outputs into the worktree, committed as a dependency setup commit (`4d5274c`).

## Known Stubs

None — all provider logic is fully implemented. The `FavouritesRepository` class exists and is functional but is not yet imported by any consumer (Wave 3 plans will use it if needed, or use `FavouritesNotifier.add/remove` directly via the provider).

## Threat Flags

None — this plan adds no new network endpoints, auth paths, file access patterns, or trust-boundary schema changes beyond what the threat model covers (Hive box read and provider state exposure).

## Self-Check: PASSED

- `lib/features/favourites/data/favourites_repository.dart` — exists
- `lib/features/favourites/presentation/providers.dart` — exists
- `lib/features/favourites/presentation/providers.g.dart` — exists (build_runner generated)
- Commit `2324613` (FavouritesRepository) — exists
- Commit `04d13a0` (providers + tests) — exists
- `flutter test test/unit/favourites/` — 12/12 passed
- `flutter analyze lib/features/favourites/` — No issues found
