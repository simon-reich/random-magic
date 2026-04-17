---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
current_plan: Not started
status: Ready to plan
last_updated: "2026-04-17T10:48:27.264Z"
progress:
  total_phases: 5
  completed_phases: 3
  total_plans: 15
  completed_plans: 15
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-10)

**Core value:** Tactile, swipeable MTG card discovery — always one swipe away from a new random card
**Current focus:** Phase 03 — favourites

## Current Status

**Phase:** 4 of 5 (card detail view)
**Active Jira ticket:** Phase 3 next
**Current Plan:** Not started
**Last session:** 2026-04-17T10:48:27.261Z

## Phase Progress

| Phase | Status |
|-------|--------|
| Phase 1: CardSwipeScreen | Done (verified 2026-04-12) |
| Phase 2: Filter Settings & Presets | Done (verified 2026-04-16) |
| Phase 3: Favourites | Next |
| Phase 4: Card Detail View | Pending |
| Phase 5: Tests | Pending |

## Plan Progress — Phase 2

| Plan | Name | Status |
|------|------|--------|
| 02-00 | Test stubs + fixtures | Done |
| 02-01 | MtgColor, FilterSettings, FilterPreset, Hive init | Done |
| 02-02 | ScryfallQueryBuilder, FilterPresetRepository, providers | Done |
| 02-03 | FilterSettingsScreen UI | Done — UAT passed, verified 2026-04-12 |
| 02-04 | Active filter bar on CardSwipeScreen | Done — UAT passed, verified 2026-04-16 |

## Key Decisions

- **ThemeData extensions for global shimmer:** SkeletonizerConfigData.dark() in ThemeData.extensions — all Skeletonizer widgets inherit dark colors automatically
- **AppColors.networkError in plan 01:** Declared before plan 03 uses it per CLAUDE.md no-hardcoded-colours rule
- **activeFilterQueryProvider in filters/presentation:** Feature ownership — card discovery imports it directly (acceptable for providers, not data/domain layers)
- **randomCardProvider naming:** Riverpod 3.x code generator produces `randomCardProvider` for `RandomCardNotifier` class — plan doc had wrong name `randomCardNotifierProvider`
- **CardSwiper int percent normalization:** flutter_card_swiper v7.x provides `percentThresholdX` as int (0–100); normalized to double via /100.0
- **skeletonizer ^2.1.3:** pubspec resolved to v2.1.3 instead of planned ^1.4.0 — forward-compatible upgrade; API unchanged, analyze clean, shimmer confirmed on device
- **color=X exact operator:** Scryfall `color<=X` includes colorless + multicolor supersets; `color=X` is mono-only exact match — changed in ScryfallQueryBuilder
- **FilterRefreshSignal counter provider:** Preset chip tap needs to force a new fetch even when filter state is identical — solved via a dedicated counter provider watched by RandomCardNotifier
- **activePresetNameProvider:** Promoted from plain Dart field to Riverpod provider so `*` suffix on preset chips rebuilds correctly on tab return
- **_ActiveFilterBar uses Wrap not Row:** SingleChildScrollView+Row clips chips; Wrap breaks into multiple lines automatically
- **Chip label color AppColors.background:** labelSmall (grey) is unreadable on gold selected chip — overridden to dark navy for contrast

## Backlog

- **Active filter bar overflow UX:** When many filters active, Wrap rows grow tall and card shrinks. Future fix: summary chip "Red · Creature +N ▾" opening a bottom sheet. Deferred — out of DISC-10 scope.

## Blockers

None.

---
*State last updated: 2026-04-16 (Phase 2 complete, Phase 3 next)*
