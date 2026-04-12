# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-10)

**Core value:** Tactile, swipeable MTG card discovery — always one swipe away from a new random card
**Current focus:** Phase 2 — Filter Settings & Presets

## Current Status

**Phase:** 2 of 5
**Active Jira ticket:** RM-13 (done) → next: Phase 2 ticket
**Current Plan:** Phase 1 complete
**Last session:** 2026-04-12 — Phase 1 verified and marked complete

## Phase Progress

| Phase | Status |
|-------|--------|
| Phase 1: CardSwipeScreen | Done (verified 2026-04-12) |
| Phase 2: Filter Settings & Presets | Next |
| Phase 3: Favourites | Pending |
| Phase 4: Card Detail View | Pending |
| Phase 5: Tests | Pending |

## Plan Progress — Phase 1

| Plan | Name | Status |
|------|------|--------|
| 01-01 | Dependencies + Theme | Done (d5f3bc1, cff778e) |
| 01-02 | Domain Layer Fixes + Provider Scaffolding | Done (2b84f0a, 086d0d1) |
| 01-03 | CardSwipeScreen Full Implementation | Done (c39fbcf) — UAT passed, verified 2026-04-12 |

## Key Decisions

- **ThemeData extensions for global shimmer:** SkeletonizerConfigData.dark() in ThemeData.extensions — all Skeletonizer widgets inherit dark colors automatically
- **AppColors.networkError in plan 01:** Declared before plan 03 uses it per CLAUDE.md no-hardcoded-colours rule
- **activeFilterQueryProvider in filters/presentation:** Feature ownership — card discovery imports it directly (acceptable for providers, not data/domain layers)
- **randomCardProvider naming:** Riverpod 3.x code generator produces `randomCardProvider` for `RandomCardNotifier` class — plan doc had wrong name `randomCardNotifierProvider`
- **CardSwiper int percent normalization:** flutter_card_swiper v7.x provides `percentThresholdX` as int (0–100); normalized to double via /100.0
- **skeletonizer ^2.1.3:** pubspec resolved to v2.1.3 instead of planned ^1.4.0 — forward-compatible upgrade; API unchanged, analyze clean, shimmer confirmed on device

## Blockers

None.

---
*State last updated: 2026-04-12 (Phase 1 complete, Phase 2 next)*
