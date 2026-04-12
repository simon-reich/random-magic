---
phase: 01-cardswipescreen
plan: "03"
subsystem: card_discovery/presentation
tags: [flutter, riverpod, card-swiper, skeletonizer, error-states, ui]
dependency_graph:
  requires:
    - 01-01 (flutter_card_swiper, skeletonizer deps + AppColors.networkError)
    - 01-02 (RateLimitedFailure, randomCardProvider, activeFilterQueryProvider)
  provides:
    - Full CardSwipeScreen implementation
    - Three card-shaped error states with navigation actions
    - Skeletonizer loading state in card shape
    - REVEAL swipe overlay label
  affects:
    - lib/features/card_discovery/presentation/card_swipe_screen.dart
tech_stack:
  added: []
  patterns:
    - "ConsumerStatefulWidget with CardSwiperController on state (not in Riverpod)"
    - "AsyncValue.when drives loading/data/error branches in a single AspectRatio slot"
    - "Skeletonizer wraps real widget tree with placeholder MagicCard for shimmer shape"
    - "flutter_card_swiper int percentThreshold normalized to double for overlay opacity"
    - "Sealed AppFailure pattern-matched in _buildErrorCard for type-safe error routing"
key_files:
  created: []
  modified:
    - lib/features/card_discovery/presentation/card_swipe_screen.dart
decisions:
  - "Used randomCardProvider (generated name) not randomCardNotifierProvider (plan doc had wrong name) — Rule 1 auto-fix"
  - "CardSwiper cardBuilder provides int percentThreshold values; normalized to double via / 100.0 for overlay opacity"
  - "Both tasks (card display + error states) implemented in one file write; committed as single atomic unit"
metrics:
  duration: ~15 minutes
  completed: "2026-04-12"
  tasks_completed: 2
  files_modified: 1
---

# Phase 1 Plan 03: CardSwipeScreen Full Implementation Summary

**One-liner:** Full CardSwipeScreen with flutter_card_swiper gestures, AspectRatio(63/88) card frame, Skeletonizer shimmer loading, REVEAL drag overlay, and four card-shaped error states (404 amber, 422 red, network blue-grey, rate-limit blue-grey).

## What Was Built

`card_swipe_screen.dart` replaced entirely — from a 17-line placeholder to a 296-line production implementation. The screen uses `ConsumerStatefulWidget` with `CardSwiperController` on state (not in Riverpod per D-08). All three `AsyncValue` branches are handled: loading shows a Skeletonizer shimmer using a real `_CardFaceWidget` placeholder; data shows the swiper with `CachedNetworkImage` loading the Scryfall `normal` image in an AspectRatio(63/88) frame; error delegates to `_buildErrorCard` which pattern-matches against the sealed `AppFailure` hierarchy.

The REVEAL overlay fades in during drag using `percentThresholdX` (int from CardSwiper, normalized to 0.0–1.0 double) driving an `Opacity` widget. All four failure types are handled: `CardNotFoundFailure` → amber "Adjust Filters" navigating to `/filters`; `InvalidQueryFailure` → red "Fix Filters" navigating to `/filters`; `RateLimitedFailure` → blue-grey "Too Many Requests" with Retry; `NetworkFailure` → blue-grey "Could not reach Scryfall" with Retry. No hardcoded color literals — all via `AppColors`.

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Implement CardSwipeScreen — card display, swipe gestures, skeletonizer loading | c39fbcf | lib/features/card_discovery/presentation/card_swipe_screen.dart |
| 2 | Implement three card-shaped error states with navigation actions | c39fbcf | lib/features/card_discovery/presentation/card_swipe_screen.dart (same file, same commit) |

## Decisions Made

- **randomCardProvider vs randomCardNotifierProvider:** The plan's interface doc specified `randomCardNotifierProvider` but the Riverpod 3.x code generator produces `randomCardProvider` (the `@ProviderFor(RandomCardNotifier)` annotation generates the provider as `randomCardProvider`). Auto-fixed via Rule 1 — using the actual generated provider name.
- **CardSwiper int percent normalization:** `flutter_card_swiper` v7.x provides `percentThresholdX` as `int` (0–100), not `double` (0.0–1.0). Normalized via `/ 100.0` before passing to `_CardFaceWidget.swipePercentX`. The plan's API reference showed `double` but actual package API uses `int`.
- **Single commit for tasks 1+2:** Both tasks modify the same file. Since both were implemented in a single write and analyze was clean, committed as one atomic unit per file rather than two artificial splits.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Wrong provider name in plan interface docs**
- **Found during:** Task 1 — `flutter analyze` reported `randomCardNotifierProvider` as undefined
- **Issue:** Plan specified `randomCardNotifierProvider` but Riverpod 3.x code generator produces `randomCardProvider` for the `RandomCardNotifier` class
- **Fix:** Changed all 4 references from `randomCardNotifierProvider` to `randomCardProvider`
- **Files modified:** lib/features/card_discovery/presentation/card_swipe_screen.dart
- **Commit:** c39fbcf

**2. [Rule 1 - Bug] CardSwiper percentThreshold type mismatch**
- **Found during:** Task 1 — `flutter analyze` reported `int` cannot be assigned to `double` at cardBuilder callback
- **Issue:** Plan's flutter_card_swiper API reference showed `double percentThresholdX` but actual package v7.2.0 API provides `int percentThresholdX` (0–100 range)
- **Fix:** Changed `swipePercentX: percentThresholdX` to `swipePercentX: percentThresholdX / 100.0`
- **Files modified:** lib/features/card_discovery/presentation/card_swipe_screen.dart
- **Commit:** c39fbcf

**3. [Rule 1 - Info] Unnecessary const keyword on placeholder MagicCard**
- **Found during:** Task 1 — `flutter analyze` flagged `const {}` in legalities field inside a const constructor context
- **Issue:** `const {}` inside `const MagicCard(...)` is redundant
- **Fix:** Changed `legalities: const {}` to `legalities: {}`
- **Files modified:** lib/features/card_discovery/presentation/card_swipe_screen.dart
- **Commit:** c39fbcf

## Status

**Awaiting human verification** (checkpoint:human-verify). The implementation is complete and `flutter analyze --fatal-infos` passes with zero issues. Verification requires running `flutter run` on a device/simulator.

## Known Stubs

None — the CardSwipeScreen is fully wired to `randomCardProvider` which fetches from Scryfall. The `activeFilterQueryProvider` returns `null` (unrestricted query) per Plan 02 design; this is an intentional stub tracked in 01-02-SUMMARY.md.

## Threat Flags

None — threats T-03-01 through T-03-04 from the plan's threat model are all mitigated:
- T-03-01: Null URL guard implemented (`imageUrl.isEmpty` check before CachedNetworkImage)
- T-03-02: `isDisabled: isLoading` gate present on CardSwiper
- T-03-03: Generic user-facing error messages only; no stack traces in UI
- T-03-04: Error buttons navigate to `AppRoutes.filters` (internal route) only

## Self-Check

### Files exist:

- lib/features/card_discovery/presentation/card_swipe_screen.dart — FOUND (296 lines, contains ConsumerStatefulWidget)

### Commits exist:

- c39fbcf — feat(01-03): implement CardSwipeScreen with swipe gestures, skeletonizer loading, and REVEAL overlay

## Self-Check: PASSED
