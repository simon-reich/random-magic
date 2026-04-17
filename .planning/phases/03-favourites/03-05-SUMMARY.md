---
phase: 03-favourites
plan: "05"
subsystem: favourites/presentation
tags: [flutter, riverpod, card-swiper, hive-ce, undo-snackbar]
dependency_graph:
  requires:
    - 03-02  # FavouritesNotifier, FavouritesRepository, providers
  provides:
    - FavouriteSwipeScreen (full implementation)
  affects:
    - lib/features/card_discovery/presentation/card_swipe_screen.dart  # bug fix: colors field
tech_stack:
  added: []
  patterns:
    - ConsumerStatefulWidget for screens with UI controller state (CardSwiperController)
    - addPostFrameCallback for post-build navigation (empty list guard)
    - SnackBar with undo action for reversible destructive operations
key_files:
  created: []
  modified:
    - lib/features/favourites/presentation/favourite_swipe_screen.dart
    - lib/features/card_discovery/presentation/card_swipe_screen.dart
decisions:
  - "initialIndex used directly in CardSwiper — verified available in flutter_card_swiper 7.2.0 source; no list reordering workaround needed"
  - "onSwipe always returns true — deletion is AppBar-only; swipe = browse only"
  - "addPostFrameCallback for context.pop() when favourites empty — avoids build-phase navigation"
metrics:
  duration_minutes: 25
  completed_date: "2026-04-16"
  tasks_completed: 1
  tasks_total: 1
  files_modified: 2
  files_created: 0
---

# Phase 3 Plan 05: FavouriteSwipeScreen Implementation Summary

**One-liner:** Full `FavouriteSwipeScreen` with `CardSwiper` seeking to `favouriteId` via `initialIndex`, AppBar delete + 3-second Undo Snackbar, and empty-list auto-pop guard.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Implement FavouriteSwipeScreen swipe view with delete and undo | d578669 | `lib/features/favourites/presentation/favourite_swipe_screen.dart` |

## What Was Built

### FavouriteSwipeScreen (`lib/features/favourites/presentation/favourite_swipe_screen.dart`)

Replaced the single-file placeholder with a complete `ConsumerStatefulWidget` implementation:

- **`CardSwiperController`** created in `initState()`, disposed in `dispose()` — matches the pattern from `CardSwipeScreen`.
- **`initialIndex`** set from `favouritesProvider` list lookup by `favouriteId` in `initState()`. If the ID is not found (edge case: card deleted between tap and navigation), defaults to index 0.
- **`CardSwiper`** with `numberOfCardsDisplayed: 1`, `initialIndex: _currentIndex`. The `onSwipe` callback always returns `true` (advance on all directions — deletion is via AppBar only).
- **AppBar delete button:** `Icons.delete_outline` with `AppColors.error` color and tooltip `'Remove from Favourites'`.
- **Delete action:** Immediate `FavouritesNotifier.remove(id)` followed by `clearSnackBars()` + `showSnackBar()` with 3-second duration, `"{card.name} removed"` message, and `"Undo"` action that calls `FavouritesNotifier.add(deleted)`.
- **Empty list guard:** `addPostFrameCallback(() => context.pop())` prevents rendering `CardSwiper` with `cardsCount: 0` (which would assert-fail). Returns `SizedBox.shrink()` during the post-frame navigation.
- **`_FavouriteCardFace`** private widget: `CachedNetworkImage` on `normalImageUrl`, `ColoredBox(AppColors.surface)` fallback when null or empty.
- **`_Strings`** abstract final class for all string constants.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed MagicCard placeholder missing required `colors` field in `card_swipe_screen.dart`**
- **Found during:** Task 1 verification (`flutter analyze` full project)
- **Issue:** Plan 03-01 added `colors` as a required field to `MagicCard`. The `CardSwipeScreen._buildLoadingCard()` placeholder `const MagicCard(...)` did not include `colors: []`, causing an analyze error: `missing_required_argument`.
- **Fix:** Added `colors: []` to the `const placeholder = MagicCard(...)` in `_buildLoadingCard()`.
- **Files modified:** `lib/features/card_discovery/presentation/card_swipe_screen.dart`
- **Commit:** d578669

**2. [Rule 3 - Blocking] Brought in Wave 1 and 2 dependency files to make worktree compile**
- **Found during:** Initial worktree setup — the worktree was based on `0a1ba84` (Phase 2 complete) but Plan 05 depends on files committed at `d1d1a5e` (Wave 2 merge commit).
- **Fix:** Used `git checkout d1d1a5e -- <files>` to bring in `FavouriteCard`, `FavouritesRepository`, `providers.dart`, `providers.g.dart`, `MagicCard` (with `colors`), `main.dart` (with Hive adapter registration), and all Wave 0 test files.
- **Files added:** `lib/features/favourites/domain/favourite_card.dart`, `lib/features/favourites/data/favourites_repository.dart`, `lib/features/favourites/presentation/providers.dart`, `lib/features/favourites/presentation/providers.g.dart`, `lib/shared/models/magic_card.dart`, `lib/main.dart`, test fixtures and stubs.
- **Commit:** d578669

### Pre-existing Warnings (Out of Scope)

9 `unused_import` warnings in Wave 0 test stubs (`favourites_notifier_test.dart`, `favourites_filter_test.dart`, `favourites_screen_test.dart`). These exist in the target commit `d1d1a5e` and are pre-existing. They are not caused by this plan's changes. Deferred to Phase 5 (test implementation wave).

## Known Stubs

None — `FavouriteSwipeScreen` is fully wired to `favouritesProvider`. Card images load from `FavouriteCard.normalImageUrl` which is populated when the card is saved.

## Threat Flags

None — no new network endpoints, auth paths, or schema changes introduced. The `favouriteId` route param guard (default to index 0 if not found) implements the `accept` disposition for T-03-05-01 correctly.

## Verification Results

```
flutter analyze lib/features/favourites/presentation/favourite_swipe_screen.dart
→ No issues found!

flutter test test/widgets/favourites/
→ All tests passed! (5 skipped — Wave 0 stubs)

flutter test
→ 54 passed, 28 skipped — All tests passed!
```

## Self-Check: PASSED

- [x] `lib/features/favourites/presentation/favourite_swipe_screen.dart` — exists and verified
- [x] Commit `d578669` — confirmed in git log
- [x] `flutter analyze` on target file — clean (no issues)
- [x] `flutter test` — 54 passing, 28 skipped, 0 failures
