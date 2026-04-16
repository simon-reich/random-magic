---
phase: 03-favourites
plan: "03"
subsystem: favourites
tags: [favourites, card-discovery, save-action, swipe-up, snackbar, shared-providers]
dependency_graph:
  requires: [03-02]
  provides: [FAV-01]
  affects: [lib/features/card_discovery/presentation/card_swipe_screen.dart]
tech_stack:
  added: []
  patterns:
    - Shared re-export layer (lib/shared/providers/) to satisfy CLAUDE.md cross-feature import rule
    - ConsumerWidget promotion of private widget for Riverpod watch access
    - Duplicate-guard pattern (isFavourite check) in both save paths
    - Intentional code duplication (~12 lines) to avoid coupling widget to state's internal method
key_files:
  created:
    - lib/shared/providers/favourites_provider.dart
  modified:
    - lib/features/card_discovery/presentation/card_swipe_screen.dart
decisions:
  - shared/providers/favourites_provider.dart re-export pattern enforces CLAUDE.md cross-feature import rule
  - _CardFaceWidget promoted to ConsumerWidget to watch favouritesProvider and derive isFav synchronously
  - Swipe-up returns false from onSwipe callback to cancel animation (card stays in place, not advanced)
  - Intentional duplication of _saveToFavourites / _saveCardToFavourites to avoid coupling widget to state
  - FavouriteCard.colors set from card.colors (not const []) in both save paths to enable FAV-07 colour filtering
metrics:
  duration: ~10 minutes
  completed_date: "2026-04-16"
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 1
---

# Phase 3 Plan 03: Bookmark Overlay and Swipe-Up Save Summary

**One-liner:** Bookmark heart button on card face + swipe-up gesture both save to Hive via shared `favouritesProvider` re-export, with duplicate-save guard and "Saved to Favourites" Snackbar.

## What Was Built

### Task 1 — Shared Favourites Provider Re-export

Created `lib/shared/providers/favourites_provider.dart` as a thin re-export that makes `favouritesProvider` and `FavouritesNotifier` accessible to `card_discovery/presentation/` without violating CLAUDE.md's cross-feature import rule.

The shared layer wraps `features/favourites/presentation/providers.dart` — no logic lives in the re-export file itself.

### Task 2 — Bookmark Overlay and Swipe-Up Save

Modified `lib/features/card_discovery/presentation/card_swipe_screen.dart`:

- **`_CardFaceWidget`** promoted from `StatelessWidget` to `ConsumerWidget` — watches `favouritesProvider` for reactivity, derives `isFav` synchronously via `isFavourite(card.id)`.
- **Bookmark `Positioned`** added as the last Stack child (bottom-right, `AppSpacing.sm` inset). Icon toggles between `Icons.favorite_border` (`AppColors.onBackground`) and `Icons.favorite` (`AppColors.error`). `onPressed: null` when already saved (D-04).
- **`_saveToFavourites`** on `_CardFaceWidget` handles the button-tap save path — guards duplicates, calls `FavouritesNotifier.add()`, shows Snackbar.
- **`_saveCardToFavourites`** on `_CardSwipeScreenState` handles the swipe-up save path — identical guard and logic.
- **`onSwipe` callback** updated: `CardSwiperDirection.top` fires `_saveCardToFavourites` and returns `false` (cancels animation — card snaps back, stays in place). Left/right still calls `randomCardProvider.refresh()` and returns `true`.
- **`_Strings`** private constants class holds all string literals (`savedToFavourites`, `tooltipSave`, `tooltipAlreadySaved`).
- **`FavouriteCard.colors`** set from `card.colors` (not `const []`) in both save paths — required for FAV-07 colour filtering.

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 | 21e3281 | feat(03-03): add shared favourites provider re-export |
| 2 | 1f20646 | feat(03-03): wire bookmark overlay and swipe-up save to CardSwipeScreen |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all functionality is fully wired. The bookmark button is live, swipe-up is live, Snackbar fires on save, and `FavouriteCard.colors` is populated from real card data.

## Threat Flags

No new security surface introduced. The `FavouriteCard` projection is a typed, read-only snapshot from already-parsed Scryfall data. Both save paths include the T-03-03-01 duplicate-save guard (`isFavourite` check). T-03-03-02 (`clearSnackBars` before `showSnackBar`) is implemented in both paths.

## Self-Check: PASSED

All created files exist on disk. Both task commits (21e3281, 1f20646) confirmed in git log.
