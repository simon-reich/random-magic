---
phase: 04-card-detail-view
plan: "03"
subsystem: card-detail
tags: [navigation, gesture, tap-to-detail, test-stubs]
dependency_graph:
  requires:
    - GoRouter /card/:id builder with state.extra cast (04-01)
    - CardDetailScreen accepting MagicCard? (04-01)
    - getCardById on CardRepository + ScryfallApiClient (04-01)
    - Full CardDetailScreen implementation (04-02)
  provides:
    - GestureDetector tap-to-detail on _CardFaceWidget in CardSwipeScreen (CARD-01 / D-02)
    - Tap handler in FavouriteSwipeScreen fetching full MagicCard via getCardById before navigating
    - test/widgets/card_discovery/card_swipe_screen_tap_test.dart (2 skip-stubs for CARD-01)
  affects:
    - lib/features/card_discovery/presentation/card_swipe_screen.dart
    - lib/features/favourites/presentation/favourite_swipe_screen.dart
    - test/widgets/card_discovery/card_swipe_screen_tap_test.dart
tech_stack:
  added: []
  patterns:
    - GestureDetector nested inside CardSwiper cardBuilder for additive tap handling
    - Async onTap with context.mounted guard across await boundary
    - switch on sealed Result<T> for getCardById response in tap handler
key_files:
  created:
    - test/widgets/card_discovery/card_swipe_screen_tap_test.dart
  modified:
    - lib/features/card_discovery/presentation/card_swipe_screen.dart
    - lib/features/favourites/presentation/favourite_swipe_screen.dart
decisions:
  - "Pitfall 6 resolved via Option D: tap handler in FavouriteSwipeScreen calls getCardById to fetch full MagicCard before navigating; CardDetailScreen itself does not re-fetch"
  - "GestureDetector nested inside CardSwiper cardBuilder: short taps reach onTap; pan/swipe gestures are consumed by CardSwiper — no conflict"
  - "Generic SnackBar on getCardById failure: no API response detail exposed (T-04-11 accept disposition)"
metrics:
  duration: "~15 minutes"
  completed: "2026-04-17"
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 2
---

# Phase 04 Plan 03: Tap-to-detail navigation wiring Summary

GestureDetector tap handler wired in both swipe screens — tapping a card opens CardDetailScreen with the full MagicCard passed via GoRouter extra; FavouriteSwipeScreen fetches full card via getCardById before navigating.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add GestureDetector to _CardFaceWidget in CardSwipeScreen (D-02) | fcc0315 | card_swipe_screen.dart |
| 2 | Add tap-to-detail to FavouriteSwipeScreen via getCardById + CARD-01 test stubs | 627ec58 | favourite_swipe_screen.dart, card_swipe_screen_tap_test.dart |

## What Was Built

- **CardSwipeScreen GestureDetector**: `GestureDetector(onTap: () => context.go('/card/${card.id}', extra: card))` wraps `_CardFaceWidget` in the `cardBuilder` lambda. Short taps are delivered to `onTap`; swipe pan gestures are consumed by the parent `CardSwiper` — no conflict between the two gesture detectors.
- **FavouriteSwipeScreen tap handler**: `GestureDetector.onTap` is `async`; calls `ref.read(cardRepositoryProvider).getCardById(card.id)`, then switches on the sealed `Result<T>`: `Success` navigates via `context.go('/card/${value.id}', extra: value)`; `Failure` shows a generic SnackBar. `context.mounted` guard prevents use-after-dispose across the `await` boundary.
- **Imports added to FavouriteSwipeScreen**: `card_discovery/presentation/providers.dart` (show `cardRepositoryProvider`) and `shared/result.dart` (for `Success`/`Failure` pattern match).
- **CARD-01 test stubs**: `test/widgets/card_discovery/card_swipe_screen_tap_test.dart` with 2 `skip: true` stubs — one for CardSwipeScreen tap, one for FavouriteSwipeScreen tap. Full integration tests deferred to Phase 5.

## Deviations from Plan

None — plan executed exactly as written. The `Result<T>` fold pattern described in the plan (`result.fold(onSuccess:, onFailure:)`) was adapted to the project's actual sealed-class switch pattern (`switch (result) { case Success(:final value): ... case Failure(): ... }`), which is the correct usage for this codebase (not a deviation — the plan noted to adapt to the existing pattern).

## Known Stubs

| Stub | File | Reason |
|------|------|--------|
| 2 `skip: true` testWidgets cases (CARD-01) | test/widgets/card_discovery/card_swipe_screen_tap_test.dart | Full integration test requires running router and mock repository — deferred to Phase 5 integration suite |

## Threat Surface Scan

No new threat surface beyond the plan's threat model. T-04-10 (DoS via getCardById) is mitigated: `DioException` is caught inside `getCardById` and returned as a typed `Failure`; the `Failure` case shows a generic SnackBar and the user stays in the swipe view — no crash. T-04-11 (SnackBar information disclosure) accepted: message is `'Could not load card details. Try again.'` with no API detail.

## Self-Check: PASSED

- `lib/features/card_discovery/presentation/card_swipe_screen.dart` — contains `GestureDetector`, `onTap: () => context.go('/card/${card.id}', extra: card)`
- `lib/features/favourites/presentation/favourite_swipe_screen.dart` — contains `getCardById`, `context.go('/card/${value.id}', extra: value)`, `context.mounted`, `SnackBar`
- `test/widgets/card_discovery/card_swipe_screen_tap_test.dart` — exists, 2 skip-stub tests
- Commits fcc0315 and 627ec58 — verified in git log
- `flutter analyze --fatal-infos` — clean on both modified files
- `flutter test --no-pub` — 86 passed, 13 skipped (pre-existing + 2 new stubs = 15 total would be if stubs counted in pre-existing), 0 failed
